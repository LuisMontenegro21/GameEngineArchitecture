local Snapshot = {}
Snapshot.VERSION = 1
Snapshot.schemaVersion = "1.0"

local function clone(value, seen)
    local t = type(value)
    if t == "nil" or t == "boolean" or t == "number" or t == "string" then return value end
    assert(t == "table", "snapshot data must be plain Lua data")
    seen = seen or {}
    assert(not seen[value], "snapshot data cannot contain cycles")
    seen[value] = true
    local out = {}
    for k, v in pairs(value) do
        assert(type(k) == "string" or type(k) == "number", "snapshot keys must be strings or numbers")
        out[clone(k, seen)] = clone(v, seen)
    end
    seen[value] = nil
    return out
end

local function sortedEntities(world)
    local entities = world:entities()
    table.sort(entities, function(a, b) return a.id < b.id end)
    return entities
end

function Snapshot.capture(world)
    assert(world and type(world.entities) == "function", "Snapshot.capture requires World")
    local result = { version = Snapshot.VERSION, components = {}, resources = {}, entities = {} }
    for _, name in ipairs(world:componentNames()) do
        local definition = world:componentDefinition(name)
        result.components[name] = { version = definition.version }
    end
    for _, name in ipairs(world:resourceNames()) do
        local definition = world:resourceDefinition(name)
        local value = world:getResource(name)
        if definition.serializable and value ~= nil then
            result.resources[name] = { version = definition.version, value = clone(value) }
        end
    end
    for _, entity in ipairs(sortedEntities(world)) do
        local record = { id = entity.id, components = {} }
        local parent = world:getParent(entity)
        if parent then record.parent = parent.id end
        for _, name in ipairs(world:componentNames()) do
            if world:has(entity, name) then
                local definition = world:componentDefinition(name)
                local value = world:get(entity, name)
                record.components[name] = { version = definition.version,
                    value = definition.serialize and definition.serialize(value) or clone(value) }
            end
        end
        result.entities[#result.entities + 1] = record
    end
    return result
end

local function normalizeValue(definition, record)
    assert(type(record) == "table", "invalid serialized value")
    local value = clone(record.value)
    local version = record.version or 1
    if version ~= definition.version then
        assert(definition.migrate, "no migration for " .. definition.name)
        value = definition.migrate(value, version, definition.version)
    end
    if definition.deserialize then value = definition.deserialize(value) end
    return value
end

function Snapshot.restore(world, snapshot)
    assert(type(snapshot) == "table" and snapshot.version == Snapshot.VERSION, "unsupported snapshot")
    assert(type(snapshot.entities) == "table", "snapshot entities are required")
    local records, ids, prepared = {}, {}, {}
    for _, record in ipairs(snapshot.entities) do
        assert(type(record) == "table" and type(record.id) == "number" and not ids[record.id], "invalid entity record")
        ids[record.id] = true; records[#records + 1] = record
        assert(type(record.components) == "table", "invalid component record")
        for name, component in pairs(record.components) do
            local definition = world:componentDefinition(name)
            assert(definition, "unregistered component in snapshot: " .. name)
            prepared[record] = prepared[record] or {}
            prepared[record][name] = normalizeValue(definition, component)
        end
    end
    for _, record in ipairs(records) do
        if record.parent then assert(ids[record.parent], "invalid parent reference") end
    end
    for name, resource in pairs(snapshot.resources or {}) do
        local definition = world:resourceDefinition(name)
        assert(definition and definition.serializable, "invalid resource in snapshot: " .. name)
        local value = clone(resource.value)
        if resource.version ~= definition.version then error("resource migration unavailable: " .. name) end
        if definition.validate then assert(definition.validate(value) ~= false, "invalid resource value: " .. name) end
        prepared[resource] = value
    end
    local remap = {}
    for _, record in ipairs(records) do
        local components = {}
        for name in pairs(record.components) do components[name] = prepared[record][name] end
        remap[record.id] = world:create(components)
    end
    for _, record in ipairs(records) do
        if record.parent then world:setParent(remap[record.id], remap[record.parent]) end
    end
    for name, resource in pairs(snapshot.resources or {}) do world:setResource(name, prepared[resource]) end
    return remap
end

function Snapshot.load(world, snapshot)
    -- Validation happens before any entities/resources are created.
    return Snapshot.restore(world, snapshot)
end

return Snapshot
