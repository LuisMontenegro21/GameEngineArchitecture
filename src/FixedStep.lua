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
    }, FixedStep)
end

function FixedStep:advance(frameDelta, update)
    assert(type(frameDelta) == "number" and frameDelta >= 0,
        "frame delta must be a non-negative number")
    assert(type(update) == "function", "update must be a function")

    -- A debugger pause or a dragged window must not cause hundreds of physics
    -- updates when the game resumes.
    frameDelta = math.min(frameDelta, self.maximumFrameDelta)
    self.accumulator = math.min(
        self.accumulator + frameDelta,
        self.maximumFrameDelta
    )

    local updateCount = 0
    while self.accumulator + EPSILON >= self.step do
        update(self.step)
        self.accumulator = self.accumulator - self.step
        updateCount = updateCount + 1
    end

    if self.accumulator < 0 then
        self.accumulator = 0
    end

    return updateCount
end

return FixedStep
