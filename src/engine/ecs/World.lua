-- Public ECS state facade.
--
-- World owns entity identity, component definitions, and component stores. It
-- deliberately does not expose those mutable internals or execute systems.
-- Scheduler and Runtime are introduced in later phases.

local Entity = require("src.engine.ecs.Entity")
local ComponentRegistry = require("src.engine.ecs.ComponentRegistry")
local ComponentStore = require("src.engine.ecs.ComponentStore")
local Query = require("src.engine.ecs.Query")
local CommandBuffer = require("src.engine.ecs.CommandBuffer")
local Resources = require("src.engine.ecs.Resources")
local Events = require("src.engine.ecs.Events")

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
local function assertMutable(state)
    assert(not state.readOnly, "world is read-only during render")
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

local function relationshipId(handle)
    return handle and handle.id
end

local function removeChildIndex(state, parentId, childId)
    local children = state.children[parentId]
    if not children then return end
    children[childId] = nil
    if next(children) == nil then state.children[parentId] = nil end
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
        resources = Resources.new(),
        events = Events.new(options.events),
        stores = {},
        queryCache = {},
        activeIterators = 0,
        changeVersion = 0,
        componentChanges = {},
        resourceVersion = 0,
        structuralVersion = 0,
        disposed = false,
        readOnly = false,
        parent = {},
        children = {},
        relationshipPolicy = options.relationshipPolicy or "cascade",
    }
    states[world].commandBuffer = CommandBuffer.new(world)
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
    assertMutable(state)
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

function World:registerResource(name, definition)
    local state = ensureOpen(self, "register resource")
    assertMutable(state)
    assertNoActiveIterators(state, "register resource")
    local normalized = state.resources:register(name, definition)
    state.resourceVersion = state.resourceVersion + 1
    return normalized
end

function World:hasResourceDefinition(name)
    return stateOf(self).resources:hasDefinition(name)
end

function World:resourceDefinition(name)
    return stateOf(self).resources:definition(name)
end

function World:resourceNames()
    return stateOf(self).resources:names()
end

function World:resourceVersion()
    return stateOf(self).resourceVersion
end

function World:hasResource(name)
    return stateOf(self).resources:has(name)
end

function World:getResource(name)
    return stateOf(self).resources:get(name)
end

function World:requireResource(name)
    return stateOf(self).resources:require(name)
end

function World:setResource(name, value)
    local state = ensureOpen(self, "set resource")
    assertMutable(state)
    local _, changed = state.resources:set(name, value)
    if changed then
        state.resourceVersion = state.resourceVersion + 1
    end
    return value
end

function World:removeResource(name)
    local state = ensureOpen(self, "remove resource")
    assertMutable(state)
    local value, removed = state.resources:remove(name)
    if removed then
        state.resourceVersion = state.resourceVersion + 1
    end
    return value, removed
end

function World:resourceStats(name)
    return stateOf(self).resources:stats(name)
end

function World:registerEvent(name, definition)
    local state = ensureOpen(self, "register event")
    assertMutable(state)
    assertNoActiveIterators(state, "register event")
    return state.events:register(name, definition)
end

function World:hasEventDefinition(name)
    return stateOf(self).events:hasDefinition(name)
end

function World:eventDefinition(name)
    return stateOf(self).events:definition(name)
end

function World:eventNames()
    return stateOf(self).events:names()
end

function World:emit(name, payload)
    local state = ensureOpen(self, "emit event"); assertMutable(state)
    return state.events:emit(name, payload)
end

function World:events(name)
    return ensureOpen(self, "read events").events:read(name)
end

function World:eventCount(name)
    return stateOf(self).events:count(name)
end

function World:pendingEventCount(name)
    return stateOf(self).events:pendingCount(name)
end

function World:eventStats(name)
    return stateOf(self).events:stats(name)
end

function World:advanceEvents()
    local state = ensureOpen(self, "advance events"); assertMutable(state); state.events:advance()
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
    assertMutable(state)
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
    assertMutable(state)
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
    assertMutable(state)
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

function World:getParent(handle)
    local state = requireEntity(self, handle, "get parent")
    local parentId = state.parent[handle.id]
    return parentId and state.entity:handleForId(parentId) or nil
end

