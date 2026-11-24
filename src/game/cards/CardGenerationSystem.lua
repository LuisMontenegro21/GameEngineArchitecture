-- Generates day-seeded card drafts from plain session data. The local hash is
-- deterministic and deliberately does not touch Lua's global random state.
local Activities = require("src.game.progression.Activities")
local CardCatalog = require("src.game.cards.CardCatalog")

local CardGenerationSystem = {}

local HASH_MODULUS = 2147483647

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

local function categoryHash(category)
    local hash = 0
    for index = 1, #category do
        hash = (hash * 131 + category:byte(index)) % HASH_MODULUS
    end
    return hash
end

-- The day offset guarantees rotation whenever the current candidate pool has
-- more than one card, while the seed/category/slot hash fixes each run's
-- ordering without relying on math.random or LOVE state.
local function selectionIndex(runSeed, day, category, slot, count)
    assert(count >= 1, "card selection requires at least one candidate")
    local hash = (runSeed % HASH_MODULUS + categoryHash(category)) % HASH_MODULUS
    hash = (hash * 48271 + slot) % HASH_MODULUS
    return ((hash + day - 1) % count) + 1
end

local function ownedIds(collection)
    local ids = {}
    for _, card in ipairs(collection) do ids[card.id] = true end
    return ids
end

local function candidates(category, used, owned, avoidOwned)
    local result = {}
    for _, card in ipairs(CardCatalog.forCategory(category)) do
        if not used[card.id] and (not avoidOwned or not owned[card.id]) then
            result[#result + 1] = card
        end
    end
    return result
end

local function chooseCard(session, category, slot, used, owned)
    local available = candidates(category, used, owned, true)
    if #available == 0 then
        available = candidates(category, used, owned, false)
    end
    local card = available[selectionIndex(
        session.runSeed, session.day, category, slot, #available)]
    used[card.id] = true
    card.generationSource = {
        kind = slot == 1 and "dominantStat" or (slot == 2 and "lastActivity" or "balanced"),
        category = category,
        slot = slot,
    }
    return card
end

function CardGenerationSystem.sources(session)
    return {
        { kind = "dominantStat", category = dominantCategory(session.stats) },
        { kind = "lastActivity", category = activityCategory(session.lastActivity) },
        { kind = "balanced", category = "balanced" },
    }
end

function CardGenerationSystem.generate(session)
    local used = {}
    local owned = ownedIds(session.collection)
    local cards = {}
    for slot, source in ipairs(CardGenerationSystem.sources(session)) do
        cards[slot] = chooseCard(session, source.category, slot, used, owned)
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

CardGenerationSystem.dominantCategory = dominantCategory
CardGenerationSystem.activityCategory = activityCategory
CardGenerationSystem.selectionIndex = selectionIndex
return CardGenerationSystem
