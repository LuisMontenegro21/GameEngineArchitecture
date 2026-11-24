local AcademyLocationScene = require("src.game.scenes.AcademyLocationScene")
local AcademyMapScene = require("src.game.scenes.AcademyMapScene")
local GameSession = require("src.game.session.GameSession")
local LocationCatalog = require("src.game.locations.LocationCatalog")
local MapReturnPosition = require("src.game.maps.MapReturnPosition")
local SceneManager = require("src.engine.scene.SceneManager")

local function tick(manager)
    manager:preUpdate(1 / 60)
    manager:fixedUpdate(1 / 60)
    manager:postFixedUpdate(1 / 60)
    manager:update(1 / 60)
    manager:postUpdate(1 / 60)
end

local function press(manager, key)
    manager:current():world():emit("keyPressed", { key = key })
    tick(manager)
end

local function player(world)
    local query = world:query({ all = { "mapPlayer", "mapPosition", "mapSize" } })
    local position, size = nil, nil
    for _, _, currentPosition, currentSize in query:each() do
        position, size = currentPosition, currentSize
        break
    end
    query:close()
    assert(position and size, "map player is missing")
    return position, size
end

local function pointById(map, id)
    for _, point in ipairs(map.pointsOfInterest) do
        if point.id == id then return point end
    end
    error("unknown POI: " .. id)
end

return function()
    for _, locationId in ipairs(LocationCatalog.ids()) do
        local manager = SceneManager.new()
        manager:register("academyMap", AcademyMapScene)
        manager:register("academyLocation", AcademyLocationScene)
        local session = GameSession.new()
        manager:start("academyMap", { session = session })
        local mapWorld = manager:current():world()
        local map = mapWorld:requireResource("mapDefinition")
        local point = pointById(map, locationId)
        local position, size = player(mapWorld)
        position.x = point.trigger.x + (point.trigger.w - size.w) / 2
        position.y = point.trigger.y + (point.trigger.h - size.h) / 2
        tick(manager)
        assert(mapWorld:requireResource("nearbyInteraction").id == locationId,
            "the POI must remain discoverable before location entry")

        press(manager, "e")
        assert(manager:current():name() == "academyLocation",
            "E must open the matching dedicated location scene")
        local locationWorld = manager:current():world()
        assert(locationWorld:requireResource("locationDefinition").id == locationId)
        assert(locationWorld:requireResource("gameSession") == session
            and session.actionsRemaining == session.actionsPerDay,
            "entering a location must preserve the session without consuming an action")
        local expectedReturn = locationWorld:requireResource("mapReturnPosition")

        press(manager, "backspace")
        assert(manager:current():name() == "academyMap",
            "Backspace must return from each location to the Academy Garden")
        mapWorld = manager:current():world()
        position = player(mapWorld)
        assert(position.x == expectedReturn.x and position.y == expectedReturn.y,
            "the map must restore the captured near-location return position")
        assert(MapReturnPosition.isSafe(mapWorld:requireResource("mapDefinition"), position),
            "a return position must be in bounds and outside all colliders/triggers")
        assert(position.x ~= map.spawn.x or position.y ~= map.spawn.y,
            "location return must not reset the player to the Academy entrance")
        assert(mapWorld:requireResource("gameSession") == session)
        manager:quit()
    end

    local map = AcademyMapScene({ session = GameSession.new() })
    map:initialize()
    local world = map:world()
    world:emit("locationEnterRequested", { locationId = "astral_court" })
    world:emit("locationEnterRequested", { locationId = "astral_court" })
    map:preUpdate(0)
    map:postFixedUpdate(1 / 60)
    assert(world:requireResource("locationTransitionQueued")
        and world:eventCount("sceneRequest") == 1,
        "repeated POI entries must queue one location transition")
    map:dispose()

    local definition = AcademyMapScene({ session = GameSession.new() })
    definition:initialize()
    local mapData = definition:world():requireResource("mapDefinition")
    local clamped = MapReturnPosition.resolve(mapData, "quiet_garden", { x = -999, y = -999 })
    assert(MapReturnPosition.isSafe(mapData, clamped),
        "out-of-bounds return payloads must be clamped to a safe position")
    definition:dispose()
end
