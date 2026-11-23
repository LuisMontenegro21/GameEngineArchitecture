local ECS = require("src.engine.ecs")
local AcademyGardenTiles = require("src.game.maps.AcademyGardenTiles")
local MapDefinition = require("src.game.maps.MapDefinition")
local registerMap = require("src.game.maps.register")
local GameSession = require("src.game.session.GameSession")
local TerrainDefinition = require("src.game.maps.TerrainDefinition")

return function()
    local map = MapDefinition.get()
    assert(MapDefinition.validate(map), "Academy Garden definition must validate")
    assert(map.bounds.w == 896 and map.bounds.h == 448,
        "the map must align to the 28-by-14 terrain grid")
    assert(TerrainDefinition.validate(AcademyGardenTiles),
        "Academy Garden terrain must remain valid plain data")
    local terrain = TerrainDefinition.build(AcademyGardenTiles)
    assert(terrain.width == 28 and terrain.height == 14,
        "Academy Garden terrain dimensions must match its aligned bounds")
    assert(terrain:count() == 28 * 14,
        "the Academy Garden ground grid must contain no accidental empty holes")
    assert(#map.pointsOfInterest == 4, "the map requires four planned locations")
    assert(#map.obstacles >= 6, "the map requires visible collision obstacles")

    local originalName = MapDefinition.get().pointsOfInterest[1].name
    map.pointsOfInterest[1].name = "changed"
    assert(MapDefinition.get().pointsOfInterest[1].name == originalName,
        "callers must receive an isolated map definition copy")

    local invalid = MapDefinition.get()
    invalid.spawn.x = invalid.bounds.x - 1
    assert(not MapDefinition.validate(invalid), "spawn outside bounds must be rejected")
    invalid = MapDefinition.get()
    invalid.pointsOfInterest[1].id = invalid.obstacles[1].id
    assert(not MapDefinition.validate(invalid), "map identifiers must be unique")
    invalid = MapDefinition.get()
    invalid.pointsOfInterest[1].trigger = {
        x = invalid.obstacles[1].x,
        y = invalid.obstacles[1].y,
        w = 1,
        h = 1,
    }
    assert(not MapDefinition.validate(invalid), "POI triggers cannot overlap solid scenery")
    invalid = MapDefinition.get()
    invalid.obstacles[1].sprite.fallback.color.r = function() end
    assert(not MapDefinition.validate(invalid), "map data must remain plain")
    invalid = MapDefinition.get()
    invalid.obstacles[2].pointOfInterestId = "missing_location"
    assert(not MapDefinition.validate(invalid),
        "visible POI structures must reference an existing point of interest")

    local world = ECS.World.new({ identity = "map-data" })
    registerMap(world)
    world:setResource("gameSession", GameSession.new())
    world:setResource("mapDefinition", MapDefinition.get())
    world:setResource("mapBounds", MapDefinition.get().bounds)
    world:setResource("mapInput", { up = false, down = false, left = false, right = false })
    world:setResource("mapReturnTarget", "training")
    world:setResource("nearbyPointOfInterest", false)
    world:setResource("mapTransitionQueued", false)

    local player = world:create({
        mapPosition = { x = 471, y = 470 },
        mapSize = { w = 18, h = 14 },
        mapPlayer = true,
        mapCollider = { solid = true },
        desiredMovement = { dx = 0, dy = 0 },
        mapSprite = {
            key = "player_idle", layer = "actors",
            fallback = {
                shape = "rectangle",
                color = { r = 0.55, g = 0.30, b = 0.85 },
            },
        },
    })
    assert(world:isAlive(player))
    assert(not pcall(function()
        world:setResource("mapInput", { up = "yes", down = false, left = false, right = false })
    end), "invalid map input must be rejected")
    assert(not pcall(function()
        world:emit("keyReleased", { key = 42 })
    end), "invalid key event payloads must be rejected")
    assert(not pcall(function()
        world:emit("sceneRequest", { to = "training", payload = function() end })
    end), "non-plain transition payloads must be rejected")
    assert(world:validate())
    world:dispose()
end
