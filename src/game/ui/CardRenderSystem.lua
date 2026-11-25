-- Presentation only: generation, acquisition, and collection storage remain
-- in dedicated gameplay systems.
local Screen = require("src.game.Screen")
local UiTheme = require("src.game.ui.UiTheme")
local SceneBackground = require("src.game.graphics.SceneBackground")
local CardPresentationCatalog = require("src.game.graphics.CardPresentationCatalog")
local ImageManager = require("src.game.graphics.ImageManager")

local CardRenderSystem = {}

local function categoryColor(category)
    return UiTheme.categoryColor(category)
end

local SOURCE_LABELS = {
    dominantStat = "Dominant stat",
    lastActivity = "Last activity",
    balanced = "Balanced option",
}

local function sourceText(card)
    local source = card and card.generationSource
    if not source then return nil end
    return ("Draft source: %s (%s)"):format(
        SOURCE_LABELS[source.kind] or "Daily option", source.category)
end

local function cardText(card)
    if not card then
        return "No cards acquired yet.\nChoose a generated card to begin your collection."
    end
    local text = ("%s\n%s\n%s\nPower %d   Cost %d"):format(
        card.name, string.upper(card.symbol), card.description, card.power, card.cost)
    local source = sourceText(card)
    return source and (text .. "\n" .. source) or text
end

local function imageWithDimensions(path, width, height)
    local image = ImageManager.get(path)
    if not image or type(image.getDimensions) ~= "function" then return nil end
    local imageWidth, imageHeight = image:getDimensions()
    return imageWidth == width and imageHeight == height and image or nil
end

local function drawCardArt(g, card, x, y, height)
    local presentation = CardPresentationCatalog.get(card)
    if not presentation or type(g.draw) ~= "function" then return false, 0 end
    local base = imageWithDimensions(presentation.base.path, presentation.base.width, presentation.base.height)
    local icon = imageWithDimensions(presentation.icon.path, presentation.icon.width, presentation.icon.height)
    if not base or not icon then return false, 0 end

    local size = height >= 150 and 64 or 42
    local iconSize = height >= 150 and 32 or 22
    g.setColor(1, 1, 1, 1)
    g.draw(base, x, y, 0, size / presentation.base.width, size / presentation.base.height)
    g.draw(icon, x + (size - iconSize) / 2, y + (size - iconSize) / 2,
        0, iconSize / presentation.icon.width, iconSize / presentation.icon.height)
    return true, size
end

local function drawCard(g, card, x, y, width, height, selected)
    local color = categoryColor(card.category)
    if selected then
        UiTheme.setColor(g, UiTheme.colors.selection)
        g.rectangle("fill", x - 8, y - 8, width + 16, height + 16)
    end
    UiTheme.setColor(g, UiTheme.colors.panel)
    g.rectangle("fill", x, y, width, height)
    g.setColor(color.r, color.g, color.b, 1)
    g.rectangle("fill", x, y, width, 28)
    UiTheme.setColor(g, UiTheme.colors.background)
    g.printf(string.upper(card.category), x + 10, y + 7, width - 20, "left")
    UiTheme.setColor(g, UiTheme.colors.panelBorder)
    g.rectangle("line", x, y, width, height)
    local hasArt, artSize = drawCardArt(g, card, x + 10, y + 36, height)
    local textX = x + (hasArt and artSize + 22 or 12)
    local textWidth = width - (textX - x) - 12
    UiTheme.setColor(g, UiTheme.colors.text)
    g.printf(card.name, textX, y + 40, textWidth, "left")
    if not hasArt then
        UiTheme.setColor(g, UiTheme.colors.muted)
        g.printf(string.upper(card.symbol), textX, y + 62, textWidth, "left")
    end
    UiTheme.setColor(g, UiTheme.colors.text)
    local descriptionY = hasArt and y + 66 or y + 84
    g.printf(card.description, textX, descriptionY, textWidth, "left")
    UiTheme.setColor(g, UiTheme.colors.heading)
    g.printf(("Power %d   Cost %d"):format(card.power, card.cost), textX,
        height >= 150 and y + height - 30 or y + height - 22, textWidth, "left")
