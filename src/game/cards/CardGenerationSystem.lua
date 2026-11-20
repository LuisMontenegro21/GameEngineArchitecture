local Activities = require("src.game.progression.Activities")
local CardCatalog = require("src.game.cards.CardCatalog")

local CardGenerationSystem = {}

local function dominantCategory(stats)
    local highest = math.max(stats.confidence, stats.empathy, stats.arcaneKnowledge)
    local leaders = 0
    if stats.confidence == highest then leaders = leaders + 1 end
    if stats.empathy == highest then leaders = leaders + 1 end
    if stats.arcaneKnowledge == highest then leaders = leaders + 1 end
    if leaders ~= 1 then return "balanced" end
    if stats.confidence == highest then return "confidence" end
    if stats.empathy == highest then return "empathy" end
    return "knowledge"
end

local function activityCategory(activityId)
    local activity = activityId and Activities.get(activityId) or nil
    return activity and activity.cardCategory or "balanced"
end

local function nextUnique(category, used)
    for _, card in ipairs(CardCatalog.forCategory(category)) do
        if not used[card.id] then
            used[card.id] = true
            return card
        end
    end
    error("card category does not contain enough unique cards: " .. category)
end

function CardGenerationSystem.generate(session)
    local used = {}
    local categories = {
        dominantCategory(session.stats),
        activityCategory(session.lastActivity),
        "balanced",
    }
    local cards = {}
    for index, category in ipairs(categories) do
        cards[index] = nextUnique(category, used)
    end
    return cards
end

function CardGenerationSystem.install(scheduler)
    scheduler:addSystem({
        name = "cardGeneration",
        stage = "startup",
        readsResources = { "gameSession" },
        writesResources = { "gameSession", "generatedCardSelection" },
        run = function(context)
            local world = context.world
            context.emit("cardGenerationRequested")
            local session = world:requireResource("gameSession")
            local cards = CardGenerationSystem.generate(session)
            session.generatedCards = cards
            session.generatedSelection = 1
            world:setResource("gameSession", session)
            world:setResource("generatedCardSelection", 1)
            context.emit("cardsGenerated", { cards = cards })
        end,
    })
end

return CardGenerationSystem
