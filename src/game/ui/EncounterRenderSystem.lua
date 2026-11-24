-- Read-only LOVE presentation for the Final Conversation. It maps encounter
-- state into panels and card states without resolving any gameplay rules.
local Screen = require("src.game.Screen")
local UiTheme = require("src.game.ui.UiTheme")
local SceneBackground = require("src.game.graphics.SceneBackground")

local EncounterRenderSystem = {}

local function availability(card, index, state)
    if state.usedCollectionIndexes[index] then return "used" end
    if card.cost > state.focus then return "unaffordable" end
    return "playable"
end

local function selectedDetailText(card)
    if not card then return "No conversation cards are available." end
    return ("%s  |  %s\n%s\nPower %d    Focus Cost %d"):format(
        card.name, string.upper(card.category), card.description, card.power, card.cost)
end

local function promptText(definition, state)
    local prompt = definition.prompts[state.promptIndex]
    return prompt and prompt.text or "The conversation has concluded."
end

local function cardWidth(count)
    if count <= 1 then return 320 end
    return math.max(120, math.floor((880 - (count - 1) * 10) / count))
end

local function drawCollectionCard(graphics, card, index, x, y, width, state, selected, prompt)
    local status = availability(card, index, state)
    local categoryColor = UiTheme.categoryColor(card.category)
    local matching = prompt and card.category == prompt.preferredCategory
    UiTheme.drawPanel(graphics, x, y, width, 150, selected)
    UiTheme.setColor(graphics, categoryColor, status == "playable" and 1 or 0.55)
    graphics.rectangle("fill", x, y, width, 24)
    UiTheme.setColor(graphics, UiTheme.colors.background)
    graphics.printf(string.upper(card.category), x + 8, y + 5, width - 16, "left")

    if matching and status == "playable" then
        UiTheme.setColor(graphics, UiTheme.colors.positive)
        graphics.rectangle("line", x + 3, y + 3, width - 6, 144)
    end
    local textColor = status == "playable" and UiTheme.colors.text or UiTheme.colors.unavailable
    UiTheme.setColor(graphics, textColor)
    graphics.printf(card.name, x + 10, y + 38, width - 20, "left")
    graphics.printf(string.upper(card.symbol), x + 10, y + 64, width - 20, "left")
    graphics.printf(("Power %d\nFocus %d"):format(card.power, card.cost),
        x + 10, y + 92, width - 20, "left")

    if status == "used" then
        UiTheme.setColor(graphics, UiTheme.colors.unavailable)
        graphics.printf("USED", x + 10, y + 126, width - 20, "center")
    elseif status == "unaffordable" then
        UiTheme.setColor(graphics, UiTheme.colors.warning)
        graphics.printf("NO FOCUS", x + 10, y + 126, width - 20, "center")
    elseif matching then
        UiTheme.setColor(graphics, UiTheme.colors.positive)
        graphics.printf("MATCH", x + 10, y + 126, width - 20, "center")
    end
end

function EncounterRenderSystem.install(scheduler)
    scheduler:addSystem({
        name = "encounterRender",
        stage = "render",
        readsResources = {
            "gameSession",
            "encounterDefinition",
            "encounterState",
            "encounterCollectionSelection",
        },
        run = function(context)
            local graphics = love and love.graphics or nil
            if not graphics then return end
            local world = context.world
            local session = world:requireResource("gameSession")
            local definition = world:requireResource("encounterDefinition")
            local state = world:requireResource("encounterState")
            local selected = world:requireResource("encounterCollectionSelection")
            local prompt = definition.prompts[state.promptIndex]

            SceneBackground.draw(graphics, "finalConversation")
            UiTheme.setColor(graphics, UiTheme.colors.title)
            graphics.printf("HOMECOMING INVITATION", 0, 14, Screen.w, "center")

            UiTheme.drawPanel(graphics, 100, 44, 760, 82, false)
            UiTheme.setColor(graphics, UiTheme.colors.heading)
            graphics.printf(definition.partnerName .. "   |   ROUND " .. state.promptIndex
                .. " / " .. #definition.prompts, 120, 54, 720, "center")
            UiTheme.setColor(graphics, UiTheme.colors.text)
            graphics.printf(promptText(definition, state), 128, 78, 704, "center")

            UiTheme.drawPanel(graphics, 160, 138, 640, 34, false)
            UiTheme.setColor(graphics, UiTheme.colors.heading)
            graphics.printf(("FOCUS: %d     RAPPORT: %d     PREPARATION: +%d     CARDS: %d"):format(
                state.focus, state.rapport, state.startingRapportBonus,
                #session.collection), 0, 148, Screen.w, "center")

            local width = cardWidth(#session.collection)
            local totalWidth = #session.collection * width + math.max(0, #session.collection - 1) * 10
            local startX = math.floor((Screen.w - totalWidth) / 2)
            for index, card in ipairs(session.collection) do
                drawCollectionCard(graphics, card, index, startX + (index - 1) * (width + 10),
                    190, width, state, index == selected, prompt)
            end
            if #session.collection == 0 then
                UiTheme.drawPanel(graphics, 250, 220, 460, 80, false)
                UiTheme.setColor(graphics, UiTheme.colors.muted)
                graphics.printf("No conversation cards are available.", 0, 250, Screen.w, "center")
            end

            UiTheme.drawPanel(graphics, 100, 356, 760, 88, false)
            UiTheme.setColor(graphics, UiTheme.colors.text)
            graphics.printf(selectedDetailText(session.collection[selected]), 118, 368, 724, "left")

            UiTheme.drawPanel(graphics, 100, 454, 760, 34, false)
            UiTheme.setColor(graphics, UiTheme.colors.feedback)
            graphics.printf(state.feedback, 116, 464, 728, "center")

            UiTheme.drawPanel(graphics, 80, 498, 800, 30, false)
            UiTheme.setColor(graphics, UiTheme.colors.muted)
            graphics.printf("LEFT/RIGHT or A/D: select     ENTER/SPACE: play selected card",
                0, 506, Screen.w, "center")
        end,
    })
end

EncounterRenderSystem.availability = availability
EncounterRenderSystem.selectedDetailText = selectedDetailText
EncounterRenderSystem.promptText = promptText
return EncounterRenderSystem
