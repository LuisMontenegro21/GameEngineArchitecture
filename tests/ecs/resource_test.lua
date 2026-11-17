local Assert = require("tests.support.assert")
local ECS = require("src.engine.ecs")

local function expectError(callback)
    local ok = pcall(callback)
    Assert.falsy(ok, "expected the operation to fail")
end

return function()
    local disposedCount = 0
    local world = ECS.World.new({ identity = "resources" })
    world:registerComponent("position")
    world:registerResource("score", {
        version = 2,
        validate = function(value)
            return type(value) == "number"
        end,
    })
    world:registerResource("service", {
        transient = true,
        owned = true,
        onDispose = function(value)
            Assert.truthy(value.name ~= nil)
            disposedCount = disposedCount + 1
        end,
    })

    Assert.equals(2, world:resourceVersion())
    Assert.truthy(world:hasResourceDefinition("score"))
    Assert.falsy(world:hasResource("score"))
    Assert.equals(nil, world:getResource("score"))
    expectError(function()
        world:requireResource("score")
    end)
    expectError(function()
        world:setResource("score", "invalid")
    end)

    local entity = world:create({ position = { x = 1, y = 1 } })
    local beforeId = entity.id
    world:setResource("score", 10)
    Assert.truthy(world:hasResource("score"))
    Assert.equals(10, world:requireResource("score"))
    Assert.equals(beforeId, world:entities()[1].id)
    Assert.equals(3, world:resourceVersion())

    local scoreDefinition = world:resourceDefinition("score")
    Assert.equals(2, scoreDefinition.version)
    Assert.falsy(scoreDefinition.transient)
    Assert.truthy(scoreDefinition.serializable)
    local serviceStats = world:resourceStats("service")
    Assert.truthy(serviceStats.transient)
    Assert.falsy(serviceStats.serializable)
    Assert.truthy(serviceStats.owned)

    world:setResource("service", { name = "first" })
    world:setResource("service", { name = "second" })
    Assert.equals(1, disposedCount)
    local removed, didRemove = world:removeResource("service")
    Assert.equals("second", removed.name)
    Assert.truthy(didRemove)
    Assert.equals(2, disposedCount)
    local missing, removedMissing = world:removeResource("service")
    Assert.falsy(missing)
    Assert.falsy(removedMissing)
    Assert.equals(2, disposedCount)

    local commands = world:commands()
    commands:setResource("score", 25)
    Assert.equals(10, world:getResource("score"))
    Assert.equals(1, commands:pending())
    Assert.equals(1, commands:flush())
    Assert.equals(25, world:getResource("score"))

    commands:removeResource("score")
    Assert.truthy(world:hasResource("score"))
    Assert.equals(1, commands:flush())
    Assert.falsy(world:hasResource("score"))
    expectError(function()
        world:requireResource("score")
    end)

    local other = ECS.World.new({ identity = "other-resources" })
    other:registerResource("score", {
        validate = function(value)
            return type(value) == "number"
        end,
    })
    other:setResource("score", 99)
    Assert.equals(99, other:requireResource("score"))
    Assert.falsy(world:hasResource("score"))
    Assert.equals(0, other:count())
    Assert.truthy(other:dispose())

    world:setResource("service", { name = "final" })
    Assert.truthy(world:validate())
    Assert.truthy(world:dispose())
    Assert.equals(3, disposedCount)
    Assert.truthy(world:isDisposed())
    Assert.falsy(world:isAlive(entity))
end
