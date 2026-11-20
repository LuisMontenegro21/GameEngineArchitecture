-- Persistent, plain-data state shared by Arcane Hearts scenes. This object is
-- owned by the application layer, not by a Scene-local ECS World.
local GameSession = {}
local CardCatalog = require("src.game.cards.CardCatalog")

local DEFAULTS = {
    day = 1,
    maxDays = 5,
    actionsRemaining = 2,
    actionsPerDay = 2,
    energy = 3,
    maxEnergy = 5,
}

local function integer(value, minimum)
    return type(value) == "number" and value % 1 == 0 and value >= minimum
end

local function copyTable(value)
    local result = {}
    for key, item in pairs(value) do
        result[key] = type(item) == "table" and copyTable(item) or item
    end
    return result
end

local function plain(value, seen)
    local kind = type(value)
    if kind == "nil" or kind == "boolean" or kind == "number" or kind == "string" then
        return true
    end
    if kind ~= "table" then return false end
    seen = seen or {}
    if seen[value] then return false end
    seen[value] = true
    for key, item in pairs(value) do
        if not plain(key, seen) or not plain(item, seen) then return false end
    end
    seen[value] = nil
    return true
end

local function validCardList(cards, expectedCount, uniqueIds)
    if type(cards) ~= "table" then return false end
    if expectedCount ~= nil and #cards ~= expectedCount then return false end
    local ids = {}
    for _, card in ipairs(cards) do
        if not CardCatalog.validate(card) or (uniqueIds and ids[card.id]) then return false end
        ids[card.id] = true
    end
    return true
end

function GameSession.validate(session)
    return type(session) == "table"
        and integer(session.day, 1)
        and integer(session.maxDays, 1)
        and session.day <= session.maxDays + 1
        and integer(session.actionsRemaining, 0)
        and integer(session.actionsPerDay, 1)
        and session.actionsRemaining <= session.actionsPerDay
        and integer(session.energy, 0)
        and integer(session.maxEnergy, 1)
        and session.energy <= session.maxEnergy
        and type(session.stats) == "table"
        and integer(session.stats.confidence, 0)
        and integer(session.stats.empathy, 0)
        and integer(session.stats.arcaneKnowledge, 0)
        and (session.lastActivity == nil or type(session.lastActivity) == "string")
        and type(session.feedback) == "string"
        and validCardList(session.generatedCards, nil, true)
        and integer(session.generatedSelection, 1)
        and validCardList(session.collection)
        and integer(session.collectionSelection, 1)
        and type(session.cardChosenThisDay) == "boolean"
        and type(session.complete) == "boolean"
        and plain(session)
end

function GameSession.new(options)
    options = options or {}
    assert(type(options) == "table", "session options must be a table")
    local session = {
        day = options.day or DEFAULTS.day,
        maxDays = options.maxDays or DEFAULTS.maxDays,
        actionsRemaining = options.actionsRemaining or DEFAULTS.actionsRemaining,
        actionsPerDay = options.actionsPerDay or DEFAULTS.actionsPerDay,
        energy = options.energy or DEFAULTS.energy,
        maxEnergy = options.maxEnergy or DEFAULTS.maxEnergy,
        stats = { confidence = 0, empathy = 0, arcaneKnowledge = 0 },
        lastActivity = nil,
        feedback = "Choose a magical training activity.",
        generatedCards = {},
        generatedSelection = 1,
        collection = {},
        collectionSelection = 1,
        cardChosenThisDay = false,
        complete = false,
    }
    if options.stats then session.stats = copyTable(options.stats) end
    assert(GameSession.validate(session), "invalid game session")
    return session
end

function GameSession.copy(value)
    assert(GameSession.validate(value), "cannot copy invalid game session")
    return copyTable(value)
end

return GameSession
