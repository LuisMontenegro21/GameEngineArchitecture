-- Reflects balls from the left, right, and top boundaries. The bottom edge
-- belongs to BallLossSystem and must never bounce a ball back into play.
local Screen = require("src.Screen")

local BallWallBounceSystem = { name = "ballWallBounce" }

function BallWallBounceSystem.update(scene, dt)
    local registry = scene.registry

    for _, position, size, velocity in registry:each(
        "position", "size", "velocity", "ball"
    ) do
        if position.x < 0 then
            position.x = 0
            velocity.vx = math.abs(velocity.vx)
        elseif position.x + size.w > Screen.w then
            position.x = Screen.w - size.w
            velocity.vx = -math.abs(velocity.vx)
        end

        if position.y < 0 then
            position.y = 0
            velocity.vy = math.abs(velocity.vy)
        end
    end
end

return BallWallBounceSystem
