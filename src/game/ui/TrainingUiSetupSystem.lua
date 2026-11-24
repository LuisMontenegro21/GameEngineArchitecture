-- Initializes only presentation selection state. Activity effects remain owned
-- by progression systems.
local Activities = require("src.game.progression.Activities")

local TrainingUiSetupSystem = {}

local function clamp(index, count)
    return math.max(1, math.min(index, math.max(1, count)))
end

function TrainingUiSetupSystem.install(scheduler)
    scheduler:addSystem({
        name = "trainingUiSetup",
        stage = "startup",
        readsResources = { "gameSession", "trainingSelection" },
        writesResources = { "trainingSelection" },
        run = function(context)
            local world = context.world
            local session = world:requireResource("gameSession")
            assert(session, "Training UI requires a game session")
            local activities = Activities.all()
            world:setResource("trainingSelection", clamp(
                world:requireResource("trainingSelection"), #activities))
        end,
    })
end

TrainingUiSetupSystem.clamp = clamp
return TrainingUiSetupSystem
