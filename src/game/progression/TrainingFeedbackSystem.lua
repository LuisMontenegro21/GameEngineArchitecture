-- Converts training outcomes into user-facing feedback without changing stats.
local Activities = require("src.game.progression.Activities")
local TrainingFeedbackSystem = {}

function TrainingFeedbackSystem.install(scheduler)
    scheduler:addSystem({
        name = "trainingFeedback",
        stage = "update",
        readsResources = { "gameSession" },
        writesResources = { "gameSession" },
        run = function(context)
            local world = context.world
            local session = world:requireResource("gameSession")
            for event in world:events("trainingActivityResolved") do
                local result = event.payload
                local activity = Activities.get(result.activityId)
                session.feedback = result.success and activity.feedback or result.reason
                world:setResource("gameSession", session)
            end
        end,
    })
end

return TrainingFeedbackSystem
