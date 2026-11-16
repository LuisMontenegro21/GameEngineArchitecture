-- Registry of immutable component type definitions.

local ComponentRegistry = {}
ComponentRegistry.__index = ComponentRegistry

local function copyDefinition(definition)
    local copy = {}
    for key, value in pairs(definition) do
        copy[key] = value
    end
    return copy
end

local function normalizeDefault(definition, tag)
    if tag then
        assert(definition.default == nil,
            "tag component definitions cannot declare a default value")
        return nil
    end

    if definition.default == nil then
        return function()
            return {}
        end
    end

    if type(definition.default) == "function" then
        return definition.default
    end

    assert(type(definition.default) ~= "table",
        "mutable component defaults must be factory functions")

    local constant = definition.default
    return function()
        return constant
    end
end

function ComponentRegistry.new()
    return setmetatable({
        nextTypeId = 1,
        definitions = {},
        used = {},
    }, ComponentRegistry)
end

function ComponentRegistry:register(name, definition)
    assert(type(name) == "string" and name ~= "",
        "component name must be a non-empty string")
    assert(self.definitions[name] == nil,
        "component type already registered: " .. name)
    assert(definition == nil or type(definition) == "table",
        "component definition must be a table")

    definition = definition or {}
    local tag = definition.tag == true
    if definition.validate ~= nil then
        assert(type(definition.validate) == "function",
            "component validator must be a function: " .. name)
    end
    if definition.serialize ~= nil then
        assert(type(definition.serialize) == "function",
            "component serializer must be a function: " .. name)
    end
    if definition.deserialize ~= nil then
        assert(type(definition.deserialize) == "function",
            "component deserializer must be a function: " .. name)
    end
    if definition.migrate ~= nil then
        assert(type(definition.migrate) == "function",
            "component migrator must be a function: " .. name)
    end

    local version = definition.version or 1
    assert(type(version) == "number" and version >= 1 and version % 1 == 0,
        "component version must be a positive integer: " .. name)

    local normalized = {
        name = name,
        typeId = self.nextTypeId,
        version = version,
        tag = tag,
        default = normalizeDefault(definition, tag),
        validate = definition.validate,
        serialize = definition.serialize,
        deserialize = definition.deserialize,
        migrate = definition.migrate,
    }

    self.nextTypeId = self.nextTypeId + 1
    self.definitions[name] = normalized
    return copyDefinition(normalized)
end

function ComponentRegistry:has(name)
    return self.definitions[name] ~= nil
end

function ComponentRegistry:get(name)
    local definition = self.definitions[name]
    return definition and copyDefinition(definition) or nil
end

function ComponentRegistry:require(name)
    local definition = self.definitions[name]
    assert(definition ~= nil, "unregistered component type: " .. tostring(name))
    return copyDefinition(definition)
end

function ComponentRegistry:markUsed(name)
    self:require(name)
    self.used[name] = true
end

function ComponentRegistry:isUsed(name)
    return self.used[name] == true
end

function ComponentRegistry:names()
    local names = {}
    for name in pairs(self.definitions) do
        names[#names + 1] = name
    end
    table.sort(names)
    return names
end

function ComponentRegistry:count()
    local count = 0
    for _ in pairs(self.definitions) do
        count = count + 1
    end
    return count
end

return ComponentRegistry
