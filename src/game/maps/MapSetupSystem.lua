-- Builds the static Academy Garden entities from the validated map definition.
local AcademyGardenTiles = require("src.game.maps.AcademyGardenTiles")
local TerrainDefinition = require("src.game.maps.TerrainDefinition")

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

function MapSetupSystem.install(scheduler)
    scheduler:addSystem({
        name = "mapSetup",
        stage = "startup",
        readsResources = { "mapDefinition", "mapBounds" },
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
                end
                world:create(components)
            end
        end,
    })
end

return MapSetupSystem