end

function CardRenderSystem.install(scheduler)
    scheduler:addSystem({
        name = "cardRender",
        stage = "render",
        readsResources = { "gameSession", "generatedCardSelection", "collectionSelection", "cardFocus" },
        run = function(context)
            local g = love and love.graphics or nil
            if not g then return end
            local world = context.world
            local session = world:requireResource("gameSession")
            local generated = world:requireResource("generatedCardSelection")
            local collection = world:requireResource("collectionSelection")
            local focus = world:requireResource("cardFocus")

            SceneBackground.draw(g, "cardAcquisition")
            UiTheme.setColor(g, UiTheme.colors.title)
            g.printf("Choose a Conversation Card", 0, 24, Screen.w, "center")
            UiTheme.drawPanel(g, 90, 50, 780, 30, false)
            UiTheme.setColor(g, UiTheme.colors.heading)
            g.printf(("Choices reflect your training: Confidence %d, Empathy %d, Knowledge %d"):format(
                session.stats.confidence, session.stats.empathy, session.stats.arcaneKnowledge),
                0, 57, Screen.w, "center")
            UiTheme.setColor(g, UiTheme.colors.muted)
            g.printf(("Day %d draft: seeded from your run and rotated for today."):format(
                session.day), 0, 80, Screen.w, "center")

            for index, card in ipairs(session.generatedCards) do
                local x = 70 + (index - 1) * 300
                drawCard(g, card, x, 104, 260, 190,
                    focus == "generated" and index == generated)
            end

            local selected = session.generatedCards[generated]
            UiTheme.setColor(g, UiTheme.colors.heading)
            g.printf(focus == "generated" and "FOCUS: GENERATED CHOICES" or "FOCUS: COLLECTION",
                0, 308, Screen.w, "center")
            UiTheme.setColor(g, UiTheme.colors.text)
            g.printf(selected and ("Selected choice: " .. selected.name) or "Generating cards...",
                0, 330, Screen.w, "center")

            UiTheme.setColor(g, UiTheme.colors.heading)
            g.printf(("YOUR COLLECTION: %d card(s)   %d / %d"):format(
                #session.collection, collection, math.max(1, #session.collection)), 90, 365, 430, "left")
            local owned = session.collection[collection]
            if owned then
                drawCard(g, owned, 90, 390, 390, 92, focus == "collection")
            else
                UiTheme.drawPanel(g, 90, 390, 390, 92, focus == "collection")
                UiTheme.setColor(g, UiTheme.colors.text)
                g.printf(cardText(nil), 102, 404, 366, "left")
            end

            UiTheme.drawPanel(g, 510, 380, 360, 105, false)
            if session.cardChosenThisDay then
                local acquired = session.collection[#session.collection]
                UiTheme.setColor(g, UiTheme.colors.positive)
                g.printf("Acquired: " .. (acquired and acquired.name or "card") .. ".",
                    522, 400, 336, "center")
            else
                UiTheme.setColor(g, UiTheme.colors.muted)
                g.printf("Choose one generated card\nto add it to your collection.",
                    522, 400, 336, "center")
            end
            UiTheme.drawPanel(g, 80, 496, 800, 32, false)
            UiTheme.setColor(g, UiTheme.colors.muted)
            g.printf(session.cardChosenThisDay
                and "ENTER: begin the next day"
                or "LEFT/RIGHT or A/D: navigate     TAB: switch focus     ENTER: acquire",
                0, 505, Screen.w, "center")
        end,
    })
end

CardRenderSystem.cardText = cardText
CardRenderSystem.categoryColor = categoryColor
CardRenderSystem.sourceText = sourceText
CardRenderSystem.drawCardArt = drawCardArt
return CardRenderSystem
