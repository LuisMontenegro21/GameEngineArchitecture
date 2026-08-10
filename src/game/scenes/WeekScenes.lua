local Scene = require("src.engine.ecs.Scene")

local MenuSetupSystem = require("src.game.systems.MenySetupSystem")
local MenuRenderSystem = require("src.game.systems.MenuRenderSystem")
local MenuInputSystem = require("src.game.systems.MenuInputSystem")

return function (payload)
    local scene = Scene.new("week")
    scene:addSystem(MenuSetupSystem)
    scene:addSystem(MenuInputSystem)
    scene:addSystem(MenuRenderSystem)
    return scene
end