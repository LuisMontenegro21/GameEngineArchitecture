local Game = require("src.game.Game")
local FixedStep = require("src.engine.loop.FixedStep")
local MenuScene = require("src.game.scenes.MenuScene")
local PlayScene = require("src.game.scenes.PlayScene")
local GameOverScene = require("src.game.scenes.GameOverScene")

local PHYSICS_STEP = 1 / 120
local MAXIMUM_FRAME_DELTA = 0.25
local physics = FixedStep.new(PHYSICS_STEP, MAXIMUM_FRAME_DELTA)

local function hasGameArgument(wanted)
    for _, value in ipairs(arg or {}) do
        if value == wanted then return true end
    end
    return false
end

function love.load()
    Game.registerScene("menu", MenuScene)
    Game.registerScene("play", PlayScene)
    Game.registerScene("gameover", GameOverScene)

    Game.start("menu")

    if hasGameArgument("--debug") then
        require("src.debug.attach")(Game)
        require("src.debug.DebugOverlay").enterEditor()
    end
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

function love.keyreleased(key)
    Game.keyreleased(key)
end

function love.quit()
    Game.quit()
end
