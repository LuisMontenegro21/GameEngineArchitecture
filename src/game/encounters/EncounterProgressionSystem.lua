-- Advances prompts after a resolved card play and commits only the final
-- encounter result to the shared GameSession.
local EncounterProgressionSystem = {}

local function endingForRapport(definition, rapport)
    local selected = definition.endings[1]
    for _, ending in ipairs(definition.endings) do
        if rapport >= ending.minimumRapport then selected = ending end
    end
    return selected
end

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
                        local ending = endingForRapport(definition, state.rapport)
                        state.complete = true
                        state.transitionQueued = true
                        state.feedback = "Conversation complete: " .. ending.title .. "."
                        session.finalRapport = state.rapport
                        session.endingId = ending.id
                        session.complete = true
                        session.feedback = state.feedback
                        world:setResource("encounterState", state)
                        world:setResource("gameSession", session)
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

EncounterProgressionSystem.endingForRapport = endingForRapport
return EncounterProgressionSystem
