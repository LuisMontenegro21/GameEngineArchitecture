local Assert = require("tests.support.assert")
local ECS = require("src.engine.ecs")

return function()
    Assert.isTable(ECS, "the canonical ECS import must return a table")
    Assert.equals("1.0.0", ECS.version)
    Assert.equals("off", ECS.validationModes.off)
    Assert.equals("warn", ECS.validationModes.warn)
    Assert.equals("strict", ECS.validationModes.strict)
    Assert.isTable(ECS.Entity, "Phase 1 must expose the Entity manager")

    Assert.isTable(ECS.World, "Phase 3 must expose the World facade")
end
