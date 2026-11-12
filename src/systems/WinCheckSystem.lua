-- Completes the round when every brick has been removed. BrickCollisionSystem
-- owns the counter; this system only decides the terminal scene transition.
local WinCheckSystem = { name = "winCheck" }

function WinCheckSystem.update(scene, dt)
    local registry = scene.registry
    local breakout = registry:resource("breakout")

    if not breakout or breakout.status ~= "playing" then
        return
    end

    if breakout.remainingBricks == 0 then
        breakout.status = "won"
        registry:spawn({
            switchRequest = {
                to = "gameover",
                payload = { result = "won" },
            },
        })
    end
end

return WinCheckSystem
