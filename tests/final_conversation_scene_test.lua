local CardCatalog = require("src.game.cards.CardCatalog")
local FinalConversationScene = require("src.game.scenes.FinalConversationScene")
local GameSession = require("src.game.session.GameSession")

local function systemNames(scene, stage)
    local names = {}
    for _, system in ipairs(scene:scheduler():systemsFor(stage)) do
        names[#names + 1] = system.name
    end
    return table.concat(names, ",")
end

return function()
    local session = GameSession.new()
    session.collection = { CardCatalog.forCategory("knowledge")[1] }
    local scene = FinalConversationScene({ session = session })
    scene:initialize()
    local world = scene:world()

    assert(scene:name() == "finalConversation")
    assert(world:requireResource("gameSession") == session,
        "the final encounter must receive the shared session object")
    assert(systemNames(scene, "startup") == "encounterSetup,cardUseUiSetup")
    assert(systemNames(scene, "fixedUpdate") == "cardUseUiUpdate")
    assert(systemNames(scene, "postFixedUpdate") == "encounterResolution")
    assert(systemNames(scene, "update") == "encounterProgression")
    assert(systemNames(scene, "render") == "encounterRender")
    assert(world:requireResource("encounterState").promptIndex == 1)
    assert(world:requireResource("encounterCollectionSelection") == 1)
    assert(not session.complete and session.endingId == nil,
        "scene setup must not complete the run before cards are played")
    scene:draw(0)
    assert(world:validate(), "the pre-UI final conversation scene must remain valid headlessly")
    scene:dispose()
end
