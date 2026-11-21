-- Plain-data Wizard Academia conversation cards. Rendering stays separate.
local CardCatalog = {}

local validCategories = {
    confidence = true,
    empathy = true,
    knowledge = true,
    balanced = true,
}

local function integer(value, minimum)
    return type(value) == "number" and value % 1 == 0 and value >= minimum
end
-- twelve cards, might add more later?
local catalog = {
    confidence = {
        { id = "dazzling_introduction", name = "Dazzling Introduction", description = "Open with a small, charming illusion.", power = 2, cost = 1, symbol = "star" },
        { id = "playful_illusion", name = "Playful Illusion", description = "Turn an awkward pause into a shared laugh.", power = 2, cost = 1, symbol = "spark" },
        { id = "honest_invitation", name = "Honest Invitation", description = "Say what you mean with confidence.", power = 3, cost = 2, symbol = "moon" },
    },
    empathy = {
        { id = "calming_charm", name = "Calming Charm", description = "Help someone feel safe during an awkward moment.", power = 2, cost = 1, symbol = "heart" },
        { id = "thoughtful_question", name = "Thoughtful Question", description = "Ask about something that matters to them.", power = 2, cost = 1, symbol = "leaf" },
        { id = "familiar_friend", name = "Familiar Friend", description = "Offer gentle help with a restless familiar.", power = 3, cost = 2, symbol = "paw" },
    },
    knowledge = {
        { id = "shared_research", name = "Shared Research", description = "Discuss a difficult magical theory together.", power = 2, cost = 1, symbol = "rune" },
        { id = "constellation_trivia", name = "Constellation Trivia", description = "Recognize a story hidden in the night sky.", power = 2, cost = 1, symbol = "star" },
        { id = "ancient_riddle", name = "Ancient Riddle", description = "Solve an old academy puzzle together.", power = 3, cost = 2, symbol = "book" },
    },
    balanced = {
        { id = "comfortable_silence", name = "Comfortable Silence", description = "Let a quiet moment feel natural.", power = 2, cost = 1, symbol = "cloud" },
        { id = "stargazing_together", name = "Stargazing Together", description = "Share a simple view of the evening sky.", power = 2, cost = 1, symbol = "moon" },
        { id = "genuine_connection", name = "Genuine Connection", description = "Find a moment of mutual understanding.", power = 3, cost = 2, symbol = "heart" },
    },
}

local function copy(card, category)
    return { id = card.id, name = card.name, description = card.description,
        category = category, power = card.power, cost = card.cost, symbol = card.symbol }
end

function CardCatalog.categories()
    return { "confidence", "empathy", "knowledge", "balanced" }
end

function CardCatalog.forCategory(category)
    local cards = catalog[category]
    assert(cards ~= nil, "unknown card category: " .. tostring(category))
    local result = {}
    for index, card in ipairs(cards) do result[index] = copy(card, category) end
    return result
end

function CardCatalog.count()
    local count = 0
    for _, category in ipairs(CardCatalog.categories()) do count = count + #catalog[category] end
    return count
end

function CardCatalog.validate(card)
    return type(card) == "table"
        and type(card.id) == "string" and card.id ~= ""
        and type(card.name) == "string" and card.name ~= ""
        and type(card.description) == "string" and card.description ~= ""
        and validCategories[card.category] == true
        and integer(card.power, 0)
        and integer(card.cost, 0)
        and type(card.symbol) == "string" and card.symbol ~= ""
end

return CardCatalog
