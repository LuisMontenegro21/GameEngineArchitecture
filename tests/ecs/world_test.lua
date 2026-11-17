local Assert = require("tests.support.assert")
local ECS = require("src.engine.ecs")

local function expectError(callback)
    local ok = pcall(callback)
    Assert.falsy(ok, "expected the operation to fail")
end

local function nextRandom(seed)
    return (seed * 48271) % 2147483647
end

return function()
    local world = ECS.World.new({ identity = "phase3" })
    Assert.equals("phase3", world:identity())
    Assert.equals(0, world:count())
    Assert.equals(0, world:structuralVersion())
    Assert.falsy(world.registry)
    Assert.falsy(world.stores)

    world:registerComponent("position", {
        default = function()
            return { x = 0, y = 0 }
        end,
        validate = function(value)
            return type(value) == "table"
                and type(value.x) == "number"
                and type(value.y) == "number"
        end,
    })
    world:registerComponent("ball", { tag = true })
    Assert.equals(2, world:structuralVersion())
    Assert.truthy(world:hasComponentType("position"))
    Assert.falsy(world:hasComponentType("missing"))

    local entity = world:create({ position = { x = 10, y = 20 }, ball = true })
    Assert.truthy(world:isAlive(entity))
    Assert.equals(1, world:count())
    Assert.equals(3, world:structuralVersion())
    Assert.truthy(world:has(entity, "position"))
    Assert.truthy(world:has(entity, "ball"))
    Assert.equals(10, world:get(entity, "position").x)
    Assert.equals(true, world:get(entity, "ball"))
    Assert.equals(10, world:require(entity, "position").x)

    world:set(entity, "position", { x = 30, y = 40 })
    Assert.equals(30, world:get(entity, "position").x)
    Assert.equals(3, world:structuralVersion())

    local removed, didRemove = world:remove(entity, "ball")
    Assert.equals(true, removed)
    Assert.truthy(didRemove)
    Assert.falsy(world:has(entity, "ball"))
    Assert.equals(4, world:structuralVersion())

    local beforeFailedCreate = world:count()
    local beforeFailedVersion = world:structuralVersion()
    expectError(function()
        world:create({ missing = {} })
    end)
    Assert.equals(beforeFailedCreate, world:count())
    Assert.equals(beforeFailedVersion, world:structuralVersion())

    expectError(function()
        world:create({ position = { x = "bad", y = 1 } })
    end)
    Assert.equals(beforeFailedCreate, world:count())
    Assert.equals(beforeFailedVersion, world:structuralVersion())

    local second = world:create({ position = { x = 0, y = 0 } })
    Assert.equals(2, world:count())
    Assert.equals(5, world:structuralVersion())
    Assert.equals(0, world:get(second, "position").x)
    Assert.truthy(world:validate())

    Assert.truthy(world:destroy(entity))
    Assert.falsy(world:isAlive(entity))
    Assert.equals(1, world:count())
    Assert.equals(6, world:structuralVersion())
    expectError(function()
        world:get(entity, "position")
    end)
    Assert.truthy(world:validate())

    local other = ECS.World.new({ identity = "other" })
    other:registerComponent("position")
    local otherEntity = other:create()
    Assert.truthy(other:isAlive(otherEntity))
    Assert.falsy(world:isAlive(otherEntity))
    Assert.equals(1, world:count())
    Assert.equals(1, other:count())

    local randomized = ECS.World.new({ identity = "randomized" })
    randomized:registerComponent("position", {
        default = function()
            return { x = 0, y = 0 }
        end,
    })
    randomized:registerComponent("marked", { tag = true })
    local handles = {}
    local seed = 314159
    for step = 1, 5000 do
        seed = nextRandom(seed)
        local slot = (seed % 200) + 1
        local handle = handles[slot]
        if handle and randomized:isAlive(handle) then
            local operation = seed % 4
            if operation == 0 then
                randomized:destroy(handle)
                handles[slot] = nil
            elseif operation == 1 then
                if randomized:has(handle, "marked") then
                    randomized:remove(handle, "marked")
                else
                    randomized:add(handle, "marked")
                end
            else
                randomized:set(handle, "position", { x = step, y = slot })
            end
        else
            handles[slot] = randomized:create({ position = { x = step, y = slot } })
        end

        if step % 100 == 0 then
            Assert.truthy(randomized:validate())
        end
    end
    Assert.truthy(randomized:validate())

    Assert.equals("position", world:componentsOf(second)[1])
    Assert.equals(1, #world:componentsOf(second))

    local cleared = world:clear()
    Assert.equals(1, cleared)
    Assert.equals(0, world:count())
    Assert.truthy(world:validate())

    Assert.truthy(other:dispose())
    Assert.truthy(other:isDisposed())
    expectError(function()
        other:create()
    end)
    Assert.falsy(other:isAlive(otherEntity))

    Assert.truthy(world:dispose())
    Assert.truthy(world:isDisposed())
end
