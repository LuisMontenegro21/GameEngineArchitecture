local Assert = require("tests.support.assert")
local ECS = require("src.engine.ecs")

local function expectError(callback)
    local ok = pcall(callback)
    Assert.falsy(ok, "expected the operation to fail")
end

local function idsFromQuery(query)
    local ids = {}
    for entity in query:each() do
        ids[#ids + 1] = entity.id
    end
    return ids
end

local function shuffle(values, seed)
    for i = #values, 2, -1 do
        seed = (seed * 48271) % 2147483647
        local j = (seed % i) + 1
        values[i], values[j] = values[j], values[i]
    end
end

return function()
    local world = ECS.World.new({ identity = "commands" })
    world:registerComponent("position", {
        default = function()
            return { x = 0, y = 0 }
        end,
    })
    world:registerComponent("marked", { tag = true })

    local entity = world:create({ position = { x = 1, y = 1 } })
    local commands = world:commands()
    Assert.equals(0, commands:count())

    local activeQuery = world:query({ all = { "position" } })
    local iterator = activeQuery:each()
    Assert.truthy(iterator())
    commands:add(entity, "marked")
    commands:set(entity, "position", { x = 5, y = 6 })
    Assert.equals(2, commands:count())
    Assert.falsy(world:has(entity, "marked"))
    expectError(function()
        world:add(entity, "marked")
    end)
    -- The active query is closed before the runtime-safe flush boundary.
    activeQuery:close()
    local flushed = commands:flush()
    Assert.equals(2, flushed)
    Assert.truthy(world:has(entity, "marked"))
    Assert.equals(5, world:get(entity, "position").x)
    Assert.equals(0, commands:pending())

    local future = commands:create({ position = { x = 10, y = 10 } })
    commands:add(future, "marked")
    commands:set(future, "position", { x = 11, y = 12 })
    Assert.equals(1, world:count())
    Assert.equals(3, commands:count())
    Assert.equals(3, world:flush())
    Assert.equals(2, world:count())
    local markedIds = idsFromQuery(world:query({ all = { "marked" }, stable = true }))
    Assert.equals(2, #markedIds)

    local doomed = world:create({ position = { x = 20, y = 20 } })
    local failing = world:commands()
    failing:destroy(doomed)
    failing:set(doomed, "position", { x = 99, y = 99 })
    expectError(function()
        failing:flush()
    end)
    Assert.falsy(world:isAlive(doomed))
    Assert.equals(0, failing:pending())
    Assert.truthy(world:validate())

    local unresolved = commands:create()
    commands:add(unresolved, "marked")
    Assert.equals(2, commands:pending())
    commands:clear()
    Assert.equals(0, commands:pending())
    Assert.equals(2, world:count())

    local batch = {}
    for i = 1, 100 do
        batch[i] = commands:create({ position = { x = i, y = i } })
        commands:add(batch[i], "marked")
    end
    Assert.equals(200, commands:pending())
    Assert.equals(200, commands:flush())
    Assert.equals(102, world:count())
    Assert.truthy(world:validate())

    local live = world:entities()
    shuffle(live, 12345)
    for i = 1, 50 do
        commands:destroy(live[i])
    end
    for i = 51, #live do
        commands:set(live[i], "position", { x = i, y = -i })
    end
    Assert.equals(#live, commands:pending())
    Assert.equals(#live, commands:flush())
    Assert.equals(52, world:count())
    Assert.truthy(world:validate())
end
