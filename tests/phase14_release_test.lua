local ECS = require("src.engine.ecs")

return function()
    assert(ECS.version == "1.0.0" and ECS.apiVersion == 1)
    assert(ECS.Snapshot.schemaVersion == "1.0")
    local function pair()
        local world = ECS.World.new(); world:registerComponent("value", { default = 0 })
        local scheduler = ECS.Scheduler.new()
        scheduler:addSystem({ name = "step", stage = "update", run = function(ctx)
            for entity, value in ctx.world:query({ all = { "value" } }):each() do ctx.world:set(entity, "value", value + 1) end
        end })
        local runtime = ECS.Runtime.new({ world = world, scheduler = scheduler }); runtime:build(); runtime:initialize()
        world:create({ value = 0 }); return world, runtime
    end
    local worldA, runtimeA = pair(); local worldB, runtimeB = pair()
    runtimeA:runStage("update", 1); assert(worldA:count() == 1 and worldB:count() == 1)
    assert(worldA:snapshot().entities[1].components.value.value == 1)
    assert(worldB:snapshot().entities[1].components.value.value == 0)
    runtimeA:dispose(); runtimeB:dispose()
end
