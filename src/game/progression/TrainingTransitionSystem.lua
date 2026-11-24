-- Moves from Training to Card Acquisition when the day's actions are spent.
local TrainingTransitionSystem = {}

function TrainingTransitionSystem.install(scheduler)
    scheduler:addSystem({
        name = "trainingTransition",
        stage = "update",
        after = { "trainingFeedback" },
        readsResources = { "gameSession", "trainingTransitionQueued" },
        writesResources = { "gameSession", "trainingTransitionQueued" },
        run = function(context)
            local world = context.world
            local session = world:requireResource("gameSession")
            if session.actionsRemaining == 0
                and not world:requireResource("trainingTransitionQueued") then
                world:setResource("trainingTransitionQueued", true)
                local previousPhase = session.dayPhase
                session.dayPhase = "cardAcquisition"
                world:setResource("gameSession", session)
                if previousPhase ~= session.dayPhase then
                    context.emit("dayPhaseChanged", {
                        from = previousPhase,
                        to = session.dayPhase,
                        day = session.day,
                    })
                end
                context.emit("cardGenerationRequested")
                context.emit("sceneRequest", { to = "cardAcquisition", payload = { session = session } })
            end
        end,
    })
end

return TrainingTransitionSystem
