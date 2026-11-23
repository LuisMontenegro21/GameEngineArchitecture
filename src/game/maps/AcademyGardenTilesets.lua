-- Asset declarations only. Images are loaded later by the M11 cache pipeline;
-- M9 continues to use MapTerrainRenderSystem's colored fallback tiles.
local TerrainTilesets = require("src.game.maps.TerrainTilesets")

local tilesets = {
    grass = {
        path = "assets/maps/grass_tiles.png",
        sourceCell = 16,
        maskLayout = "standard16",
    },
    path = {
        path = "assets/maps/path_tiles.png",
        sourceCell = 16,
        maskLayout = "standard16",
    },
}

assert(TerrainTilesets.validate(tilesets), "invalid Academy Garden terrain tilesets")
return tilesets
