local AcademyLocationScene = require("src.game.scenes.AcademyLocationScene")
local AcademyMapScene = require("src.game.scenes.AcademyMapScene")
local GameSession = require("src.game.session.GameSession")
local LocationCatalog = require("src.game.locations.LocationCatalog")
local SceneManager = require("src.engine.scene.SceneManager")

local function payload(session, locationId)
    return {
        session = session,
        locationId = locationId,
        returnTo = "academyMap",
        mapReturnPosition = { x = 220, y = 235 },
    }
end

local function tick(manager)
    manager:preUpdate(1 / 60)
    manager:fixedUpdate(1 / 60)
    manager:postFixedUpdate(1 / 60)
    manager:update(1 / 60)
    manager:postUpdate(1 / 60)
end

return function()
    for _, locationId in ipairs(LocationCatalog.ids()) do
        local session = GameSession.new()
        local scene = AcademyLocationScene(payload(session, locationId))
        scene:initialize()
        local world = scene:world()
        assert(world:requireResource("gameSession") == session,
            "location scenes must preserve the provided session object")
        assert(world:requireResource("locationDefinition").id == locationId)
        assert(world:requireResource("locationState").focusKind == "activity")
        scene:draw(0)
        assert(world:validate(), "location scenes must draw safely without LOVE")
        scene:dispose()
    end

    assert(not pcall(function()
        AcademyLocationScene(payload(GameSession.new(), "unknown_location"))
    end), "unknown location payloads must be rejected before scene initialization")

    local manager = SceneManager.new()
    manager:register("academyLocation", AcademyLocationScene)
    manager:register("academyMap", AcademyMapScene)
    local session = GameSession.new()
    manager:start("academyLocation", payload(session, "astral_court"))
    local world = manager:current():world()
    world:emit("keyPressed", { key = "backspace" })
    tick(manager)
    assert(manager:current():name() == "academyMap",
        "Backspace must use a deferred transition back to the map")
    assert(manager:current():world():requireResource("gameSession") == session,
        "location return must preserve the exact shared session object")
    manager:quit()

    local direct = AcademyLocationScene(payload(GameSession.new(), "quiet_garden"))
    direct:initialize()
    world = direct:world()
    world:emit("locationExitRequested")
    world:emit("locationExitRequested")
    direct:fixedUpdate(1 / 60)
    direct:postFixedUpdate(1 / 60)
    assert(world:requireResource("locationState").transitionQueued,
        "the first exit request must lock further room transitions")
    assert(world:eventCount("sceneRequest") == 1,
        "repeated location exits must emit one deferred scene request")
    direct:dispose()
end
