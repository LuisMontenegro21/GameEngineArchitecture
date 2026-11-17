local World = require("src.engine.ecs.World")
local Scheduler = require("src.engine.ecs.Scheduler")
local Runtime = require("src.engine.ecs.Runtime")
local Snapshot = require("src.engine.ecs.Snapshot")

local function simulation(trace)
    local world = World.new(); world:registerComponent("value", { default = 0 })
    local scheduler = Scheduler.new(); scheduler:addSystem({ name = "step", stage = "update", run = function(ctx)
        for entity, value in ctx.world:query({ all = { "value" } }):each() do ctx.world:set(entity, "value", value + 1) end
    end })
    local runtime = Runtime.new({ world = world, scheduler = scheduler, trace = trace }); runtime:build(); runtime:initialize()
    world:create({ value = 0 }); runtime:runStage("update", 1 / 60); runtime:runStage("update", 1 / 60)
    local result = Snapshot.capture(world); runtime:dispose(); return result
end

return function()
    local traceCount = 0
    local resultA = simulation(function() traceCount = traceCount + 1 end)
    local resultB = simulation(nil)
    assert(traceCount > 0 and resultA.entities[1].components.value.value == resultB.entities[1].components.value.value)

    local world = World.new(); world:registerComponent("value", { default = 0 })
    for i = 1, 1000 do world:create({ value = i }) end
    local report = world:inspect(); assert(report.entities == 1000 and report.components.value.count == 1000)
    local ok = world:validateDetailed(); assert(ok)
    assert(not pcall(function() world:restoreSnapshot({ version = 1, entities = {{ id = 1, components = { missing = { version = 1, value = {} } } }}, resources = {} }) end))
    world:dispose()
end
