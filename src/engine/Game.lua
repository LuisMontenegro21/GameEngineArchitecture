local Registry = require("src.engine.ecs.Registry")
local Scene = require("src.engine.ecs.Scene")

local Game = {}

local factories = {}
local currentScene = nil
local pendingScene = nil
local isUpdating = false

local function createScene(name, payload)
    local factory = factories[name]
    assert(factory, ("no scene registered with the name '%s'"):format(name))

    local scene = factory(payload)
    assert(getmetatable(scene) == Scene, "scene factories must return Scene.new(...)")
    assert(type(scene.setup) == "function", "scenes must implement setup")
    assert(type(scene.update) == "function", "scenes must implement update")
    assert(type(scene.draw) == "function", "scenes must implement draw")
    assert(type(scene.unload) == "function", "scenes must implement unload")
    assert(getmetatable(scene.registry) == Registry, "scenes must own a Registry.new() instance")
    assert(type(scene.registry.query) == "function", "scene registries must implement query")
    assert(type(scene.registry.destroyLater) == "function", "scene registries must implement destroyLater")
    assert(type(scene.registry.flushDestroyed) == "function", "scene registries must implement flushDestroyed")

    return scene
end

-- Event entities are single-frame messages. Scene systems can read events
-- during their update; Game removes them only after every system has run.
local function clearEvents(scene)
    for _, entity in ipairs(scene.registry:query("event")) do
        scene.registry:destroyLater(entity)
    end

    scene.registry:flushDestroyed()
end

local function performSwitch(name, payload)
    local nextScene = createScene(name, payload)

    if currentScene then
        currentScene:unload()
    end

    currentScene = nextScene
    currentScene:setup()
end

function Game.registerScene(name, factory)
    assert(type(name) == "string", "scene names must be strings")
    assert(type(factory) == "function", "scene factories must be functions")

    factories[name] = factory
end

function Game.start(name, payload)
    assert(not currentScene, "the game has already started")
    performSwitch(name, payload)
end

-- Calls made during an update are applied after all systems have completed.
-- This prevents unloading a scene while one of its systems is still running.
function Game.switchScene(name, payload)
    assert(type(name) == "string", "scene names must be strings")

    if isUpdating then
        pendingScene = { name = name, payload = payload }
        return
    end

    performSwitch(name, payload)
end

function Game.currentScene()
    return currentScene
end

function Game.update(dt)
    assert(type(dt) == "number", "dt must be a number")

    if not currentScene then
        return
    end

    isUpdating = true
    currentScene:update(dt)
    isUpdating = false

    clearEvents(currentScene)

    if pendingScene then
        local nextScene = pendingScene
        pendingScene = nil
        performSwitch(nextScene.name, nextScene.payload)
    end
end

function Game.draw()
    if currentScene then
        currentScene:draw()
    end
end

function Game.quit()
    pendingScene = nil

    if currentScene then
        currentScene:unload()
        currentScene = nil
    end
end

return Game

