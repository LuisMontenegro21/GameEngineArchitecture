local Assert = require("tests.support.assert")
local ECS = require("src.engine.ecs")

return function()
    Assert.isTable(ECS, "the canonical ECS import must return a table")
    Assert.equals("0.1.0-dev", ECS.version)
    Assert.equals("off", ECS.validationModes.off)
    Assert.equals("warn", ECS.validationModes.warn)
    Assert.equals("strict", ECS.validationModes.strict)
    Assert.isTable(ECS.Entity, "Phase 1 must expose the Entity manager")

    -- Phase 0 intentionally has no World implementation yet. This assertion
    -- protects the import boundary without coupling the test to future storage.
    Assert.falsy(ECS.World, "World is introduced in a later phase")
end
