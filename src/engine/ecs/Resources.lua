-- Dedicated world-level resource container.
--
-- Resources are singleton values, not entities or components. Definitions and
-- values are kept private by the container and exposed through copies/queries.

local Resources = {}
Resources.__index = Resources

local states = setmetatable({}, { __mode = "k" })

local function stateOf(resources)
    local state = states[resources]
    assert(state ~= nil, "invalid Resources container")
    return state
end

local function copyDefinition(definition)
    local copy = {}
    for key, value in pairs(definition) do
        copy[key] = value
    end
    return copy
end

local function ensureOpen(resources, operation)
    local state = stateOf(resources)
    assert(not state.disposed,
        "cannot " .. operation .. " on disposed resources")
    return state
end

local function validateValue(definition, value)
    if not definition.validate then
        return
    end
    local ok, valid = pcall(definition.validate, value)
    assert(ok and valid ~= false,
        "invalid value for resource: " .. definition.name)
end

local function releaseValue(definition, value)
    if not definition.onDispose then
        return nil
    end
    local ok, message = pcall(definition.onDispose, value)
    if not ok then
        return tostring(message)
    end
    return nil
end

function Resources.new()
    local resources = setmetatable({}, Resources)
    states[resources] = {
        definitions = {},
        values = {},
        disposed = false,
    }
    return resources
end

function Resources:register(name, definition)
    local state = ensureOpen(self, "register resource")
    assert(type(name) == "string" and name ~= "",
        "resource name must be a non-empty string")
    assert(state.definitions[name] == nil,
        "resource type already registered: " .. name)
    assert(definition == nil or type(definition) == "table",
        "resource definition must be a table")

    definition = definition or {}
    if definition.validate ~= nil then
        assert(type(definition.validate) == "function",
            "resource validator must be a function: " .. name)
    end
    if definition.onDispose ~= nil then
        assert(type(definition.onDispose) == "function",
            "resource onDispose hook must be a function: " .. name)
    end

    local transient = definition.transient == true
    local serializable = definition.serializable
    if serializable == nil then
        serializable = not transient
    end
    assert(type(serializable) == "boolean",
        "resource serializable flag must be boolean: " .. name)
    if transient then
        serializable = false
    end

    local owned = definition.owned == true or definition.onDispose ~= nil
    if owned then
        assert(type(definition.onDispose) == "function",
            "owned resource requires an onDispose hook: " .. name)
    end

    local version = definition.version or 1
    assert(type(version) == "number" and version >= 1 and version % 1 == 0,
        "resource version must be a positive integer: " .. name)

    local normalized = {
        name = name,
        version = version,
        transient = transient,
        serializable = serializable,
        owned = owned,
        validate = definition.validate,
        onDispose = definition.onDispose,
    }
    state.definitions[name] = normalized
    return copyDefinition(normalized)
end

function Resources:hasDefinition(name)
    return stateOf(self).definitions[name] ~= nil
end

function Resources:definition(name)
    local definition = stateOf(self).definitions[name]
    return definition and copyDefinition(definition) or nil
end

function Resources:requireDefinition(name)
    local definition = stateOf(self).definitions[name]
    assert(definition ~= nil, "unregistered resource type: " .. tostring(name))
    return copyDefinition(definition)
end

function Resources:names()
    local names = {}
    for name in pairs(stateOf(self).definitions) do
        names[#names + 1] = name
    end
    table.sort(names)
    return names
end

function Resources:has(name)
    return stateOf(self).values[name] ~= nil
end

function Resources:get(name)
    return stateOf(self).values[name]
end

function Resources:require(name)
    local state = stateOf(self)
    assert(state.values[name] ~= nil,
        "required resource is not set: " .. tostring(name))
    return state.values[name]
end

function Resources:set(name, value)
    local state = ensureOpen(self, "set resource")
    local definition = state.definitions[name]
    assert(definition ~= nil, "unregistered resource type: " .. tostring(name))
    assert(value ~= nil, "resource values cannot be nil: " .. name)
    validateValue(definition, value)

    local oldValue = state.values[name]
    if oldValue == value then
        return value, false
    end

    if oldValue ~= nil then
        state.values[name] = nil
        local releaseError = releaseValue(definition, oldValue)
        if releaseError then
            error(("resource %s disposal failed: %s"):format(name, releaseError), 2)
        end
    end

    state.values[name] = value
    return value, true
end

function Resources:remove(name)
    local state = ensureOpen(self, "remove resource")
    local definition = state.definitions[name]
    assert(definition ~= nil, "unregistered resource type: " .. tostring(name))
    local value = state.values[name]
    if value == nil then
        return nil, false
    end

    state.values[name] = nil
    local releaseError = releaseValue(definition, value)
    if releaseError then
        error(("resource %s disposal failed: %s"):format(name, releaseError), 2)
    end
    return value, true
end

function Resources:_clearValues()
    local state = stateOf(self)
    local firstError = nil
    for name, value in pairs(state.values) do
        state.values[name] = nil
        local releaseError = releaseValue(state.definitions[name], value)
        if releaseError and not firstError then
            firstError = ("resource %s disposal failed: %s"):format(name, releaseError)
        end
    end
    if firstError then
        error(firstError, 2)
    end
end

function Resources:validate()
    local state = ensureOpen(self, "validate resources")
    for name, value in pairs(state.values) do
        validateValue(state.definitions[name], value)
    end
    return true
end

function Resources:stats(name)
    local state = stateOf(self)
    local definition = state.definitions[name]
    assert(definition ~= nil, "unregistered resource type: " .. tostring(name))
    return {
        name = name,
        version = definition.version,
        transient = definition.transient,
        serializable = definition.serializable,
        owned = definition.owned,
        present = state.values[name] ~= nil,
    }
end

function Resources:dispose()
    local state = stateOf(self)
    if state.disposed then
        return false
    end
    state.disposed = true
    self:_clearValues()
    state.definitions = nil
    state.values = nil
    return true
end

return Resources
