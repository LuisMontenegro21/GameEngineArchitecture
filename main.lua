local Game = require("src.game.Game")
local FixedStep = require("src.engine.loop.FixedStep")
local MenuScene = require("src.game.scenes.MenuScene")
local PlayScene = require("src.game.scenes.PlayScene")
local GameOverScene = require("src.game.scenes.GameOverScene")

local PHYSICS_STEP = 1 / 120
local MAXIMUM_FRAME_DELTA = 0.25
local physics = FixedStep.new(PHYSICS_STEP, MAXIMUM_FRAME_DELTA)

function love.load()
    Game.registerScene("menu", MenuScene)
    Game.registerScene("play", PlayScene)
    Game.registerScene("gameover", GameOverScene)

    Game.start("menu")
end

function love.update(dt)
    physics:advance(dt, Game.update)
end

function love.draw()
    Game.draw()
end

function love.keypressed(key)
    Game.keypressed(key)
end

function love.quit()
    Game.quit()
end
