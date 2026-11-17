-- ECS-backed application scene. Scenes compose a World, Scheduler, and Runtime
-- without adding scene policy to the ECS core.
local ECS = require("src.engine.ecs")

local Scene = {}
Scene.__index = Scene

local states = setmetatable({}, { __mode = "k" })

local function stateOf(scene)
    local state = states[scene]
    assert(state ~= nil, "invalid Scene")
    return state
end

local function ensureOpen(scene, operation)
    local state = stateOf(scene)
    assert(not state.disposed, "cannot " .. operation .. " on disposed scene")
    return state
end

function Scene.new(options)
    options = options or {}
    assert(type(options) == "table", "scene options must be a table")
    assert(type(options.name) == "string" and options.name ~= "",
        "scene name must be a non-empty string")

    local world = options.world or ECS.World.new({ identity = "scene:" .. options.name })
    local scheduler = options.scheduler or ECS.Scheduler.new()
    local runtime = options.runtime or ECS.Runtime.new({
        world = world,
        scheduler = scheduler,
        ownsWorld = true,
        clock = options.clock,
    })

    assert(runtime:world() == world, "scene runtime must own the supplied world")
    assert(runtime:scheduler() == scheduler,
        "scene runtime must own the supplied scheduler")

    local scene = setmetatable({}, Scene)
    states[scene] = {
        name = options.name,
        world = world,
        scheduler = scheduler,
        runtime = runtime,
        initialized = false,
        disposed = false,
        requestTransition = nil,
    }
    return scene
end

function Scene:name()
    return stateOf(self).name
end

function Scene:world()
    return stateOf(self).world
end

function Scene:scheduler()
    return stateOf(self).scheduler
end

function Scene:runtime()
    return stateOf(self).runtime
end

function Scene:addSystem(definition)
    local state = ensureOpen(self, "add a system")
    assert(not state.initialized, "cannot add systems after scene initialization")
    return state.runtime:addSystem(definition)
end

function Scene:setTransitionHandler(handler)
    local state = ensureOpen(self, "set transition handler")
    assert(handler == nil or type(handler) == "function",
        "transition handler must be a function or nil")
    state.requestTransition = handler
end

function Scene:requestTransition(name, payload)
    local state = ensureOpen(self, "request transition")
    assert(type(name) == "string" and name ~= "",
        "transition destination must be a non-empty string")
    assert(state.requestTransition ~= nil, "scene has no transition handler")
    return state.requestTransition(name, payload)
end

function Scene:initialize()
    local state = ensureOpen(self, "initialize")
    assert(not state.initialized, "scene is already initialized")
    if not state.runtime:isBuilt() then state.runtime:build() end
    state.runtime:initialize()
    state.runtime:runStage("startup", 0)
    state.initialized = true
    return true
end

function Scene:isInitialized()
    return stateOf(self).initialized
end

function Scene:fixedUpdate(dt)
    local state = ensureOpen(self, "run fixed update")
    assert(state.initialized, "scene must be initialized before updates")
    return state.runtime:runStage("fixedUpdate", dt)
end

local function runStage(scene, stage, dt)
    local state = ensureOpen(scene, "run " .. stage)
    assert(state.initialized, "scene must be initialized before updates")
    return state.runtime:runStage(stage, dt)
end

function Scene:preUpdate(dt)
    return runStage(self, "preUpdate", dt)
end

function Scene:postFixedUpdate(dt)
    return runStage(self, "postFixedUpdate", dt)
end

function Scene:update(dt)
    return runStage(self, "update", dt)
end

function Scene:postUpdate(dt)
    return runStage(self, "postUpdate", dt)
end

function Scene:draw(alpha)
    local state = ensureOpen(self, "draw")
    assert(state.initialized, "scene must be initialized before drawing")
    return state.runtime:runStage("render", alpha or 0)
end

function Scene:dispose()
    local state = stateOf(self)
    if state.disposed then return false end
    state.disposed = true
    if state.initialized then state.runtime:shutdown() end
    state.runtime:dispose()
    return true
end

function Scene:isDisposed()
    return stateOf(self).disposed
end

return Scene
