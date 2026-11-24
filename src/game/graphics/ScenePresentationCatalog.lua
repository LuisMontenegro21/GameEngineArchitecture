-- Renderer-only scene background metadata. These stable IDs and optional PNG
-- paths never enter ECS Worlds or persistent game sessions.
local ScenePresentationCatalog = {}

local entries = {
    training = {
        id = "training", path = "assets/wizard_academia/backgrounds/training.png",
        nativeW = 960, nativeH = 540,
        fallback = { r = 0.06, g = 0.04, b = 0.12, a = 1 },
    },
    cardAcquisition = {
        id = "cardAcquisition", path = "assets/wizard_academia/backgrounds/card-acquisition.png",
        nativeW = 960, nativeH = 540,
        fallback = { r = 0.06, g = 0.04, b = 0.12, a = 1 },
    },
    finalConversation = {
        id = "finalConversation", path = "assets/wizard_academia/backgrounds/homecoming-night.png",
        nativeW = 960, nativeH = 540,
        fallback = { r = 0.06, g = 0.04, b = 0.12, a = 1 },
    },
    arcaneComplete = {
        id = "arcaneComplete", path = "assets/wizard_academia/backgrounds/homecoming-night.png",
        nativeW = 960, nativeH = 540,
        fallback = { r = 0.06, g = 0.04, b = 0.12, a = 1 },
    },
}

local function positiveInteger(value)
    return type(value) == "number" and value > 0 and value == math.floor(value)
end

local function color(value)
    return type(value) == "table"
        and type(value.r) == "number" and value.r >= 0 and value.r <= 1
        and type(value.g) == "number" and value.g >= 0 and value.g <= 1
        and type(value.b) == "number" and value.b >= 0 and value.b <= 1
        and type(value.a) == "number" and value.a >= 0 and value.a <= 1
end

local function copy(entry)
    return {
        id = entry.id,
        path = entry.path,
        nativeW = entry.nativeW,
        nativeH = entry.nativeH,
        fallback = {
            r = entry.fallback.r,
            g = entry.fallback.g,
            b = entry.fallback.b,
            a = entry.fallback.a,
        },
    }
end

function ScenePresentationCatalog.validate(entry)
    return type(entry) == "table"
        and type(entry.id) == "string" and entry.id ~= ""
        and type(entry.path) == "string" and entry.path ~= ""
        and positiveInteger(entry.nativeW) and positiveInteger(entry.nativeH)
        and color(entry.fallback)
end

for id, entry in pairs(entries) do
    assert(entry.id == id and ScenePresentationCatalog.validate(entry),
        "invalid scene presentation: " .. tostring(id))
end

function ScenePresentationCatalog.get(id)
    local entry = entries[id]
    return entry and copy(entry) or nil
end

function ScenePresentationCatalog.all()
    local result = {}
    for id, entry in pairs(entries) do result[id] = copy(entry) end
    return result
end

return ScenePresentationCatalog
