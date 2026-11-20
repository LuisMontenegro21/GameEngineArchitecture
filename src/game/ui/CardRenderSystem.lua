-- Rendering is intentionally separate from generation, selection, and storage.
local Screen = require("src.game.Screen")

local CardRenderSystem = {}

local function cardText(card)
    if not card then return "No card selected." end
    return ("%s [%s]\n%s\nPower %d  Cost %d"):format(
        card.name, card.category, card.description, card.power, card.cost)
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
            g.clear(0.06, 0.04, 0.12, 1)
            g.setColor(0.9, 0.82, 1, 1)
            g.printf("Choose a Conversation Card", 0, 24, Screen.w, "center")
            g.setColor(0.75, 0.84, 1, 1)
            g.printf(("Choices reflect your current training: Confidence %d, Empathy %d, Knowledge %d"):format(
                session.stats.confidence, session.stats.empathy, session.stats.arcaneKnowledge),
                0, 52, Screen.w, "center")
            for index, card in ipairs(session.generatedCards) do
                local x = 80 + (index - 1) * 290
                if focus == "generated" and index == generated then
                    g.setColor(0.38, 0.24, 0.6, 1)
                    g.rectangle("fill", x - 8, 94, 266, 192)
                end
                g.setColor(1, 1, 1, 1)
                g.rectangle("line", x - 8, 94, 266, 192)
                g.printf(cardText(card), x, 112, 250, "left")
            end
            local selected = session.generatedCards[generated]
            g.setColor(0.8, 0.9, 1, 1)
            g.printf(selected and ("Selected: " .. selected.name) or "Generating cards...",
                0, 305, Screen.w, "center")
            g.setColor(1, 1, 1, 1)
            g.printf(("Collection  %d card(s)  —  %d / %d"):format(
                #session.collection, collection, math.max(1, #session.collection)), 80, 350, 360, "left")
            local owned = session.collection[collection]
            if focus == "collection" then g.setColor(0.38, 0.24, 0.6, 1); g.rectangle("fill", 72, 377, 360, 86) end
            g.setColor(1, 1, 1, 1)
            g.rectangle("line", 72, 377, 360, 86)
            g.printf(cardText(owned), 86, 388, 335, "left")
            g.setColor(0.7, 0.7, 0.7, 1)
            g.printf(session.cardChosenThisDay
                and "ENTER: begin the next day"
                or "LEFT/RIGHT: navigate     TAB: collection     ENTER: acquire selected card",
                0, 500, Screen.w, "center")
        end,
    })
end

return CardRenderSystem
