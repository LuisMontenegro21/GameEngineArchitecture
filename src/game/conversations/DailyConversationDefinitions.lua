-- Plain definitions for the four map-based conversations before homecoming.
-- The fifth day intentionally uses the existing final conversation encounter.
local DailyConversationDefinitions = {}

local definitions = {
    [1] = {
        day = 1,
        targetCharacterId = "outgoing_peer",
        preferredCategory = "confidence",
        prompt = "Mira waves you over and invites you to start a conversation with the group.",
    },
    [2] = {
        day = 2,
        targetCharacterId = "studious_peer",
        preferredCategory = "knowledge",
        prompt = "Tomas has found a puzzling passage and asks what you make of it.",
    },
    [3] = {
        day = 3,
        targetCharacterId = "crush",
        preferredCategory = "empathy",
        prompt = "Rowan seems thoughtful today. This is a chance to listen with care.",
    },
    [4] = {
        day = 4,
        targetCharacterId = "crush",
        preferredCategory = "balanced",
        prompt = "Rowan suggests a quiet moment before the homecoming preparations begin.",
    },
}

local validCategories = {
    confidence = true,
    empathy = true,
    knowledge = true,
    balanced = true,
}

local function nonEmptyString(value)
    return type(value) == "string" and value ~= ""
end

local function copy(value)
    return {
        day = value.day,
        targetCharacterId = value.targetCharacterId,
        preferredCategory = value.preferredCategory,
        prompt = value.prompt,
    }
end

function DailyConversationDefinitions.validate(value)
    return type(value) == "table"
        and type(value.day) == "number" and value.day % 1 == 0 and value.day >= 1
        and nonEmptyString(value.targetCharacterId)
        and validCategories[value.preferredCategory] == true
        and nonEmptyString(value.prompt)
end

for day = 1, 4 do
    assert(DailyConversationDefinitions.validate(definitions[day]),
        "invalid daily conversation for day " .. day)
end

function DailyConversationDefinitions.get(day)
    local definition = definitions[day]
    return definition and copy(definition) or nil
end

return DailyConversationDefinitions
