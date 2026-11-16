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

local function assertIds(expected, actual)
    Assert.equals(#expected, #actual)
    for i, id in ipairs(expected) do
        Assert.equals(id, actual[i])
    end
end

return function()
    local world = ECS.World.new({ identity = "queries" })
    world:registerComponent("position", {
        default = function()
            return { x = 0, y = 0 }
        end,
    })
    world:registerComponent("velocity", {
        default = function()
            return { x = 1, y = 1 }
        end,
    })
    world:registerComponent("enemy", { tag = true })
    world:registerComponent("disabled", { tag = true })

    local e1 = world:create({ position = { x = 1, y = 1 }, velocity = { x = 2, y = 2 } })
    local e2 = world:create({ position = { x = 2, y = 2 } })
    local e3 = world:create({ velocity = { x = 3, y = 3 }, enemy = true })
    local e4 = world:create({
        position = { x = 4, y = 4 },
        velocity = { x = 4, y = 4 },
        disabled = true,
    })
    local e5 = world:create({ enemy = true })

    assertIds({ e1.id, e4.id }, idsFromQuery(world:query({
        all = { "position", "velocity" },
        stable = true,
    })))
    assertIds({ e1.id, e2.id }, idsFromQuery(world:query({
        all = { "position" },
        none = { "disabled" },
        stable = true,
    })))
    assertIds({ e1.id, e3.id, e4.id, e5.id }, idsFromQuery(world:query({
        any = { "velocity", "enemy" },
        stable = true,
    })))
    assertIds({}, idsFromQuery(world:query({
        all = { "position" },
        none = { "position" },
    })))
    assertIds({ e1.id, e2.id, e3.id, e4.id, e5.id }, idsFromQuery(world:query({
        stable = true,
    })))

    local optionalRows = {}
    for entity, position, velocity in world:query({
        all = { "position" },
        optional = { "velocity" },
        stable = true,
    }):each() do
        optionalRows[entity.id] = {
            x = position.x,
            velocity = velocity and velocity.x or nil,
        }
    end
    Assert.equals(1, optionalRows[e1.id].x)
    Assert.equals(2, optionalRows[e1.id].velocity)
    Assert.equals(nil, optionalRows[e2.id].velocity)

    local stableQuery = world:query({ all = { "position" }, stable = true })
    assertIds({ e1.id, e2.id, e4.id }, idsFromQuery(stableQuery))
    assertIds({ e1.id, e2.id, e4.id }, idsFromQuery(stableQuery))

    local nestedOuter = world:query({ all = { "position" }, stable = true })
    local nestedCount = 0
    for outerEntity in nestedOuter:each() do
        for innerEntity in world:query({ any = { "enemy", "velocity" } }):each() do
            Assert.truthy(innerEntity ~= nil)
            nestedCount = nestedCount + 1
        end
        Assert.truthy(outerEntity ~= nil)
    end
    Assert.equals(3 * 4, nestedCount)

    local guarded = world:query({ all = { "position" }, stable = true })
    local iterator = guarded:each()
    local first = iterator()
    Assert.truthy(first)
    expectError(function()
        world:destroy(first)
    end)
    world:set(first, "position", { x = 99, y = 99 })
    guarded:close()
    Assert.truthy(world:destroy(first))

    local changedQuery = world:query({
        all = { "position" },
        changed = { "position" },
        stable = true,
    })
    Assert.equals(0, changedQuery:count())
    world:set(e2, "position", { x = 22, y = 22 })
    assertIds({ e2.id }, idsFromQuery(changedQuery))
    Assert.equals(0, changedQuery:count())
    world:touch(e2, "position")
    assertIds({ e2.id }, idsFromQuery(changedQuery))

    expectError(function()
        world:query({ all = { "missing" } })
    end)
    expectError(function()
        world:query({ all = { "position" }, optional = { "position" } })
    end)
    Assert.truthy(world:validate())
end
