-- Public ECS state facade.
--
-- World owns entity identity, component definitions, and component stores. It
-- deliberately does not expose those mutable internals or execute systems.
-- Scheduler and Runtime are introduced in later phases.

local Entity = require("src.engine.ecs.Entity")
local ComponentRegistry = require("src.engine.ecs.ComponentRegistry")
local ComponentStore = require("src.engine.ecs.ComponentStore")
local Query = require("src.engine.ecs.Query")

local World = {}
World.__index = World

local states = setmetatable({}, { __mode = "k" })
local nextWorldId = 1

local function stateOf(world)
    local state = states[world]
    assert(state ~= nil, "invalid or disposed World object")
    return state
end

local function ensureOpen(world, operation)
    local state = stateOf(world)
    assert(not state.disposed,
        "cannot " .. operation .. " on disposed world " .. state.identity)
    return state
end

local function sortedComponentNames(components)
    local names = {}
    for name in pairs(components) do
        names[#names + 1] = name
    end
    table.sort(names)
    return names
end

local function contains(values, wanted)
    for _, value in ipairs(values) do
        if value == wanted then
            return true
        end
    end
    return false
end

local function normalizeList(value, label, stores)
    if value == nil then
        return {}, {}
    end
    assert(type(value) == "table", label .. " must be an array")

    local ordered = {}
    local seen = {}
    for _, name in ipairs(value) do
        assert(type(name) == "string" and name ~= "",
            label .. " component names must be non-empty strings")
        assert(stores[name] ~= nil,
            "unregistered component type in " .. label .. ": " .. name)
        if not seen[name] then
            seen[name] = true
            ordered[#ordered + 1] = name
        end
    end

    local sorted = {}
    for i, name in ipairs(ordered) do
        sorted[i] = name
    end
    table.sort(sorted)
    return sorted, ordered
end

local function listKey(values)
    return table.concat(values, "\31")
end

local function normalizeQuerySpecification(specification, stores)
    if specification == nil then
        specification = {}
    end
    assert(type(specification) == "table", "query specification must be a table")

    local all, allOutput = normalizeList(specification.all, "all", stores)
    local any, anyOutput = normalizeList(specification.any, "any", stores)
    local none, noneOutput = normalizeList(specification.none, "none", stores)
    local optional, optionalOutput = normalizeList(
        specification.optional, "optional", stores)
    local changed, changedOutput = normalizeList(
        specification.changed, "changed", stores)

    for _, name in ipairs(optionalOutput) do
        assert(not contains(allOutput, name),
            "component cannot be both all and optional: " .. name)
    end

    local stable = specification.stable == true
    local key = table.concat({
        listKey(all),
        listKey(any),
        listKey(none),
        listKey(optional),
        listKey(changed),
        stable and "stable" or "fast",
    }, "\30")

    return {
        all = all,
        allOutput = allOutput,
        any = any,
        anyOutput = anyOutput,
        none = none,
        noneOutput = noneOutput,
        optional = optional,
        optionalOutput = optionalOutput,
        changed = changed,
        changedOutput = changedOutput,
        stable = stable,
        key = key,
    }
end

local function assertNoActiveIterators(state, operation)
    assert(state.activeIterators == 0,
        "cannot " .. operation .. " while a query iterator is active; close the query first")
end

local function markChanged(state, entityId, componentName)
    state.changeVersion = state.changeVersion + 1
    local versions = state.componentChanges[componentName]
    if not versions then
        versions = {}
        state.componentChanges[componentName] = versions
    end
    versions[entityId] = state.changeVersion
end

function World.new(options)
    if options == nil then
        options = {}
    end
    assert(type(options) == "table", "world options must be a table")

    local identity = options.identity
    if identity == nil then
        identity = "world-" .. tostring(nextWorldId)
    end
    assert(type(identity) == "string" and identity ~= "",
        "world identity must be a non-empty string")

    local world = setmetatable({}, World)
    states[world] = {
        identity = identity,
        entity = Entity.new({
            validation = options.validation,
            diagnostic = options.diagnostic,
        }),
        components = ComponentRegistry.new(),
        stores = {},
        queryCache = {},
        activeIterators = 0,
        changeVersion = 0,
        componentChanges = {},
        structuralVersion = 0,
        disposed = false,
    }
    nextWorldId = nextWorldId + 1
    return world
end

function World:identity()
    return stateOf(self).identity
end

function World:isDisposed()
    return stateOf(self).disposed
end

function World:structuralVersion()
    return stateOf(self).structuralVersion
end

function World:registerComponent(name, definition)
    local state = ensureOpen(self, "register component")
    assertNoActiveIterators(state, "register component")
    local normalized = state.components:register(name, definition)
    state.stores[name] = ComponentStore.new(normalized)
    state.structuralVersion = state.structuralVersion + 1
    return state.components:get(name)
end

function World:hasComponentType(name)
    return stateOf(self).components:has(name)
end

function World:componentDefinition(name)
    return stateOf(self).components:get(name)
end

function World:componentNames()
    return stateOf(self).components:names()
end

function World:isAlive(handle)
    return stateOf(self).entity:isAlive(handle)
end

function World:entities()
    return stateOf(self).entity:entities()
end

function World:count()
    return stateOf(self).entity:count()
end

function World:create(initialComponents)
    local state = ensureOpen(self, "create entity")
    assertNoActiveIterators(state, "create entity")
    if initialComponents == nil then
        initialComponents = {}
    end
    assert(type(initialComponents) == "table",
        "initial components must be a table")

    -- Preflight all names, defaults, and validators before allocating an entity.
    -- This is what makes create(initialComponents) atomic on validation failure.
    local names = sortedComponentNames(initialComponents)
    local prepared = {}
    for _, name in ipairs(names) do
        local store = state.stores[name]
        assert(store ~= nil, "unregistered component type: " .. tostring(name))
        prepared[name] = store:prepare(initialComponents[name])
    end

    local handle = state.entity:create()
    local added = {}
    local ok, message = pcall(function()
        for _, name in ipairs(names) do
            state.stores[name]:add(handle.id, prepared[name], true)
            added[#added + 1] = name
        end
    end)

    if not ok then
        for _, name in ipairs(added) do
            state.stores[name]:remove(handle.id)
        end
        state.entity:destroy(handle)
        error(message, 2)
    end

    for _, name in ipairs(names) do
        markChanged(state, handle.id, name)
    end

    state.structuralVersion = state.structuralVersion + 1
    return handle
end

local function requireEntity(world, handle, operation)
    local state = ensureOpen(world, operation)
    assert(state.entity:requireAlive(handle, operation),
        "invalid entity for operation: " .. operation)
    return state
end

function World:add(handle, name, value)
    local state = requireEntity(self, handle, "add component")
    assertNoActiveIterators(state, "add component")
    local store = state.stores[name]
    assert(store ~= nil, "unregistered component type: " .. tostring(name))
    local result = store:add(handle.id, value)
    markChanged(state, handle.id, name)
    state.structuralVersion = state.structuralVersion + 1
    return result
end

function World:set(handle, name, value)
    local state = requireEntity(self, handle, "set component")
    local store = state.stores[name]
    assert(store ~= nil, "unregistered component type: " .. tostring(name))
    local result = store:set(handle.id, value)
    markChanged(state, handle.id, name)
    -- Setting a value is not structural, so the structural version is stable.
    return result
end

function World:get(handle, name)
    local state = requireEntity(self, handle, "get component")
    local store = state.stores[name]
    assert(store ~= nil, "unregistered component type: " .. tostring(name))
    return store:get(handle.id)
end

function World:require(handle, name)
    local value = self:get(handle, name)
    assert(value ~= nil, "entity does not have component: " .. tostring(name))
    return value
end

function World:has(handle, name)
    local state = requireEntity(self, handle, "check component")
    local store = state.stores[name]
    assert(store ~= nil, "unregistered component type: " .. tostring(name))
    return store:has(handle.id)
end

function World:remove(handle, name)
    local state = requireEntity(self, handle, "remove component")
    assertNoActiveIterators(state, "remove component")
    local store = state.stores[name]
    assert(store ~= nil, "unregistered component type: " .. tostring(name))
    local value, removed = store:remove(handle.id)
    if removed then
        local versions = state.componentChanges[name]
        if versions then
            versions[handle.id] = nil
        end
        state.structuralVersion = state.structuralVersion + 1
    end
    return value, removed
end

function World:destroy(handle)
    local state = requireEntity(self, handle, "destroy entity")
    assertNoActiveIterators(state, "destroy entity")
    for _, store in pairs(state.stores) do
        store:remove(handle.id)
    end
    for name, versions in pairs(state.componentChanges) do
        versions[handle.id] = nil
    end
    assert(state.entity:destroy(handle), "failed to destroy entity")
    state.structuralVersion = state.structuralVersion + 1
    return true
end

function World:clear()
    local state = ensureOpen(self, "clear world")
    assertNoActiveIterators(state, "clear world")
    local handles = state.entity:entities()
    for _, handle in ipairs(handles) do
        self:destroy(handle)
    end
    return #handles
end

function World:touch(handle, name)
    local state = requireEntity(self, handle, "touch component")
    local store = state.stores[name]
    assert(store ~= nil, "unregistered component type: " .. tostring(name))
    assert(store:has(handle.id),
        "entity does not have component: " .. tostring(name))
    markChanged(state, handle.id, name)
    return true
end

function World:query(specification)
    local state = ensureOpen(self, "create query")
    local metadata = normalizeQuerySpecification(specification, state.stores)
    local cached = state.queryCache[metadata.key]
    if not cached then
        cached = metadata
        state.queryCache[metadata.key] = cached
    end
    return Query.new(self, state, cached)
end

function World:componentStats(name)
    local state = stateOf(self)
    local store = state.stores[name]
    assert(store ~= nil, "unregistered component type: " .. tostring(name))
    return store:stats()
end

function World:validate()
    local state = ensureOpen(self, "validate world")
    for name, store in pairs(state.stores) do
        assert(store:validate(), "invalid component store: " .. name)
        for entityId in store:each() do
            assert(state.entity:handleForId(entityId) ~= nil,
                ("component %s contains dead entity ID %d"):format(name, entityId))
        end
    end
    return true
end

function World:dispose()
    local state = stateOf(self)
    if state.disposed then
        return false
    end

    assertNoActiveIterators(state, "dispose world")
    self:clear()
    state.entity:dispose()
    state.components = nil
    state.stores = nil
    state.disposed = true
    return true
end

return World
