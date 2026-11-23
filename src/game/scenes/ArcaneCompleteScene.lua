local Scene = require("src.engine.scene.Scene")
local Screen = require("src.game.Screen")
local EncounterDefinitions = require("src.game.encounters.EncounterDefinitions")
local GameSession = require("src.game.session.GameSession")
local Definitions = require("src.game.progression.Definitions")
local UiTheme = require("src.game.ui.UiTheme")

return function(payload)
    payload = payload or {}
    local session = assert(payload.session, "ArcaneCompleteScene requires a session")
    assert(GameSession.validate(session) and session.complete,
        "ArcaneCompleteScene requires a completed game session")
    local scene = Scene.new({ name = "arcaneComplete" })
    local world = scene:world()
    Definitions.registerArcaneHearts(world)
    world:setResource("gameSession", session)
    scene:addSystem({
        name = "arcaneCompleteRender",
        stage = "render",
        readsResources = { "gameSession" },
        run = function(context)
            local g = love and love.graphics or nil
            if not g then return end
            local run = context.world:requireResource("gameSession")
            local ending = EncounterDefinitions.endingForRapport(run.finalRapport)
            g.clear(UiTheme.colors.background.r, UiTheme.colors.background.g,
                UiTheme.colors.background.b, UiTheme.colors.background.a)
            UiTheme.setColor(g, UiTheme.colors.title)
            g.printf("ACADEMY TERM COMPLETE", 0, 94, Screen.w, "center")
            UiTheme.drawPanel(g, 150, 142, 660, 228, true)
            UiTheme.setColor(g, UiTheme.colors.positive)
            g.printf(ending.title, 180, 174, 600, "center")
            UiTheme.setColor(g, UiTheme.colors.text)
            g.printf(ending.text, 200, 218, 560, "center")
            UiTheme.setColor(g, UiTheme.colors.heading)
            g.printf(("Final Rapport: %d"):format(run.finalRapport),
                0, 276, Screen.w, "center")
            UiTheme.setColor(g, UiTheme.colors.text)
            g.printf(("Conversation cards collected: %d"):format(#run.collection),
                0, 310, Screen.w, "center")
        end,
    })
    return scene
end
