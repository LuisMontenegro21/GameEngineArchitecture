local FixedStep = require("src.engine.loop.FixedStep")
local World = require("src.engine.ecs.World")
local Scheduler = require("src.engine.ecs.Scheduler")
local Runtime = require("src.engine.ecs.Runtime")
local LoveRunner = require("src.engine.loop.LoveRunner")

return function()
    local function ticks(rate)
        local f = FixedStep.new(1 / 60, 0.25); local n = 0
        for _ = 1, rate do f:advance(1 / rate, function() n = n + 1 end) end
        return n
    end
    assert(ticks(30) == ticks(60) and ticks(60) == ticks(144))
    local f = FixedStep.new(1 / 60, 0.1); local n = f:advance(10, function() end)
    assert(n <= 6)
    f:setPaused(true); assert(f:advance(1, function() error("paused") end) == 0)
    local world = World.new(); local scheduler = Scheduler.new()
    local rendered = false
    scheduler:addSystem({ name = "render", stage = "render", run = function(ctx)
        rendered = true; assert(ctx.world:isReadOnly()); assert(ctx.dt >= 0 and ctx.dt < 1)
        local ok = pcall(function() ctx.world:create() end); assert(not ok)
    end })
    local runtime = Runtime.new({ world = world, scheduler = scheduler })
    local runner = LoveRunner.new({ runtime = runtime, fixedDelta = 1 / 60 })
    runner:load(); runner:update(1 / 60); runner:draw(); assert(rendered)
    runner:quit(); runtime:dispose()
end
