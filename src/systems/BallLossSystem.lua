-- Turns a bottom-edge crossing into a terminal loss. The status guard makes
-- this safe even if a scene switch is delayed by another engine feature.
local Screen = require("src.Screen")

local BallLossSystem = { name = "ballLoss" }

function BallLossSystem.update(scene, dt)
    local registry = scene.registry
    local breakout = registry:resource("breakout")

    if not breakout or breakout.status ~= "playing" then
        return
    end

    for _, position, size in registry:each("position", "size", "ball") do
        if position.y + size.h >= Screen.h then
            breakout.status = "lost"
            registry:spawn({
                switchRequest = {
                    to = "gameover",
                    payload = { result = "lost" },
                },
            })
            return
        end
    end
end

return BallLossSystem
