-- The Breakout board. Movement is followed by boundary resolution: balls
-- bounce from the left/right/top, while the bottom edge ends the round.
local Scene = require("src.engine.legacy.Scene")
local BreakoutSetupSystem = require("src.game.systems.BreakoutSetupSystem")
local PaddleControlSystem = require("src.game.systems.PaddleControlSystem")
local MovementSystem = require("src.game.systems.MovementSystem")
local ClampSystem = require("src.game.systems.ClampSystem")
local BallWallBounceSystem = require("src.game.systems.BallWallBounceSystem")
local PaddleHitsSystem = require("src.game.systems.PaddleHitsSystem")
local BrickCollisionSystem = require("src.game.systems.BrickCollisionSystem")
local BallLossSystem = require("src.game.systems.BallLossSystem")
local WinCheckSystem = require("src.game.systems.WinCheckSystem")
local ShapeRenderSystem = require("src.game.systems.ShapeRenderSystem")
local BrickRenderSystem = require("src.game.systems.BrickRenderSystem")
local HudRenderSystem = require("src.game.systems.HudRenderSystem")

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
