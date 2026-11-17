-- Headless, Runtime-context Breakout gameplay systems. Rendering and scene
-- transitions are deliberately outside this module.
local GameplaySystems = {}

local PADDLE_WIDTH, PADDLE_HEIGHT, PADDLE_MARGIN = 96, 16, 40
local BALL_SIZE, BALL_SPEED_X, BALL_SPEED_Y = 12, 220, -220
local ROWS, COLUMNS = 5, 10
local BRICK_WIDTH, BRICK_HEIGHT, BRICK_GAP_X, BRICK_GAP_Y, BRICK_TOP = 72, 22, 8, 8, 56
local PADDLE_ENGLISH, MAX_HORIZONTAL_SPEED = 140, 360
local BRICK_COLORS = {
    { r = 0.95, g = 0.35, b = 0.35 }, { r = 0.95, g = 0.60, b = 0.25 },
    { r = 0.95, g = 0.85, b = 0.25 }, { r = 0.35, g = 0.75, b = 0.45 },
    { r = 0.35, g = 0.55, b = 0.95 },
}

local function overlaps(a, b)
    return a.x < b.x + b.w and b.x < a.x + a.w
        and a.y < b.y + b.h and b.y < a.y + a.h
end

local function resolveBrick(ballPosition, ballSize, ballVelocity, brickPosition, brickSize)
    local left = ballPosition.x + ballSize.w - brickPosition.x
    local right = brickPosition.x + brickSize.w - ballPosition.x
    local top = ballPosition.y + ballSize.h - brickPosition.y
    local bottom = brickPosition.y + brickSize.h - ballPosition.y
    if math.min(left, right) < math.min(top, bottom) then
        if ballPosition.x + ballSize.w / 2 < brickPosition.x + brickSize.w / 2 then
            ballPosition.x = brickPosition.x - ballSize.w; ballVelocity.vx = -math.abs(ballVelocity.vx)
        else
            ballPosition.x = brickPosition.x + brickSize.w; ballVelocity.vx = math.abs(ballVelocity.vx)
        end
    elseif ballPosition.y + ballSize.h / 2 < brickPosition.y + brickSize.h / 2 then
        ballPosition.y = brickPosition.y - ballSize.h; ballVelocity.vy = -math.abs(ballVelocity.vy)
    else
        ballPosition.y = brickPosition.y + brickSize.h; ballVelocity.vy = math.abs(ballVelocity.vy)
    end
end

