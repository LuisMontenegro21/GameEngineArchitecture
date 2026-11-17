-- Double-buffered event channels for one World.
--
-- Emission always targets the pending buffer. Readers observe snapshots of the
-- current buffer, so multiple readers never consume one another's events and
-- emissions during processing cannot extend the active iteration.

local Events = {}
Events.__index = Events

local states = setmetatable({}, { __mode = "k" })

local function stateOf(events)
    local state = states[events]
    assert(state ~= nil, "invalid Events container")
    return state
end

local function copyDefinition(definition)
    local copy = {}
    for key, value in pairs(definition) do
        copy[key] = value
    end
    return copy
end

local function ensureOpen(events, operation)
    local state = stateOf(events)
    assert(not state.disposed,
        "cannot " .. operation .. " on disposed events")
    return state
end

local function validatePayload(definition, payload)
    if not definition.validate then
        return
    end
    local ok, valid = pcall(definition.validate, payload)
    assert(ok and valid ~= false,
        "invalid payload for event: " .. definition.name)
end

local function clearChannels(channels)
    for name, records in pairs(channels) do
        for i = 1, #records do
            records[i] = nil
        end
        channels[name] = nil
    end
end

function Events.new(options)
    options = options or {}
    assert(type(options) == "table", "events options must be a table")
    local events = setmetatable({}, Events)
    states[events] = {
        definitions = {},
        current = {},
        pending = {},
        defaultCapacity = options.maxQueue,
        nextSequence = 1,
        disposed = false,
    }
    return events
end

function Events:register(name, definition)
    local state = ensureOpen(self, "register event")
    assert(type(name) == "string" and name ~= "",
        "event name must be a non-empty string")
    assert(state.definitions[name] == nil,
        "event type already registered: " .. name)
    assert(definition == nil or type(definition) == "table",
        "event definition must be a table")

    definition = definition or {}
    if definition.validate ~= nil then
        assert(type(definition.validate) == "function",
            "event validator must be a function: " .. name)
    end

    local capacity = definition.maxQueue or state.defaultCapacity
    if capacity ~= nil then
        assert(type(capacity) == "number" and capacity >= 1 and capacity % 1 == 0,
            "event maxQueue must be a positive integer: " .. name)
    end

    local version = definition.version or 1
    assert(type(version) == "number" and version >= 1 and version % 1 == 0,
        "event version must be a positive integer: " .. name)

    local normalized = {
        name = name,
        version = version,
        maxQueue = capacity,
        validate = definition.validate,
    }
    state.definitions[name] = normalized
    return copyDefinition(normalized)
end

function Events:hasDefinition(name)
    return stateOf(self).definitions[name] ~= nil
end

function Events:definition(name)
    local definition = stateOf(self).definitions[name]
    return definition and copyDefinition(definition) or nil
end

function Events:requireDefinition(name)
    local definition = stateOf(self).definitions[name]
    assert(definition ~= nil, "unregistered event type: " .. tostring(name))
    return copyDefinition(definition)
end

function Events:names()
    local names = {}
    for name in pairs(stateOf(self).definitions) do
        names[#names + 1] = name
    end
    table.sort(names)
    return names
end

function Events:emit(name, payload)
    local state = ensureOpen(self, "emit event")
    local definition = state.definitions[name]
    assert(definition ~= nil, "unregistered event type: " .. tostring(name))
    validatePayload(definition, payload)

    local records = state.pending[name]
    if not records then
        records = {}
        state.pending[name] = records
    end
    if definition.maxQueue and #records >= definition.maxQueue then
        error(("event queue limit reached for %s (%d)"):format(
            name, definition.maxQueue), 2)
    end

    local record = {
        name = name,
        payload = payload,
        sequence = state.nextSequence,
    }
    state.nextSequence = state.nextSequence + 1
    records[#records + 1] = record
    return record.sequence
end

function Events:read(name)
    local state = ensureOpen(self, "read events")
    assert(state.definitions[name] ~= nil,
        "unregistered event type: " .. tostring(name))
    local source = state.current[name] or {}
    local snapshot = {}
    for i, record in ipairs(source) do
        snapshot[i] = {
            name = record.name,
            payload = record.payload,
            sequence = record.sequence,
        }
    end

    local index = 0
    return function()
        index = index + 1
        return snapshot[index]
    end
end

function Events:count(name)
    local state = stateOf(self)
    assert(state.definitions[name] ~= nil,
        "unregistered event type: " .. tostring(name))
    return #(state.current[name] or {})
end

function Events:pendingCount(name)
    local state = stateOf(self)
    assert(state.definitions[name] ~= nil,
        "unregistered event type: " .. tostring(name))
    return #(state.pending[name] or {})
end

function Events:advance()
    local state = ensureOpen(self, "advance events")
    local oldCurrent = state.current
    state.current = state.pending
    state.pending = oldCurrent
    clearChannels(state.pending)
end

function Events:clear()
    local state = ensureOpen(self, "clear events")
    clearChannels(state.current)
    clearChannels(state.pending)
end

function Events:validate()
    local state = ensureOpen(self, "validate events")
    for _, channels in ipairs({ state.current, state.pending }) do
        for name, records in pairs(channels) do
            local definition = state.definitions[name]
            assert(definition ~= nil, "event channel has no definition: " .. name)
            if definition.maxQueue then
                assert(#records <= definition.maxQueue,
                    "event queue exceeds configured limit: " .. name)
            end
            for _, record in ipairs(records) do
                validatePayload(definition, record.payload)
            end
        end
    end
    return true
end

function Events:stats(name)
    local state = stateOf(self)
    local definition = state.definitions[name]
    assert(definition ~= nil, "unregistered event type: " .. tostring(name))
    return {
        name = name,
        version = definition.version,
        maxQueue = definition.maxQueue,
        current = #(state.current[name] or {}),
        pending = #(state.pending[name] or {}),
    }
end

function Events:dispose()
    local state = stateOf(self)
    if state.disposed then
        return false
    end
    state.disposed = true
    clearChannels(state.current)
    clearChannels(state.pending)
    state.definitions = nil
    state.current = nil
    state.pending = nil
    return true
end

return Events
