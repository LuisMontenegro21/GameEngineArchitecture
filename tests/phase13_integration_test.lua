local SceneManager = require("src.engine.scene.SceneManager")
local LoveRunner = require("src.engine.loop.LoveRunner")
local MenuScene = require("src.game.scenes.MenuScene")
local PlayScene = require("src.game.scenes.PlayScene")
local GameOverScene = require("src.game.scenes.GameOverScene")

local function managerAt(name)
    local manager = SceneManager.new()
    manager:register("menu", MenuScene)
    manager:register("play", PlayScene)
    manager:register("gameover", GameOverScene)
    manager:start(name)
    return manager
end

local function sendKey(manager, key)
    manager:current():world():emit("keyPressed", { key = key })
    manager:preUpdate(0)
    manager:fixedUpdate(0)
end

local function firstBall(world)
    local result = nil
    for entity, position, size, velocity in world:query({ all = { "position", "size", "velocity", "ball" } }):each() do
        result = { entity = entity, position = position, size = size, velocity = velocity }
    end
    return result
end

local function runAtRate(rate)
    local manager = managerAt("play")
    local runner = LoveRunner.new({ sceneManager = manager, fixedDelta = 1 / 60 })
    runner:load()
    runner:setPaused(true)
    local before = firstBall(manager:current():world()).position.y
    runner:update(1 / rate)
    runner:draw()
    assert(firstBall(manager:current():world()).position.y == before)
    runner:setPaused(false)
    for _ = 1, rate do runner:update(1 / rate) end
    local ball = firstBall(manager:current():world())
    local state = { x = ball.position.x, y = ball.position.y, vx = ball.velocity.vx, vy = ball.velocity.vy,
        status = manager:current():world():requireResource("match").status }
    runner:quit()
    return state
end

return function()
    -- Complete application flow plus restart/re-entry with isolated Worlds.
    local manager = managerAt("menu")
    sendKey(manager, "space")
    assert(manager:current():name() == "play")
    local firstPlayWorld = manager:current():world()
    assert(firstPlayWorld:requireResource("match").remainingBricks == 50)

    local ball = firstBall(firstPlayWorld)
    ball.position.y = firstPlayWorld:requireResource("screen").h - ball.size.h
    manager:fixedUpdate(0)
    assert(manager:current():name() == "gameover")
    assert(manager:current():world():requireResource("match").status == "lost")
    sendKey(manager, "space")
    assert(manager:current():name() == "menu")
    sendKey(manager, "space")
    assert(manager:current():name() == "play")
    local secondPlayWorld = manager:current():world()
    assert(secondPlayWorld ~= firstPlayWorld)
    assert(secondPlayWorld:requireResource("match").remainingBricks == 50)

    secondPlayWorld:requireResource("match").remainingBricks = 0
    manager:fixedUpdate(0)
    assert(manager:current():name() == "gameover")
    assert(manager:current():world():requireResource("match").status == "won")
    assert(manager:quit())

    local at30, at60, at144 = runAtRate(30), runAtRate(60), runAtRate(144)
    for _, state in ipairs({ at60, at144 }) do
        assert(math.abs(state.x - at30.x) < 0.001)
        assert(math.abs(state.y - at30.y) < 0.001)
        assert(state.vx == at30.vx and state.vy == at30.vy and state.status == at30.status)
    end
end
