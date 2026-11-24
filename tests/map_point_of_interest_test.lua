local AcademyMapScene = require("src.game.scenes.AcademyMapScene")

local function player(world)
    local position, size = nil, nil
    for _, _, currentPosition, currentSize in world:query({
        all = { "mapPlayer", "mapPosition", "mapSize" },
    }):each() do
        position, size = currentPosition, currentSize
    end
    assert(position and size, "map player is missing")
    return position, size
end

local function tick(scene)
    scene:fixedUpdate(1 / 60)
end

return function()
    local scene = AcademyMapScene()
    scene:initialize()
    local world = scene:world()
    local session = world:requireResource("gameSession")
    local map = world:requireResource("mapDefinition")
    local position, size = player(world)

    for _, point in ipairs(map.pointsOfInterest) do
        position.x = point.trigger.x + (point.trigger.w - size.w) / 2
        position.y = point.trigger.y + (point.trigger.h - size.h) / 2
        tick(scene)
        local nearby = world:requireResource("nearbyPointOfInterest")
        assert(nearby.id == point.id and nearby.name == point.name
            and nearby.subtitle == point.subtitle,
            "each location trigger must expose its own proximity information")
        local hudLocation = world:requireResource("mapHudLocation")
        assert(hudLocation.id == point.id and hudLocation.name == point.name
            and hudLocation.subtitle == point.subtitle,
            "map HUD state must mirror the authoritative POI result")
    end

    position.x, position.y = 400, 430
    tick(scene)
    assert(world:requireResource("nearbyPointOfInterest") == false,
        "leaving all triggers must clear proximity state")
    assert(world:requireResource("mapHudLocation") == false,
        "leaving all triggers must clear the map HUD panel")

    local first = map.pointsOfInterest[1]
    world:create({
        pointOfInterest = {
            id = "aaa_overlap",
            name = "Overlap Test",
            subtitle = "Deterministic tie breaker.",
            trigger = {
                x = first.trigger.x,
                y = first.trigger.y,
                w = first.trigger.w,
                h = first.trigger.h,
            },
        },
    })
    position.x = first.trigger.x + (first.trigger.w - size.w) / 2
    position.y = first.trigger.y + (first.trigger.h - size.h) / 2
    tick(scene)
    assert(world:requireResource("nearbyPointOfInterest").id == "aaa_overlap",
        "overlapping triggers must choose a deterministic closest/tie-broken location")
    assert(world:requireResource("mapHudLocation").id == "aaa_overlap",
        "HUD state must preserve deterministic POI selection")

    assert(session.actionsRemaining == 2 and session.energy == 3
        and session.stats.confidence == 0 and session.stats.empathy == 0
        and session.stats.arcaneKnowledge == 0 and #session.collection == 0,
        "map proximity must not change progression state")
    assert(world:validate())
    scene:dispose()
end
