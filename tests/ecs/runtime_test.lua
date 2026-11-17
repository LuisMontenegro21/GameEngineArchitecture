local Assert = require("tests.support.assert")
local ECS = require("src.engine.ecs")

local function expectError(callback, fragment)
    local ok, message = pcall(callback)
    Assert.falsy(ok, "expected the operation to fail")
    if fragment then
        Assert.truthy(tostring(message):find(fragment, 1, true) ~= nil,
            "error did not contain expected text: " .. fragment)
    end
end

return function()
    local order = {}
    local scheduler = ECS.Scheduler.new()
    scheduler:addSystem({
        name = "second",
        stage = "update",
        after = { "first" },
        run = function()
            order[#order + 1] = "second"
        end,
    })
    scheduler:addSystem({
        name = "first",
        stage = "update",
        run = function()
            order[#order + 1] = "first"
        end,
    })
    scheduler:build()
    local resolved = scheduler:systemsFor("update")
    Assert.equals("first", resolved[1].name)
    Assert.equals("second", resolved[2].name)
    Assert.truthy(scheduler:isBuilt())

    local fallback = ECS.Scheduler.new()
    fallback:addSystem({ name = "z", stage = "update", run = function() end })
    fallback:addSystem({ name = "a", stage = "update", run = function() end })
    fallback:build()
    Assert.equals("z", fallback:systemsFor("update")[1].name)
    Assert.equals("a", fallback:systemsFor("update")[2].name)

    local missing = ECS.Scheduler.new()
    missing:addSystem({ name = "one", stage = "update", before = { "absent" }, run = function() end })
    expectError(function()
        missing:build()
    end, "unknown system dependency")

    local cycle = ECS.Scheduler.new()
    cycle:addSystem({ name = "left", stage = "update", after = { "right" }, run = function() end })
    cycle:addSystem({ name = "right", stage = "update", after = { "left" }, run = function() end })
    expectError(function()
        cycle:build()
    end, "dependency cycle")

    local conflictCount = 0
    local conflictScheduler = ECS.Scheduler.new({
        diagnostic = function(message)
            Assert.truthy(message:find("access conflict", 1, true) ~= nil)
            conflictCount = conflictCount + 1
        end,
    })
    conflictScheduler:addSystem({
        name = "writer",
        stage = "update",
        writes = { "position" },
        run = function() end,
    })
    conflictScheduler:addSystem({
        name = "reader",
        stage = "update",
        reads = { "position" },
        run = function() end,
    })
    conflictScheduler:build()
    Assert.equals(1, conflictCount)
    Assert.equals(1, #conflictScheduler:conflicts())

    local world = ECS.World.new({ identity = "runtime" })
    world:registerComponent("position", {
        default = function()
            return { x = 0, y = 0 }
        end,
    })
    world:registerEvent("pulse")

    local initialized = 0
    local ran = 0
    local shutDown = 0
    local observedDt = nil
    local runtimeScheduler = ECS.Scheduler.new()
    runtimeScheduler:addSystem({
        name = "producer",
        stage = "update",
        initialize = function()
            initialized = initialized + 1
        end,
        run = function(context)
            ran = ran + 1
            observedDt = context.dt
            local future = context.commands:create({ position = { x = ran, y = ran } })
            context.commands:set(future, "position", { x = 10, y = 20 })
            context.commands:emit("pulse", { tick = ran })
        end,
        shutdown = function()
            shutDown = shutDown + 1
        end,
    })
    runtimeScheduler:addSystem({
        name = "observer",
        stage = "update",
        run = function(context)
            Assert.truthy(context.world ~= nil)
            Assert.equals("update", context.stage)
        end,
    })
    local clockValue = 0
    local runtime = ECS.Runtime.new({
        world = world,
        scheduler = runtimeScheduler,
        clock = function()
            clockValue = clockValue + 0.001
            return clockValue
        end,
    })
    expectError(function()
        runtime:runStage("update", 0.1)
    end, "built")
    runtime:build()
    runtime:initialize()
    Assert.equals(1, initialized)
    runtime:runStage("update", 0.1)
    Assert.equals(1, ran)
    Assert.equals(0.1, observedDt)
    Assert.equals(1, world:count())
    Assert.equals(1, world:eventCount("pulse"))
    Assert.equals(10, world:get(world:entities()[1], "position").x)
    Assert.truthy(runtime:timings().producer ~= nil)

    runtime:setSystemEnabled("observer", false)
    Assert.falsy(runtime:isSystemEnabled("observer"))
    runtime:runStage("update", 0.2)
    Assert.equals(2, ran)
    runtime:shutdown()
    Assert.equals(1, shutDown)
    Assert.falsy(runtime:isInitialized())
    Assert.truthy(runtime:dispose())
    Assert.truthy(world:isAlive(world:entities()[1]))

    local sharedRuns = 0
    local definition = {
        name = "shared",
        stage = "update",
        run = function()
            sharedRuns = sharedRuns + 1
        end,
    }
    local worldA = ECS.World.new()
    local worldB = ECS.World.new()
    local schedulerA = ECS.Scheduler.new()
    local schedulerB = ECS.Scheduler.new()
    schedulerA:addSystem(definition)
    schedulerB:addSystem(definition)
    local runtimeA = ECS.Runtime.new({ world = worldA, scheduler = schedulerA })
    local runtimeB = ECS.Runtime.new({ world = worldB, scheduler = schedulerB })
    runtimeA:build()
    runtimeB:build()
    runtimeA:initialize()
    runtimeB:initialize()
    runtimeA:setSystemEnabled("shared", false)
    runtimeA:runStage("update", 0)
    runtimeB:runStage("update", 0)
    Assert.equals(1, sharedRuns)
    runtimeA:dispose()
    runtimeB:dispose()
end
