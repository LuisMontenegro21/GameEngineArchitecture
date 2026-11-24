-- Advances from a resolved daily conversation to the next day's map scene.
local DailyConversationAdvanceSystem = {}

function DailyConversationAdvanceSystem.install(scheduler)
    scheduler:addSystem({
        name = "dailyConversationAdvance",
        stage = "update",
        readsResources = { "gameSession", "dailyConversationState" },
        writesResources = { "gameSession", "dailyConversationState" },
        run = function(context)
            local world = context.world
            local session = world:requireResource("gameSession")
            local state = world:requireResource("dailyConversationState")
            if not state then return end

            for _ in world:events("dayAdvanceRequested") do
                if state.resolved and not state.transitionQueued and session.day < session.maxDays then
                    state.transitionQueued = true
                    local previousPhase = session.dayPhase
                    session.day = session.day + 1
                    session.actionsRemaining = session.actionsPerDay
                    session.generatedCards = {}
                    session.generatedSelection = 1
                    session.cardChosenThisDay = false
                    session.lastActivity = nil
                    session.dailyConversationCompleted = false
                    session.dayPhase = "activities"
                    session.feedback = "A new academy day begins. Choose an activity."
                    world:setResource("dailyConversationState", state)
                    world:setResource("gameSession", session)
                    context.emit("dayPhaseChanged", {
                        from = previousPhase,
                        to = session.dayPhase,
                        day = session.day,
                    })
                    context.emit("sceneRequest", {
                        to = "academyMap",
                        payload = { session = session },
                    })
                end
                break
            end
        end,
    })
end

return DailyConversationAdvanceSystem
