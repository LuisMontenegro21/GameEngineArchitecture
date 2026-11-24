-- Plain, deterministic micro-challenges for room activities. Completion is
-- intentionally separate from ActivityRules, which remains authoritative for
-- costs, stats, actions, and progression transitions.
local ActivityChallengeCatalog = {}

local definitions = {
    practice_spells = {
        activityId = "practice_spells",
        mode = "sequence",
        title = "Spell Rehearsal",
        prompt = "Trace the three runes in order to stabilize your spell.",
        steps = { "left", "up", "right" },
        completionFeedback = "The final rune clicks into place.",
    },
    study_ancient_runes = {
        activityId = "study_ancient_runes",
        mode = "sequence",
        title = "Rune Study",
        prompt = "Follow the sequence hidden in the ancient inscription.",
        steps = { "up", "left", "down" },
        completionFeedback = "The rune pattern becomes clear.",
    },
    help_a_classmate = {
        activityId = "help_a_classmate",
        mode = "choice",
        title = "Peer Support",
        prompt = "A classmate hesitates over a difficult lesson. How do you help?",
        options = {
            { id = "listen", label = "Listen before answering", feedback = "You give them space to explain their concern." },
            { id = "explain", label = "Explain the concept together", feedback = "You work through the difficult part together." },
            { id = "encourage", label = "Offer encouragement", feedback = "Your encouragement helps them try again." },
        },
    },
    meditate = {
        activityId = "meditate",
        mode = "choice",
        title = "Quiet Reflection",
        prompt = "The garden grows still. What do you focus on?",
        options = {
            { id = "breath", label = "Steady your breathing", feedback = "Your breath settles into a calm rhythm." },
            { id = "garden", label = "Observe the garden", feedback = "You notice small details in the quiet garden." },
            { id = "homecoming", label = "Visualize homecoming", feedback = "You picture yourself speaking with confidence." },
        },
    },
}

local validKeys = { up = true, down = true, left = true, right = true }

local function nonEmpty(value)
    return type(value) == "string" and value ~= ""
end

local function validOptions(options)
    if type(options) ~= "table" or #options < 2 then return false end
    local ids = {}
    for _, option in ipairs(options) do
        if type(option) ~= "table" or not nonEmpty(option.id) or ids[option.id]
            or not nonEmpty(option.label) or not nonEmpty(option.feedback) then return false end
        ids[option.id] = true
    end
    return true
end

function ActivityChallengeCatalog.validate(definition)
    if type(definition) ~= "table" or not nonEmpty(definition.activityId)
        or not nonEmpty(definition.title) or not nonEmpty(definition.prompt) then return false end
    if definition.mode == "sequence" then
        if type(definition.steps) ~= "table" or #definition.steps ~= 3
            or not nonEmpty(definition.completionFeedback) then return false end
        for _, key in ipairs(definition.steps) do if not validKeys[key] then return false end end
        return true
    end
    return definition.mode == "choice" and validOptions(definition.options)
end

for id, definition in pairs(definitions) do
    assert(id == definition.activityId and ActivityChallengeCatalog.validate(definition),
        "invalid activity challenge: " .. tostring(id))
end

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = copy(item) end
    return result
end

function ActivityChallengeCatalog.get(activityId)
    local definition = definitions[activityId]
    return definition and copy(definition) or nil
end

return ActivityChallengeCatalog
