local FixedStep = require("src.engine.loop.FixedStep")
local Time = require("src.engine.loop.Time")
local LoveRunner = {}
LoveRunner.__index = LoveRunner

function LoveRunner.new(options)
    options = options or {}
    assert(options.runtime, "LoveRunner requires runtime")
    local runner = setmetatable({}, LoveRunner)
    runner.runtime = options.runtime
    runner.fixed = options.fixedStep or FixedStep.new(options.fixedDelta or 1 / 60, options.maximumFrameDelta or 0.25)
    runner.timeResource = options.timeResource or "time"
    runner.time = Time.new(runner.fixed.step)
    runner.loaded = false
    runner.callbacks = options
    return runner
end
function LoveRunner:load()
    local world = self.runtime:world()
    if not world:hasResourceDefinition(self.timeResource) then
        world:registerResource(self.timeResource, { transient = true })
    end
    world:setResource(self.timeResource, self.time)
    if not self.runtime:isBuilt() then self.runtime:build() end
    if not self.runtime:isInitialized() then self.runtime:initialize() end
    self.loaded = true
end
function LoveRunner:update(dt)
    assert(self.loaded, "runner must be loaded")
    self.time.frameDelta = math.min(dt, self.fixed.maximumFrameDelta)
    self.fixed:advance(dt, function(step, tick)
        self.time.fixedDelta, self.time.tick = step, tick
        self.runtime:runStage("fixedUpdate", step)
    end)
    self.time.elapsed, self.time.alpha = self.fixed:getElapsed(), self.fixed:getAlpha()
    self.time.timeScale, self.time.paused = self.fixed:getTimeScale(), self.fixed:isPaused()
    self.time.updateCount = self.fixed.lastUpdateCount
    local world = self.runtime:world(); world:setResource(self.timeResource, self.time)
    self.runtime:runStage("preUpdate", dt)
    self.runtime:runStage("postFixedUpdate", dt)
    self.runtime:runStage("update", dt)
    self.runtime:runStage("postUpdate", dt)
end
function LoveRunner:draw()
    if self.loaded then self.runtime:runStage("render", self.time.alpha) end
end
function LoveRunner:setPaused(value) self.fixed:setPaused(value) end
function LoveRunner:setTimeScale(value) self.fixed:setTimeScale(value) end
function LoveRunner:keypressed(...) if self.callbacks.onKeyPressed then return self.callbacks.onKeyPressed(...) end end
function LoveRunner:keyreleased(...) if self.callbacks.onKeyReleased then return self.callbacks.onKeyReleased(...) end end
function LoveRunner:mousepressed(...) if self.callbacks.onMousePressed then return self.callbacks.onMousePressed(...) end end
function LoveRunner:quit() if self.runtime:isInitialized() then self.runtime:shutdown() end end
return LoveRunner
