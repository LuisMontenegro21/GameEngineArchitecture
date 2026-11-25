-- Terrain renderer with renderer-side optional tile art and colored fallbacks.
local MapTerrainRenderSystem = {}
local AcademyGardenTilesets = require("src.game.maps.AcademyGardenTilesets")
local ImageManager = require("src.game.graphics.ImageManager")

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

local DIRECTIONS = {
    up = { dx = 0, dy = -1, bit = 1 },
    right = { dx = 1, dy = 0, bit = 2 },
    down = { dx = 0, dy = 1, bit = 4 },
    left = { dx = -1, dy = 0, bit = 8 },
}

local function pathMask(grid, x, y)
    local mask = 0
    for _, direction in pairs(DIRECTIONS) do
        if grid:get(x + direction.dx, y + direction.dy) == "path" then
            mask = mask + direction.bit
        end
    end
    return mask
end

local function pathAsset(mask)
    local tiles = AcademyGardenTilesets.path
    return tiles.assets[mask] or tiles.path
end

local function hasCellDimensions(image, cell)
    if not image or type(image.getDimensions) ~= "function" then return false end
    local width, height = image:getDimensions()
    return width == cell and height == cell
end

local function drawImageTile(g, path, x, y, cell)
    local image = ImageManager.get(path)
    if image and hasCellDimensions(image, cell) and type(g.draw) == "function" then
        g.setColor(1, 1, 1, 1)
        g.draw(image, x, y)
        return true
    end
    return false
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
                local drawX = terrain.ox + (x - 1) * terrain.cell
                local drawY = terrain.oy + (y - 1) * terrain.cell
                local path = identity == "path" and pathAsset(pathMask(terrain.grid, x, y))
                    or AcademyGardenTilesets.grass.path
                if not drawImageTile(g, path, drawX, drawY, terrain.cell) then
                    local color = colorForTerrain(identity)
                    g.setColor(color.r, color.g, color.b, color.a)
                    g.rectangle("fill", drawX, drawY, terrain.cell, terrain.cell)
                end
            end
        end,
    })
end

MapTerrainRenderSystem.colorForTerrain = colorForTerrain
MapTerrainRenderSystem.pathMask = pathMask
MapTerrainRenderSystem.pathAsset = pathAsset
MapTerrainRenderSystem.drawImageTile = drawImageTile
return MapTerrainRenderSystem
