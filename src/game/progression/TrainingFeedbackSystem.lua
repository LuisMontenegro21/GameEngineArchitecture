-- Retains the Training Scene's feedback stage while using the shared activity
-- rules as its text source.
local ActivityRules = require("src.game.progression.ActivityRules")
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
                local feedbackResult = result
                if result.success then
                    feedbackResult = {
                        activityId = result.activityId,
                        activity = Activities.get(result.activityId),
                        success = true,
                        reason = nil,
                    }
                end
                session.feedback = ActivityRules.feedback(feedbackResult)
                world:setResource("gameSession", session)
            end
        end,
    })
end

return TrainingFeedbackSystem
