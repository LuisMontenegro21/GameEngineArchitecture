-- Fixed-camera location movement and proximity interaction acceptance tests.
local AcademyLocationScene = require("src.game.scenes.AcademyLocationScene")
local GameSession = require("src.game.session.GameSession")
local LocationMovementSystem = require("src.game.locations.LocationMovementSystem")

local function payload(session)
    return {
        session = session,
        locationId = "astral_court",
        returnTo = "academyMap",
        mapReturnPosition = { x = 220, y = 235 },
    }
end

local function fixed(scene, dt)
    scene:preUpdate(dt)
    scene:fixedUpdate(dt)
    scene:postFixedUpdate(dt)
end

local function player(world)
    local query = world:query({ all = { "locationPlayer", "locationPosition", "locationSize" } })
    local position, size
    for _, _, currentPosition, currentSize in query:each() do position, size = currentPosition, currentSize break end
    query:close()
    assert(position and size, "location player is missing")
    return position, size
end

local function target(world, id)
    local query = world:query({ all = { "locationInteractable" } })
    for _, current in query:each() do
        if current.id == id then
            query:close()
            return current
        end
    end
    query:close()
    error("location interaction target is missing: " .. tostring(id))
end

return function()
    local scene = AcademyLocationScene(payload(GameSession.new()))
    scene:initialize()
    local world = scene:world()
    local position, size = player(world)
    local initialX = position.x
    world:emit("keyPressed", { key = "d" })
    fixed(scene, 1 / 60)
    assert(position.x == initialX + LocationMovementSystem.speed / 60,
        "room movement must be delta-time based at the documented speed")
    world:emit("keyReleased", { key = "d" })
    fixed(scene, 1 / 60)

    local bounds = world:requireResource("locationBounds")
    position.x = bounds.x + bounds.w - size.w
    world:emit("keyPressed", { key = "right" })
    fixed(scene, 1 / 60)
    assert(position.x == bounds.x + bounds.w - size.w,
        "the fixed camera room must clamp player movement to its bounds")
    world:emit("keyReleased", { key = "right" })
    fixed(scene, 1 / 60)

    local mentor = target(world, "mentor")
    position.x = mentor.trigger.x + (mentor.trigger.w - size.w) / 2
    position.y = mentor.trigger.y + (mentor.trigger.h - size.h) / 2
    fixed(scene, 1 / 60)
    local nearby = world:requireResource("nearbyLocationInteraction")
    assert(nearby and nearby.id == "mentor" and nearby.kind == "character",
        "standing near a character must expose that character as the interaction target")
    world:emit("keyPressed", { key = "e" })
    fixed(scene, 1 / 60)
    assert(world:requireResource("locationState").dialogue,
        "E near a non-daily character must open their existing dialogue")
    local dialogueX, dialogueY = position.x, position.y
    world:emit("keyPressed", { key = "d" })
    fixed(scene, 1 / 60)
    assert(position.x == dialogueX and position.y == dialogueY,
        "movement must pause while dialogue owns room input")
    scene:dispose()
end
