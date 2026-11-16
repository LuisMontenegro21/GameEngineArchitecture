local Assert = require("tests.support.assert")
local Entity = require("src.engine.ecs.Entity")

local function expectError(callback)
    local ok = pcall(callback)
    Assert.falsy(ok, "expected the operation to fail")
end

local function shuffle(values, seed)
    -- Deterministic pseudo-random ordering keeps the invariant test repeatable
    -- while exercising ID recycling in a non-sequential pattern.
    for i = #values, 2, -1 do
        seed = (seed * 48271) % 2147483647
        local j = (seed % i) + 1
        values[i], values[j] = values[j], values[i]
    end
end

return function()
    local manager = Entity.new()
    local first = manager:create()
    local second = manager:create()

    Assert.truthy(manager:isAlive(first))
    Assert.truthy(manager:isAlive(second))
    Assert.equals(2, manager:count())
    Assert.truthy(Entity.equals(first, first))
    Assert.falsy(Entity.equals(first, second))
    Assert.equals("Entity(1:1)", Entity.toString(first))

    Assert.truthy(manager:destroy(first))
    Assert.falsy(manager:isAlive(first))
    Assert.equals(1, manager:count())
    expectError(function()
        manager:destroy(first)
    end)

    local recycled = manager:create()
    Assert.equals(first.id, recycled.id)
    Assert.falsy(Entity.equals(first, recycled))
    Assert.falsy(manager:isAlive(first))
    Assert.truthy(manager:isAlive(recycled))
    Assert.equals(2, recycled.generation)

    local listed = manager:entities()
    Assert.equals(2, #listed)
    Assert.equals(second.id, listed[1].id)
    Assert.equals(recycled.id, listed[2].id)

    local iterated = 0
    for handle in manager:each() do
        Assert.truthy(manager:isAlive(handle))
        iterated = iterated + 1
    end
    Assert.equals(2, iterated)

    local warnings = 0
    local warningManager = Entity.new({
        validation = "warn",
        diagnostic = function(message)
            Assert.truthy(message:find("stale") ~= nil)
            warnings = warnings + 1
        end,
    })
    local warningHandle = warningManager:create()
    Assert.truthy(warningManager:destroy(warningHandle))
    Assert.falsy(warningManager:destroy(warningHandle))
    Assert.equals(1, warnings)

    local large = Entity.new()
    local handles = {}
    for i = 1, 100000 do
        handles[i] = large:create()
    end
    Assert.equals(100000, large:count())

    local destructionOrder = {}
    for i = 1, 100000 do
        destructionOrder[i] = i
    end
    shuffle(destructionOrder, 123456789)
    for i = 1, 50000 do
        Assert.truthy(large:destroy(handles[destructionOrder[i]]))
    end
    Assert.equals(50000, large:count())

    for _ = 1, 50000 do
        large:create()
    end
    Assert.equals(100000, large:count())

    local stats = large:stats()
    Assert.equals(100000, stats.live)
    Assert.equals(100000, stats.allocated)

    local old = large:create()
    Assert.equals(100001, large:count())
    Assert.truthy(large:clear())
    Assert.equals(0, large:count())
    Assert.falsy(large:isAlive(old))
    Assert.truthy(large:dispose())
    Assert.falsy(large:isAlive(old))
    expectError(function()
        large:create()
    end)
end
