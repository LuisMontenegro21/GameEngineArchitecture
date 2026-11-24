-- Resolves one requested activity through the rules shared with map play.
local ActivityRules = require("src.game.progression.ActivityRules")
local TrainingActivitySystem = {}

function TrainingActivitySystem.install(scheduler)
    scheduler:addSystem({
        name = "trainingActivity",
        stage = "postFixedUpdate",
        readsResources = { "gameSession" },
        writesResources = { "gameSession" },
        run = function(context)
            local world = context.world
            local session = world:requireResource("gameSession")
            for event in world:events("trainingActivityRequested") do
                local result = ActivityRules.resolveAndApply(session, event.payload.activityId)
                world:setResource("gameSession", session)
                context.emit("trainingActivityResolved", {
                    activityId = event.payload.activityId,
                    success = result.success,
                    reason = result.reason,
                })
            end
        end,
    })
end

return TrainingActivitySystem
