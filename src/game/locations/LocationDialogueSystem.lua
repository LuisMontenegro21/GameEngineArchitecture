-- Owns short location-character dialogue state. It reads catalog flavor text
-- but leaves daily card conversations to the dedicated Beta 7 systems.
local CharacterCatalog = require("src.game.characters.CharacterCatalog")

local LocationDialogueSystem = {}

local function copyLines(lines)
    local result = {}
    for index, line in ipairs(lines) do result[index] = line end
    return result
end

function LocationDialogueSystem.install(scheduler)
    scheduler:addSystem({
        name = "locationDialogue",
        stage = "postFixedUpdate",
        readsResources = { "locationState" },
        writesResources = { "locationState" },
        run = function(context)
            local world = context.world
            local state = world:requireResource("locationState")
            if state.transitionQueued then return end
            if state.dialogue then
                for _ in world:events("locationDialogueAdvanceRequested") do
                    if state.dialogue.lineIndex < #state.dialogue.lines then
                        state.dialogue.lineIndex = state.dialogue.lineIndex + 1
                    else
                        state.dialogue = false
                        state.feedback = "Conversation complete."
                    end
                    world:setResource("locationState", state)
                    return
                end
                return
            end
            for event in world:events("locationCharacterInteractionRequested") do
                local character = assert(CharacterCatalog.get(event.payload.characterId),
                    "location dialogue requested an unknown character")
                state.dialogue = {
                    characterId = character.id,
                    targetName = character.displayName,
                    lines = copyLines(character.dialogue),
                    lineIndex = 1,
                }
                state.feedback = ""
                world:setResource("locationState", state)
                return
            end
        end,
    })
end

return LocationDialogueSystem
