local DayAdvanceSystem = {}

function DayAdvanceSystem.install(scheduler)
    scheduler:addSystem({
        name = "dayAdvance",
        stage = "postFixedUpdate",
        after = { "collectionNavigation" },
        readsResources = { "gameSession" },
        writesResources = { "gameSession" },
        run = function(context)
            local world = context.world
            local session = world:requireResource("gameSession")
            for _ in world:events("dayAdvanceRequested") do
                if session.cardChosenThisDay then
                    session.generatedCards = {}
                    session.generatedSelection = 1
                    session.cardChosenThisDay = false
                    session.lastActivity = nil
                    if session.day >= session.maxDays then
                        local previousPhase = session.dayPhase
                        session.dayPhase = "finalConversation"
                        session.complete = false
                        session.finalRapport = 0
                        session.endingId = nil
                        session.feedback = "Your final academy conversation awaits."
                        world:setResource("gameSession", session)
                        if previousPhase ~= session.dayPhase then
                            context.emit("dayPhaseChanged", {
                                from = previousPhase,
                                to = session.dayPhase,
                                day = session.day,
                            })
                        end
                        context.emit("sceneRequest", {
                            to = "finalConversation",
                            payload = { session = session },
                        })
                    else
                        local previousPhase = session.dayPhase
                        session.dayPhase = "socialConversation"
                        session.dailyConversationCompleted = false
                        session.feedback = "Find today's conversation partner in the Academy Garden."
                        world:setResource("gameSession", session)
                        if previousPhase ~= session.dayPhase then
                            context.emit("dayPhaseChanged", {
                                from = previousPhase,
                                to = session.dayPhase,
                                day = session.day,
                            })
                        end
                        context.emit("sceneRequest", {
                            to = "academyMap",
                            payload = { session = session },
                        })
                    end
                end
            end
        end,
    })
end

return DayAdvanceSystem
