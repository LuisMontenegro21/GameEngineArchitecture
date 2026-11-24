-- Optional renderer-only images for micro-challenges. The timing challenge
-- falls back to shapes when these PNGs are absent, so presentation assets
-- never enter ECS state or affect challenge rules.
local ActivityChallengePresentationCatalog = {}

local entries = {
    spellRehearsalTiming = {
        id = "spellRehearsalTiming",
        trackPath = "assets/wizard_academia/activity-challenges/spell-rehearsal-track.png",
        trackW = 560,
        trackH = 24,
        markerPath = "assets/wizard_academia/activity-challenges/spell-rehearsal-marker.png",
        markerW = 24,
        markerH = 32,
    },
}

local function positiveInteger(value)
    return type(value) == "number" and value > 0 and value == math.floor(value)
end

local function copy(value)
    local result = {}
    for key, item in pairs(value) do result[key] = item end
    return result
end

function ActivityChallengePresentationCatalog.validate(value)
    return type(value) == "table" and type(value.id) == "string" and value.id ~= ""
        and type(value.trackPath) == "string" and value.trackPath ~= ""
        and positiveInteger(value.trackW) and positiveInteger(value.trackH)
        and type(value.markerPath) == "string" and value.markerPath ~= ""
        and positiveInteger(value.markerW) and positiveInteger(value.markerH)
end

for id, entry in pairs(entries) do
    assert(id == entry.id and ActivityChallengePresentationCatalog.validate(entry),
        "invalid activity challenge presentation: " .. tostring(id))
end

function ActivityChallengePresentationCatalog.get(id)
    local entry = entries[id]
    return entry and copy(entry) or nil
end

return ActivityChallengePresentationCatalog
