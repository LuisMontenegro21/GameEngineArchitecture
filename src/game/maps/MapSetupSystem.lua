-- Builds the static Academy Garden entities from the validated map definition.
local AcademyGardenTiles = require("src.game.maps.AcademyGardenTiles")
local TerrainDefinition = require("src.game.maps.TerrainDefinition")
local CharacterCatalog = require("src.game.characters.CharacterCatalog")
local CharacterSchedule = require("src.game.characters.CharacterSchedule")
local CharacterPlacement = require("src.game.maps.CharacterPlacement")

local MapSetupSystem = {}

local function copySprite(sprite)
    return {
        key = sprite.key,
        frame = 1,
        row = 1,
        scaleX = sprite.scaleX,
        scaleY = sprite.scaleY,
        offsetX = sprite.offsetX,
        offsetY = sprite.offsetY,
        layer = sprite.layer,
        fallback = {
            shape = sprite.fallback.shape,
            color = {
                r = sprite.fallback.color.r,
                g = sprite.fallback.color.g,
                b = sprite.fallback.color.b,
                a = sprite.fallback.color.a,
            },
        },
    }
end

local function copyInteraction(point)
    local dialogue = {}
    for index, line in ipairs(point.interaction.dialogue) do dialogue[index] = line end
    return {
        id = point.id,
        kind = "location",
        name = point.name,
        prompt = point.interaction.prompt,
        activityId = point.interaction.activityId,
        trigger = {
            x = point.trigger.x,
            y = point.trigger.y,
            w = point.trigger.w,
            h = point.trigger.h,
        },
        dialogue = dialogue,
    }
end

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

local function characterTrigger(placement)
    return {
        x = placement.x - 5,
        y = placement.y - 4,
        w = placement.w + 10,
        h = placement.h + 8,
    }
end

function MapSetupSystem.install(scheduler)
    scheduler:addSystem({
        name = "mapSetup",
        stage = "startup",
        readsResources = { "gameSession", "mapDefinition", "mapBounds" },
        writesResources = { "mapTerrain" },
        run = function(context)
            local world = context.world
            local map = world:requireResource("mapDefinition")
            local bounds = world:requireResource("mapBounds")
            local terrain = TerrainDefinition.build(AcademyGardenTiles)
            local terrainWidth, terrainHeight = TerrainDefinition.dimensions(AcademyGardenTiles)
            assert(AcademyGardenTiles.origin.x == bounds.x and AcademyGardenTiles.origin.y == bounds.y,
                "Academy Garden terrain origin must match map bounds")
            assert(terrainWidth * AcademyGardenTiles.cell == bounds.w
                and terrainHeight * AcademyGardenTiles.cell == bounds.h,
                "Academy Garden terrain dimensions must match map bounds")
            world:setResource("mapTerrain", {
                grid = terrain,
                cell = AcademyGardenTiles.cell,
                ox = AcademyGardenTiles.origin.x,
                oy = AcademyGardenTiles.origin.y,
            })

            world:create({
                mapPosition = { x = map.spawn.x, y = map.spawn.y },
                mapSize = { w = map.playerFootprint.w, h = map.playerFootprint.h },
                mapPlayer = true,
                mapCollider = { solid = true },
                desiredMovement = { dx = 0, dy = 0 },
                mapSprite = {
                    key = "player_idle", frame = 1, row = 1,
                    scaleX = 1, scaleY = 1, offsetX = -7, offsetY = -34, layer = "actors",
                    fallback = { shape = "rectangle", color = { r = 0.55, g = 0.30, b = 0.85, a = 1 } },
                },
            })

            local pointsById = {}
            for _, point in ipairs(map.pointsOfInterest) do pointsById[point.id] = point end
            for _, obstacle in ipairs(map.obstacles) do
                local components = {
                    mapPosition = { x = obstacle.x, y = obstacle.y },
                    mapSize = { w = obstacle.w, h = obstacle.h },
                    mapCollider = { solid = true },
                    mapSprite = copySprite(obstacle.sprite),
                }
                local point = obstacle.pointOfInterestId and pointsById[obstacle.pointOfInterestId]
                if point then
                    components.pointOfInterest = {
                        id = point.id,
                        name = point.name,
                        subtitle = point.subtitle,
                        trigger = {
                            x = point.trigger.x,
                            y = point.trigger.y,
                            w = point.trigger.w,
                            h = point.trigger.h,
                        },
                    }
                    components.mapInteractable = copyInteraction(point)
                end
                world:create(components)
            end

            local schedule = CharacterSchedule.forDay(
                world:requireResource("gameSession").day)
            for _, character in ipairs(CharacterCatalog.all()) do
                local locationId = assert(schedule[character.id],
                    "character schedule is missing " .. character.id)
                local placement = CharacterPlacement.get(locationId, "primary")
                world:create({
                    mapPosition = { x = placement.x, y = placement.y },
                    mapSize = { w = placement.w, h = placement.h },
                    mapCharacter = {
                        id = character.id,
                        displayName = character.displayName,
                        role = character.role,
                        locationId = locationId,
                        interactionId = character.interactionId,
                    },
                    mapInteractable = {
                        id = character.id,
                        kind = "character",
                        name = character.displayName,
                        prompt = "Press E to talk",
                        trigger = characterTrigger(placement),
                        dialogue = character.dialogue,
                    },
                    mapSprite = {
                        key = character.spriteKey,
                        frame = 1,
                        row = 1,
                        scaleX = 1,
                        scaleY = 1,
                        offsetX = -7,
                        offsetY = -24,
                        layer = "actors",
                        fallback = copyFallback(character.fallback),
                    },
                })
            end
        end,
    })
end

return MapSetupSystem
