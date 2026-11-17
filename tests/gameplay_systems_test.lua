local Breakout = require("src.game.BreakoutECS")

local function find(world, specification)
    local result = nil
    for entity, first, second, third in world:query(specification):each() do
        if not result then result = { entity = entity, first = first, second = second, third = third } end
    end
    return result
end

return function()
    local game = Breakout.new({ width = 960, height = 540 })
    local world = game.world
    assert(game:status().remainingBricks == 50)
    local order = {}
    for _, system in ipairs(game.scheduler:systemsFor("fixedUpdate")) do order[#order + 1] = system.name end
    assert(table.concat(order, ",") == "inputState,paddleControl,movement,horizontalClamp,ballWallBounce,paddleHits,brickCollision,ballLoss,winCheck")

    local paddle = find(world, { all = { "position", "size", "velocity", "paddle" } })
    paddle.first.x, paddle.third.vx = 959, 420
    game:step(0, { right = true })
    assert(paddle.first.x == 864)

    paddle.first.x = 100
    world:emit("keyPressed", { key = "right" })
    world:advanceEvents()
    game:step(0.1, {})
    assert(paddle.first.x > 100)

    local ball = find(world, { all = { "position", "size", "velocity", "ball" } })
    ball.first.x, ball.third.vx = -1, -220
    game:step(0, {})
    assert(ball.first.x == 0 and ball.third.vx > 0)

    ball.first.y, ball.third.vy = paddle.first.y - ball.second.h + 1, 220
    ball.first.x = paddle.first.x + paddle.second.w / 2
    game:step(0, {})
    assert(ball.third.vy < 0 and ball.first.y == paddle.first.y - ball.second.h)

    local brick = find(world, { all = { "position", "size", "brick" } })
    ball.first.x, ball.first.y = brick.first.x, brick.first.y
    ball.third.vx, ball.third.vy = 0, -220
    game:step(0, {})
    assert(game:status().remainingBricks == 49)
    assert(not world:isAlive(brick.entity))

    ball.first.y = 540 - ball.second.h
    game:step(0, {})
    assert(game:status().status == "lost")
    local lossRequest = nil
    for event in world:events("sceneRequest") do lossRequest = event.payload end
    assert(lossRequest.to == "gameover" and lossRequest.payload.result == "lost")
    game:dispose()

    local restarted = Breakout.new({ width = 960, height = 540 })
    assert(restarted:status().status == "playing" and restarted:status().remainingBricks == 50)
    restarted:status().remainingBricks = 0
    restarted:step(0, {})
    assert(restarted:status().status == "won")
    restarted:dispose()
end
