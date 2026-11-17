local Snapshot = require("src.engine.ecs.Snapshot")
local Prefab = {}

function Prefab.capture(world, root)
    local snapshot = Snapshot.capture(world)
    local keep = {[root.id] = true}
    for _, entity in ipairs(world:descendants(root)) do keep[entity.id] = true end
    local entities = {}
    for _, record in ipairs(snapshot.entities) do
        if keep[record.id] then entities[#entities + 1] = record end
    end
    snapshot.entities = entities
    snapshot.root = root.id
    return snapshot
end

function Prefab.instantiate(world, prefab, overrides)
    assert(type(prefab) == "table" and type(prefab.entities) == "table", "invalid prefab")
    local snapshot = {}
    for key, value in pairs(prefab) do snapshot[key] = value end
    snapshot.entities = {}
    for i, record in ipairs(prefab.entities) do
        local out = { id = record.id, parent = record.parent, components = {} }
        for name, component in pairs(record.components) do
            out.components[name] = { version = component.version, value = component.value }
        end
        snapshot.entities[i] = out
    end
    if overrides then
        for name, value in pairs(overrides) do
            local root = snapshot.entities[1]
            root.components[name] = { version = 1, value = value }
        end
    end
    local remap = Snapshot.restore(world, snapshot)
    return remap[prefab.root or prefab.entities[1].id], remap
end

return Prefab
