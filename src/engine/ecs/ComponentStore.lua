-- Storage for one registered component type.

local SparseSet = require("src.engine.ecs.SparseSet")

local ComponentStore = {}
ComponentStore.__index = ComponentStore

local function copyDefinition(definition)
    local copy = {}
    for key, value in pairs(definition) do
        copy[key] = value
    end
    return copy
end

function ComponentStore.new(definition)
    assert(type(definition) == "table", "component store requires a definition")
    assert(type(definition.name) == "string" and definition.name ~= "",
        "component definition requires a name")
    assert(type(definition.typeId) == "number",
        "component definition requires a type ID")

    local tag = definition.tag == true
    return setmetatable({
        definition = copyDefinition(definition),
        sparse = SparseSet.new(not tag),
        tag = tag,
        used = false,
    }, ComponentStore)
end

function ComponentStore:name()
    return self.definition.name
end

function ComponentStore:typeId()
    return self.definition.typeId
end

function ComponentStore:isTag()
    return self.tag
end

function ComponentStore:definitionCopy()
    return copyDefinition(self.definition)
end

function ComponentStore:_validate(value)
    if self.tag then
        return true
    end

    if self.definition.validate then
        local valid, result = pcall(self.definition.validate, value)
        assert(valid and result ~= false,
            "invalid value for component: " .. self.definition.name)
    end
    return true
end

function ComponentStore:_default()
    if self.tag then
        return nil
    end

    local value = self.definition.default()
    self:_validate(value)
    return value
end

function ComponentStore:prepare(value)
    if self.tag then
        return nil
    end
    if value == nil then
        return self:_default()
    end
    self:_validate(value)
    return value
end

function ComponentStore:add(entityId, value, prepared)
    assert(not self:has(entityId),
        "entity already has component: " .. self.definition.name)

    if not self.tag then
        if not prepared then
            value = self:prepare(value)
        end
    end

    local added = self.sparse:add(entityId, value)
    assert(added, "failed to add component: " .. self.definition.name)
    self.used = true
    return self.tag and true or value
end

function ComponentStore:set(entityId, value)
    assert(self:has(entityId),
        "entity does not have component: " .. self.definition.name)

    if not self.tag then
        self:_validate(value)
    end
    assert(self.sparse:set(entityId, value),
        "failed to set component: " .. self.definition.name)
    self.used = true
    return self.tag and true or value
end

function ComponentStore:get(entityId)
    return self.sparse:get(entityId)
end

function ComponentStore:has(entityId)
    return self.sparse:has(entityId)
end

function ComponentStore:remove(entityId)
    return self.sparse:remove(entityId)
end

function ComponentStore:count()
    return self.sparse:count()
end

function ComponentStore:entities()
    return self.sparse:entities()
end

function ComponentStore:each()
    return self.sparse:each()
end

function ComponentStore:stats()
    local stats = self.sparse:stats()
    stats.name = self.definition.name
    stats.typeId = self.definition.typeId
    stats.tag = self.tag
    stats.used = self.used
    return stats
end

function ComponentStore:validate()
    return self.sparse:validate()
end

return ComponentStore
