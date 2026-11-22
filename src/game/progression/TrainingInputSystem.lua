-- Converts Training Scene keyboard input into selection and activity events.
local Activities = require("src.game.progression.Activities")
local TrainingInputSystem = {}

function TrainingInputSystem.install(scheduler)
    scheduler:addSystem({
        name = "trainingInput",
        stage = "fixedUpdate",
        readsResources = { "trainingSelection" },
        writesResources = { "trainingSelection" },
        run = function(context)
            local world = context.world
            local selection = world:requireResource("trainingSelection")
            local total = #Activities.all()
            for event in world:events("keyPressed") do
                local key = event.payload.key
                if key == "up" or key == "w" then
                    selection = math.max(1, selection - 1)
                    world:setResource("trainingSelection", selection)
                    context.emit("trainingSelectionChanged", { index = selection })
                elseif key == "down" or key == "s" then
                    selection = math.min(total, selection + 1)
                    world:setResource("trainingSelection", selection)
                    context.emit("trainingSelectionChanged", { index = selection })
                elseif key == "return" or key == "space" then
                    local activity = Activities.all()[selection]
                    context.emit("trainingActivityRequested", { activityId = activity.id })
                end
            end
        end,
    })
end

return TrainingInputSystem
