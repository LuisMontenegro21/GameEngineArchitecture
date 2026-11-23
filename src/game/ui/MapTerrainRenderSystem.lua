-- Fallback terrain renderer. Tile images are intentionally deferred until the
-- cache and sprite contract phase; this system still owns terrain presentation.
local MapTerrainRenderSystem = {}
local AcademyGardenTilesets = require("src.game.maps.AcademyGardenTilesets")

local FALLBACK_COLORS = {
    grass = { r = 0.15, g = 0.34, b = 0.19, a = 1 },
    path = { r = 0.66, g = 0.59, b = 0.42, a = 1 },
    astral_path = { r = 0.53, g = 0.40, b = 0.76, a = 1 },
    garden_path = { r = 0.50, g = 0.67, b = 0.40, a = 1 },
}

local function graphics()
    return love and love.graphics or nil
end

local function colorForTerrain(terrain)
    return FALLBACK_COLORS[terrain] or FALLBACK_COLORS.grass
end

function MapTerrainRenderSystem.install(scheduler)
    scheduler:addSystem({
        name = "mapTerrainRender",
        stage = "render",
        readsResources = { "mapTerrain" },
        before = { "mapSpriteRender" },
        run = function(context)
            local g = graphics()
            if not g then return end
            local terrain = context.world:requireResource("mapTerrain")

            g.clear(0.04, 0.09, 0.08, 1)
            for x, y, identity in terrain.grid:each() do
                assert(AcademyGardenTilesets[identity] ~= nil,
                    "map terrain uses an undeclared tileset: " .. tostring(identity))
                local color = colorForTerrain(identity)
                g.setColor(color.r, color.g, color.b, color.a)
                g.rectangle("fill", terrain.ox + (x - 1) * terrain.cell,
                    terrain.oy + (y - 1) * terrain.cell, terrain.cell, terrain.cell)
            end
        end,
    })
end

MapTerrainRenderSystem.colorForTerrain = colorForTerrain
return MapTerrainRenderSystem
