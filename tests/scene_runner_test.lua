local Scene = require("src.engine.scene.Scene")
local SceneManager = require("src.engine.scene.SceneManager")
local LoveRunner = require("src.engine.loop.LoveRunner")

return function()
    local manager = SceneManager.new()
    local fixedRuns, received, secondUpdates = 0, 0, 0

    manager:register("first", function()
        local scene = Scene.new({ name = "first" })
        scene:world():registerEvent("keyPressed")
        scene:addSystem({ name = "pre", stage = "preUpdate", run = function() end })
        scene:addSystem({ name = "fixed", stage = "fixedUpdate", run = function(context)
            fixedRuns = fixedRuns + 1
            for event in context.world:events("keyPressed") do
                if event.payload.key == "space" then received = received + 1 end
            end
            scene:requestTransition("second")
        end })
        return scene
    end)
    manager:register("second", function()
        local scene = Scene.new({ name = "second" })
        scene:addSystem({ name = "updated", stage = "update", run = function()
            secondUpdates = secondUpdates + 1
        end })
        return scene
    end)
    manager:start("first")
    local runner = LoveRunner.new({ sceneManager = manager, fixedDelta = 1 / 60 })
    runner:load()
    runner:keypressed("space")
    runner:update(3 / 60)
    assert(received == 1)
    assert(fixedRuns == 1)
    assert(manager:current():name() == "second")
    assert(secondUpdates == 1)
    runner:quit()
end
