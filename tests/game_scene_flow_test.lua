local SceneManager = require("src.engine.scene.SceneManager")
local MenuScene = require("src.game.scenes.MenuScene")
local PlayScene = require("src.game.scenes.PlayScene")
local GameOverScene = require("src.game.scenes.GameOverScene")

local function sendKey(manager, key)
    local world = manager:current():world()
    world:emit("keyPressed", { key = key })
    manager:preUpdate(0)
    manager:fixedUpdate(0)
end

local function ball(world)
    local result = nil
    for entity, position, size in world:query({ all = { "position", "size", "ball" } }):each() do
        result = { entity = entity, position = position, size = size }
    end
    return result
end

return function()
    local manager = SceneManager.new()
    manager:register("menu", MenuScene)
    manager:register("play", PlayScene)
    manager:register("gameover", GameOverScene)
    manager:start("menu")
    manager:draw(0)
    sendKey(manager, "space")
    assert(manager:current():name() == "play")
    local world = manager:current():world()
    assert(world:requireResource("match").remainingBricks == 50)
    manager:draw(0)

    local activeBall = ball(world)
    activeBall.position.y = world:requireResource("screen").h - activeBall.size.h
    manager:fixedUpdate(0)
    assert(manager:current():name() == "gameover")
    assert(manager:current():world():requireResource("match").status == "lost")
    manager:draw(0)

    sendKey(manager, "space")
    assert(manager:current():name() == "menu")
    manager:quit()
end
