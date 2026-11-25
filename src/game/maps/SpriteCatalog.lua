-- Plain sprite metadata. Rendering resolves these keys through caches at draw time.
local SpriteCatalog = {}

local entries = {
    { key = "player_idle", path = "assets/wizard_academia/characters/main-char-walk.png", frameW = 32, frameH = 48 },
    { key = "academy_tree", path = "assets/wizard_academia/maps/academy-tree.png", frameW = 96, frameH = 112 },
    { key = "ancient_library", path = "assets/wizard_academia/map/ancient-library.png", frameW = 192, frameH = 128 },
    { key = "student_commons", path = "assets/wizard_academia/map/student-commons.png", frameW = 192, frameH = 128 },
    { key = "astral_court", path = "assets/wizard_academia/map/astral-court.png", frameW = 192, frameH = 96 },
    { key = "quiet_garden", path = "assets/wizard_academia/map/quiet-garden.png", frameW = 224, frameH = 112 },
    { key = "quiet_pond", path = "assets/wizard_academia/map/quiet-pond.png", frameW = 224, frameH = 96 },
    { key = "garden_hedge", path = "assets/wizard_academia/map/garden-hedge.png", frameW = 64, frameH = 64 },
    { key = "mentor_overworld", path = "assets/wizard_academia/characters/prof-elian-walk.png", frameW = 32, frameH = 48 },
    { key = "crush_overworld", path = "assets/wizard_academia/characters/rowan-walk.png", frameW = 32, frameH = 48 },
    { key = "outgoing_peer_overworld", path = "assets/wizard_academia/characters/mira-walk.png", frameW = 32, frameH = 48 },
    { key = "studious_peer_overworld", path = "assets/wizard_academia/characters/tomas-walk-32.png", frameW = 32, frameH = 48 },
}

local function positiveInteger(value)
    return type(value) == "number" and value > 0 and value == math.floor(value)
end

local function nonEmptyString(value)
    return type(value) == "string" and value ~= ""
end

function SpriteCatalog.validate(value)
    if type(value) ~= "table" then return false end
    local seen = {}
    for _, sprite in ipairs(value) do
        if type(sprite) ~= "table" or not nonEmptyString(sprite.key)
            or seen[sprite.key] or not nonEmptyString(sprite.path)
            or not positiveInteger(sprite.frameW) or not positiveInteger(sprite.frameH) then
            return false
        end
        seen[sprite.key] = true
    end
    return #value > 0
end

assert(SpriteCatalog.validate(entries), "invalid Wizard Academia sprite catalog")

local catalog = {}
for _, entry in ipairs(entries) do
    catalog[entry.key] = {
        path = entry.path,
        frameW = entry.frameW,
        frameH = entry.frameH,
    }
end

function SpriteCatalog.has(key)
    return catalog[key] ~= nil
end

function SpriteCatalog.get(key)
    return catalog[key]
end

function SpriteCatalog.all()
    local copy = {}
    for index, entry in ipairs(entries) do
        copy[index] = {
            key = entry.key,
            path = entry.path,
            frameW = entry.frameW,
            frameH = entry.frameH,
        }
    end
    return copy
end

return SpriteCatalog
