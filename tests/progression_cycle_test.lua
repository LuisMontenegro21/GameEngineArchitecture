local ECS = require("src.engine.ecs")
local registerProgression = require("src.game.progression.register")
local ProgressionCycleSystem = require("src.game.progression.ProgressionCycleSystem")
local ProgressionRewardSystem = require("src.game.progression.ProgressionRewardSystem")

local function event(world, name, payload)
    world:emit(name, payload)
    world:advanceEvents()
end

return function()
    local plan = {
        id = "test_cycle",
        stages = {
            { id = "collect", required = 3, reward = {
                experience = 100, currency = 25, unlocks = { "next_map" },
            } },
            { id = "exit", required = 1, reward = { experience = 50 } },
        },
    }
    local world, scheduler = ECS.World.new(), ECS.Scheduler.new()
    registerProgression(world, plan)
    ProgressionCycleSystem.install(scheduler)
    ProgressionRewardSystem.install(scheduler)
    local runtime = ECS.Runtime.new({ world = world, scheduler = scheduler })
    runtime:build(); runtime:initialize()

    plan.stages[1].required = 999 -- registration owns an isolated plan copy
    local progression = world:requireResource("progression")
    assert(progression.state == "available" and progression.required == 3)

    event(world, "progressionStartRequested")
    runtime:runStage("fixedUpdate", 1 / 60)
    assert(progression.state == "active")

    event(world, "objectiveProgress", { objectiveId = "collect", amount = 2 })
    runtime:runStage("fixedUpdate", 1 / 60)
    assert(progression.current == 2 and progression.state == "active")
    event(world, "objectiveProgress", { objectiveId = "collect", amount = 1 })
    runtime:runStage("fixedUpdate", 1 / 60)
    assert(progression.state == "completed")
    runtime:runStage("postFixedUpdate", 1 / 60)
    assert(progression.state == "rewarded" and progression.rewardGranted)
    assert(progression.experience == 100 and progression.currency == 25)
    assert(progression.unlocks.next_map and progression.completedObjectives.collect)

    event(world, "progressionNextRequested")
    runtime:runStage("fixedUpdate", 1 / 60)
    assert(progression.state == "available" and progression.objectiveId == "exit")
    event(world, "progressionStartRequested")
    runtime:runStage("fixedUpdate", 1 / 60)
    event(world, "progressionFailed", { reason = "player_defeated" })
    runtime:runStage("fixedUpdate", 1 / 60)
    assert(progression.state == "failed")
    event(world, "progressionStartRequested")
    runtime:runStage("fixedUpdate", 1 / 60)
    assert(progression.state == "active" and progression.current == 0)

    assert(not pcall(function()
        world:emit("objectiveProgress", { objectiveId = "exit", amount = 0 })
    end))
    assert(world:validate())
    runtime:dispose(); world:dispose()
end
