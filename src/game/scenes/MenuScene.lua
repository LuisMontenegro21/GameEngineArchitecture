local Scene = require("src.engine.scene.Scene")
local Screen = require("src.game.Screen")
local registerBreakout = require("src.game.ecs.register")
local RenderSystems = require("src.game.ecs.RenderSystems")

return function()
    local scene = Scene.new({ name = "menu" })
    local world = scene:world()
    registerBreakout(world)
    world:setResource("screen", { w = Screen.w, h = Screen.h })
    world:setResource("input", {})
    world:setResource("match", { status = "playing", remainingBricks = 0 })
    scene:addSystem({ name = "menuInput", stage = "fixedUpdate", run = function(context)
        for event in context.world:events("keyPressed") do
            if event.payload.key == "space" then context.emit("sceneRequest", { to = "play" }) end
        end
    end })
    RenderSystems.installMenu(scene:scheduler())
    return scene
end
