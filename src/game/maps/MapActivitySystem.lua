-- Commits activity requests emitted by the final line of a location dialogue.
-- It shares the Training Scene's rule module and only owns map-scene routing.
local ActivityRules = require("src.game.progression.ActivityRules")

local MapActivitySystem = {}

local function unavailableResult(activityId)
    return {
        activityId = activityId,
        success = false,
        reason = "Activities are unavailable during this part of the day.",
    }
end

function MapActivitySystem.install(scheduler)
    scheduler:addSystem({
        name = "mapActivity",
        stage = "postFixedUpdate",
        readsResources = { "gameSession", "mapActivityTransitionQueued", "mapTransitionQueued" },
        writesResources = {
            "gameSession", "mapActivityFeedback", "mapActivityTransitionQueued", "mapTransitionQueued",
        },
        run = function(context)
            local world = context.world
            local session = world:requireResource("gameSession")
            for event in world:events("mapActivityRequested") do
                local activityId = event.payload.activityId
                local result
                if session.dayPhase == "activities" then
                    result = ActivityRules.resolveAndApply(session, activityId)
                else
                    result = unavailableResult(activityId)
                    session.feedback = result.reason
                end
                world:setResource("gameSession", session)
                world:setResource("mapActivityFeedback", ActivityRules.feedback(result))
                context.emit("mapActivityResolved", {
                    activityId = activityId,
                    success = result.success,
                    reason = result.reason,
                })

                if result.success and session.actionsRemaining == 0
                    and not world:requireResource("mapActivityTransitionQueued") then
                    local previousPhase = session.dayPhase
                    session.dayPhase = "cardAcquisition"
                    world:setResource("gameSession", session)
                    world:setResource("mapActivityTransitionQueued", true)
                    world:setResource("mapTransitionQueued", true)
                    context.emit("dayPhaseChanged", {
                        from = previousPhase,
                        to = session.dayPhase,
                        day = session.day,
                    })
                    context.emit("sceneRequest", {
                        to = "cardAcquisition",
                        payload = { session = session },
                    })
                end
            end
        end,
    })
end

return MapActivitySystem
