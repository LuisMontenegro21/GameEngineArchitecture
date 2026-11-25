-- Turns the active conversation partner toward the player's current position.
-- This is presentation-only: schedules, interaction ranges, and dialogue
-- state remain owned by their existing systems.
local LocationCharacterFacingSystem = {}

-- Sprite-sheet row convention shared by the 32x48 Academy character sheets.
local ROW_FOR_DIRECTION = { down = 1, right = 2, up = 3, left = 4 }

local function facingRow(playerPosition, playerSize, characterPosition, characterSize)
    local playerX = playerPosition.x + playerSize.w / 2
    local playerY = playerPosition.y + playerSize.h / 2
    local characterX = characterPosition.x + characterSize.w / 2
    local characterY = characterPosition.y + characterSize.h / 2
    local dx, dy = playerX - characterX, playerY - characterY
    if math.abs(dx) > math.abs(dy) then
        return dx >= 0 and ROW_FOR_DIRECTION.right or ROW_FOR_DIRECTION.left
    end
    return dy >= 0 and ROW_FOR_DIRECTION.down or ROW_FOR_DIRECTION.up
end

local function activeCharacterId(state, daily)
    if state.dialogue then return state.dialogue.characterId end
    if daily and daily.open then return daily.targetCharacterId end
    return nil
end

local function copySprite(sprite, row)
    return {
        key = sprite.key, frame = sprite.frame, row = row,
        offsetX = sprite.offsetX, offsetY = sprite.offsetY,
        scaleX = sprite.scaleX, scaleY = sprite.scaleY,
        fallback = sprite.fallback,
    }
end

function LocationCharacterFacingSystem.install(scheduler)
    scheduler:addSystem({
        name = "locationCharacterFacing",
        stage = "postFixedUpdate",
        after = { "locationDialogue", "locationDailyConversation" },
        reads = { "locationPosition", "locationSize", "locationPlayer", "locationCharacter", "locationSprite" },
        readsResources = { "locationState", "dailyConversationState" },
        writes = { "locationSprite" },
        run = function(context)
            local world = context.world
            local characterId = activeCharacterId(world:requireResource("locationState"),
                world:requireResource("dailyConversationState"))
            if not characterId then return end

            local playerPosition, playerSize
            local playerQuery = world:query({ all = { "locationPlayer", "locationPosition", "locationSize" } })
            for _, _, position, size in playerQuery:each() do
                playerPosition, playerSize = position, size
                break
            end
            playerQuery:close()
            if not playerPosition then return end

            local query = world:query({
                all = { "locationCharacter", "locationPosition", "locationSize", "locationSprite" },
            })
            for entity, character, position, size, sprite in query:each() do
                if character.id == characterId then
                    local row = facingRow(playerPosition, playerSize, position, size)
                    if sprite.row ~= row then world:set(entity, "locationSprite", copySprite(sprite, row)) end
                    break
                end
            end
            query:close()
        end,
    })
end

LocationCharacterFacingSystem.facingRow = facingRow
LocationCharacterFacingSystem.activeCharacterId = activeCharacterId
return LocationCharacterFacingSystem
