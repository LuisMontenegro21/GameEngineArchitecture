-- Query views over one World.
--
-- Query metadata is normalized and cached by World. Each Query instance keeps
-- its own changed-filter baseline and active iterator tokens.

local Query = {}
Query.__index = Query

local queryStates = setmetatable({}, { __mode = "k" })

local function copyList(values)
    local copy = {}
    for i, value in ipairs(values) do
        copy[i] = value
    end
    return copy
end

local function contains(values, wanted)
    for _, value in ipairs(values) do
        if value == wanted then
            return true
        end
    end
    return false
end

local function sortedCandidates(state, metadata)
    if #metadata.all == 0 then
        local handles = state.entity:entities()
        local ids = {}
        for i, handle in ipairs(handles) do
            ids[i] = handle.id
        end
        return ids
    end

    local smallestName = metadata.all[1]
    local smallestStore = state.stores[smallestName]
    for i = 2, #metadata.all do
        local store = state.stores[metadata.all[i]]
        if store:count() < smallestStore:count() then
            smallestName = metadata.all[i]
            smallestStore = store
        end
    end

    local candidates = smallestStore:entities()
    if metadata.stable then
        table.sort(candidates)
    end
    return candidates
end

local function hasAll(state, id, names)
    for _, name in ipairs(names) do
        if not state.stores[name]:has(id) then
            return false
        end
    end
    return true
end

local function hasAny(state, id, names)
    if #names == 0 then
        return true
    end
    for _, name in ipairs(names) do
        if state.stores[name]:has(id) then
            return true
        end
    end
    return false
end

local function hasNone(state, id, names)
    for _, name in ipairs(names) do
        if state.stores[name]:has(id) then
            return false
        end
    end
    return true
end

local function hasChanged(state, id, names, baseline)
    for _, name in ipairs(names) do
        local versions = state.componentChanges[name]
        if not versions or not versions[id] or versions[id] <= baseline then
            return false
        end
    end
    return true
end

function Query.new(world, state, metadata)
    local query = setmetatable({}, Query)
    queryStates[query] = {
        world = world,
        state = state,
        metadata = metadata,
        baseline = state.changeVersion,
        tokens = {},
    }
    return query
end

function Query:specification()
    local state = queryStates[self]
    assert(state ~= nil, "invalid Query object")
    local metadata = state.metadata
    return {
        all = copyList(metadata.allOutput),
        any = copyList(metadata.anyOutput),
        none = copyList(metadata.noneOutput),
        optional = copyList(metadata.optionalOutput),
        changed = copyList(metadata.changedOutput),
        stable = metadata.stable,
    }
end

function Query:_matchingIds()
    local queryState = queryStates[self]
    assert(queryState ~= nil, "invalid Query object")
    local state = queryState.state
    local metadata = queryState.metadata
    local candidates = sortedCandidates(state, metadata)
    local result = {}

    for _, id in ipairs(candidates) do
        if hasAll(state, id, metadata.all)
            and hasAny(state, id, metadata.any)
            and hasNone(state, id, metadata.none)
            and hasChanged(state, id, metadata.changed, queryState.baseline) then
            result[#result + 1] = id
        end
    end

    return result
end

function Query:_closeToken(token)
    local queryState = queryStates[self]
    if not queryState or not queryState.tokens[token] then
        return
    end

    queryState.tokens[token] = nil
    queryState.state.activeIterators = queryState.state.activeIterators - 1
    queryState.baseline = queryState.state.changeVersion
end

function Query:close()
    local queryState = queryStates[self]
    assert(queryState ~= nil, "invalid Query object")
    local tokens = {}
    for token in pairs(queryState.tokens) do
        tokens[#tokens + 1] = token
    end
    for _, token in ipairs(tokens) do
        self:_closeToken(token)
    end
end

function Query:entities()
    local queryState = queryStates[self]
    assert(queryState ~= nil, "invalid Query object")
    local ids = self:_matchingIds()
    local result = {}
    for i, id in ipairs(ids) do
        result[i] = queryState.state.entity:handleForId(id)
    end
    queryState.baseline = queryState.state.changeVersion
    return result
end

function Query:count()
    return #self:_matchingIds()
end

function Query:each()
    local queryState = queryStates[self]
    assert(queryState ~= nil, "invalid Query object")
    local ids = self:_matchingIds()
    local metadata = queryState.metadata
    local state = queryState.state
    local token = {}
    queryState.tokens[token] = true
    state.activeIterators = state.activeIterators + 1

    local index = 0
    local closed = false
    local function finish()
        if not closed then
            closed = true
            self:_closeToken(token)
        end
    end

    return function()
        index = index + 1
        local id = ids[index]
        if not id then
            finish()
            return nil
        end

        local handle = state.entity:handleForId(id)
        if not handle then
            finish()
            return nil
        end

        local values = {}
        local valueIndex = 0
        for _, name in ipairs(metadata.allOutput) do
            valueIndex = valueIndex + 1
            values[valueIndex] = state.stores[name]:get(id)
        end
        for _, name in ipairs(metadata.optionalOutput) do
            valueIndex = valueIndex + 1
            values[valueIndex] = state.stores[name]:get(id)
        end

        if valueIndex == 0 then
            return handle
        end
        return handle, unpack(values, 1, valueIndex)
    end
end

return Query
