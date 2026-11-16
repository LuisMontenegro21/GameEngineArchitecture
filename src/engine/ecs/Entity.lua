-- Generational entity manager for the new ECS.
--
-- An entity is only an identity. Component storage is introduced in a later
-- phase. Handles contain an ID and generation so a recycled ID cannot be used
-- through an old reference by accident.

local Entity = {}
Entity.__index = Entity

local VALIDATION_MODES = {
    off = true,
    warn = true,
    strict = true,
}

local function copyHandle(id, generation)
    return {
        id = id,
        generation = generation,
    }
end

local function handleShapeIsValid(handle)
    return type(handle) == "table"
        and type(handle.id) == "number"
        and handle.id >= 1
        and handle.id % 1 == 0
        and type(handle.generation) == "number"
        and handle.generation >= 1
        and handle.generation % 1 == 0
end

function Entity.new(options)
    if options == nil then
        options = {}
    end
    assert(type(options) == "table", "entity manager options must be a table")

    local validation = options.validation or "strict"
    assert(VALIDATION_MODES[validation],
        "unknown entity validation mode: " .. tostring(validation))

    return setmetatable({
        nextId = 1,
        generations = {}, -- entity ID -> current generation
        alive = {},       -- entity ID -> true
        free = {},        -- recycled IDs, used as a stack
        liveCount = 0,
        validation = validation,
        diagnostic = options.diagnostic,
        disposed = false,
    }, Entity)
end

function Entity.equals(left, right)
    return handleShapeIsValid(left)
        and handleShapeIsValid(right)
        and left.id == right.id
        and left.generation == right.generation
end

function Entity.toString(handle)
    if not handleShapeIsValid(handle) then
        return "Entity(<invalid>)"
    end
    return ("Entity(%d:%d)"):format(handle.id, handle.generation)
end

function Entity:isDisposed()
    return self.disposed
end

function Entity:validationMode()
    return self.validation
end

function Entity:setValidationMode(mode)
    assert(VALIDATION_MODES[mode],
        "unknown entity validation mode: " .. tostring(mode))
    self.validation = mode
end

function Entity:_issue(message)
    if self.validation == "strict" then
        error(message, 3)
    end

    if self.validation == "warn" and self.diagnostic then
        self.diagnostic(message)
    end

    return false
end

function Entity:_ensureOpen(operation)
    if self.disposed then
        return self:_issue("cannot " .. operation .. " on a disposed entity manager")
    end
    return true
end

function Entity:_isCurrent(handle)
    if not handleShapeIsValid(handle) then
        return false
    end

    return self.alive[handle.id] == true
        and self.generations[handle.id] == handle.generation
end

function Entity:isAlive(handle)
    if self.disposed then
        return false
    end
    return self:_isCurrent(handle)
end

function Entity:handleForId(id)
    if self.disposed or type(id) ~= "number" or id % 1 ~= 0 or id < 1 then
        return nil
    end
    if not self.alive[id] then
        return nil
    end
    return copyHandle(id, self.generations[id])
end

function Entity:requireAlive(handle, operation)
    operation = operation or "use entity"
    if not self:_ensureOpen(operation) then
        return false
    end

    if not self:_isCurrent(handle) then
        return self:_issue(
            ("cannot %s stale or invalid %s"):format(operation, Entity.toString(handle))
        )
    end

    return true
end

function Entity:create()
    if not self:_ensureOpen("create entity") then
        return nil
    end

    local recycled = #self.free > 0
    local id
    if recycled then
        id = self.free[#self.free]
        self.free[#self.free] = nil
    else
        id = self.nextId
        self.nextId = self.nextId + 1
    end

    local generation = self.generations[id] or 1
    self.generations[id] = generation
    self.alive[id] = true
    self.liveCount = self.liveCount + 1

    return copyHandle(id, generation)
end

function Entity:destroy(handle)
    if not self:requireAlive(handle, "destroy entity") then
        return false
    end

    local id = handle.id
    self.alive[id] = nil
    self.generations[id] = self.generations[id] + 1
    self.free[#self.free + 1] = id
    self.liveCount = self.liveCount - 1
    return true
end

function Entity:count()
    return self.liveCount
end

function Entity:generationOf(id)
    if type(id) ~= "number" or id % 1 ~= 0 or id < 1 then
        return nil
    end
    return self.generations[id]
end

function Entity:entities()
    local ids = {}
    for id in pairs(self.alive) do
        ids[#ids + 1] = id
    end
    table.sort(ids)

    local result = {}
    for i, id in ipairs(ids) do
        result[i] = copyHandle(id, self.generations[id])
    end
    return result
end

function Entity:each()
    local snapshot = self:entities()
    local index = 0
    return function()
        index = index + 1
        return snapshot[index]
    end
end

function Entity:stats()
    local recycled = 0
    for _ in pairs(self.free) do
        recycled = recycled + 1
    end

    return {
        live = self.liveCount,
        allocated = self.nextId - 1,
        recycled = recycled,
        nextId = self.nextId,
        disposed = self.disposed,
    }
end

function Entity:clear()
    if not self:_ensureOpen("clear entities") then
        return false
    end

    for id in pairs(self.alive) do
        self.alive[id] = nil
        self.generations[id] = self.generations[id] + 1
        self.free[#self.free + 1] = id
    end
    self.liveCount = 0
    return true
end

function Entity:dispose()
    if self.disposed then
        return false
    end

    self:clear()
    self.disposed = true
    self.diagnostic = nil
    return true
end

return Entity
