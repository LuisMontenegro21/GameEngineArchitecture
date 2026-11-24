-- Builds transient map conversation state from the persistent social phase.
local CharacterCatalog = require("src.game.characters.CharacterCatalog")
local DailyConversationDefinitions = require("src.game.conversations.DailyConversationDefinitions")

local DailyConversationSetupSystem = {}

function DailyConversationSetupSystem.install(scheduler)
    scheduler:addSystem({
        name = "dailyConversationSetup",
        stage = "startup",
        after = { "mapSetup" },
        readsResources = { "gameSession" },
        writesResources = { "dailyConversationState", "dailyConversationSelection" },
        run = function(context)
            local world = context.world
            local session = world:requireResource("gameSession")
            local definition = session.dayPhase == "socialConversation"
                and not session.dailyConversationCompleted
                and DailyConversationDefinitions.get(session.day) or nil
            if not definition then
                world:setResource("dailyConversationState", false)
                world:setResource("dailyConversationSelection", 1)
                return
            end

            local target = assert(CharacterCatalog.get(definition.targetCharacterId),
                "daily conversation target is missing from the character catalog")
            world:setResource("dailyConversationState", {
                day = definition.day,
                targetCharacterId = definition.targetCharacterId,
                targetName = target.displayName,
                preferredCategory = definition.preferredCategory,
                prompt = definition.prompt,
                open = false,
                resolved = false,
                transitionQueued = false,
                feedback = "Find " .. target.displayName .. " to continue your day.",
            })
            world:setResource("dailyConversationSelection", 1)
        end,
    })
end

return DailyConversationSetupSystem