function GameplaySystems.install(scheduler)
    scheduler:addSystem({ name = "breakoutSetup", stage = "startup", run = function(context)
        local world, screen = context.world, context.world:requireResource("screen")
        local paddleY = screen.h - PADDLE_MARGIN - PADDLE_HEIGHT
        world:create({ position = { x = (screen.w - PADDLE_WIDTH) / 2, y = paddleY },
            size = { w = PADDLE_WIDTH, h = PADDLE_HEIGHT }, velocity = { vx = 0, vy = 0 },
            paddle = true, moves = true, renderShape = true })
        world:create({ position = { x = (screen.w - BALL_SIZE) / 2, y = paddleY - BALL_SIZE - 12 },
            size = { w = BALL_SIZE, h = BALL_SIZE }, velocity = { vx = BALL_SPEED_X, vy = BALL_SPEED_Y },
            ball = true, moves = true, renderShape = true })
        local gridWidth = COLUMNS * BRICK_WIDTH + (COLUMNS - 1) * BRICK_GAP_X
        for row = 1, ROWS do
            for column = 1, COLUMNS do
                world:create({ position = { x = (screen.w - gridWidth) / 2 + (column - 1) * (BRICK_WIDTH + BRICK_GAP_X),
                    y = BRICK_TOP + (row - 1) * (BRICK_HEIGHT + BRICK_GAP_Y) },
                    size = { w = BRICK_WIDTH, h = BRICK_HEIGHT }, brick = true,
                    color = BRICK_COLORS[row], renderShape = true })
            end
        end
        world:setResource("match", { status = "playing", remainingBricks = ROWS * COLUMNS })
    end })
    scheduler:addSystem({ name = "inputState", stage = "fixedUpdate", writesResources = { "input" }, run = function(context)
        local input = context.world:requireResource("input")
        input.keys = input.keys or {}
        for event in context.world:events("keyPressed") do input.keys[event.payload.key] = true end
        for event in context.world:events("keyReleased") do input.keys[event.payload.key] = nil end
        input.left = input.keys.left == true or input.keys.a == true
        input.right = input.keys.right == true or input.keys.d == true
    end })
    scheduler:addSystem({ name = "paddleControl", stage = "fixedUpdate", after = { "inputState" }, readsResources = { "input" }, writes = { "velocity" }, run = function(context)
        local input = context.world:requireResource("input")
        local keys = input.keys or {}
        local left = input.left or keys.left or keys.a
        local right = input.right or keys.right or keys.d
        local direction = (right and 1 or 0) - (left and 1 or 0)
        for _, velocity in context.world:query({ all = { "velocity", "paddle" } }):each() do
            velocity.vx, velocity.vy = direction * 420, 0
        end
    end })
    scheduler:addSystem({ name = "movement", stage = "fixedUpdate", after = { "paddleControl" }, writes = { "position" }, reads = { "velocity" }, run = function(context)
        for _, position, velocity in context.world:query({ all = { "position", "velocity", "moves" } }):each() do
            position.x, position.y = position.x + velocity.vx * context.dt, position.y + velocity.vy * context.dt
        end
    end })
    scheduler:addSystem({ name = "horizontalClamp", stage = "fixedUpdate", after = { "movement" }, readsResources = { "screen" }, writes = { "position" }, run = function(context)
        local screen = context.world:requireResource("screen")
        for _, position, size in context.world:query({ all = { "position", "size", "paddle" } }):each() do
            position.x = math.max(0, math.min(screen.w - size.w, position.x))
        end
    end })
    scheduler:addSystem({ name = "ballWallBounce", stage = "fixedUpdate", after = { "horizontalClamp" }, readsResources = { "screen" }, writes = { "position", "velocity" }, run = function(context)
        local screen = context.world:requireResource("screen")
        for _, position, size, velocity in context.world:query({ all = { "position", "size", "velocity", "ball" } }):each() do
            if position.x < 0 then position.x = 0; velocity.vx = math.abs(velocity.vx)
            elseif position.x + size.w > screen.w then position.x = screen.w - size.w; velocity.vx = -math.abs(velocity.vx) end
            if position.y < 0 then position.y = 0; velocity.vy = math.abs(velocity.vy) end
        end
    end })
    scheduler:addSystem({ name = "paddleHits", stage = "fixedUpdate", after = { "ballWallBounce" }, writes = { "position", "velocity" }, run = function(context)
        for _, ballPosition, ballSize, ballVelocity in context.world:query({ all = { "position", "size", "velocity", "ball" } }):each() do
            if ballVelocity.vy > 0 then
                for _, paddlePosition, paddleSize in context.world:query({ all = { "position", "size", "paddle" } }):each() do
                    if overlaps({ x = ballPosition.x, y = ballPosition.y, w = ballSize.w, h = ballSize.h }, { x = paddlePosition.x, y = paddlePosition.y, w = paddleSize.w, h = paddleSize.h }) then
                        ballPosition.y, ballVelocity.vy = paddlePosition.y - ballSize.h, -math.abs(ballVelocity.vy)
                        local offset = math.max(-1, math.min(1, ((ballPosition.x + ballSize.w / 2) - (paddlePosition.x + paddleSize.w / 2)) / (paddleSize.w / 2)))
                        ballVelocity.vx = math.max(-MAX_HORIZONTAL_SPEED, math.min(MAX_HORIZONTAL_SPEED, ballVelocity.vx + offset * PADDLE_ENGLISH))
                    end
                end
            end
        end
    end })
    scheduler:addSystem({ name = "brickCollision", stage = "fixedUpdate", after = { "paddleHits" }, writes = { "position", "velocity" }, writesResources = { "match" }, run = function(context)
        local world, match = context.world, context.world:requireResource("match")
        if match.status ~= "playing" then return end
        for _, ballPosition, ballSize, ballVelocity in world:query({ all = { "position", "size", "velocity", "ball" } }):each() do
            local hit, hitPosition, hitSize = nil, nil, nil
            for brick, brickPosition, brickSize in world:query({ all = { "position", "size", "brick" } }):each() do
                if not hit and overlaps({ x = ballPosition.x, y = ballPosition.y, w = ballSize.w, h = ballSize.h }, { x = brickPosition.x, y = brickPosition.y, w = brickSize.w, h = brickSize.h }) then
                    hit, hitPosition, hitSize = brick, brickPosition, brickSize
                end
            end
            if hit then
                resolveBrick(ballPosition, ballSize, ballVelocity, hitPosition, hitSize)
                context.commands:destroy(hit)
                match.remainingBricks = math.max(0, match.remainingBricks - 1)
            end
        end
    end })
    scheduler:addSystem({ name = "ballLoss", stage = "fixedUpdate", after = { "brickCollision" }, readsResources = { "screen" }, writesResources = { "match" }, run = function(context)
        local world, match = context.world, context.world:requireResource("match")
        if match.status ~= "playing" then return end
        local screen = world:requireResource("screen")
        local lost = false
        for _, position, size in world:query({ all = { "position", "size", "ball" } }):each() do
            if position.y + size.h >= screen.h then lost = true end
        end
        if lost then
            match.status = "lost"
            context.emit("roundLost", { result = "lost" })
            context.emit("sceneRequest", { to = "gameover", payload = { result = "lost" } })
        end
    end })
    scheduler:addSystem({ name = "winCheck", stage = "fixedUpdate", after = { "ballLoss" }, writesResources = { "match" }, run = function(context)
        local match = context.world:requireResource("match")
        if match.status == "playing" and match.remainingBricks == 0 then
            match.status = "won"
            context.emit("roundWon", { result = "won" })
            context.emit("sceneRequest", { to = "gameover", payload = { result = "won" } })
        end
    end })
end

GameplaySystems.constants = { rows = ROWS, columns = COLUMNS, brickCount = ROWS * COLUMNS }
return GameplaySystems
