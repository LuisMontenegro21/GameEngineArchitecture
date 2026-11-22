-- Validates and applies one requested training activity to the shared session.
local Activities = require("src.game.progression.Activities")
local TrainingActivitySystem = {}

function TrainingActivitySystem.install(scheduler)
    scheduler:addSystem({
        name = "trainingActivity",
        stage = "postFixedUpdate",
        readsResources = { "gameSession" },
        writesResources = { "gameSession" },
        run = function(context)
            local world = context.world
            local session = world:requireResource("gameSession")
            for event in world:events("trainingActivityRequested") do
                local activity = Activities.get(event.payload.activityId)
                local success, reason = false, nil
                if not activity then
                    reason = "That training activity is unavailable."
                elseif session.actionsRemaining <= 0 then
                    reason = "There are no training actions remaining today."
                elseif session.energy < activity.energyCost then
                    reason = "You do not have enough energy for that activity."
                else
                    session.actionsRemaining = session.actionsRemaining - 1
                    session.energy = session.energy - activity.energyCost
                    for stat, amount in pairs(activity.effects) do
                        if stat == "energy" then
                            session.energy = math.min(session.maxEnergy, session.energy + amount)
                        else
                            session.stats[stat] = session.stats[stat] + amount
                        end
                    end
                    session.lastActivity = activity.id
                    success = true
                end
                world:setResource("gameSession", session)
                context.emit("trainingActivityResolved", {
                    activityId = event.payload.activityId,
                    success = success,
                    reason = reason,
                })
            end
        end,
    })
end

return TrainingActivitySystem
