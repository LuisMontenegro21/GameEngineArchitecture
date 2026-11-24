local ECS = require("src.engine.ecs")
local ImageManager = require("src.game.graphics.ImageManager")
local SpriteSheet = require("src.game.graphics.SpriteSheet")
local SceneBackground = require("src.game.graphics.SceneBackground")
local ScenePresentationCatalog = require("src.game.graphics.ScenePresentationCatalog")
local CharacterCatalog = require("src.game.characters.CharacterCatalog")
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
    for _, character in ipairs(CharacterCatalog.all()) do
        local sprite = SpriteCatalog.get(character.spriteKey)
        assert(sprite and sprite.frameW == 32 and sprite.frameH == 48,
            "each character must reference a 32 x 48 overworld sprite")
    end
    for _, presentation in pairs(ScenePresentationCatalog.all()) do
        assert(ScenePresentationCatalog.validate(presentation)
            and presentation.nativeW == 960 and presentation.nativeH == 540,
            "scene backgrounds must use their documented native resolution")
    end

    local previousLove = love
    local imageLoads, quadLoads, fallbackDraws, spriteDraws, backgroundDraws = 0, 0, 0, 0, 0
    local fakeImage = {
        width = 64, height = 96,
        setFilter = function(self, min, mag) self.min, self.mag = min, mag end,
        getDimensions = function(self) return self.width, self.height end,
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
    assert(sheet:quad(4, 0) == nil,
        "out-of-bounds sprite frames must not create invalid quads")

    local spriteGraphics = {
        setColor = function() end,
        draw = function() spriteDraws = spriteDraws + 1 end,
        rectangle = function() error("a valid sprite must not draw its fallback") end,
        ellipse = function() error("a valid sprite must not draw its fallback") end,
    }
    assert(MapSpriteRenderSystem.drawSpriteOrFallback(spriteGraphics, { x = 10, y = 20 }, { w = 18, h = 14 }, {
        key = "mentor_overworld", frame = 1, row = 1, layer = "actors",
        fallback = { shape = "rectangle", color = { r = 1, g = 1, b = 1, a = 1 } },
    }), "a valid sprite must replace its fallback")
    assert(spriteDraws == 1)

    local invalidBackgroundGraphics = {
        setColor = function() end,
        clear = function() fallbackDraws = fallbackDraws + 1 end,
    }
    assert(not SceneBackground.draw(invalidBackgroundGraphics, "training"),
        "wrong-sized optional backgrounds must use their fallback color")
    assert(fallbackDraws == 1)
    fakeImage.width, fakeImage.height = 960, 540
    ImageManager.clear()
    local backgroundGraphics = {
        setColor = function() end,
        clear = function() error("a valid background must not clear to its fallback") end,
        draw = function() backgroundDraws = backgroundDraws + 1 end,
    }
    assert(SceneBackground.draw(backgroundGraphics, "training"),
        "a valid scene background must replace its fallback")
    assert(backgroundDraws == 1)
    fakeImage.width, fakeImage.height = 64, 96

    _G.love.graphics.newImage = function() error("missing optional asset") end
    ImageManager.clear()
    SpriteSheet.clear()
    local g = {
        setColor = function() end,
        clear = function() fallbackDraws = fallbackDraws + 1 end,
        rectangle = function() fallbackDraws = fallbackDraws + 1 end,
        ellipse = function() fallbackDraws = fallbackDraws + 1 end,
    }
    assert(not MapSpriteRenderSystem.drawSpriteOrFallback(g, { x = 10, y = 20 }, { w = 18, h = 14 }, {
        key = "player_idle", layer = "actors",
        fallback = { shape = "rectangle", color = { r = 1, g = 1, b = 1, a = 1 } },
    }), "missing optional assets must use the fallback shape")
    assert(fallbackDraws == 2)
    assert(not SceneBackground.draw(g, "finalConversation"),
        "missing optional scene backgrounds must safely use their fallback color")
    assert(fallbackDraws == 3)

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
    assert(not pcall(function()
        world:create({ mapSprite = {
            key = "player_idle", layer = "actors", image = fakeImage,
            fallback = { shape = "rectangle", color = { r = 1, g = 1, b = 1 } },
        } })
    end), "map sprites must not store renderer objects in ECS components")
    world:dispose()
end
