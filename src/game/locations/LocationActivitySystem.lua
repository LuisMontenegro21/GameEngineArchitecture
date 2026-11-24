-- Resolves a room's catalog activity through the existing shared rule module.
local ActivityRules = require("src.game.progression.ActivityRules")

local LocationActivitySystem = {}

local function unavailableResult(activityId)
    return {
        activityId = activityId,
        success = false,
        reason = "Activities are unavailable during this part of the day.",
    }
end

function LocationActivitySystem.install(scheduler)
    scheduler:addSystem({
        name = "locationActivity",
        stage = "postFixedUpdate",
        after = { "locationDialogue" },
        readsResources = { "gameSession", "locationDefinition", "locationState" },
        writesResources = { "gameSession", "locationState" },
        run = function(context)
            local world = context.world
            local session = world:requireResource("gameSession")
            local state = world:requireResource("locationState")
            if state.transitionQueued then return end
            for event in world:events("locationActivityRequested") do
                local activityId = event.payload.activityId
                local location = world:requireResource("locationDefinition")
                local result
                if activityId ~= location.activityId then
                    result = { success = false, reason = "That activity is unavailable in this location." }
                elseif session.dayPhase ~= "activities" then
                    result = unavailableResult(activityId)
                else
                    result = ActivityRules.resolveAndApply(session, activityId)
                end
                session.feedback = ActivityRules.feedback(result)
                state.feedback = session.feedback
                world:setResource("gameSession", session)

                if result.success and session.actionsRemaining == 0 then
                    local previousPhase = session.dayPhase
                    session.dayPhase = "cardAcquisition"
                    state.transitionQueued = true
                    world:setResource("gameSession", session)
                    world:setResource("locationState", state)
                    context.emit("sceneRequest", {
                        to = "cardAcquisition",
                        payload = { session = session },
                    })
                else
                    world:setResource("locationState", state)
                end
                return
            end
        end,
    })
end

return LocationActivitySystem
