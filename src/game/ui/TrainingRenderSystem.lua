-- LOVE presentation for the Training Scene. Game state is read-only here.
local Activities = require("src.game.progression.Activities")
local Screen = require("src.game.Screen")

local TrainingRenderSystem = {}

function TrainingRenderSystem.install(scheduler)
    scheduler:addSystem({
        name = "trainingRender",
        stage = "render",
        readsResources = { "gameSession", "trainingSelection" },
        run = function(context)
            local g = love and love.graphics or nil
            if not g then return end
            local session = context.world:requireResource("gameSession")
            local selected = context.world:requireResource("trainingSelection")
            local activities = Activities.all()

            g.clear(0.06, 0.04, 0.12, 1)
            g.setColor(0.9, 0.82, 1, 1)
            g.printf("WIZARD ACADEMIA", 0, 28, Screen.w, "center")
            g.setColor(1, 1, 1, 1)
            g.printf(("Day %d / %d    Actions: %d    Energy: %d / %d"):format(
                session.day, session.maxDays, session.actionsRemaining,
                session.energy, session.maxEnergy), 0, 70, Screen.w, "center")
            g.printf(("Confidence: %d    Empathy: %d    Arcane Knowledge: %d"):format(
                session.stats.confidence, session.stats.empathy,
                session.stats.arcaneKnowledge), 0, 100, Screen.w, "center")

            for index, activity in ipairs(activities) do
                local y = 150 + (index - 1) * 62
                if index == selected then
                    g.setColor(0.36, 0.22, 0.56, 1)
                    g.rectangle("fill", 170, y - 6, 620, 46)
                end
                g.setColor(1, 1, 1, 1)
                local cost = activity.energyCost == 0 and "no energy" or (activity.energyCost .. " energy")
                local marker = index == selected and ">" or " "
                g.printf(("%s %s  [%s]"):format(marker, activity.name, cost), 190, y, 580, "left")
            end
            g.setColor(0.8, 0.9, 1, 1)
            g.printf(session.feedback, 100, 420, 760, "center")
            g.setColor(0.7, 0.7, 0.7, 1)
            g.printf("UP/DOWN or W/S: select     ENTER/SPACE: train", 0, 485, Screen.w, "center")
        end,
    })
end

return TrainingRenderSystem
