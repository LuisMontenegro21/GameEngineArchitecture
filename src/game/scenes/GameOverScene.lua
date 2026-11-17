local Scene = require("src.engine.scene.Scene")
local Screen = require("src.game.Screen")
local registerBreakout = require("src.game.ecs.register")
local RenderSystems = require("src.game.ecs.RenderSystems")

return function(payload)
    local result = payload and payload.result == "won" and "won" or "lost"
    local scene = Scene.new({ name = "gameover" })
    local world = scene:world()
    registerBreakout(world)
    world:setResource("screen", { w = Screen.w, h = Screen.h })
    world:setResource("input", {})
    world:setResource("match", { status = result, remainingBricks = 0 })
    scene:addSystem({ name = "gameOverInput", stage = "fixedUpdate", run = function(context)
        for event in context.world:events("keyPressed") do
            if event.payload.key == "space" then context.emit("sceneRequest", { to = "menu" }) end
        end
    end })
    RenderSystems.installGameOver(scene:scheduler())

    return scene
end
