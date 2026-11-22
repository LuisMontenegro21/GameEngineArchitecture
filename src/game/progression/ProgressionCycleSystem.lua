-- Generic objective-stage state transitions. This is independent of
-- Wizard Academia's training loop and can be installed by another game.
local ProgressionCycleSystem = {}

local function firstEvent(world, name)
    for event in world:events(name) do return event.payload or {} end
    return nil
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

function ProgressionCycleSystem.install(scheduler)
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
                    progression.current = math.min(progression.required,
                        progression.current + payload.amount)
                end
            end
            if progression.current >= progression.required then
                progression.state = "completed"
                progression.completedObjectives[progression.objectiveId] = true
                context.emit("objectiveCompleted", { objectiveId = progression.objectiveId })
            end
        end,
    })
end

return ProgressionCycleSystem
