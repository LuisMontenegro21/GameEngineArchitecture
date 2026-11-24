-- Opens, advances, and closes generic map dialogue from the shared keyboard
-- event boundary. It changes only transient presentation state.
local MapDialogueSystem = {}

local function copyLines(lines)
    local result = {}
    for index, line in ipairs(lines) do result[index] = line end
    return result
end

local function isAdvanceKey(key)
    return key == "e" or key == "return" or key == "enter"
end

function MapDialogueSystem.install(scheduler)
    scheduler:addSystem({
        name = "mapDialogue",
        stage = "fixedUpdate",
        after = { "interactionTarget" },
        readsResources = { "nearbyInteraction", "dialogueState", "dailyConversationState" },
        writesResources = { "dialogueState" },
        run = function(context)
            local world = context.world
            local dialogue = world:requireResource("dialogueState")

            if dialogue then
                for event in world:events("keyPressed") do
                    local key = event.payload.key
                    if key == "escape" then
                        world:setResource("dialogueState", false)
                        return
                    end
                    if isAdvanceKey(key) then
                        if dialogue.lineIndex < #dialogue.lines then
                            dialogue.lineIndex = dialogue.lineIndex + 1
                            world:setResource("dialogueState", dialogue)
                        else
                            if dialogue.activityId then
                                context.emit("mapActivityRequested", {
                                    activityId = dialogue.activityId,
                                })
                            end
                            world:setResource("dialogueState", false)
                        end
                        return
                    end
                end
                return
            end

            local target = world:requireResource("nearbyInteraction")
            if not target then return end
            local dailyConversation = world:requireResource("dailyConversationState")
            if dailyConversation and not dailyConversation.resolved
                and target.id == dailyConversation.targetCharacterId then
                return
            end
            for event in world:events("keyPressed") do
                if event.payload.key == "e" then
                    if target.kind == "location" then
                        context.emit("locationEnterRequested", { locationId = target.id })
                        return
                    end
                    world:setResource("dialogueState", {
                        targetId = target.id,
                        targetName = target.name,
                        lines = copyLines(target.dialogue),
                        lineIndex = 1,
                        activityId = target.activityId,
                    })
                    return
                end
            end
        end,
    })
end

MapDialogueSystem.copyLines = copyLines
return MapDialogueSystem
