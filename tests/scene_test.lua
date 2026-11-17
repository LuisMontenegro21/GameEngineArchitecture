local Assert = require("tests.support.assert")
local Scene = require("src.engine.scene.Scene")
local SceneManager = require("src.engine.scene.SceneManager")

return function()
    local manager = SceneManager.new()
    local order = {}
    local first = nil

    manager:register("first", function()
        local scene = Scene.new({ name = "first" })
        scene:addSystem({ name = "startup", stage = "startup", run = function()
            order[#order + 1] = "startup"
        end })
        scene:addSystem({ name = "fixed", stage = "fixedUpdate", run = function()
            order[#order + 1] = "fixed"
        end })
        scene:addSystem({ name = "switch", stage = "update", run = function()
            order[#order + 1] = "update"
            scene:requestTransition("second", { source = "first" })
        end })
        scene:addSystem({ name = "render", stage = "render", run = function()
            order[#order + 1] = "render"
        end })
        first = scene
        return scene
    end)
    manager:register("second", function(payload)
        Assert.equals("first", payload.source)
        local scene = Scene.new({ name = "second" })
        scene:addSystem({ name = "startup-second", stage = "startup", run = function()
            order[#order + 1] = "startup-second"
        end })
        return scene
    end)
    manager:register("broken", function()
        local scene = Scene.new({ name = "broken" })
        scene:addSystem({ name = "explode", stage = "startup", run = function()
            error("factory startup failed")
        end })
        return scene
    end)

    manager:start("first")
    Assert.truthy(first:isInitialized())
    manager:fixedUpdate(1 / 60)
    manager:draw(0.5)
    manager:update(1 / 60)
    Assert.equals("second", manager:current():name())
    Assert.truthy(first:isDisposed())
    Assert.equals("startup", order[1])
    Assert.equals("fixed", order[2])
    Assert.equals("render", order[3])
    Assert.equals("update", order[4])
    Assert.equals("startup-second", order[5])

    manager:requestTransition("broken")
    local ok = pcall(function() manager:update(0) end)
    Assert.falsy(ok)
    Assert.equals("second", manager:current():name())
    Assert.truthy(manager:quit())
    Assert.falsy(manager:quit())
end
