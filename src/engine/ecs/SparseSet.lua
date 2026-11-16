-- Dense/sparse membership storage keyed by numeric entity IDs.
--
-- This module knows nothing about Worlds, handles, components, or LOVE. The
-- World will validate a generational handle before passing its numeric ID to a
-- component store. A store can opt out of value storage for tag components.

local SparseSet = {}
SparseSet.__index = SparseSet

local function assertEntityId(entityId)
    assert(type(entityId) == "number"
        and entityId >= 1
        and entityId % 1 == 0,
        "sparse-set entity ID must be a positive integer")
end

function SparseSet.new(withValues)
    return setmetatable({
        dense = {},
        sparse = {},
        values = withValues and {} or nil,
    }, SparseSet)
end

function SparseSet:has(entityId)
    return self.sparse[entityId] ~= nil
end

function SparseSet:indexOf(entityId)
    return self.sparse[entityId]
end

function SparseSet:add(entityId, value)
    assertEntityId(entityId)
    if self:has(entityId) then
        return false
    end

    local index = #self.dense + 1
    self.dense[index] = entityId
    self.sparse[entityId] = index
    if self.values then
        self.values[index] = value
    end
    return true
end

function SparseSet:get(entityId)
    local index = self.sparse[entityId]
    if not index then
        return nil
    end

    if self.values then
        return self.values[index]
    end
    return true
end

function SparseSet:set(entityId, value)
    local index = self.sparse[entityId]
    if not index then
        return false
    end

    if self.values then
        self.values[index] = value
    end
    return true
end

function SparseSet:remove(entityId)
    local index = self.sparse[entityId]
    if not index then
        return nil, false
    end

    local lastIndex = #self.dense
    local oldValue = self.values and self.values[index] or true
    local lastEntityId = self.dense[lastIndex]

    if index ~= lastIndex then
        self.dense[index] = lastEntityId
        self.sparse[lastEntityId] = index
        if self.values then
            self.values[index] = self.values[lastIndex]
        end
    end

    self.dense[lastIndex] = nil
    self.sparse[entityId] = nil
    if self.values then
        self.values[lastIndex] = nil
    end

    return oldValue, true
end

function SparseSet:count()
    return #self.dense
end

function SparseSet:entities()
    local result = {}
    for i, entityId in ipairs(self.dense) do
        result[i] = entityId
    end
    return result
end

function SparseSet:each()
    local index = 0
    return function()
        index = index + 1
        local entityId = self.dense[index]
        if not entityId then
            return nil
        end
        if self.values then
            return entityId, self.values[index]
        end
        return entityId
    end
end

function SparseSet:stats()
    return {
        count = #self.dense,
        valueStorage = self.values and #self.values or 0,
    }
end

return SparseSet
