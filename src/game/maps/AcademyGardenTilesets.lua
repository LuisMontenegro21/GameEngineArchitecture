-- Asset declarations only. Images are loaded later by the M11 cache pipeline;
-- M9 continues to use MapTerrainRenderSystem's colored fallback tiles.
local TerrainTilesets = require("src.game.maps.TerrainTilesets")

local tilesets = {
    grass = {
        path = "assets/wizard_academia/maps/grass-tile.png",
        sourceCell = 32,
        maskLayout = "single",
    },
    path = {
        -- One explicit image per four-neighbour connection mask. Keeping the
        -- artwork data here makes the renderer independent from file names.
        path = "assets/wizard_academia/maps/road.png", -- vertical straight
        sourceCell = 32,
        maskLayout = "connected",
        straightHorizontalPath = "assets/wizard_academia/maps/road-90.png",
        bendPaths = {
            upRight = "assets/wizard_academia/maps/bend-road.png",
            rightDown = "assets/wizard_academia/maps/bend-road-90.png",
            downLeft = "assets/wizard_academia/maps/bend-road-180.png",
            leftUp = "assets/wizard_academia/maps/bend-road-270.png",
        },
        junctionPath = "assets/wizard_academia/maps/t-road.png",
        assets = {
            [0] = "assets/wizard_academia/maps/road-isolated.png",
            [1] = "assets/wizard_academia/maps/road-end-up.png",
            [2] = "assets/wizard_academia/maps/road-end-right.png",
            [3] = "assets/wizard_academia/maps/bend-road.png",
            [4] = "assets/wizard_academia/maps/road-end-down.png",
            [5] = "assets/wizard_academia/maps/road.png",
            [6] = "assets/wizard_academia/maps/bend-road-90.png",
            [7] = "assets/wizard_academia/maps/t-road-no-left.png",
            [8] = "assets/wizard_academia/maps/road-end-left.png",
            [9] = "assets/wizard_academia/maps/bend-road-270.png",
            [10] = "assets/wizard_academia/maps/road-90.png",
            [11] = "assets/wizard_academia/maps/t-road-no-down.png",
            [12] = "assets/wizard_academia/maps/bend-road-180.png",
            [13] = "assets/wizard_academia/maps/t-road-no-right.png",
            [14] = "assets/wizard_academia/maps/t-road.png",
            [15] = "assets/wizard_academia/maps/cross-road.png",
        },
    },
}

assert(TerrainTilesets.validate(tilesets), "invalid Academy Garden terrain tilesets")
return tilesets
