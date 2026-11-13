-- Integrates velocity into position for active movers. The `moves` tag lets a
-- scene create an entity with velocity data before it is ready to simulate.
-- Phase 4 activates the paddle; Phase 5 will activate the ball.

local MovementSystem = { name = "movement" }

function MovementSystem.update(scene, dt)
    local registry = scene.registry

    for _, pos, vel in registry:each("position", "velocity", "moves") do
        pos.x = pos.x + vel.vx * dt
        pos.y = pos.y + vel.vy * dt
    end
end

return MovementSystem
