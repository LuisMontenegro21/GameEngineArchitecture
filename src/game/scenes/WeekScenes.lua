local Scene = require("src.engine.ecs.Scene")

local MenuSetupSystem = require("src.game.systems.MenySetupSystem")
local MenuRenderSystem = require("src.game.systems.MenuRenderSystem")
local MenuInputSystem = require("src.game.systems.MenuInputSystem")

local TextBoxSetupSystem = require("src.game.systems.TextBoxRenderSystem")
local TextboxRenderSystem = require("src.game.systems.TextBoxRenderSystem")

local RunStateSetupSystem = require("src.game.systems.RunStateSetupSystem")
local StatsUpdateSystem = require("src.game.systems.StatsUpdateSystem")

return function (payload)
    local scene = Scene.new("week")
    scene:addSystem(MenuSetupSystem)
    scene:addSystem(MenuInputSystem)
    scene:addSystem(MenuRenderSystem)
    return scene
end