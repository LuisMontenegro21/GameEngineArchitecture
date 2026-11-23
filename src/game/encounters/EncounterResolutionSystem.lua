-- Validates one card-play request and applies only this encounter's transient
-- Focus, rapport, and used-card state. It never edits the card collection.
local EncounterResolutionSystem = {}

local function reject(context, state, collectionIndex, reason)
    state.feedback = reason
    context.world:setResource("encounterState", state)
    context.emit("cardPlayRejected", {
        collectionIndex = collectionIndex,
        reason = reason,
    })
end

function EncounterResolutionSystem.install(scheduler)
    scheduler:addSystem({
        name = "encounterResolution",
        stage = "postFixedUpdate",
        readsResources = { "gameSession", "encounterDefinition", "encounterState" },
        writesResources = { "encounterState" },
        run = function(context)
            local world = context.world
            local session = world:requireResource("gameSession")
            local definition = world:requireResource("encounterDefinition")
            local state = world:requireResource("encounterState")
            local prompt = definition.prompts[state.promptIndex]

            for event in world:events("cardPlayRequested") do
                local collectionIndex = event.payload.collectionIndex
                if state.complete then
                    reject(context, state, collectionIndex, "The conversation has already ended.")
                elseif not prompt then
                    reject(context, state, collectionIndex, "There is no active conversation prompt.")
                elseif not session.collection[collectionIndex] then
                    reject(context, state, collectionIndex, "Select a card from your collection first.")
                elseif state.usedCollectionIndexes[collectionIndex] then
                    reject(context, state, collectionIndex, "That card has already been used in this conversation.")
                else
                    local card = session.collection[collectionIndex]
                    if card.cost > state.focus then
                        reject(context, state, collectionIndex, "You do not have enough Focus for that card.")
                    else
                        local categoryMatched = card.category == prompt.preferredCategory
                        local rapportGained = card.power
                            + (categoryMatched and definition.categoryMatchBonus or 0)
                        state.focus = state.focus - card.cost
                        state.rapport = state.rapport + rapportGained
                        state.usedCollectionIndexes[collectionIndex] = true
                        state.feedback = categoryMatched
                            and ("A perfect response. Rapport +" .. rapportGained .. ".")
                            or ("A sincere response. Rapport +" .. rapportGained .. ".")
                        world:setResource("encounterState", state)
                        context.emit("cardPlayed", {
                            collectionIndex = collectionIndex,
                            cardId = card.id,
                            promptId = prompt.id,
                            categoryMatched = categoryMatched,
                            focusSpent = card.cost,
                            focusRemaining = state.focus,
                            rapportGained = rapportGained,
                            rapport = state.rapport,
                        })
                    end
                end
                -- One confirmation may resolve at most one prompt per update.
                break
            end
        end,
    })
end

return EncounterResolutionSystem
