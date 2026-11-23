local AcademyMapScene = require("src.game.scenes.AcademyMapScene")
local PlayerMovementSystem = require("src.game.maps.PlayerMovementSystem")

local function playerMovement(world)
    local result = nil
    for _, _, desired in world:query({
        all = { "mapPlayer", "desiredMovement" },
    }):each() do
        result = desired
    end
    assert(result, "map player has no desiredMovement component")
    return result
end

local function advanceInput(scene, name, key)
    local world = scene:world()
    world:emit(name, { key = key })
    scene:preUpdate(0)
    scene:fixedUpdate(1 / 60)
end

local function newScene()
    local scene = AcademyMapScene()
    scene:initialize()
    return scene
end

local function close(value, expected)
    return math.abs(value - expected) < 0.000001
end

return function()
    local scene = newScene()
    local world = scene:world()
    local step = PlayerMovementSystem.speed / 60

    advanceInput(scene, "keyPressed", "right")
    local desired = playerMovement(world)
    assert(close(desired.dx, step) and close(desired.dy, 0),
        "right input must produce horizontal movement")

    advanceInput(scene, "keyPressed", "up")
    desired = playerMovement(world)
    assert(close(desired.dx, step / math.sqrt(2))
        and close(desired.dy, -step / math.sqrt(2)),
        "diagonal input must be normalized")
    assert(close(math.sqrt(desired.dx * desired.dx + desired.dy * desired.dy), step),
        "diagonal magnitude must equal single-axis magnitude")

    advanceInput(scene, "keyPressed", "left")
    desired = playerMovement(world)
    assert(close(desired.dx, 0) and close(desired.dy, -step),
        "opposing horizontal input must cancel while preserving vertical input")

    advanceInput(scene, "keyReleased", "up")
    desired = playerMovement(world)
    assert(close(desired.dx, 0) and close(desired.dy, 0),
        "releasing one direction must stop only that direction")

    advanceInput(scene, "keyReleased", "left")
    advanceInput(scene, "keyPressed", "d")
    desired = playerMovement(world)
    assert(close(desired.dx, step) and close(desired.dy, 0),
        "WASD aliases must produce the same movement as arrows")

    local distance = 0
    for _ = 1, 60 do
        scene:fixedUpdate(1 / 60)
        distance = distance + playerMovement(world).dx
    end
    assert(close(distance, PlayerMovementSystem.speed),
        "one second of fixed ticks must produce one speed unit of proposed movement")

    advanceInput(scene, "keyReleased", "d")
    assert(world:requireResource("mapInput").right == true,
        "releasing one alias must preserve the held matching direction")
    advanceInput(scene, "keyReleased", "right")
    assert(world:requireResource("mapInput").right == false)
    assert(world:validate())
    scene:dispose()
end
