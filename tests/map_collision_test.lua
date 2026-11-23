local AcademyMapScene = require("src.game.scenes.AcademyMapScene")
local PlayerMovementSystem = require("src.game.maps.PlayerMovementSystem")

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

local function setInput(world, directions)
    world:setResource("mapInput", {
        up = directions.up == true,
        down = directions.down == true,
        left = directions.left == true,
        right = directions.right == true,
        keys = {},
    })
end

local function move(scene, directions, dt)
    setInput(scene:world(), directions)
    scene:fixedUpdate(dt or 1 / 60)
end

local function close(value, expected)
    return math.abs(value - expected) < 0.000001
end

return function()
    local scene = AcademyMapScene()
    scene:initialize()
    local world = scene:world()
    local map = world:requireResource("mapDefinition")
    local bounds = map.bounds
    local position, size = player(world)

    position.x, position.y = bounds.x, 300
    move(scene, { left = true }, 1)
    assert(close(position.x, bounds.x), "left map boundary must block movement")

    position.x, position.y = bounds.x + bounds.w - size.w, 300
    move(scene, { right = true }, 1)
    assert(close(position.x, bounds.x + bounds.w - size.w),
        "right map boundary must block movement")

    position.x, position.y = 500, bounds.y
    move(scene, { up = true }, 1)
    assert(close(position.y, bounds.y), "top map boundary must block movement")

    position.x, position.y = 500, bounds.y + bounds.h - size.h
    move(scene, { down = true }, 1)
    assert(close(position.y, bounds.y + bounds.h - size.h),
        "bottom map boundary must block movement")

    local academyTree = map.obstacles[1]
    position.x, position.y = academyTree.x - size.w - 1, academyTree.y + 20
    move(scene, { right = true }, 1 / 60)
    assert(close(position.x, academyTree.x - size.w),
        "academy tree must block movement from the left")

    position.x, position.y = academyTree.x + academyTree.w + 1, academyTree.y + 20
    move(scene, { left = true }, 1 / 60)
    assert(close(position.x, academyTree.x + academyTree.w),
        "academy tree must block movement from the right")

    local library = map.obstacles[2]
    position.x, position.y = library.x + 20, library.y - size.h - 1
    move(scene, { down = true }, 1 / 60)
    assert(close(position.y, library.y - size.h),
        "library footprint must block movement from above")

    local pond = map.obstacles[5]
    position.x, position.y = pond.x + 20, pond.y + pond.h + 1
    move(scene, { up = true }, 1 / 60)
    assert(close(position.y, pond.y + pond.h),
        "pond footprint must block movement from below")

    local diagonalStep = PlayerMovementSystem.speed / 60 / math.sqrt(2)
    position.x, position.y = academyTree.x - size.w - 1, academyTree.y - 12
    move(scene, { right = true, down = true }, 1 / 60)
    assert(close(position.x, academyTree.x - size.w),
        "blocked horizontal movement must stay outside the academy tree")
    assert(close(position.y, academyTree.y - 12 + diagonalStep),
        "free vertical movement must continue while sliding along an obstacle")

    assert(world:validate())
    scene:dispose()
end
