local CardCatalog = require("src.game.cards.CardCatalog")
local CardGenerationSystem = require("src.game.cards.CardGenerationSystem")
local GameSession = require("src.game.session.GameSession")
local CardRenderSystem = require("src.game.ui.CardRenderSystem")

local function cardIds(cards)
    local result = {}
    for index, card in ipairs(cards) do result[index] = card.id end
    return result
end

local function sameList(left, right)
    if #left ~= #right then return false end
    for index, value in ipairs(left) do
        if right[index] ~= value then return false end
    end
    return true
end

local function unique(cards)
    local ids = {}
    for _, card in ipairs(cards) do
        if ids[card.id] then return false end
        ids[card.id] = true
    end
    return true
end

local function contains(ids, id)
    for _, value in ipairs(ids) do
        if value == id then return true end
    end
    return false
end

return function()
    local base = GameSession.new({
        runSeed = 91,
        day = 1,
        stats = { confidence = 5, empathy = 1, arcaneKnowledge = 0 },
    })
    base.lastActivity = "help_a_classmate"
    local first = CardGenerationSystem.generate(base)
    local repeated = CardGenerationSystem.generate(base)
    assert(sameList(cardIds(first), cardIds(repeated)),
        "the same seed and session state must reproduce the same draft")
    assert(first[1].category == "confidence" and first[2].category == "empathy"
        and first[3].category == "balanced",
        "dominant stat and last activity must remain the draft category sources")
    assert(first[1].generationSource.kind == "dominantStat"
        and first[2].generationSource.kind == "lastActivity"
        and first[3].generationSource.kind == "balanced",
        "each generated card must retain presentation source metadata")
    assert(first[1].generationSource.slot == 1 and first[2].generationSource.slot == 2
        and first[3].generationSource.slot == 3,
        "source metadata must preserve deterministic option slots")
    assert(CardRenderSystem.sourceText(first[1]):find("Dominant stat", 1, true),
        "the card UI must explain a generated card's source metadata")
    assert(unique(first), "a generated three-card draft must not contain duplicate IDs")

    local tomorrow = GameSession.copy(base)
    tomorrow.day = 2
    local secondDay = CardGenerationSystem.generate(tomorrow)
    assert(not sameList(cardIds(first), cardIds(secondDay)),
        "different days must rotate at least one card while alternatives exist")

    local differentSeed = GameSession.copy(base)
    differentSeed.runSeed = 92
    assert(not sameList(cardIds(first), cardIds(CardGenerationSystem.generate(differentSeed))),
        "the run seed must influence card selection")

    local owned = GameSession.copy(base)
    owned.collection = {
        CardCatalog.forCategory("confidence")[1],
        CardCatalog.forCategory("empathy")[1],
        CardCatalog.forCategory("balanced")[1],
    }
    local ownedIds = cardIds(owned.collection)
    local avoided = CardGenerationSystem.generate(owned)
    for _, card in ipairs(avoided) do
        assert(not contains(ownedIds, card.id),
            "owned cards must be avoided while an unowned category card exists")
    end

    local repeatedCategory = GameSession.new({ runSeed = 7 })
    repeatedCategory.lastActivity = "meditate"
    local balancedDraft = CardGenerationSystem.generate(repeatedCategory)
    assert(balancedDraft[1].category == "balanced" and balancedDraft[2].category == "balanced"
        and balancedDraft[3].category == "balanced" and unique(balancedDraft),
        "repeated source categories must still yield three unique choices")

    local exhausted = GameSession.copy(base)
    exhausted.collection = {}
    for _, category in ipairs(CardCatalog.categories()) do
        for _, card in ipairs(CardCatalog.forCategory(category)) do
            exhausted.collection[#exhausted.collection + 1] = card
        end
    end
    local fallback = CardGenerationSystem.generate(exhausted)
    assert(#fallback == 3 and unique(fallback),
        "owned cards may return only after the applicable pool is exhausted")
end
