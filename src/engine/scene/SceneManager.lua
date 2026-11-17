-- Deferred scene transitions for ECS-backed application scenes.
local SceneManager = {}
SceneManager.__index = SceneManager

local states = setmetatable({}, { __mode = "k" })

local function stateOf(manager)
    local state = states[manager]
    assert(state ~= nil, "invalid SceneManager")
    return state
end

local function ensureOpen(manager, operation)
    local state = stateOf(manager)
    assert(not state.disposed, "cannot " .. operation .. " on disposed SceneManager")
    return state
end

local function protect(state, callback)
    state.inStage = true
    local ok, result = xpcall(callback, debug and debug.traceback or tostring)
    state.inStage = false
    if not ok then error(result, 0) end
    return result
end

local function construct(manager, name, payload)
    local state = stateOf(manager)
    local factory = state.factories[name]
    assert(factory ~= nil, "unknown scene: " .. tostring(name))
    local scene = factory(payload, manager)
    assert(type(scene) == "table" and type(scene.initialize) == "function"
        and type(scene.dispose) == "function", "scene factory must return Scene")
    scene:setTransitionHandler(function(destination, transitionPayload)
        return manager:requestTransition(destination, transitionPayload)
    end)
    local ok, message = pcall(function() scene:initialize() end)
    if not ok then
        pcall(function() scene:dispose() end)
        error(message, 0)
    end
    return scene
end

local function applyPending(manager)
    local state = ensureOpen(manager, "apply transition")
    assert(not state.inStage, "cannot transition while a scene stage is executing")
    local request = state.pending
    if not request then return false end
    state.pending = nil
    local previous = state.current
    local nextScene = construct(manager, request.name, request.payload)
    state.current = nextScene
    if previous then previous:dispose() end
    return true
end

-- Runtime advances event buffers after every stage. Scene requests therefore
-- have to be captured immediately after their emitting stage, before a later
-- stage clears the current event buffer.
local function consumeSceneRequest(manager)
    local state = stateOf(manager)
    if state.pending or not state.current then return false end
    local world = state.current:world()
    if not world:hasEventDefinition("sceneRequest") then return false end
    local request = nil
    for event in world:events("sceneRequest") do
        if not request then
            request = event.payload
        elseif state.diagnostic then
            state.diagnostic("ignored duplicate scene transition: " .. event.payload.to)
        end
    end
    if not request then return false end
    return manager:requestTransition(request.to, request.payload)
end

function SceneManager.new(options)
    options = options or {}
    assert(type(options) == "table", "SceneManager options must be a table")
    assert(options.diagnostic == nil or type(options.diagnostic) == "function",
        "SceneManager diagnostic must be a function or nil")
    local manager = setmetatable({}, SceneManager)
    states[manager] = { factories = {}, current = nil, pending = nil, inStage = false,
        disposed = false, diagnostic = options.diagnostic }
    return manager
end

function SceneManager:register(name, factory)
    local state = ensureOpen(self, "register scene")
    assert(type(name) == "string" and name ~= "", "scene name must be a non-empty string")
    assert(type(factory) == "function", "scene factory must be a function")
    assert(state.factories[name] == nil, "scene already registered: " .. name)
    state.factories[name] = factory
end

function SceneManager:start(name, payload)
    local state = ensureOpen(self, "start")
    assert(state.current == nil, "SceneManager already has an active scene")
    state.current = construct(self, name, payload)
    return state.current
end

function SceneManager:requestTransition(name, payload)
    local state = ensureOpen(self, "request transition")
    assert(state.factories[name] ~= nil, "unknown scene: " .. tostring(name))
    if state.pending then
        if state.diagnostic then state.diagnostic("ignored duplicate scene transition: " .. name) end
        return false
    end
    state.pending = { name = name, payload = payload }
    return true
end

function SceneManager:fixedUpdate(dt)
    local state = ensureOpen(self, "run fixed update")
    assert(state.current ~= nil, "SceneManager has no active scene")
    protect(state, function() state.current:fixedUpdate(dt) end)
    consumeSceneRequest(self)
    return applyPending(self)
end

local function runStage(manager, method, dt)
    local state = ensureOpen(manager, "run " .. method)
    assert(state.current ~= nil, "SceneManager has no active scene")
    protect(state, function() state.current[method](state.current, dt) end)
    consumeSceneRequest(manager)
    return applyPending(manager)
end

function SceneManager:preUpdate(dt)
    return runStage(self, "preUpdate", dt)
end

function SceneManager:postFixedUpdate(dt)
    return runStage(self, "postFixedUpdate", dt)
end

function SceneManager:update(dt)
    return runStage(self, "update", dt)
end

function SceneManager:postUpdate(dt)
    return runStage(self, "postUpdate", dt)
end

function SceneManager:draw(alpha)
    local state = ensureOpen(self, "draw")
    assert(state.current ~= nil, "SceneManager has no active scene")
    protect(state, function() state.current:draw(alpha) end)
    return applyPending(self)
end

function SceneManager:keypressed(key)
    local scene = ensureOpen(self, "forward keypress").current
    if scene and scene.keypressed then return scene:keypressed(key) end
end

function SceneManager:keyreleased(key)
    local scene = ensureOpen(self, "forward key release").current
    if scene and scene.keyreleased then return scene:keyreleased(key) end
end

function SceneManager:current()
    return stateOf(self).current
end

function SceneManager:hasPendingTransition()
    return stateOf(self).pending ~= nil
end

function SceneManager:sceneNames()
    local names = {}
    for name in pairs(stateOf(self).factories) do names[#names + 1] = name end
    table.sort(names)
    return names
end

function SceneManager:quit()
    local state = stateOf(self)
    if state.disposed then return false end
    state.pending = nil
    if state.current then state.current:dispose(); state.current = nil end
    state.disposed = true
    return true
end

return SceneManager
