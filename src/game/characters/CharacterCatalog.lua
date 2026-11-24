-- Plain character identities and flavor dialogue. Sprite keys are resolved by
-- the map presentation layer, so this catalog never owns LOVE resources.
local CharacterCatalog = {}

local catalog = {
    mentor = {
        id = "mentor",
        displayName = "Professor Elian",
        role = "mentor",
        spriteKey = "mentor_overworld",
        fallback = { shape = "rectangle", color = { r = 0.55, g = 0.35, b = 0.75, a = 1 } },
        interactionId = "mentor_spell_lesson",
        dialogue = {
            "A steady hand makes even a difficult spell easier to learn.",
            "Practice with intention, and trust the progress you can already see.",
        },
    },
    crush = {
        id = "crush",
        displayName = "Rowan",
        role = "crush",
        spriteKey = "crush_overworld",
        fallback = { shape = "rectangle", color = { r = 0.91, g = 0.73, b = 0.29, a = 1 } },
        interactionId = "rowan_chat",
        dialogue = {
            "Oh, hello. The academy feels different when everyone is preparing for homecoming.",
            "It is nice to run into someone who enjoys the quiet corners of campus too.",
        },
    },
    outgoing_peer = {
        id = "outgoing_peer",
        displayName = "Mira",
        role = "outgoingPeer",
        spriteKey = "outgoing_peer_overworld",
        fallback = { shape = "rectangle", color = { r = 0.31, g = 0.66, b = 0.85, a = 1 } },
        interactionId = "mira_chat",
        dialogue = {
            "There you are! The commons are much more fun when someone joins in.",
            "A friendly hello can turn an ordinary afternoon into an adventure.",
        },
    },
    studious_peer = {
        id = "studious_peer",
        displayName = "Tomas",
        role = "studiousPeer",
        spriteKey = "studious_peer_overworld",
        fallback = { shape = "rectangle", color = { r = 0.61, g = 0.42, b = 0.83, a = 1 } },
        interactionId = "tomas_chat",
        dialogue = {
            "I found a curious footnote in the oldest section of the library.",
            "Sharing what you have learned is often the best way to understand it.",
        },
    },
}

local order = { "mentor", "crush", "outgoing_peer", "studious_peer" }

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = copy(item) end
    return result
end

local function nonEmptyString(value)
    return type(value) == "string" and value ~= ""
end

local function validDialogue(value)
    if type(value) ~= "table" or #value == 0 then return false end
    for _, line in ipairs(value) do if not nonEmptyString(line) then return false end end
    return true
end

local function validFallback(value)
    local color = value and value.color
    return type(value) == "table" and value.shape == "rectangle"
        and type(color) == "table"
        and type(color.r) == "number" and color.r >= 0 and color.r <= 1
        and type(color.g) == "number" and color.g >= 0 and color.g <= 1
        and type(color.b) == "number" and color.b >= 0 and color.b <= 1
        and type(color.a) == "number" and color.a >= 0 and color.a <= 1
end

function CharacterCatalog.validate(value)
    return type(value) == "table"
        and nonEmptyString(value.id)
        and nonEmptyString(value.displayName)
        and nonEmptyString(value.role)
        and nonEmptyString(value.spriteKey)
        and validFallback(value.fallback)
        and nonEmptyString(value.interactionId)
        and validDialogue(value.dialogue)
end

for _, id in ipairs(order) do
    assert(CharacterCatalog.validate(catalog[id]), "invalid character catalog entry: " .. id)
end

function CharacterCatalog.get(id)
    local character = catalog[id]
    return character and copy(character) or nil
end

function CharacterCatalog.all()
    local result = {}
    for index, id in ipairs(order) do result[index] = copy(catalog[id]) end
    return result
end

function CharacterCatalog.ids()
    local result = {}
    for index, id in ipairs(order) do result[index] = id end
    return result
end

return CharacterCatalog
