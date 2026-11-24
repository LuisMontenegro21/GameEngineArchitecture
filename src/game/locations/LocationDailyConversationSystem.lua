-- Opens the daily card encounter only when its scheduled character is present.
local LocationDailyConversationSystem = {}

function LocationDailyConversationSystem.install(scheduler)
    scheduler:addSystem({
        name = "locationDailyConversation",
        stage = "postFixedUpdate",
        after = { "locationActivity" },
        readsResources = { "dailyConversationState", "locationDefinition" },
        writesResources = { "dailyConversationState" },
        run = function(context)
            local world = context.world
            local state = world:requireResource("dailyConversationState")
            if not state or state.resolved then return end
            for event in world:events("locationDailyConversationOpenRequested") do
                if event.payload.characterId == state.targetCharacterId
                    and world:requireResource("locationDefinition").id == state.targetLocationId then
                    state.open = true
                    state.feedback = state.prompt
                    world:setResource("dailyConversationState", state)
                end
                return
            end
        end,
    })
end

return LocationDailyConversationSystem
