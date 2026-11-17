-- Accumulates LÖVE's variable frame delta into fixed simulation updates.
-- Rendering remains controlled by LÖVE; this module only decides how often
-- gameplay is advanced within a rendered frame.
local FixedStep = {}
FixedStep.__index = FixedStep

local EPSILON = 0.0000001

function FixedStep.new(step, maximumFrameDelta)
    assert(type(step) == "number" and step > 0, "step must be positive")
    assert(type(maximumFrameDelta) == "number" and maximumFrameDelta >= step,
        "maximum frame delta must be at least one step")

    return setmetatable({
        step = step,
        maximumFrameDelta = maximumFrameDelta,
        accumulator = 0,
        elapsed = 0,
        tick = 0,
        alpha = 0,
        paused = false,
        timeScale = 1,
        lastFrameDelta = 0,
        lastUpdateCount = 0,
    }, FixedStep)
end

function FixedStep:advance(frameDelta, update)
    assert(type(frameDelta) == "number" and frameDelta >= 0,
        "frame delta must be a non-negative number")
    assert(type(update) == "function", "update must be a function")

    -- A debugger pause or a dragged window must not cause hundreds of physics
    -- updates when the game resumes.
    frameDelta = math.min(frameDelta, self.maximumFrameDelta)
    self.lastFrameDelta = frameDelta
    if self.paused then
        self.lastUpdateCount = 0
        self.alpha = self.accumulator / self.step
        if self.alpha >= 1 then self.alpha = 0.999999 end
        return 0
    end
    frameDelta = frameDelta * self.timeScale
    self.accumulator = math.min(
        self.accumulator + frameDelta,
        self.maximumFrameDelta
    )

    local updateCount = 0
    while self.accumulator + EPSILON >= self.step do
        self.tick = self.tick + 1
        self.elapsed = self.elapsed + self.step
        update(self.step, self.tick)
        self.accumulator = self.accumulator - self.step
        updateCount = updateCount + 1
    end

    if self.accumulator < 0 then
        self.accumulator = 0
    end

    self.lastUpdateCount = updateCount
    self.alpha = self.accumulator / self.step
    if self.alpha >= 1 then self.alpha = 0.999999 end
    return updateCount
end

function FixedStep:setPaused(value) self.paused = value == true end
function FixedStep:isPaused() return self.paused end
function FixedStep:setTimeScale(value) assert(type(value) == "number" and value >= 0, "time scale must be non-negative") self.timeScale = value end
function FixedStep:getTimeScale() return self.timeScale end
function FixedStep:getAlpha() return self.alpha end
function FixedStep:getTick() return self.tick end
function FixedStep:getElapsed() return self.elapsed end
function FixedStep:timeState()
    return { frameDelta = self.lastFrameDelta, fixedDelta = self.step, elapsed = self.elapsed,
        tick = self.tick, alpha = self.alpha, timeScale = self.timeScale, paused = self.paused,
        updateCount = self.lastUpdateCount }
end
function FixedStep:reset() self.accumulator = 0 self.elapsed = 0 self.tick = 0 self.alpha = 0 end

return FixedStep
