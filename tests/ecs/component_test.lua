local Assert = require("tests.support.assert")
local ComponentRegistry = require("src.engine.ecs.ComponentRegistry")
local ComponentStore = require("src.engine.ecs.ComponentStore")
local SparseSet = require("src.engine.ecs.SparseSet")

local function expectError(callback)
    local ok = pcall(callback)
    Assert.falsy(ok, "expected the operation to fail")
end

local function nextRandom(seed)
    return (seed * 48271) % 2147483647
end

local function verifySparseSet(set, expected)
    local seen = {}
    local entities = set:entities()
    for _, entityId in ipairs(entities) do
        Assert.falsy(seen[entityId], "sparse set contains a duplicate entity")
        seen[entityId] = true
        Assert.truthy(expected[entityId], "sparse set contains an unexpected entity")
        Assert.truthy(set:has(entityId))
        Assert.equals(expected[entityId], set:get(entityId))
    end

    local expectedCount = 0
    for entityId, value in pairs(expected) do
        expectedCount = expectedCount + 1
        Assert.truthy(seen[entityId], "sparse set lost an entity")
        Assert.equals(value, set:get(entityId))
    end
    Assert.equals(expectedCount, set:count())
end

return function()
    local registry = ComponentRegistry.new()
    local positionDefinition = registry:register("position", {
        version = 1,
        default = function()
            return { x = 0, y = 0 }
        end,
        validate = function(value)
            return type(value) == "table"
                and type(value.x) == "number"
                and type(value.y) == "number"
        end,
    })
    registry:register("disabled", { tag = true })

    Assert.truthy(registry:has("position"))
    Assert.truthy(registry:has("disabled"))
    Assert.equals(2, registry:count())
    Assert.equals("disabled", registry:names()[1])
    Assert.equals("position", registry:names()[2])
    expectError(function()
        registry:register("position")
    end)
    expectError(function()
        registry:require("missing")
    end)

    local definitionCopy = registry:get("position")
    definitionCopy.name = "mutated"
    Assert.equals("position", registry:require("position").name)

    local positions = ComponentStore.new(positionDefinition)
    local first = positions:add(1)
    local second = positions:add(2)
    Assert.equals(0, first.x)
    Assert.equals(0, second.y)
    first.x = 42
    Assert.equals(0, positions:get(2).x)
    Assert.truthy(positions:has(1))
    Assert.equals(42, positions:get(1).x)
    positions:set(1, { x = 7, y = 9 })
    Assert.equals(7, positions:get(1).x)
    expectError(function()
        positions:add(1, { x = 1, y = 1 })
    end)
    expectError(function()
        positions:set(3, { x = 1, y = 1 })
    end)
    expectError(function()
        positions:set(2, { x = "invalid", y = 1 })
    end)
    local removed, didRemove = positions:remove(1)
    Assert.truthy(didRemove)
    Assert.equals(7, removed.x)
    Assert.falsy(positions:has(1))
    local missing, removedMissing = positions:remove(99)
    Assert.falsy(missing)
    Assert.falsy(removedMissing)

    local tags = ComponentStore.new(registry:require("disabled"))
    tags:add(10)
    tags:add(20)
    Assert.truthy(tags:has(10))
    Assert.equals(true, tags:get(10))
    Assert.equals(0, tags:stats().valueStorage)
    Assert.truthy(tags:stats().tag)
    local tagValue, tagRemoved = tags:remove(10)
    Assert.equals(true, tagValue)
    Assert.truthy(tagRemoved)
    Assert.falsy(tags:has(10))

    local sparse = SparseSet.new(true)
    local expected = {}
    local seed = 90210
    for step = 1, 20000 do
        seed = nextRandom(seed)
        local entityId = (seed % 500) + 1
        if expected[entityId] then
            local oldValue, didRemove = sparse:remove(entityId)
            Assert.truthy(didRemove)
            Assert.equals(expected[entityId], oldValue)
            expected[entityId] = nil
        else
            Assert.truthy(sparse:add(entityId, step))
            expected[entityId] = step
        end

        if step % 100 == 0 then
            verifySparseSet(sparse, expected)
        end
    end
    verifySparseSet(sparse, expected)

    local stats = positions:stats()
    Assert.equals("position", stats.name)
    Assert.equals(1, stats.typeId)
end
