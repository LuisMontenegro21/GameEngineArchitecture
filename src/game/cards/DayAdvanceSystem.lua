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
                        session.complete = true
                        session.feedback = "Your academy term is complete."
                        world:setResource("gameSession", session)
                        context.emit("sceneRequest", {
                            to = "arcaneComplete",
                            payload = { session = session },
                        })
                    else
                        session.day = session.day + 1
                        session.actionsRemaining = session.actionsPerDay
                        session.feedback = "Choose a magical training activity."
                        world:setResource("gameSession", session)
                        context.emit("sceneRequest", {
                            to = "training",
                            payload = { session = session },
                        })
                    end
                end
            end
        end,
    })
end

return DayAdvanceSystem
