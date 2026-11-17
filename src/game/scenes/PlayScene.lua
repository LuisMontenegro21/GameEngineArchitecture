local Scene = require("src.engine.scene.Scene")
local Screen = require("src.game.Screen")
local registerBreakout = require("src.game.ecs.register")
local GameplaySystems = require("src.game.ecs.GameplaySystems")
local RenderSystems = require("src.game.ecs.RenderSystems")

return function()
    local scene = Scene.new({ name = "play" })
    local world = scene:world()
    registerBreakout(world)
    world:setResource("screen", { w = Screen.w, h = Screen.h })
    world:setResource("input", {})
    world:setResource("match", { status = "playing", remainingBricks = 0 })
    GameplaySystems.install(scene:scheduler())
    RenderSystems.installPlay(scene:scheduler())
    return scene
end
