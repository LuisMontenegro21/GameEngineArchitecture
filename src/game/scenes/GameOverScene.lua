local Scene = require("src.engine.legacy.Scene")
local GameOverSystem = require("src.game.systems.GameOverSystem")
local GameOverRenderSystem = require("src.game.systems.GameOverRenderSystem")

return function(payload)
    local scene = Scene.new("gameover")
    local result = payload and payload.result or "lost"

    if result ~= "won" then
        result = "lost"
    end

    scene.registry:setResource("result", result)
    scene:addSystem(GameOverSystem)
    scene:addSystem(GameOverRenderSystem)

    return scene
end
