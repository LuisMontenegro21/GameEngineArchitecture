-- Opens a transient challenge when the player interacts with an activity.
local ActivityChallengeCatalog = require("src.game.locations.ActivityChallengeCatalog")

local LocationActivityChallengeSystem = {}

function LocationActivityChallengeSystem.install(scheduler)
    scheduler:addSystem({
        name = "locationActivityChallenge",
        stage = "postFixedUpdate",
        after = { "locationDialogue" },
        readsResources = { "gameSession", "locationDefinition", "activityChallengeState" },
        writesResources = { "activityChallengeState", "locationState" },
        run = function(context)
            local world = context.world
            if world:requireResource("activityChallengeState") then return end
            for event in world:events("locationActivityChallengeRequested") do
                local location = world:requireResource("locationDefinition")
                local state = world:requireResource("locationState")
                if event.payload.activityId ~= location.activityId then
                    state.feedback = "That activity is unavailable in this location."
                    world:setResource("locationState", state)
                    return
                end
                if world:requireResource("gameSession").dayPhase ~= "activities" then
                    state.feedback = "Activities are unavailable during this part of the day."
                    world:setResource("locationState", state)
                    return
                end
                local definition = assert(ActivityChallengeCatalog.get(location.activityId))
                local challenge = {
                    activityId = definition.activityId,
                    mode = definition.mode,
                    title = definition.title,
                    prompt = definition.prompt,
                    steps = definition.steps,
                    currentStep = 1,
                    options = definition.options,
                    selection = 1,
                    timing = definition.timing,
                    visualId = definition.visualId,
                    completionFeedback = definition.completionFeedback,
                    feedback = definition.mode == "sequence" and "Use the arrow keys to trace the runes."
                        or (definition.mode == "timing" and "Press E inside the highlighted focus zone."
                            or "Use Left and Right to choose your response."),
                }
                world:setResource("activityChallengeState", challenge)
                return
            end
        end,
    })
end

return LocationActivityChallengeSystem
