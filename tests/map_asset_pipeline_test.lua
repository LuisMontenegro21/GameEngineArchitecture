local ECS = require("src.engine.ecs")
local ImageManager = require("src.game.graphics.ImageManager")
local SpriteSheet = require("src.game.graphics.SpriteSheet")
local SpriteCatalog = require("src.game.maps.SpriteCatalog")
local MapSpriteRenderSystem = require("src.game.ui.MapSpriteRenderSystem")
local registerMap = require("src.game.maps.register")

return function()
    assert(SpriteCatalog.validate(SpriteCatalog.all()), "the sprite catalog must validate")
    assert(SpriteCatalog.has("player_idle") and not SpriteCatalog.has("missing"))
    assert(not SpriteCatalog.validate({ { key = "bad", path = "x.png", frameW = 0, frameH = 16 } }),
        "catalog frame dimensions must validate")
    assert(not SpriteCatalog.validate({
        { key = "duplicate", path = "one.png", frameW = 16, frameH = 16 },
        { key = "duplicate", path = "two.png", frameW = 16, frameH = 16 },
    }), "catalog keys must be unique")

    local previousLove = love
    local imageLoads, quadLoads, fallbackDraws = 0, 0, 0
    local fakeImage = {
        setFilter = function(self, min, mag) self.min, self.mag = min, mag end,
        getDimensions = function() return 32, 32 end,
    }
    _G.love = {
        graphics = {
            newImage = function() imageLoads = imageLoads + 1 return fakeImage end,
            newQuad = function(x, y, w, h, imageW, imageH)
                quadLoads = quadLoads + 1
                return { x = x, y = y, w = w, h = h, imageW = imageW, imageH = imageH }
            end,
        },
    }
    ImageManager.clear()
    SpriteSheet.clear()
    assert(ImageManager.get("assets/test.png") == fakeImage)
    assert(ImageManager.get("assets/test.png") == fakeImage and imageLoads == 1,
        "images must be loaded once per path")
    assert(fakeImage.min == "nearest" and fakeImage.mag == "nearest",
        "pixel-art images must use nearest-neighbor filtering")
    local sheet = SpriteSheet.get("assets/test.png", 16, 16)
    assert(sheet == SpriteSheet.get("assets/test.png", 16, 16), "sheets must be cached")
    assert(sheet:quad(0, 0) == sheet:quad(0, 0) and quadLoads == 1,
        "quads must be cached by sheet coordinate")

    _G.love.graphics.newImage = function() error("missing optional asset") end
    ImageManager.clear()
    SpriteSheet.clear()
    local g = {
        setColor = function() end,
        rectangle = function() fallbackDraws = fallbackDraws + 1 end,
        ellipse = function() fallbackDraws = fallbackDraws + 1 end,
    }
    assert(not MapSpriteRenderSystem.drawSpriteOrFallback(g, { x = 10, y = 20 }, { w = 18, h = 14 }, {
        key = "player_idle", layer = "actors",
        fallback = { shape = "rectangle", color = { r = 1, g = 1, b = 1, a = 1 } },
    }), "missing optional assets must use the fallback shape")
    assert(fallbackDraws == 1)

    _G.love = previousLove
    ImageManager.clear()
    SpriteSheet.clear()
    assert(ImageManager.get("assets/headless.png") == nil, "headless image requests must be safe")
    assert(SpriteSheet.get("assets/headless.png", 16, 16) == nil, "headless sheet requests must be safe")

    local world = ECS.World.new({ identity = "sprite-contract" })
    registerMap(world)
    local entity = world:create({
        mapPosition = { x = 1, y = 2 }, mapSize = { w = 3, h = 4 },
        mapSprite = {
            key = "player_idle", frame = 1, row = 1, scaleX = 1, scaleY = 1,
            offsetX = 0, offsetY = -34, layer = "actors",
            fallback = { shape = "rectangle", color = { r = 1, g = 1, b = 1, a = 1 } },
        },
    })
    assert(world:isAlive(entity))
    assert(not pcall(function()
        world:create({ mapSprite = {
            key = "unknown", layer = "actors",
            fallback = { shape = "rectangle", color = { r = 1, g = 1, b = 1 } },
        } })
    end), "map sprites must reference catalog keys")
    world:dispose()
end
