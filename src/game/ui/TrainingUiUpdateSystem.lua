-- Converts Training UI navigation and confirmation input into presentation
-- selection state and gameplay requests. It never applies activity effects.
local Activities = require("src.game.progression.Activities")

local TrainingUiUpdateSystem = {}

function TrainingUiUpdateSystem.install(scheduler)
    scheduler:addSystem({
        name = "trainingUiUpdate",
        stage = "fixedUpdate",
        readsResources = { "trainingSelection" },
        writesResources = { "trainingSelection" },
        run = function(context)
            local world = context.world
            local selection = world:requireResource("trainingSelection")
            local activities = Activities.all()
            for event in world:events("keyPressed") do
                local key = event.payload.key
                if key == "up" or key == "w" then
                    selection = math.max(1, selection - 1)
                    world:setResource("trainingSelection", selection)
                    context.emit("trainingSelectionChanged", { index = selection })
                elseif key == "down" or key == "s" then
                    selection = math.min(#activities, selection + 1)
                    world:setResource("trainingSelection", selection)
                    context.emit("trainingSelectionChanged", { index = selection })
                elseif key == "return" or key == "space" then
                    context.emit("trainingActivityRequested", {
                        activityId = activities[selection].id,
                    })
                end
            end
        end,
    })
end

return TrainingUiUpdateSystem
