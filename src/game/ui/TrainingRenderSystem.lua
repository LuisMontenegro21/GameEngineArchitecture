-- LOVE presentation for the Training Scene. Game state is read-only here.
local Activities = require("src.game.progression.Activities")
local Screen = require("src.game.Screen")
local UiTheme = require("src.game.ui.UiTheme")
local SceneBackground = require("src.game.graphics.SceneBackground")

local TrainingRenderSystem = {}

local function effectText(activity)
    local effects = {}
    if activity.effects.confidence then effects[#effects + 1] = "Confidence +" .. activity.effects.confidence end
    if activity.effects.empathy then effects[#effects + 1] = "Empathy +" .. activity.effects.empathy end
    if activity.effects.arcaneKnowledge then
        effects[#effects + 1] = "Knowledge +" .. activity.effects.arcaneKnowledge
    end
    if activity.effects.energy then effects[#effects + 1] = "Energy +" .. activity.effects.energy end
    return table.concat(effects, "   ")
end

local function costText(activity)
    return activity.energyCost == 0 and "No energy cost" or (activity.energyCost .. " energy")
end

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

            SceneBackground.draw(g, "training")
            UiTheme.setColor(g, UiTheme.colors.title)
            g.printf("WIZARD ACADEMIA", 0, 28, Screen.w, "center")
            UiTheme.drawPanel(g, 120, 62, 720, 58, false)
            UiTheme.setColor(g, UiTheme.colors.text)
            g.printf(("Day %d / %d    Actions: %d    Energy: %d / %d"):format(
                session.day, session.maxDays, session.actionsRemaining,
                session.energy, session.maxEnergy), 0, 72, Screen.w, "center")
            UiTheme.setColor(g, UiTheme.colors.heading)
            g.printf(("Confidence: %d    Empathy: %d    Arcane Knowledge: %d"):format(
                session.stats.confidence, session.stats.empathy,
                session.stats.arcaneKnowledge), 0, 96, Screen.w, "center")

            for index, activity in ipairs(activities) do
                local y = 145 + (index - 1) * 64
                local unavailable = session.actionsRemaining <= 0 or session.energy < activity.energyCost
                UiTheme.drawPanel(g, 150, y - 6, 660, 56, index == selected)
                UiTheme.setColor(g, unavailable and UiTheme.colors.unavailable or UiTheme.colors.text)
                local marker = index == selected and ">" or " "
                g.printf(("%s %s  [%s]"):format(marker, activity.name, costText(activity)),
                    175, y, 600, "left")
                UiTheme.setColor(g, unavailable and UiTheme.colors.unavailable or UiTheme.colors.heading,
                    unavailable and 0.72 or nil)
                g.printf(effectText(activity), 195, y + 24, 570, "left")
            end
            UiTheme.drawPanel(g, 140, 408, 680, 50, false)
            UiTheme.setColor(g, UiTheme.colors.feedback)
            g.printf(session.feedback, 100, 420, 760, "center")
            UiTheme.drawPanel(g, 80, 476, 800, 36, false)
            UiTheme.setColor(g, UiTheme.colors.muted)
            g.printf("UP/DOWN or W/S: select     ENTER/SPACE: train     M: explore academy",
                0, 487, Screen.w, "center")
        end,
    })
end

TrainingRenderSystem.costText = costText
TrainingRenderSystem.effectText = effectText
return TrainingRenderSystem
