-- Optional grass/path tile rendering must use the cache and preserve colored
-- fallback terrain when an image is missing or has the wrong native size.
local ImageManager = require("src.game.graphics.ImageManager")
local AcademyGardenTilesets = require("src.game.maps.AcademyGardenTilesets")
local MapTerrainRenderSystem = require("src.game.ui.MapTerrainRenderSystem")
local SpriteCatalog = require("src.game.maps.SpriteCatalog")

return function()
    assert(AcademyGardenTilesets.grass.path == "assets/wizard_academia/maps/grass-tile.png")
    assert(AcademyGardenTilesets.path.path == "assets/wizard_academia/maps/road.png")
    assert(MapTerrainRenderSystem.pathAsset(5) == AcademyGardenTilesets.path.path,
        "vertical paths must use the base road tile")
    assert(MapTerrainRenderSystem.pathAsset(10) == AcademyGardenTilesets.path.straightHorizontalPath,
        "horizontal paths must use the rotated road tile")
    assert(MapTerrainRenderSystem.pathAsset(3) == AcademyGardenTilesets.path.bendPaths.upRight,
        "corner masks must select their dedicated bend art")
    assert(MapTerrainRenderSystem.pathAsset(1) == "assets/wizard_academia/maps/road-end-up.png"
        and MapTerrainRenderSystem.pathAsset(7) == "assets/wizard_academia/maps/t-road-no-left.png"
        and MapTerrainRenderSystem.pathAsset(15) == "assets/wizard_academia/maps/cross-road.png",
        "endpoints, each T-junction orientation, and crossroads must use dedicated road art")
    assert(SpriteCatalog.get("academy_tree").path == "assets/wizard_academia/maps/academy-tree.png",
        "the available Academy tree must replace only its scenery fallback")

    local previousLove = love
    local loads, draws = 0, 0
    local image = {
        width = 32, height = 32,
        setFilter = function(self, min, mag) self.min, self.mag = min, mag end,
        getDimensions = function(self) return self.width, self.height end,
    }
    _G.love = { graphics = { newImage = function() loads = loads + 1 return image end } }
    ImageManager.clear()
    local graphics = {
        setColor = function() end,
        draw = function(drawn) assert(drawn == image); draws = draws + 1 end,
    }
    assert(MapTerrainRenderSystem.drawImageTile(graphics, AcademyGardenTilesets.grass.path, 0, 0, 32)
        and draws == 1 and loads == 1 and image.min == "nearest" and image.mag == "nearest",
        "valid 32-pixel tile art must render through the nearest-filtered image cache")
    image.width = 16
    ImageManager.clear()
    assert(not MapTerrainRenderSystem.drawImageTile(graphics, AcademyGardenTilesets.grass.path, 0, 0, 32),
        "wrong-sized terrain images must preserve the renderer fallback")
    _G.love = previousLove
    ImageManager.clear()
end
