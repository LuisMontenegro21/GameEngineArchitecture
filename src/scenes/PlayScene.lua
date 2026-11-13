-- The Breakout board. Movement is followed by boundary resolution: balls
-- bounce from the left/right/top, while the bottom edge ends the round.
local Scene = require("src.ecs.Scene")
local BreakoutSetupSystem = require("src.systems.BreakoutSetupSystem")
local PaddleControlSystem = require("src.systems.PaddleControlSystem")
local MovementSystem = require("src.systems.MovementSystem")
local ClampSystem = require("src.systems.ClampSystem")
local BallWallBounceSystem = require("src.systems.BallWallBounceSystem")
local PaddleHitsSystem = require("src.systems.PaddleHitsSystem")
local BrickCollisionSystem = require("src.systems.BrickCollisionSystem")
local BallLossSystem = require("src.systems.BallLossSystem")
local WinCheckSystem = require("src.systems.WinCheckSystem")
local ShapeRenderSystem = require("src.systems.ShapeRenderSystem")
local BrickRenderSystem = require("src.systems.BrickRenderSystem")
local HudRenderSystem = require("src.systems.HudRenderSystem")

return function(payload)
    local scene = Scene.new("play")

    scene:addSystem(BreakoutSetupSystem)
    scene:addSystem(PaddleControlSystem)
    scene:addSystem(MovementSystem)
    scene:addSystem(ClampSystem)
    scene:addSystem(BallWallBounceSystem)
    scene:addSystem(PaddleHitsSystem)
    scene:addSystem(BrickCollisionSystem)
    scene:addSystem(BallLossSystem)
    scene:addSystem(WinCheckSystem)
    scene:addSystem(ShapeRenderSystem)
    scene:addSystem(BrickRenderSystem)
    scene:addSystem(HudRenderSystem)

    return scene
end
