local Scene = require("src.engine.scene.Scene")
local Screen = require("src.game.Screen")
local GameSession = require("src.game.session.GameSession")
local Definitions = require("src.game.progression.Definitions")

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
            g.clear(0.06, 0.04, 0.12, 1)
            g.setColor(0.9, 0.82, 1, 1)
            g.printf("Academy Term Complete", 0, 180, Screen.w, "center")
            g.setColor(1, 1, 1, 1)
            g.printf(("You collected %d conversation cards."):format(#run.collection),
                0, 230, Screen.w, "center")
        end,
    })
    return scene
end
