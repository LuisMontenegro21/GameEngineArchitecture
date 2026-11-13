-- Resolves at most one brick hit per ball per physics step. Resolving only
-- one prevents adjacent-brick impacts from reversing velocity twice.
local BrickCollisionSystem = { name = "brickCollision" }

local function aabb(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and bx < ax + aw
        and ay < by + bh and by < ay + ah
end

local function resolveCollision(ballPosition, ballSize, ballVelocity, brickPosition, brickSize)
    local overlapLeft = ballPosition.x + ballSize.w - brickPosition.x
    local overlapRight = brickPosition.x + brickSize.w - ballPosition.x
    local overlapTop = ballPosition.y + ballSize.h - brickPosition.y
    local overlapBottom = brickPosition.y + brickSize.h - ballPosition.y

    local horizontalPenetration = math.min(overlapLeft, overlapRight)
    local verticalPenetration = math.min(overlapTop, overlapBottom)

    if horizontalPenetration < verticalPenetration then
        if ballPosition.x + ballSize.w / 2 < brickPosition.x + brickSize.w / 2 then
            ballPosition.x = brickPosition.x - ballSize.w
            ballVelocity.vx = -math.abs(ballVelocity.vx)
        else
            ballPosition.x = brickPosition.x + brickSize.w
            ballVelocity.vx = math.abs(ballVelocity.vx)
        end
    else
        if ballPosition.y + ballSize.h / 2 < brickPosition.y + brickSize.h / 2 then
            ballPosition.y = brickPosition.y - ballSize.h
            ballVelocity.vy = -math.abs(ballVelocity.vy)
        else
            ballPosition.y = brickPosition.y + brickSize.h
            ballVelocity.vy = math.abs(ballVelocity.vy)
        end
    end
end

function BrickCollisionSystem.update(scene, dt)
    local registry = scene.registry
    local breakout = registry:resource("breakout")

    if not breakout or breakout.status ~= "playing" then
        return
    end

    for _, ballPosition, ballSize, ballVelocity in registry:each(
        "position", "size", "velocity", "ball"
    ) do
        for brickEntity, brickPosition, brickSize in registry:each(
            "position", "size", "brick"
        ) do
            if aabb(
                ballPosition.x, ballPosition.y, ballSize.w, ballSize.h,
                brickPosition.x, brickPosition.y, brickSize.w, brickSize.h
            ) then
                resolveCollision(
                    ballPosition, ballSize, ballVelocity, brickPosition, brickSize
                )
                registry:destroy(brickEntity)
                breakout.remainingBricks = math.max(0, breakout.remainingBricks - 1)
                break
            end
        end
    end
end

return BrickCollisionSystem
