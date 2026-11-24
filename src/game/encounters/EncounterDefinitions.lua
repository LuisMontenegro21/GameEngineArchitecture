-- Plain-data rules for Wizard Academia's final conversation encounter.
-- Encounter systems consume this data; UI and persistent session state do not
-- own prompt text, scoring constants, or outcome thresholds.
local EncounterDefinitions = {}

local VALID_CATEGORIES = {
    confidence = true,
    empathy = true,
    knowledge = true,
    balanced = true,
}

local definition = {
    partnerName = "Rowan",
    startingFocus = 5,
    categoryMatchBonus = 2,
    maximumReadinessBonus = 3,
    prompts = {
        {
            id = "astral_theory",
            text = "Before the homecoming lanterns are lit, Rowan asks what gave you the courage to come over.",
            preferredCategory = "knowledge",
        },
        {
            id = "quiet_confession",
            text = "Rowan admits feeling nervous about the evening. How do you answer with care?",
            preferredCategory = "empathy",
        },
        {
            id = "moonlit_invitation",
            text = "The music begins in the distance. Can you ask Rowan to attend homecoming with you?",
            preferredCategory = "confidence",
        },
    },
    endings = {
        {
            id = "promising_friendship",
            minimumRapport = 0,
            title = "A Gentle Promise",
            text = "Rowan appreciates your honesty. It was not the answer you hoped for, but you leave with a warmer understanding of one another.",
        },
        {
            id = "growing_connection",
            minimumRapport = 8,
            title = "A Hopeful Yes",
            text = "Rowan smiles and agrees to spend homecoming with you. The evening begins with an excited, meaningful connection.",
        },
        {
            id = "arcane_hearts",
            minimumRapport = 12,
            title = "Homecoming Hearts",
            text = "Your courage, care, and curiosity make the invitation unforgettable. Rowan happily takes your hand as the celebration begins.",
        },
    },
}

local function integer(value, minimum)
    return type(value) == "number" and value % 1 == 0 and value >= minimum
end

local function nonEmptyString(value)
    return type(value) == "string" and value ~= ""
end

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = copy(item) end
    return result
end

local function plain(value, seen)
    local kind = type(value)
    if kind == "nil" or kind == "boolean" or kind == "number" or kind == "string" then return true end
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

function EncounterDefinitions.validate(value)
    if type(value) ~= "table"
        or not nonEmptyString(value.partnerName)
        or not integer(value.startingFocus, 0)
        or not integer(value.categoryMatchBonus, 0)
        or not integer(value.maximumReadinessBonus, 0)
        or type(value.prompts) ~= "table" or #value.prompts ~= 3
        or type(value.endings) ~= "table" or #value.endings < 2 then
        return false
    end

    local promptIds = {}
    for _, prompt in ipairs(value.prompts) do
        if type(prompt) ~= "table"
            or not nonEmptyString(prompt.id)
            or promptIds[prompt.id]
            or not nonEmptyString(prompt.text)
            or not VALID_CATEGORIES[prompt.preferredCategory] then
            return false
        end
        promptIds[prompt.id] = true
    end

    local endingIds = {}
    local previousMinimum = nil
    for index, ending in ipairs(value.endings) do
        if type(ending) ~= "table"
            or not nonEmptyString(ending.id)
            or endingIds[ending.id]
            or not integer(ending.minimumRapport, 0)
            or not nonEmptyString(ending.title)
            or not nonEmptyString(ending.text)
            or (index == 1 and ending.minimumRapport ~= 0)
            or (previousMinimum and ending.minimumRapport <= previousMinimum) then
            return false
        end
        endingIds[ending.id] = true
        previousMinimum = ending.minimumRapport
    end

    return plain(value)
end

function EncounterDefinitions.get()
    return copy(definition)
end

-- Returns an isolated ending record using the same ordered thresholds that
-- encounter progression persists into GameSession.
function EncounterDefinitions.endingForRapport(rapport)
    assert(integer(rapport, 0), "rapport must be a non-negative integer")
    local selected = definition.endings[1]
    for _, ending in ipairs(definition.endings) do
        if rapport >= ending.minimumRapport then selected = ending end
    end
    return copy(selected)
end

function EncounterDefinitions.readinessBonus(readiness)
    assert(integer(readiness, 0), "homecoming readiness must be a non-negative integer")
    return math.min(definition.maximumReadinessBonus, math.floor(readiness / 5))
end

return EncounterDefinitions
