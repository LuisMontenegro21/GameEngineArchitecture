local Assert = require("tests.support.assert")
local ECS = require("src.engine.ecs")

local function expectError(callback)
    local ok = pcall(callback)
    Assert.falsy(ok, "expected the operation to fail")
end

local function readEvents(iterator)
    local records = {}
    for record in iterator do
        records[#records + 1] = record
    end
    return records
end

return function()
    local world = ECS.World.new({
        identity = "events",
        events = { maxQueue = 4 },
    })
    world:registerComponent("position")
    world:registerEvent("hit", {
        version = 2,
        validate = function(payload)
            return type(payload) == "table" and type(payload.damage) == "number"
        end,
    })
    world:registerEvent("pulse")
    world:registerEvent("limited", { maxQueue = 2 })

    local entity = world:create({ position = { x = 1, y = 1 } })
    local beforeCount = world:count()
    world:emit("hit", { damage = 2 })
    world:emit("hit", { damage = 3 })
    Assert.equals(beforeCount, world:count())
    Assert.equals(0, world:eventCount("hit"))
    Assert.equals(2, world:pendingEventCount("hit"))

    world:advanceEvents()
    Assert.equals(2, world:eventCount("hit"))
    Assert.equals(0, world:pendingEventCount("hit"))
    local firstReader = readEvents(world:events("hit"))
    local secondReader = readEvents(world:events("hit"))
    Assert.equals(2, #firstReader)
    Assert.equals(2, #secondReader)
    Assert.equals(2, firstReader[1].payload.damage)
    Assert.equals(3, firstReader[2].payload.damage)
    Assert.equals(firstReader[1].sequence, secondReader[1].sequence)

    -- Emission during current-event processing goes to pending and cannot
    -- extend either reader's current snapshot.
    world:emit("hit", { damage = 4 })
    Assert.equals(2, world:eventCount("hit"))
    Assert.equals(1, world:pendingEventCount("hit"))
    Assert.equals(2, #readEvents(world:events("hit")))
    world:advanceEvents()
    Assert.equals(1, world:eventCount("hit"))
    Assert.equals(4, readEvents(world:events("hit"))[1].payload.damage)
    world:advanceEvents()
    Assert.equals(0, world:eventCount("hit"))

    expectError(function()
        world:emit("hit", { damage = "bad" })
    end)
    world:emit("limited", 1)
    world:emit("limited", 2)
    expectError(function()
        world:emit("limited", 3)
    end)
    expectError(function()
        world:emit("missing", {})
    end)
    world:advanceEvents()
    Assert.equals(2, world:eventCount("limited"))

    local commands = world:commands()
    commands:emit("pulse", nil)
    Assert.equals(0, world:eventCount("pulse"))
    Assert.equals(0, world:pendingEventCount("pulse"))
    Assert.equals(1, commands:flush())
    Assert.equals(1, world:pendingEventCount("pulse"))
    world:advanceEvents()
    local pulse = readEvents(world:events("pulse"))
    Assert.equals(1, #pulse)
    Assert.equals(nil, pulse[1].payload)

    local other = ECS.World.new()
    other:registerEvent("pulse")
    other:emit("pulse", "other")
    Assert.equals(1, other:pendingEventCount("pulse"))
    Assert.equals(0, world:pendingEventCount("pulse"))
    Assert.truthy(other:validate())
    Assert.truthy(other:dispose())

    local definition = world:eventDefinition("hit")
    Assert.equals(2, definition.version)
    Assert.equals("hit", world:eventNames()[1])
    Assert.equals(entity.id, world:entities()[1].id)
    Assert.truthy(world:validate())
    Assert.truthy(world:dispose())
end
