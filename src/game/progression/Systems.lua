local Systems = {}
local Activities = require("src.game.progression.Activities")

local function firstEvent(world, name)
    local result = nil
    for event in world:events(name) do if not result then result = event.payload or {} end end
    return result
end

local function resetForStage(progression, plan, index)
    local stage = plan.stages[index]
    progression.state = "available"
    progression.stageIndex = index
    progression.objectiveId = stage.id
    progression.current = 0
    progression.required = stage.required
    progression.rewardGranted = false
end

function Systems.install(scheduler)
    scheduler:addSystem({
        name = "progressionCycle",
        stage = "fixedUpdate",
        readsResources = { "progressionPlan" },
        writesResources = { "progression" },
        run = function(context)
            local world = context.world
            local progression = world:requireResource("progression")
            local plan = world:requireResource("progressionPlan")

            if firstEvent(world, "progressionNextRequested") then
                if progression.state == "rewarded" then
                    local nextIndex = progression.stageIndex + 1
                    if plan.stages[nextIndex] then
                        resetForStage(progression, plan, nextIndex)
                    else
                        progression.state = "cycleCompleted"
                        context.emit("progressionCycleCompleted", { cycleId = plan.id })
                    end
                end
                return
            end

            if firstEvent(world, "progressionStartRequested") then
                if progression.state == "available" or progression.state == "failed" then
                    progression.state = "active"
                    progression.current = 0
                    context.emit("objectiveStarted", { objectiveId = progression.objectiveId })
                end
            end

            if progression.state == "active" and firstEvent(world, "progressionFailed") then
                progression.state = "failed"
                return
            end

            if progression.state ~= "active" then return end
            for event in world:events("objectiveProgress") do
                local payload = event.payload
                if payload.objectiveId == progression.objectiveId then
                    progression.current = math.min(
                        progression.required,
                        progression.current + payload.amount
                    )
                end
            end
            if progression.current >= progression.required then
                progression.state = "completed"
                progression.completedObjectives[progression.objectiveId] = true
                context.emit("objectiveCompleted", { objectiveId = progression.objectiveId })
            end
        end,
    })

    scheduler:addSystem({
        name = "progressionRewards",
        stage = "postFixedUpdate",
        readsResources = { "progressionPlan" },
        writesResources = { "progression" },
        run = function(context)
            local world = context.world
            local progression = world:requireResource("progression")
            if progression.state ~= "completed" or progression.rewardGranted then return end
            local completed = firstEvent(world, "objectiveCompleted")
            if not completed or completed.objectiveId ~= progression.objectiveId then return end
            local stage = world:requireResource("progressionPlan").stages[progression.stageIndex]
            local reward = stage.reward or {}
            progression.experience = progression.experience + (reward.experience or 0)
            progression.currency = progression.currency + (reward.currency or 0)
            for _, unlock in ipairs(reward.unlocks or {}) do progression.unlocks[unlock] = true end
            progression.rewardGranted = true
            progression.state = "rewarded"
            context.emit("rewardGranted", { objectiveId = progression.objectiveId })
        end,
    })
end

-- Arcane Hearts keeps input, state changes, feedback, and transitions as
-- separate systems so the Training Scene can evolve without a monolithic
-- scene controller.
function Systems.installArcaneTraining(scheduler)
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

    scheduler:addSystem({
        name = "trainingFeedback",
        stage = "update",
        readsResources = { "gameSession" },
        writesResources = { "gameSession" },
        run = function(context)
            local world = context.world
            local session = world:requireResource("gameSession")
            for event in world:events("trainingActivityResolved") do
                local result = event.payload
                local activity = Activities.get(result.activityId)
                session.feedback = result.success and activity.feedback or result.reason
                world:setResource("gameSession", session)
            end
        end,
    })

    scheduler:addSystem({
        name = "trainingTransition",
        stage = "update",
        after = { "trainingFeedback" },
        readsResources = { "gameSession", "trainingTransitionQueued" },
        writesResources = { "trainingTransitionQueued" },
        run = function(context)
            local world = context.world
            local session = world:requireResource("gameSession")
            if session.actionsRemaining == 0
                and not world:requireResource("trainingTransitionQueued") then
                world:setResource("trainingTransitionQueued", true)
                context.emit("cardGenerationRequested")
                context.emit("sceneRequest", { to = "cardAcquisition", payload = { session = session } })
            end
        end,
    })
end

return Systems
