local Definitions = require("src.game.progression.Definitions")

local function copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    assert(not seen[value], "progression plan cannot contain cycles")
    seen[value] = true
    local result = {}
    for key, item in pairs(value) do result[copy(key, seen)] = copy(item, seen) end
    seen[value] = nil
    return result
end

return function(world, plan)
    assert(Definitions.validPlan(plan), "invalid progression plan")
    Definitions.register(world)
    plan = copy(plan)
    local first = plan.stages[1]
    world:setResource("progressionPlan", plan)
    world:setResource("progression", {
        state = "available",
        stageIndex = 1,
        objectiveId = first.id,
        current = 0,
        required = first.required,
        rewardGranted = false,
        experience = 0,
        currency = 0,
        completedObjectives = {},
        unlocks = {},
    })
    return world
end
