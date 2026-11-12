-- Translates keyboard state into horizontal paddle velocity. Position changes
-- remain the responsibility of MovementSystem.
local PaddleControlSystem = { name = "paddleControl" }

function PaddleControlSystem.update(scene, dt)
    local registry = scene.registry

    for _, paddle, velocity in registry:each("paddle", "velocity") do
        local direction = 0

        if love.keyboard.isDown(paddle.leftKey)
            or (paddle.altLeftKey and love.keyboard.isDown(paddle.altLeftKey)) then
            direction = direction - 1
        end

        if love.keyboard.isDown(paddle.rightKey)
            or (paddle.altRightKey and love.keyboard.isDown(paddle.altRightKey)) then
            direction = direction + 1
        end

        velocity.vx = direction * paddle.speed
        velocity.vy = 0
    end
end

return PaddleControlSystem
