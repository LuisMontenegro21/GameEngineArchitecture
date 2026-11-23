local Game = require("src.game.Game")
local FixedStep = require("src.engine.loop.FixedStep")
local GameSession = require("src.game.session.GameSession")
local TrainingScene = require("src.game.scenes.TrainingScene")
local CardAcquisitionScene = require("src.game.scenes.CardAcquisitionScene")
local ArcaneCompleteScene = require("src.game.scenes.ArcaneCompleteScene")
local AcademyMapScene = require("src.game.scenes.AcademyMapScene")

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
    Game.registerScene("training", TrainingScene)
    Game.registerScene("cardAcquisition", CardAcquisitionScene)
    Game.registerScene("arcaneComplete", ArcaneCompleteScene)
    Game.registerScene("academyMap", AcademyMapScene)

    Game.start("training", { session = GameSession.new() })

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
