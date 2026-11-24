-- Converts room keys into held movement input or nearby-target requests.
-- Dialogue and card resolution remain in their dedicated systems.
local LocationInputSystem = {}

local function setDirections(input)
    local keys = input.keys or {}
    input.up = keys.up == true or keys.w == true
    input.down = keys.down == true or keys.s == true
    input.left = keys.left == true or keys.a == true
    input.right = keys.right == true or keys.d == true
end

local function interact(context, target, daily)
    if not target then return false end
    if target.kind == "activity" then
        context.emit("locationActivityRequested", { activityId = target.activityId })
    elseif target.kind == "character" then
        if daily and not daily.resolved and target.id == daily.targetCharacterId then
            context.emit("locationDailyConversationOpenRequested", { characterId = target.id })
        else
            context.emit("locationCharacterInteractionRequested", { characterId = target.id })
        end
    else
        context.emit("locationExitRequested")
    end
    return true
end

function LocationInputSystem.install(scheduler)
    scheduler:addSystem({
        name = "locationInput",
        stage = "fixedUpdate",
        readsResources = {
            "gameSession", "locationState", "dailyConversationState", "dailyConversationSelection",
            "nearbyLocationInteraction",
        },
        writesResources = { "locationInput", "locationState", "dailyConversationState", "dailyConversationSelection" },
        run = function(context)
            local world = context.world
            local state = world:requireResource("locationState")
            local daily = world:requireResource("dailyConversationState")
            if state.transitionQueued then return end
            local input = world:requireResource("locationInput")
            input.keys = input.keys or {}
            local changed = false

            for event in world:events("keyReleased") do
                input.keys[event.payload.key] = nil
                changed = true
            end
            for event in world:events("keyPressed") do
                local key = event.payload.key
                if daily and daily.open then
                    if key == "escape" or key == "backspace" then
                        daily.open = false
                        daily.feedback = "Conversation closed. Speak to " .. daily.targetName .. " when ready."
                        world:setResource("dailyConversationState", daily)
                    elseif not daily.resolved and (key == "left" or key == "up" or key == "right" or key == "down") then
                        local selection = world:requireResource("dailyConversationSelection")
                            + ((key == "left" or key == "up") and -1 or 1)
                        local collection = world:requireResource("gameSession").collection
                        if #collection > 0 then
                            if selection < 1 then selection = #collection end
                            if selection > #collection then selection = 1 end
                            world:setResource("dailyConversationSelection", selection)
                        end
                    elseif not daily.resolved and (key == "e" or key == "return" or key == "enter" or key == "space") then
                        context.emit("dailyCardPlayRequested", {
                            collectionIndex = world:requireResource("dailyConversationSelection"),
                        })
                    end
                    return
                end
                if state.dialogue then
                    if key == "escape" or key == "backspace" then
                        state.dialogue = false
                        state.feedback = "Conversation closed."
                        world:setResource("locationState", state)
                    elseif key == "e" or key == "return" or key == "enter" or key == "space" then
                        context.emit("locationDialogueAdvanceRequested")
                    end
                    return
                end
                if key == "backspace" then
                    context.emit("locationExitRequested")
                    return
                elseif key == "e" or key == "return" or key == "enter" or key == "space" then
                    interact(context, world:requireResource("nearbyLocationInteraction"), daily)
                    return
                else
                    input.keys[key] = true
                    changed = true
                end
            end
            if changed then
                setDirections(input)
                world:setResource("locationInput", input)
            end
        end,
    })
end

LocationInputSystem.setDirections = setDirections
LocationInputSystem.interact = interact
return LocationInputSystem
