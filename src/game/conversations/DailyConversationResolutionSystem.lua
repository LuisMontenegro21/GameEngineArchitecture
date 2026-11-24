-- Scores one persistent collection card against the active daily prompt.
-- Cards remain reusable; the daily state prevents more than one resolution.
local DailyConversationResolutionSystem = {}

local MATCH_BONUS = 2

local function reject(world, state, reason)
    state.feedback = reason
    world:setResource("dailyConversationState", state)
end

function DailyConversationResolutionSystem.install(scheduler)
    scheduler:addSystem({
        name = "dailyConversationResolution",
        stage = "postFixedUpdate",
        readsResources = { "gameSession", "dailyConversationState" },
        writesResources = { "gameSession", "dailyConversationState" },
        run = function(context)
            local world = context.world
            local session = world:requireResource("gameSession")
            local state = world:requireResource("dailyConversationState")
            if not state then return end

            for event in world:events("dailyCardPlayRequested") do
                local index = event.payload.collectionIndex
                if state.resolved or session.dailyConversationCompleted then
                    reject(world, state, "This conversation has already been resolved.")
                elseif not session.collection[index] then
                    reject(world, state, "Select a card from your collection first.")
                else
                    local card = session.collection[index]
                    local categoryMatched = card.category == state.preferredCategory
                    local readinessGained = card.power + (categoryMatched and MATCH_BONUS or 0)
                    session.homecomingReadiness = session.homecomingReadiness + readinessGained
                    session.dailyConversationCompleted = true
                    session.feedback = categoryMatched
                        and ("%s fits perfectly. Readiness +%d."):format(card.name, readinessGained)
                        or ("%s is sincere. Readiness +%d."):format(card.name, readinessGained)
                    state.resolved = true
                    state.feedback = session.feedback
                    world:setResource("gameSession", session)
                    world:setResource("dailyConversationState", state)
                    context.emit("dailyConversationResolved", {
                        targetCharacterId = state.targetCharacterId,
                        cardId = card.id,
                        categoryMatched = categoryMatched,
                        readinessGained = readinessGained,
                        homecomingReadiness = session.homecomingReadiness,
                    })
                    context.emit("dayAdvanceRequested")
                end
                break
            end
        end,
    })
end

DailyConversationResolutionSystem.matchBonus = MATCH_BONUS
return DailyConversationResolutionSystem
