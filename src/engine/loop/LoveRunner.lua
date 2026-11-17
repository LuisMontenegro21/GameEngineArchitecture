local FixedStep = require("src.engine.loop.FixedStep")
local Time = require("src.engine.loop.Time")
local LoveRunner = {}
LoveRunner.__index = LoveRunner

function LoveRunner.new(options)
    options = options or {}
    assert((options.runtime and not options.sceneManager)
        or (options.sceneManager and not options.runtime),
        "LoveRunner requires exactly one runtime or sceneManager")
    local runner = setmetatable({}, LoveRunner)
    runner.runtime = options.runtime
    runner.sceneManager = options.sceneManager
    runner.fixed = options.fixedStep or FixedStep.new(options.fixedDelta or 1 / 60, options.maximumFrameDelta or 0.25)
    runner.timeResource = options.timeResource or "time"
    runner.time = Time.new(runner.fixed.step)
    runner.loaded = false
    runner.callbacks = options
    runner.inputQueue = {}
    return runner
end

function LoveRunner:_currentRuntime()
    if self.sceneManager then
        local scene = self.sceneManager:current()
        assert(scene ~= nil, "LoveRunner sceneManager has no active scene")
        return scene:runtime()
    end
    return self.runtime
end

function LoveRunner:_currentWorld()
    return self:_currentRuntime():world()
end

function LoveRunner:_syncTime()
    local world = self:_currentWorld()
    if not world:hasResourceDefinition(self.timeResource) then
        world:registerResource(self.timeResource, { transient = true })
    end
    world:setResource(self.timeResource, self.time)
end

function LoveRunner:_drainInput()
    local queue = self.inputQueue
    self.inputQueue = {}
    if #queue == 0 then return end
    local world = self:_currentWorld()
    for _, record in ipairs(queue) do
        if self.callbacks.onInput then self.callbacks.onInput(record, world) end
        local eventName = record.kind == "keypressed" and "keyPressed" or "keyReleased"
        if world:hasEventDefinition(eventName) then world:emit(eventName, { key = record.key }) end
    end
end

function LoveRunner:_run(method, dt)
    if self.sceneManager then
        if method == "render" then return self.sceneManager:draw(dt) end
        return self.sceneManager[method](self.sceneManager, dt)
    end
    local runtime = self.runtime
    if method == "preUpdate" or method == "postFixedUpdate" or method == "update"
        or method == "postUpdate" or method == "fixedUpdate" or method == "render" then
        return runtime:runStage(method, dt)
    end
end

function LoveRunner:load()
    if self.sceneManager then
        assert(self.sceneManager:current() ~= nil,
            "start a scene before loading LoveRunner")
    else
        local runtime = self.runtime
        if not runtime:isBuilt() then runtime:build() end
        if not runtime:isInitialized() then runtime:initialize() end
    end
    self:_syncTime()
    self.loaded = true
end
function LoveRunner:update(dt)
    assert(self.loaded, "runner must be loaded")
    self.time.frameDelta = math.min(dt, self.fixed.maximumFrameDelta)
    self.time.timeScale, self.time.paused = self.fixed:getTimeScale(), self.fixed:isPaused()
    self:_syncTime()
    self:_drainInput()
    self:_run("preUpdate", dt)

    local transitioned = false
    self.fixed:advance(dt, function(step, tick)
        if transitioned then return end
        self.time.fixedDelta, self.time.tick = step, tick
        self:_syncTime()
        local changedScene = self:_run("fixedUpdate", step)
        transitioned = self.sceneManager ~= nil and changedScene == true
    end)
    self.time.elapsed, self.time.alpha = self.fixed:getElapsed(), self.fixed:getAlpha()
    self.time.timeScale, self.time.paused = self.fixed:getTimeScale(), self.fixed:isPaused()
    self.time.updateCount = self.fixed.lastUpdateCount
    self:_syncTime()
    self:_run("postFixedUpdate", dt)
    self:_syncTime()
    self:_run("update", dt)
    self:_syncTime()
    self:_run("postUpdate", dt)
end
function LoveRunner:draw()
    if self.loaded then self:_syncTime(); self:_run("render", self.time.alpha) end
end
function LoveRunner:setPaused(value) self.fixed:setPaused(value) end
function LoveRunner:setTimeScale(value) self.fixed:setTimeScale(value) end
function LoveRunner:keypressed(key, ...)
    self.inputQueue[#self.inputQueue + 1] = { kind = "keypressed", key = key }
    if self.callbacks.onKeyPressed then return self.callbacks.onKeyPressed(key, ...) end
end
function LoveRunner:keyreleased(key, ...)
    self.inputQueue[#self.inputQueue + 1] = { kind = "keyreleased", key = key }
    if self.callbacks.onKeyReleased then return self.callbacks.onKeyReleased(key, ...) end
end
function LoveRunner:mousepressed(...) if self.callbacks.onMousePressed then return self.callbacks.onMousePressed(...) end end
function LoveRunner:quit()
    if self.sceneManager then return self.sceneManager:quit() end
    if self.runtime:isInitialized() then return self.runtime:shutdown() end
    return false
end
return LoveRunner
