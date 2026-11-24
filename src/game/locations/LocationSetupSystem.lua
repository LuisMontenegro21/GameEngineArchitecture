-- Initializes room state and spawns only the characters scheduled for this
-- location/day. Activities and dialogue are added in later beta phases.
local CharacterCatalog = require("src.game.characters.CharacterCatalog")
local CharacterSchedule = require("src.game.characters.CharacterSchedule")
local Activities = require("src.game.progression.Activities")

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
        writesResources = {
            "locationState", "locationBounds", "locationInput", "nearbyLocationInteraction",
            "activityChallengeState",
        },
        run = function(context)
            local world = context.world
            local location = world:requireResource("locationDefinition")
            local activity = assert(Activities.get(location.activityId))
            world:setResource("locationBounds", {
                x = location.bounds.x, y = location.bounds.y,
                w = location.bounds.w, h = location.bounds.h,
            })
            world:setResource("locationInput", {
                up = false, down = false, left = false, right = false, keys = {},
            })
            world:setResource("nearbyLocationInteraction", false)
            world:setResource("activityChallengeState", false)
            world:create({
                locationPosition = { x = location.entrance.x, y = location.entrance.y },
                locationSize = { w = 18, h = 24 },
                locationPlayer = true,
                locationDesiredMovement = { dx = 0, dy = 0 },
                locationSprite = {
                    key = "player_idle", frame = 1, row = 1,
                    offsetX = -7, offsetY = -24, scaleX = 1, scaleY = 1,
                    fallback = {
                        shape = "rectangle",
                        color = { r = 0.92, g = 0.76, b = 0.34, a = 1 },
                    },
                },
            })
            world:create({
                locationPosition = { x = location.activitySlot.x, y = location.activitySlot.y },
                locationSize = { w = 36, h = 36 },
                locationActivityStation = true,
                locationInteractable = {
                    id = location.activityId,
                    kind = "activity",
                    name = activity.name,
                    prompt = "E: " .. activity.name,
                    activityId = location.activityId,
                    trigger = {
                        x = location.activitySlot.x - 24, y = location.activitySlot.y - 24,
                        w = 84, h = 84,
                    },
                },
            })
            world:create({
                locationPosition = { x = location.exitSlot.x, y = location.exitSlot.y },
                locationSize = { w = 44, h = 16 },
                locationExit = true,
                locationInteractable = {
                    id = "exit",
                    kind = "exit",
                    name = "Academy Garden",
                    prompt = "E: Return to Academy Garden",
                    trigger = {
                        x = location.exitSlot.x - 22, y = location.exitSlot.y - 10,
                        w = 88, h = 42,
                    },
                },
            })
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
                        locationInteractable = {
                            id = character.id,
                            kind = "character",
                            name = character.displayName,
                            prompt = "E: Talk to " .. character.displayName,
                            trigger = {
                                x = slot.x - 22, y = slot.y - 22,
                                w = 62, h = 68,
                            },
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
                dialogue = false,
                feedback = "Explore the room. Move near an activity, character, or exit.",
                transitionQueued = false,
            })
        end,
    })
end

return LocationSetupSystem
