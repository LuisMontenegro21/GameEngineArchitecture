local AcademyLocationScene = require("src.game.scenes.AcademyLocationScene")
local GameSession = require("src.game.session.GameSession")
local ImageManager = require("src.game.graphics.ImageManager")
local LocationCatalog = require("src.game.locations.LocationCatalog")
local LocationRenderSystem = require("src.game.ui.LocationRenderSystem")
local SceneBackground = require("src.game.graphics.SceneBackground")

local function payload(locationId)
    return {
        session = GameSession.new(),
        locationId = locationId,
        returnTo = "academyMap",
        mapReturnPosition = { x = 220, y = 235 },
    }
end

return function()
    local scene = AcademyLocationScene(payload("astral_court"))
    scene:initialize()
    local world = scene:world()
    assert(LocationRenderSystem.promptFor(false):find("Move near", 1, true),
        "room rendering must explain proximity interaction when nothing is nearby")
    assert(LocationRenderSystem.promptFor({ prompt = "E: Talk to Professor Elian" })
        == "E: Talk to Professor Elian", "room rendering must show a nearby interaction prompt")
    local characters = LocationRenderSystem.collectCharacters(world)
    assert(#characters == 1 and characters[1].character.id == "mentor",
        "room render data must retain scheduled characters")
    scene:dispose()

    local previousLove = love
    local clears = 0
    local wrongSizedImage = {
        setFilter = function() end,
        getDimensions = function() return 64, 64 end,
    }
    _G.love = { graphics = { newImage = function() return wrongSizedImage end } }
    ImageManager.clear()
    local graphics = { clear = function() clears = clears + 1 end }
    for _, location in ipairs(LocationCatalog.all()) do
        assert(not SceneBackground.draw(graphics, location.backgroundId),
            "wrong-sized location backgrounds must use their fallback color")
    end
    assert(clears == 4, "each room must have an asset-free fallback background")
    _G.love = previousLove
    ImageManager.clear()

    local loadedPaths, filters, draws, validPath = {}, 0, 0,
        "assets/wizard_academia/locations/astral-practice-court.png"
    local validImage = {
        setFilter = function(_, min, mag)
            assert(min == "nearest" and mag == "nearest")
            filters = filters + 1
        end,
        getDimensions = function() return 960, 540 end,
    }
    _G.love = {
        graphics = {
            newImage = function(path)
                loadedPaths[#loadedPaths + 1] = path
                if path == validPath then return validImage end
                error("optional location image is absent")
            end,
        },
    }
    ImageManager.clear()
    local validGraphics = {
        setColor = function() end,
        draw = function(image)
            assert(image == validImage, "only the valid room image may draw")
            draws = draws + 1
        end,
        clear = function() clears = clears + 1 end,
    }
    for _, location in ipairs(LocationCatalog.all()) do
        local replaced = SceneBackground.draw(validGraphics, location.backgroundId)
        assert(replaced == (location.backgroundId == "astralCourtInterior"),
            "one valid room background must replace only its own fallback")
    end
    assert(#loadedPaths == 4 and filters == 1 and draws == 1,
        "location backgrounds must use path-keyed cached nearest-filtered images")
    _G.love = previousLove
    ImageManager.clear()
end
