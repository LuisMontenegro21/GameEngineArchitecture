local StatsUpdateSystem = { name = "StatsUpdateSystem"}
local acitivites = require("src.game.data.activities")

function StatsUpdateSystem.update(scene, dt)
    for _, event in scene.registry:each("event") do
        if event.activityPicked then
            local runState = scene.registry.resource("runState")
            local activity = event.activityPicked.selected

        end
    end
end


return StatsUpdateSystem