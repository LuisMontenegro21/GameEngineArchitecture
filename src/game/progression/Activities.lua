-- Data catalog for the Arcane Hearts Training Scene.
local Activities = {}

local catalog = {
    practice_illusions = {
        id = "practice_illusions",
        name = "Practice Illusions",
        energyCost = 1,
        effects = { confidence = 2 },
        feedback = "Your illusion fills the hall with floating stars. Confidence +2.",
        cardCategory = "confidence",
    },
    care_for_familiar = {
        id = "care_for_familiar",
        name = "Care for a Familiar",
        energyCost = 1,
        effects = { empathy = 2 },
        feedback = "A nervous familiar relaxes in your care. Empathy +2.",
        cardCategory = "empathy",
    },
    study_ancient_runes = {
        id = "study_ancient_runes",
        name = "Study Ancient Runes",
        energyCost = 1,
        effects = { arcaneKnowledge = 2 },
        feedback = "A difficult rune finally makes sense. Arcane Knowledge +2.",
        cardCategory = "knowledge",
    },
    meditate = {
        id = "meditate",
        name = "Meditate",
        energyCost = 0,
        effects = { energy = 2 },
        feedback = "You focus beneath the moonlight. Energy +2.",
        cardCategory = "balanced",
    },
}

local order = {
    "practice_illusions",
    "care_for_familiar",
    "study_ancient_runes",
    "meditate",
}

local function copy(activity)
    return {
        id = activity.id,
        name = activity.name,
        energyCost = activity.energyCost,
        effects = { confidence = activity.effects.confidence, empathy = activity.effects.empathy,
            arcaneKnowledge = activity.effects.arcaneKnowledge, energy = activity.effects.energy },
        feedback = activity.feedback,
        cardCategory = activity.cardCategory,
    }
end

function Activities.get(id)
    local activity = catalog[id]
    return activity and copy(activity) or nil
end

function Activities.all()
    local result = {}
    for index, id in ipairs(order) do result[index] = copy(catalog[id]) end
    return result
end

return Activities
