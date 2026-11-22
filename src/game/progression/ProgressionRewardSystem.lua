-- Generic reward application after a progression objective is completed.
local ProgressionRewardSystem = {}

local function firstEvent(world, name)
    for event in world:events(name) do return event.payload or {} end
    return nil
end

function ProgressionRewardSystem.install(scheduler)
    scheduler:addSystem({
        name = "progressionRewards",
        stage = "postFixedUpdate",
        readsResources = { "progressionPlan" },
        writesResources = { "progression" },
        run = function(context)
            local world = context.world
            local progression = world:requireResource("progression")
            if progression.state ~= "completed" or progression.rewardGranted then return end
            local completed = firstEvent(world, "objectiveCompleted")
            if not completed or completed.objectiveId ~= progression.objectiveId then return end
            local stage = world:requireResource("progressionPlan").stages[progression.stageIndex]
            local reward = stage.reward or {}
            progression.experience = progression.experience + (reward.experience or 0)
            progression.currency = progression.currency + (reward.currency or 0)
            for _, unlock in ipairs(reward.unlocks or {}) do progression.unlocks[unlock] = true end
            progression.rewardGranted = true
            progression.state = "rewarded"
            context.emit("rewardGranted", { objectiveId = progression.objectiveId })
        end,
    })
end

return ProgressionRewardSystem
