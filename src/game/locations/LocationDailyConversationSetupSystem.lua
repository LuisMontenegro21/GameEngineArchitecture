-- Creates room-local daily conversation state from the shared social phase.
local CharacterCatalog = require("src.game.characters.CharacterCatalog")
local CharacterSchedule = require("src.game.characters.CharacterSchedule")
local LocationCatalog = require("src.game.locations.LocationCatalog")
local DailyConversationDefinitions = require("src.game.conversations.DailyConversationDefinitions")

local LocationDailyConversationSetupSystem = {}

function LocationDailyConversationSetupSystem.install(scheduler)
    scheduler:addSystem({
        name = "locationDailyConversationSetup",
        stage = "startup",
        after = { "locationSetup" },
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
            local target = assert(CharacterCatalog.get(definition.targetCharacterId))
            local locationId = assert(CharacterSchedule.locationFor(session.day, target.id))
            local location = assert(LocationCatalog.get(locationId))
            world:setResource("dailyConversationState", {
                day = definition.day,
                targetCharacterId = target.id,
                targetName = target.displayName,
                targetLocationId = locationId,
                targetLocationName = location.name,
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

return LocationDailyConversationSetupSystem
