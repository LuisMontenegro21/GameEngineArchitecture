-- Advances prompts after a resolved card play and commits only the final
-- encounter result to the shared GameSession.
local EncounterDefinitions = require("src.game.encounters.EncounterDefinitions")
local EncounterProgressionSystem = {}

function EncounterProgressionSystem.install(scheduler)
    scheduler:addSystem({
        name = "encounterProgression",
        stage = "update",
        readsResources = { "gameSession", "encounterDefinition", "encounterState" },
        writesResources = { "gameSession", "encounterState" },
        run = function(context)
            local world = context.world
            local session = world:requireResource("gameSession")
            local definition = world:requireResource("encounterDefinition")
            local state = world:requireResource("encounterState")

            for event in world:events("cardPlayed") do
                local currentPrompt = definition.prompts[state.promptIndex]
                if not state.complete and currentPrompt and event.payload.promptId == currentPrompt.id then
                    state.promptIndex = state.promptIndex + 1
                    if definition.prompts[state.promptIndex] then
                        local nextPrompt = definition.prompts[state.promptIndex]
                        state.feedback = state.feedback .. " Next: " .. nextPrompt.text
                        world:setResource("encounterState", state)
                        context.emit("conversationPromptAdvanced", {
                            round = state.promptIndex,
                            promptId = nextPrompt.id,
                        })
                    else
                        local ending = EncounterDefinitions.endingForRapport(state.rapport)
                        state.complete = true
                        state.transitionQueued = true
                        state.feedback = "Homecoming invitation complete: " .. ending.title .. "."
                        local previousPhase = session.dayPhase
                        session.dayPhase = "complete"
                        session.finalRapport = state.rapport
                        session.endingId = ending.id
                        session.complete = true
                        session.feedback = state.feedback
                        world:setResource("encounterState", state)
                        world:setResource("gameSession", session)
                        if previousPhase ~= session.dayPhase then
                            context.emit("dayPhaseChanged", {
                                from = previousPhase,
                                to = session.dayPhase,
                                day = session.day,
                            })
                        end
                        context.emit("conversationCompleted", {
                            finalRapport = session.finalRapport,
                            endingId = session.endingId,
                        })
                        context.emit("sceneRequest", {
                            to = "arcaneComplete",
                            payload = { session = session },
                        })
                    end
                end
                -- Resolution accepts one play per update, so progression must
                -- also advance at most one prompt per update.
                break
            end
        end,
    })
end

EncounterProgressionSystem.endingForRapport = EncounterDefinitions.endingForRapport
return EncounterProgressionSystem
