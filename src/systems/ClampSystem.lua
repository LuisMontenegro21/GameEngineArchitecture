-- Keeps horizontal paddle entities inside the logical game screen. It runs
-- after MovementSystem so it resolves the position produced this frame.
local Screen = require("src.Screen")

local ClampSystem = { name = "horizontalClamp" }

function ClampSystem.update(scene, dt)
    local registry = scene.registry

    for _, position, size in registry:each("position", "size", "clampHorizontal") do
        position.x = math.max(0, math.min(Screen.w - size.w, position.x))
    end
end

return ClampSystem
