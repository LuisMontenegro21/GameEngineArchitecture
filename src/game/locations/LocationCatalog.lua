-- Plain-data definitions for reusable Academy location scenes. Gameplay rules
-- remain in their existing systems; this catalog describes only room identity,
-- presentation, and stable interaction positions.
local Activities = require("src.game.progression.Activities")
local ScenePresentationCatalog = require("src.game.graphics.ScenePresentationCatalog")

local LocationCatalog = {}

local entries = {
    {
        id = "astral_court",
        name = "Astral Practice Court",
        backgroundId = "astralCourtInterior",
        activityId = "practice_spells",
        fallbackColor = { r = 0.20, g = 0.12, b = 0.34, a = 1 },
        entrance = { x = 480, y = 486 },
        activitySlot = { x = 680, y = 300 },
        characterSlots = {
            { id = "primary", x = 330, y = 315 },
            { id = "secondary", x = 450, y = 315 },
        },
    },
    {
        id = "student_commons",
        name = "Student Commons",
        backgroundId = "studentCommonsInterior",
        activityId = "help_a_classmate",
        fallbackColor = { r = 0.31, g = 0.19, b = 0.10, a = 1 },
        entrance = { x = 480, y = 486 },
        activitySlot = { x = 680, y = 300 },
        characterSlots = {
            { id = "primary", x = 330, y = 315 },
            { id = "secondary", x = 450, y = 315 },
        },
    },
    {
        id = "ancient_library",
        name = "Ancient Library",
        backgroundId = "ancientLibraryInterior",
        activityId = "study_ancient_runes",
        fallbackColor = { r = 0.12, g = 0.15, b = 0.28, a = 1 },
        entrance = { x = 480, y = 486 },
        activitySlot = { x = 680, y = 300 },
        characterSlots = {
            { id = "primary", x = 330, y = 315 },
            { id = "secondary", x = 450, y = 315 },
        },
    },
    {
        id = "quiet_garden",
        name = "Quiet Garden",
        backgroundId = "quietGardenInterior",
        activityId = "meditate",
        fallbackColor = { r = 0.10, g = 0.25, b = 0.16, a = 1 },
        entrance = { x = 480, y = 486 },
        activitySlot = { x = 680, y = 300 },
        characterSlots = {
            { id = "primary", x = 330, y = 315 },
            { id = "secondary", x = 450, y = 315 },
        },
    },
}

local function finite(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

local function nonEmptyString(value)
    return type(value) == "string" and value ~= ""
end

local function point(value)
    return type(value) == "table" and finite(value.x) and finite(value.y)
end

local function color(value)
    return type(value) == "table"
        and finite(value.r) and value.r >= 0 and value.r <= 1
        and finite(value.g) and value.g >= 0 and value.g <= 1
        and finite(value.b) and value.b >= 0 and value.b <= 1
        and finite(value.a) and value.a >= 0 and value.a <= 1
end

local function slots(value)
    if type(value) ~= "table" or #value == 0 then return false end
    local ids = {}
    for _, slot in ipairs(value) do
        if type(slot) ~= "table" or not nonEmptyString(slot.id) or ids[slot.id]
            or not point(slot) then
            return false
        end
        ids[slot.id] = true
    end
    return true
end

local function validEntry(entry)
    return type(entry) == "table"
        and nonEmptyString(entry.id)
        and nonEmptyString(entry.name)
        and nonEmptyString(entry.backgroundId)
        and ScenePresentationCatalog.get(entry.backgroundId) ~= nil
        and nonEmptyString(entry.activityId)
        and Activities.get(entry.activityId) ~= nil
        and color(entry.fallbackColor)
        and point(entry.entrance)
        and point(entry.activitySlot)
        and slots(entry.characterSlots)
end

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = copy(item) end
    return result
end

function LocationCatalog.validate(value)
    if type(value) ~= "table" or #value ~= 4 then return false end
    local ids = {}
    for _, entry in ipairs(value) do
        if not validEntry(entry) or ids[entry.id] then return false end
        ids[entry.id] = true
    end
    return true
end

function LocationCatalog.validateEntry(value)
    return validEntry(value)
end

assert(LocationCatalog.validate(entries), "invalid Academy location catalog")

local byId = {}
for _, entry in ipairs(entries) do byId[entry.id] = entry end

function LocationCatalog.get(id)
    local entry = byId[id]
    return entry and copy(entry) or nil
end

function LocationCatalog.all()
    return copy(entries)
end

function LocationCatalog.ids()
    local result = {}
    for index, entry in ipairs(entries) do result[index] = entry.id end
    return result
end

return LocationCatalog
