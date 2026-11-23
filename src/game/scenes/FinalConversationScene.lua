-- Composes the authoritative final encounter. Card-use input and rendering are
-- added separately by Phase U6, so this factory owns only scene wiring.
local Scene = require("src.engine.scene.Scene")
local EncounterProgressionSystem = require("src.game.encounters.EncounterProgressionSystem")
local EncounterResolutionSystem = require("src.game.encounters.EncounterResolutionSystem")
local EncounterSetupSystem = require("src.game.encounters.EncounterSetupSystem")
local Definitions = require("src.game.progression.Definitions")
local GameSession = require("src.game.session.GameSession")
local CardUseUiSetupSystem = require("src.game.ui.CardUseUiSetupSystem")
local CardUseUiUpdateSystem = require("src.game.ui.CardUseUiUpdateSystem")
local EncounterRenderSystem = require("src.game.ui.EncounterRenderSystem")

return function(payload)
    payload = payload or {}
    local session = assert(payload.session, "FinalConversationScene requires a session")
    assert(GameSession.validate(session), "FinalConversationScene requires a valid game session")

    local scene = Scene.new({ name = "finalConversation" })
    local world = scene:world()
    Definitions.registerArcaneHearts(world)
    world:setResource("gameSession", session)
    EncounterSetupSystem.install(scene:scheduler())
    CardUseUiSetupSystem.install(scene:scheduler())
    CardUseUiUpdateSystem.install(scene:scheduler())
    EncounterResolutionSystem.install(scene:scheduler())
    EncounterProgressionSystem.install(scene:scheduler())
    EncounterRenderSystem.install(scene:scheduler())
    return scene
end
