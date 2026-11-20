-- Resolves a downward-moving ball against the top of the horizontal paddle.
-- The ball is pushed out before it is reflected, avoiding repeated overlaps.
local PaddleHitsSystem = { name = "paddleHits" }

local PADDLE_ENGLISH = 140
local MAX_HORIZONTAL_SPEED = 360

local function aabb(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and bx < ax + aw
        and ay < by + bh and by < ay + ah
end

function PaddleHitsSystem.update(scene, dt)
    local registry = scene.registry

    for _, ballPosition, ballSize, ballVelocity in registry:each(
        "position", "size", "velocity", "ball"
    ) do
        if ballVelocity.vy > 0 then
            for _, paddlePosition, paddleSize in registry:each(
                "position", "size", "paddle"
            ) do
                if aabb(
                    ballPosition.x, ballPosition.y, ballSize.w, ballSize.h,
                    paddlePosition.x, paddlePosition.y, paddleSize.w, paddleSize.h
                ) then
                    ballPosition.y = paddlePosition.y - ballSize.h
                    ballVelocity.vy = -math.abs(ballVelocity.vy)

                    local ballCenter = ballPosition.x + ballSize.w / 2
                    local paddleCenter = paddlePosition.x + paddleSize.w / 2
                    local offset = (ballCenter - paddleCenter) / (paddleSize.w / 2)
                    offset = math.max(-1, math.min(1, offset))
                    ballVelocity.vx = math.max(
                        -MAX_HORIZONTAL_SPEED,
                        math.min(
                            MAX_HORIZONTAL_SPEED,
                            ballVelocity.vx + offset * PADDLE_ENGLISH
                        )
                    )

                    break
                end
            end
        end
    end
end

return PaddleHitsSystem
