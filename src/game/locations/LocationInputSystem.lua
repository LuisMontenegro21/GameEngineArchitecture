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
            "nearbyLocationInteraction", "activityChallengeState",
        },
        writesResources = {
            "locationInput", "locationState", "dailyConversationState", "dailyConversationSelection",
            "activityChallengeState",
        },
        run = function(context)
            local world = context.world
            local state = world:requireResource("locationState")
            local daily = world:requireResource("dailyConversationState")
            local challenge = world:requireResource("activityChallengeState")
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
                if challenge then
                    if key == "escape" or key == "backspace" then
                        state.feedback = "Activity challenge cancelled."
                        world:setResource("locationState", state)
                        world:setResource("activityChallengeState", false)
                    elseif challenge.mode == "sequence" and (key == "left" or key == "right"
                        or key == "up" or key == "down") then
                        if key == challenge.steps[challenge.currentStep] then
                            challenge.currentStep = challenge.currentStep + 1
                            if challenge.currentStep > #challenge.steps then
                                world:setResource("activityChallengeState", false)
                                context.emit("locationActivityRequested", {
                                    activityId = challenge.activityId,
                                    challengeFeedback = challenge.completionFeedback,
                                })
                            else
                                challenge.feedback = "Rune " .. (challenge.currentStep - 1) .. " is correct."
                                world:setResource("activityChallengeState", challenge)
                            end
                        else
                            challenge.currentStep = 1
                            challenge.feedback = "The rune fades. Begin the sequence again."
                            world:setResource("activityChallengeState", challenge)
                        end
                    elseif challenge.mode == "choice" and (key == "left" or key == "up"
                        or key == "right" or key == "down") then
                        local direction = (key == "left" or key == "up") and -1 or 1
                        challenge.selection = challenge.selection + direction
                        if challenge.selection < 1 then challenge.selection = #challenge.options end
                        if challenge.selection > #challenge.options then challenge.selection = 1 end
                        world:setResource("activityChallengeState", challenge)
                    elseif challenge.mode == "choice" and (key == "e" or key == "return"
                        or key == "enter" or key == "space") then
                        local choice = challenge.options[challenge.selection]
                        world:setResource("activityChallengeState", false)
                        context.emit("locationActivityRequested", {
                            activityId = challenge.activityId,
                            challengeFeedback = choice.feedback,
                        })
                    end
                    return
                end
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
                    local target = world:requireResource("nearbyLocationInteraction")
                    if target and target.kind == "activity" then
                        context.emit("locationActivityChallengeRequested", { activityId = target.activityId })
                    else
                        interact(context, target, daily)
                    end
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
