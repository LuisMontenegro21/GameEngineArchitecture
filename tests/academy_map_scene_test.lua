local GameSession = require("src.game.session.GameSession")
local AcademyMapScene = require("src.game.scenes.AcademyMapScene")
local CharacterCatalog = require("src.game.characters.CharacterCatalog")

local function count(query)
    local total = 0
    for _ in query:each() do total = total + 1 end
    return total
end

return function()
    local session = GameSession.new()
    local scene = AcademyMapScene({ session = session, returnTo = "training" })
    scene:initialize()
    local world = scene:world()
    local map = world:requireResource("mapDefinition")
    local renderSystems = scene:scheduler():systemsFor("render")
    assert(renderSystems[1].name == "mapTerrainRender"
        and renderSystems[2].name == "mapSpriteRender"
        and renderSystems[3].name == "mapLabelRender"
        and renderSystems[4].name == "mapHudRender",
        "map rendering must use explicit terrain, world, label, and HUD passes")

    assert(world:requireResource("gameSession") == session)
    assert(world:requireResource("mapReturnTarget") == "training")
    local terrain = world:requireResource("mapTerrain")
    assert(terrain.grid.width == 28 and terrain.grid.height == 14,
        "map setup must build one 28-by-14 terrain grid")
    assert(terrain.cell * terrain.grid.width == map.bounds.w
        and terrain.cell * terrain.grid.height == map.bounds.h,
        "terrain grid dimensions must match playable bounds")
    assert(count(world:query({ all = { "mapPlayer", "mapPosition", "mapSize" } })) == 1,
        "map setup must create one player")
    assert(count(world:query({ all = { "mapCollider" }, none = { "mapPlayer" } }))
        == #map.obstacles, "every static obstacle needs a collider")
    assert(count(world:query({
        all = { "mapCollider", "mapSprite" },
        none = { "mapPlayer" },
    })) == #map.obstacles, "every static obstacle needs one sprite presentation owner")
    assert(count(world:query({ all = { "pointOfInterest", "mapSprite" } }))
        == #map.pointsOfInterest, "each POI must share its structure's one visible entity")
    assert(not world:hasComponentType("mapRenderable"),
        "the transitional mapRenderable contract must be removed after conversion")
    assert(world:count() == 1 + #map.obstacles + #CharacterCatalog.all(),
        "terrain, POIs, and scheduled characters must each have one visible entity")

    scene:draw(0)
    assert(world:validate(), "headless map scene must remain valid after render")
    assert(scene:dispose())
end
