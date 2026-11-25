-- Shared, ECS-independent rules for Wizard Academia's daily activities.
-- `resolve` is pure: it reports what would happen without changing a session.
-- Callers use `resolveAndApply` when they want to commit the result.
local Activities = require("src.game.progression.Activities")

local ActivityRules = {}

function ActivityRules.resolve(session, activityId)
    local activity = Activities.get(activityId)
    if not activity then
        return {
            activityId = activityId,
            success = false,
            reason = "That training activity is unavailable.",
        }
    end
    if session.completedActivities and session.completedActivities[activityId] then
        return {
            activityId = activityId,
            activity = activity,
            success = false,
            reason = "You have already completed that activity today. Try another location.",
        }
    end
    if session.actionsRemaining <= 0 then
        return {
            activityId = activityId,
            activity = activity,
            success = false,
            reason = "There are no training actions remaining today.",
        }
    end
    if session.energy < activity.energyCost then
        return {
            activityId = activityId,
            activity = activity,
            success = false,
            reason = "You do not have enough energy for that activity.",
        }
    end
    return {
        activityId = activityId,
        activity = activity,
        success = true,
        reason = nil,
    }
end

function ActivityRules.feedback(result)
    assert(type(result) == "table" and type(result.success) == "boolean",
        "activity result must contain success")
    if result.success then return result.activity.feedback end
    return result.reason
end

function ActivityRules.apply(session, result)
    assert(type(session) == "table", "activity rules require a session")
    assert(type(result) == "table" and type(result.success) == "boolean",
        "activity result must contain success")
    if result.success then
        local activity = result.activity
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
        session.completedActivities = session.completedActivities or {}
        session.completedActivities[activity.id] = true
    end
    session.feedback = ActivityRules.feedback(result)
    return result
end

function ActivityRules.resolveAndApply(session, activityId)
    return ActivityRules.apply(session, ActivityRules.resolve(session, activityId))
end

return ActivityRules
