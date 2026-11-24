-- Converts room keyboard input into requests. Activities and dialogue are
-- resolved by dedicated post-fixed systems, keeping input non-authoritative.
local LocationInputSystem = {}

local function promptFor(state)
    if state.focusKind == "exit" then return "Backspace returns to the Academy Garden." end
    if state.focusKind == "character" then return "Press E to speak." end
    return "Press E to practice this activity."
end

local function characters(world)
    local result = {}
    local query = world:query({ all = { "locationCharacter" } })
    for _, character in query:each() do result[#result + 1] = character end
    query:close()
    table.sort(result, function(left, right) return left.id < right.id end)
    return result
end

local function focusOrdinal(state, characterCount)
    if state.focusKind == "activity" then return 1 end
    if state.focusKind == "character" then return state.focusIndex + 1 end
    return characterCount + 2
end

local function setFocus(state, characterCount, ordinal)
    local total = characterCount + 2
    if ordinal < 1 then ordinal = total end
    if ordinal > total then ordinal = 1 end
    if ordinal == 1 then
        state.focusKind, state.focusIndex = "activity", 1
    elseif ordinal == total then
        state.focusKind, state.focusIndex = "exit", 1
    else
        state.focusKind, state.focusIndex = "character", ordinal - 1
    end
    state.feedback = promptFor(state)
    return state
end

function LocationInputSystem.install(scheduler)
    scheduler:addSystem({
        name = "locationInput",
        stage = "fixedUpdate",
        reads = { "locationCharacter" },
        readsResources = { "gameSession", "locationState", "locationDefinition", "dailyConversationState", "dailyConversationSelection" },
        writesResources = { "locationState", "dailyConversationState", "dailyConversationSelection" },
        run = function(context)
            local world = context.world
            local state = world:requireResource("locationState")
            local daily = world:requireResource("dailyConversationState")
            local session = world:requireResource("gameSession")
            if state.transitionQueued then return end
            for event in world:events("keyPressed") do
                if daily and daily.open then
                    if event.payload.key == "escape" or event.payload.key == "backspace" then
                        daily.open = false
                        daily.feedback = "Conversation closed. Speak to " .. daily.targetName .. " when ready."
                        world:setResource("dailyConversationState", daily)
                    elseif not daily.resolved and (event.payload.key == "left" or event.payload.key == "up"
                        or event.payload.key == "right" or event.payload.key == "down") then
                        local direction = (event.payload.key == "left" or event.payload.key == "up") and -1 or 1
                        local selection = world:requireResource("dailyConversationSelection") + direction
                        if #session.collection > 0 then
                            if selection < 1 then selection = #session.collection end
                            if selection > #session.collection then selection = 1 end
                            world:setResource("dailyConversationSelection", selection)
                        end
                    elseif not daily.resolved and (event.payload.key == "e" or event.payload.key == "return"
                        or event.payload.key == "enter" or event.payload.key == "space") then
                        context.emit("dailyCardPlayRequested", {
                            collectionIndex = world:requireResource("dailyConversationSelection"),
                        })
                    end
                    return
                end
                if state.dialogue then
                    if event.payload.key == "escape" or event.payload.key == "backspace" then
                        state.dialogue = false
                        state.feedback = "Conversation closed."
                        world:setResource("locationState", state)
                    elseif event.payload.key == "e" or event.payload.key == "return"
                        or event.payload.key == "enter" or event.payload.key == "space" then
                        context.emit("locationDialogueAdvanceRequested")
                    end
                    return
                end
                if event.payload.key == "backspace" then
                    context.emit("locationExitRequested")
                    break
                elseif event.payload.key == "left" or event.payload.key == "right"
                    or event.payload.key == "up" or event.payload.key == "down"
                    or event.payload.key == "tab" then
                    local direction = (event.payload.key == "left" or event.payload.key == "up") and -1 or 1
                    world:setResource("locationState", setFocus(state, #characters(world),
                        focusOrdinal(state, #characters(world)) + direction))
                elseif event.payload.key == "e" or event.payload.key == "return"
                    or event.payload.key == "enter" or event.payload.key == "space" then
                    if state.focusKind == "activity" then
                        context.emit("locationActivityRequested", {
                            activityId = world:requireResource("locationDefinition").activityId,
                        })
                    elseif state.focusKind == "character" then
                        local character = characters(world)[state.focusIndex]
                        if character then
                            if daily and not daily.resolved and character.id == daily.targetCharacterId then
                                context.emit("locationDailyConversationOpenRequested", {
                                    characterId = character.id,
                                })
                            else
                                context.emit("locationCharacterInteractionRequested", {
                                    characterId = character.id,
                                })
                            end
                        end
                    else
                        context.emit("locationExitRequested")
                    end
                    return
                end
            end
        end,
    })
end

LocationInputSystem.promptFor = promptFor
LocationInputSystem.characters = characters
LocationInputSystem.focusOrdinal = focusOrdinal
LocationInputSystem.setFocus = setFocus

return LocationInputSystem
