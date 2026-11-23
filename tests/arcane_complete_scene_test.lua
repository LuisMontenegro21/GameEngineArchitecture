local ArcaneCompleteScene = require("src.game.scenes.ArcaneCompleteScene")
local GameSession = require("src.game.session.GameSession")

return function()
    local session = GameSession.new({
        finalRapport = 12,
        endingId = "arcane_hearts",
    })
    session.complete = true
    local scene = ArcaneCompleteScene({ session = session })
    scene:initialize()
    assert(scene:name() == "arcaneComplete")
    assert(scene:world():requireResource("gameSession") == session)
    assert(scene:scheduler():systemsFor("render")[1].name == "arcaneCompleteRender",
        "the result scene must install its ending renderer")
    scene:draw(0)
    assert(scene:world():validate(), "ending rendering must remain headless-safe and read-only")
    scene:dispose()
end
