-- Converts map input into social-conversation UI state and one card-play
-- request. Resolution remains authoritative in its own post-fixed system.
local DailyConversationInputSystem = {}

local function clamp(index, count)
    return math.max(1, math.min(index, math.max(1, count)))
end

function DailyConversationInputSystem.install(scheduler)
    scheduler:addSystem({
        name = "dailyConversationInput",
        stage = "fixedUpdate",
        after = { "mapDialogue" },
        readsResources = {
            "gameSession", "nearbyInteraction", "dailyConversationState", "dailyConversationSelection",
        },
        writesResources = { "dailyConversationState", "dailyConversationSelection" },
        run = function(context)
            local world = context.world
            local state = world:requireResource("dailyConversationState")
            if not state or state.resolved then return end

            local session = world:requireResource("gameSession")
            if not state.open then
                local target = world:requireResource("nearbyInteraction")
                if not target or target.id ~= state.targetCharacterId then return end
                for event in world:events("keyPressed") do
                    if event.payload.key == "e" then
                        state.open = true
                        state.feedback = state.prompt
                        world:setResource("dailyConversationState", state)
                        return
                    end
                end
                return
            end

            local selection = world:requireResource("dailyConversationSelection")
            for event in world:events("keyPressed") do
                local key = event.payload.key
                if key == "escape" then
                    state.open = false
                    state.feedback = "Conversation paused. Find " .. state.targetName .. " when you are ready."
                    world:setResource("dailyConversationState", state)
                    return
                elseif key == "left" or key == "a" then
                    selection = clamp(selection - 1, #session.collection)
                    world:setResource("dailyConversationSelection", selection)
                elseif key == "right" or key == "d" then
                    selection = clamp(selection + 1, #session.collection)
                    world:setResource("dailyConversationSelection", selection)
                elseif key == "return" or key == "enter" or key == "space" then
                    context.emit("dailyCardPlayRequested", { collectionIndex = selection })
                    return
                end
            end
        end,
    })
end

DailyConversationInputSystem.clamp = clamp
return DailyConversationInputSystem