function World:children(handle)
    local state = requireEntity(self, handle, "get children")
    local result = {}
    for childId in pairs(state.children[handle.id] or {}) do
        local child = state.entity:handleForId(childId)
        if child then result[#result + 1] = child end
    end
    table.sort(result, function(a, b) return a.id < b.id end)
    return result
end

function World:descendants(handle)
    local result = {}
    local function visit(parent)
        for _, child in ipairs(self:children(parent)) do
            result[#result + 1] = child
            visit(child)
        end
    end
    requireEntity(self, handle, "get descendants")
    visit(handle)
    return result
end

function World:setParent(child, parent)
    local state = requireEntity(self, child, "set parent")
    assertMutable(state)
    assert(parent == nil or state.entity:requireAlive(parent, "set parent"),
        "invalid parent entity")
    if parent and child.id == parent.id then error("entity cannot parent itself", 2) end
    local cursor = parent
    while cursor do
        if cursor.id == child.id then error("relationship cycle detected", 2) end
        local nextId = state.parent[cursor.id]
        cursor = nextId and state.entity:handleForId(nextId) or nil
    end
    local oldId = state.parent[child.id]
    local newId = parent and parent.id or nil
    if oldId == newId then return false end
    if oldId then removeChildIndex(state, oldId, child.id) end
    state.parent[child.id] = newId
    if newId then
        state.children[newId] = state.children[newId] or {}
        state.children[newId][child.id] = true
    end
    state.structuralVersion = state.structuralVersion + 1
    return true
end

World.reparent = World.setParent

function World:remove(handle, name)
    local state = requireEntity(self, handle, "remove component")
    assertMutable(state)
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

function World:destroy(handle, policy)
    local state = requireEntity(self, handle, "destroy entity")
    assertMutable(state)
    assertNoActiveIterators(state, "destroy entity")
    policy = policy or state.relationshipPolicy
    assert(policy == "cascade" or policy == "orphan" or policy == "reject",
        "unknown destruction policy: " .. tostring(policy))
    local childIds = {}
    for childId in pairs(state.children[handle.id] or {}) do childIds[#childIds + 1] = childId end
    if policy == "reject" and #childIds > 0 then error("cannot destroy entity with children", 2) end
    if policy == "cascade" then
        table.sort(childIds)
        for _, childId in ipairs(childIds) do
            local child = state.entity:handleForId(childId)
            if child then self:destroy(child, "cascade") end
        end
    elseif policy == "orphan" then
        for _, childId in ipairs(childIds) do state.parent[childId] = nil end
        state.children[handle.id] = nil
    end
    local parentId = state.parent[handle.id]
    if parentId then removeChildIndex(state, parentId, handle.id) end
    state.parent[handle.id] = nil
    state.children[handle.id] = nil
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
    assertMutable(state)
    assertNoActiveIterators(state, "clear world")
    local handles = state.entity:entities()
    for _, handle in ipairs(handles) do
        self:destroy(handle)
    end
    return #handles
end

function World:touch(handle, name)
    local state = requireEntity(self, handle, "touch component")
    assertMutable(state)
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

function World:commands()
    return ensureOpen(self, "access command buffer").commandBuffer
end

function World:flush()
    local state = ensureOpen(self, "flush commands")
    assertMutable(state)
    assertNoActiveIterators(state, "flush commands")
    return state.commandBuffer:_flush()
end

function World:componentStats(name)
    local state = stateOf(self)
    local store = state.stores[name]
    assert(store ~= nil, "unregistered component type: " .. tostring(name))
    return store:stats()
end

function World:inspect()
    local state = ensureOpen(self, "inspect world")
    local components = {}
    for _, name in ipairs(state.components:names()) do components[name] = self:componentStats(name) end
    local resources, events = {}, {}
    for _, name in ipairs(state.resources:names()) do resources[name] = self:resourceStats(name) end
    for _, name in ipairs(state.events:names()) do events[name] = self:eventStats(name) end
    local childLinks = 0
    for _, children in pairs(state.children) do for _ in pairs(children) do childLinks = childLinks + 1 end end
    return { identity = state.identity, entities = state.entity:count(), components = components,
        resources = resources, events = events, relationships = childLinks,
        structuralVersion = state.structuralVersion, changeVersion = state.changeVersion,
        resourceVersion = state.resourceVersion, readOnly = state.readOnly }
end

function World:validateDetailed()
    local ok, message = pcall(function() self:validate() end)
    return ok, ok and nil or tostring(message)
end

function World:validate()
    local state = ensureOpen(self, "validate world")
    assert(state.resources:validate(), "invalid resource container")
    assert(state.events:validate(), "invalid event channels")
    for name, store in pairs(state.stores) do
        assert(store:validate(), "invalid component store: " .. name)
        for entityId in store:each() do
            assert(state.entity:handleForId(entityId) ~= nil,
                ("component %s contains dead entity ID %d"):format(name, entityId))
        end
    end
    for childId, parentId in pairs(state.parent) do
        assert(state.entity:handleForId(childId) ~= nil, "stale relationship child")
        assert(state.entity:handleForId(parentId) ~= nil, "stale relationship parent")
        assert(state.children[parentId] and state.children[parentId][childId],
            "relationship indexes disagree")
    end
    for parentId, children in pairs(state.children) do
        assert(state.entity:handleForId(parentId) ~= nil, "stale relationship parent index")
        for childId in pairs(children) do
            assert(state.parent[childId] == parentId, "relationship indexes disagree")
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
    assertMutable(state)
    state.commandBuffer:clear()
    self:clear()
    state.resources:dispose()
    state.events:dispose()
    state.entity:dispose()
    state.components = nil
    state.resources = nil
    state.events = nil
    state.stores = nil
    state.disposed = true
    return true
end

function World:withReadOnly(callback)
    local state = ensureOpen(self, "enter read-only scope")
    assert(type(callback) == "function", "callback must be a function")
    assert(not state.readOnly, "world is already read-only")
    state.readOnly = true
    local ok, result = xpcall(callback, debug and debug.traceback or function(message) return message end)
    state.readOnly = false
    if not ok then error(result, 0) end
    return result
end
function World:isReadOnly() return stateOf(self).readOnly end

function World:snapshot()
    return require("src.engine.ecs.Snapshot").capture(self)
end

function World:restoreSnapshot(snapshot)
    return require("src.engine.ecs.Snapshot").restore(self, snapshot)
end

return World
