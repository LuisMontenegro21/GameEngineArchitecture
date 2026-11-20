local Scene = require("src.engine.scene.Scene")
local Screen = require("src.game.Screen")
local GameSession = require("src.game.session.GameSession")
local Definitions = require("src.game.progression.Definitions")
local TrainingSystems = require("src.game.progression.Systems")
local TrainingRenderSystem = require("src.game.ui.TrainingRenderSystem")

-- Factory payload is `{ session = GameSession }`; a fresh session also makes
-- this scene directly runnable during development and headless tests.
return function(payload)
    payload = payload or {}
    local session = payload.session or GameSession.new()
    assert(GameSession.validate(session), "TrainingScene requires a valid game session")

    local scene = Scene.new({ name = "training" })
    local world = scene:world()
    Definitions.registerArcaneHearts(world)
    world:setResource("gameSession", session)
    world:setResource("trainingSelection", 1)
    world:setResource("trainingTransitionQueued", false)
    TrainingSystems.installArcaneTraining(scene:scheduler())
    TrainingRenderSystem.install(scene:scheduler())
    return scene
end
