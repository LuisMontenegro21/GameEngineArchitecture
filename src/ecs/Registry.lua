-- Components are stored by type:
-- registry.components.position[entity] = { x = 30, y = 50 }
local Registry = {}
Registry.__index = Registry

local unpackValues = table.unpack or unpack

local function removeEntity(registry, entity)
    registry.alive[entity] = nil
    registry.pendingDestroy[entity] = nil

    for _, store in pairs(registry.components) do
        store[entity] = nil
    end
end

function Registry.new()
    return setmetatable({
        nextEntity = 1,
        alive = {},
        components = {},
        pendingDestroy = {},
        resources = {},
    }, Registry)
end

function Registry:add(entity, component, data)
    assert(type(entity) == "number", "entity IDs must be numbers")
    assert(type(component) == "string", "component names must be strings")

    local store = self.components[component]
    if not store then
        store = {}
        self.components[component] = store
    end

    self.alive[entity] = true
    self.pendingDestroy[entity] = nil
    self.nextEntity = math.max(self.nextEntity, entity + 1)
    store[entity] = data
end

function Registry:get(entity, component)
    local store = self.components[component]
    return store and store[entity]
end

function Registry:remove(entity, component)
    local store = self.components[component]
    if store then
        store[entity] = nil
    end
end

function Registry:destroy(entity)
    if self.alive[entity] then
        removeEntity(self, entity)
    end
end

function Registry:destroyLater(entity)
    if self.alive[entity] then
        self.pendingDestroy[entity] = true
    end
end

function Registry:flushDestroyed()
    for entity in pairs(self.pendingDestroy) do
        removeEntity(self, entity)
    end
end

function Registry:spawn(entityComponents)
    assert(type(entityComponents) == "table", "components must be a table")

    local entity = self.nextEntity
    self.nextEntity = entity + 1
    self.alive[entity] = true

    for component, data in pairs(entityComponents) do
        self:add(entity, component, data)
    end

    return entity
end

function Registry:query(...)
    local componentNames = { ... }
    local candidates

    if #componentNames == 0 then
        candidates = self.alive
    else
        candidates = self.components[componentNames[1]]
        if not candidates then
            return {}
        end
    end

    local result = {}
    for entity in pairs(candidates) do
        local matches = self.alive[entity] and not self.pendingDestroy[entity]

        for index = 2, #componentNames do
            local store = self.components[componentNames[index]]
            if not store or store[entity] == nil then
                matches = false
                break
            end
        end

        if matches then
            result[#result + 1] = entity
        end
    end

    table.sort(result)
    return result
end

function Registry:each(...)
    local componentNames = { ... }
    local entities = self:query(...)
    local index = 0

    return function()
        while true do
            index = index + 1
            local entity = entities[index]
            if not entity then
                return nil
            end

            if self.alive[entity] and not self.pendingDestroy[entity] then
                local values = {}
                for valueIndex, componentName in ipairs(componentNames) do
                    values[valueIndex] = self.components[componentName][entity]
                end

                return entity, unpackValues(values, 1, #componentNames)
            end
        end
    end
end

function Registry:first(...)
    local iterator = self:each(...)
    return iterator()
end

function Registry:setResource(name, value)
    assert(type(name) == "string", "resource names must be strings")
    self.resources[name] = value
    return value
end

function Registry:resource(name)
    return self.resources[name]
end

return Registry
