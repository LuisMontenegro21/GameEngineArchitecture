local Scene = require("src.engine.scene.Scene")
local SceneManager = require("src.engine.scene.SceneManager")

return function()
    local diagnostics, payload = 0, nil
    local manager = SceneManager.new({ diagnostic = function() diagnostics = diagnostics + 1 end })
    manager:register("first", function()
        local scene = Scene.new({ name = "first" })
        scene:world():registerEvent("sceneRequest")
        scene:addSystem({ name = "request", stage = "update", run = function(context)
            context.emit("sceneRequest", { to = "second", payload = { source = "event" } })
            context.emit("sceneRequest", { to = "second", payload = { source = "duplicate" } })
        end })
        return scene
    end)
    manager:register("second", function(nextPayload)
        payload = nextPayload
        return Scene.new({ name = "second" })
    end)
    manager:start("first")
    manager:update(0)
    assert(manager:current():name() == "second")
    assert(payload.source == "event")
    assert(diagnostics == 1)
    manager:quit()
end
