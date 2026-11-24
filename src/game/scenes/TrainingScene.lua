local Scene = require("src.engine.scene.Scene")
local Screen = require("src.game.Screen")
local GameSession = require("src.game.session.GameSession")
local Definitions = require("src.game.progression.Definitions")
local TrainingActivitySystem = require("src.game.progression.TrainingActivitySystem")
local TrainingFeedbackSystem = require("src.game.progression.TrainingFeedbackSystem")
local TrainingTransitionSystem = require("src.game.progression.TrainingTransitionSystem")
local MapEntrySystem = require("src.game.maps.MapEntrySystem")
local TrainingUiSetupSystem = require("src.game.ui.TrainingUiSetupSystem")
local TrainingUiUpdateSystem = require("src.game.ui.TrainingUiUpdateSystem")
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
    TrainingUiSetupSystem.install(scene:scheduler())
    TrainingUiUpdateSystem.install(scene:scheduler())
    TrainingActivitySystem.install(scene:scheduler())
    TrainingFeedbackSystem.install(scene:scheduler())
    TrainingTransitionSystem.install(scene:scheduler())
    MapEntrySystem.install(scene:scheduler())
    TrainingRenderSystem.install(scene:scheduler())
    return scene
end
