-- Initializes room state and spawns only the characters scheduled for this
-- location/day. Activities and dialogue are added in later beta phases.
local CharacterCatalog = require("src.game.characters.CharacterCatalog")
local CharacterSchedule = require("src.game.characters.CharacterSchedule")

local LocationSetupSystem = {}

local function copyFallback(fallback)
    return {
        shape = fallback.shape,
        color = {
            r = fallback.color.r,
            g = fallback.color.g,
            b = fallback.color.b,
            a = fallback.color.a,
        },
    }
end

function LocationSetupSystem.install(scheduler)
    scheduler:addSystem({
        name = "locationSetup",
        stage = "startup",
        readsResources = { "gameSession", "locationDefinition" },
        writesResources = { "locationState" },
        run = function(context)
            local world = context.world
            local location = world:requireResource("locationDefinition")
            local schedule = CharacterSchedule.forDay(world:requireResource("gameSession").day)
            local slotIndex = 1
            for _, character in ipairs(CharacterCatalog.all()) do
                if schedule[character.id] == location.id then
                    local slot = assert(location.characterSlots[slotIndex],
                        "location has too few character slots: " .. location.id)
                    world:create({
                        locationPosition = { x = slot.x, y = slot.y },
                        locationSize = { w = 18, h = 24 },
                        locationCharacter = {
                            id = character.id,
                            displayName = character.displayName,
                            role = character.role,
                        },
                        locationSprite = {
                            key = character.spriteKey,
                            frame = 1,
                            row = 1,
                            offsetX = -7,
                            offsetY = -24,
                            scaleX = 1,
                            scaleY = 1,
                            fallback = copyFallback(character.fallback),
                        },
                    })
                    slotIndex = slotIndex + 1
                end
            end
            world:setResource("locationState", {
                focusKind = "activity",
                focusIndex = 1,
                dialogue = false,
                feedback = "Explore the room. Backspace returns to the Academy Garden.",
                transitionQueued = false,
            })
        end,
    })
end

return LocationSetupSystem
