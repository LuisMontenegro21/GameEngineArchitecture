-- Static, serializable Academy Garden layout. Movement and rendering systems
-- consume this data later; this module has no ECS or LOVE dependency.
local MapDefinition = {}
local SpriteCatalog = require("src.game.maps.SpriteCatalog")
local Activities = require("src.game.progression.Activities")

local function finite(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

local function nonEmptyString(value)
    return type(value) == "string" and value ~= ""
end

local function color(value)
    return type(value) == "table"
        and finite(value.r) and value.r >= 0 and value.r <= 1
        and finite(value.g) and value.g >= 0 and value.g <= 1
        and finite(value.b) and value.b >= 0 and value.b <= 1
        and (value.a == nil or (finite(value.a) and value.a >= 0 and value.a <= 1))
end

local function rectangle(value)
    return type(value) == "table"
        and finite(value.x) and finite(value.y)
        and finite(value.w) and value.w > 0
        and finite(value.h) and value.h > 0
end

local function within(bounds, value)
    return value.x >= bounds.x and value.y >= bounds.y
        and value.x + value.w <= bounds.x + bounds.w
        and value.y + value.h <= bounds.y + bounds.h
end

local function overlaps(left, right)
    return left.x < right.x + right.w and left.x + left.w > right.x
        and left.y < right.y + right.h and left.y + left.h > right.y
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

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[copy(key)] = copy(item) end
    return result
end

local function validSprite(value)
    return type(value) == "table"
        and nonEmptyString(value.key) and SpriteCatalog.has(value.key)
        and finite(value.offsetX) and finite(value.offsetY)
        and finite(value.scaleX) and value.scaleX > 0
        and finite(value.scaleY) and value.scaleY > 0
        and nonEmptyString(value.layer)
        and type(value.fallback) == "table"
        and (value.fallback.shape == "rectangle" or value.fallback.shape == "circle")
        and color(value.fallback.color)
end

local function validObstacle(value)
    return rectangle(value)
        and nonEmptyString(value.id)
        and validSprite(value.sprite)
        and (value.pointOfInterestId == nil or nonEmptyString(value.pointOfInterestId))
end

local function validDialogue(value)
    if type(value) ~= "table" or #value == 0 then return false end
    for _, line in ipairs(value) do
        if not nonEmptyString(line) then return false end
    end
    return true
end

local function validInteraction(value)
    return type(value) == "table"
        and nonEmptyString(value.prompt)
        and validDialogue(value.dialogue)
        and nonEmptyString(value.activityId)
        and Activities.get(value.activityId) ~= nil
end

local function validPointOfInterest(value)
    return type(value) == "table"
        and nonEmptyString(value.id)
        and nonEmptyString(value.name)
        and nonEmptyString(value.subtitle)
        and rectangle(value.trigger)
        and validInteraction(value.interaction)
end

local layout = {
    bounds = { x = 32, y = 56, w = 896, h = 448 },
    spawn = { x = 471, y = 470 },
    playerFootprint = { w = 18, h = 14 },
    obstacles = {
        {
            id = "central_academy_tree", x = 438, y = 258, w = 100, h = 84,
            sprite = {
                key = "academy_tree", offsetX = 2, offsetY = -28, scaleX = 1, scaleY = 1, layer = "scenery",
                fallback = { shape = "circle", color = { r = 0.18, g = 0.42, b = 0.20 } },
            },
        },
        {
            id = "library_walls", x = 90, y = 320, w = 175, h = 100,
            pointOfInterestId = "ancient_library",
            sprite = {
                key = "ancient_library", offsetX = -9, offsetY = -28, scaleX = 1, scaleY = 1, layer = "scenery",
                fallback = { shape = "rectangle", color = { r = 0.20, g = 0.34, b = 0.56 } },
            },
        },
        {
            id = "commons_walls", x = 700, y = 255, w = 170, h = 105,
            pointOfInterestId = "student_commons",
            sprite = {
                key = "student_commons", offsetX = -11, offsetY = -23, scaleX = 1, scaleY = 1, layer = "scenery",
                fallback = { shape = "rectangle", color = { r = 0.56, g = 0.34, b = 0.16 } },
            },
        },
        {
            id = "astral_platform", x = 115, y = 95, w = 190, h = 85,
            pointOfInterestId = "astral_court",
            sprite = {
                key = "astral_court", offsetX = -1, offsetY = -11, scaleX = 1, scaleY = 1, layer = "scenery",
                fallback = { shape = "circle", color = { r = 0.42, g = 0.25, b = 0.66 } },
            },
        },
        {
            id = "quiet_pond", x = 630, y = 105, w = 205, h = 90,
            pointOfInterestId = "quiet_garden",
            sprite = {
                key = "quiet_pond", offsetX = -10, offsetY = -6, scaleX = 1, scaleY = 1, layer = "scenery",
                fallback = { shape = "circle", color = { r = 0.18, g = 0.58, b = 0.70 } },
            },
        },
        {
            id = "garden_hedge", x = 340, y = 405, w = 55, h = 45,
            sprite = {
                key = "garden_hedge", offsetX = -5, offsetY = -19, scaleX = 1, scaleY = 1, layer = "scenery",
                fallback = { shape = "rectangle", color = { r = 0.12, g = 0.38, b = 0.18 } },
            },
        },
    },
    pointsOfInterest = {
        {
            id = "ancient_library", name = "Ancient Library",
            subtitle = "Rune studies are held here.",
            trigger = { x = 275, y = 345, w = 60, h = 60 },
            interaction = {
                prompt = "Press E to inspect",
                activityId = "study_ancient_runes",
                dialogue = {
                    "Shelves of annotated runes rise above the reading tables.",
                    "A focused study session could sharpen your magical knowledge.",
                },
            },
        },
        {
            id = "student_commons", name = "Student Commons",
            subtitle = "A place to help classmates and connect.",
            trigger = { x = 635, y = 285, w = 55, h = 55 },
            interaction = {
                prompt = "Press E to inspect",
                activityId = "help_a_classmate",
                dialogue = {
                    "Students trade stories and compare notes between lessons.",
                    "There may be someone here who could use a little help.",
                },
            },
        },
        {
            id = "astral_court", name = "Astral Practice Court",
            subtitle = "Spell rehearsal takes place here.",
            trigger = { x = 185, y = 190, w = 70, h = 32 },
            interaction = {
                prompt = "Press E to inspect",
                activityId = "practice_spells",
                dialogue = {
                    "The practice sigils hum softly beneath your feet.",
                    "A careful rehearsal here could build your confidence.",
                },
            },
        },
        {
            id = "quiet_garden", name = "Quiet Garden",
            subtitle = "A peaceful place for meditation.",
            trigger = { x = 700, y = 205, w = 65, h = 32 },
            interaction = {
                prompt = "Press E to inspect",
                activityId = "meditate",
                dialogue = {
                    "The garden is quiet enough to hear the leaves shift overhead.",
                    "A calm moment here could help you regain your balance.",
                },
            },
        },
    },
}

function MapDefinition.validate(value)
    if type(value) ~= "table" or not rectangle(value.bounds)
        or type(value.spawn) ~= "table" or not finite(value.spawn.x) or not finite(value.spawn.y)
        or type(value.playerFootprint) ~= "table"
        or not finite(value.playerFootprint.w) or value.playerFootprint.w <= 0
        or not finite(value.playerFootprint.h) or value.playerFootprint.h <= 0
        or type(value.obstacles) ~= "table" or #value.obstacles == 0
        or type(value.pointsOfInterest) ~= "table" or #value.pointsOfInterest < 4 then
        return false
    end

    local spawn = {
        x = value.spawn.x,
        y = value.spawn.y,
        w = value.playerFootprint.w,
        h = value.playerFootprint.h,
    }
    if not within(value.bounds, spawn) then return false end

    local ids, points, owners = {}, {}, {}
    for _, obstacle in ipairs(value.obstacles) do
        if not validObstacle(obstacle) or not within(value.bounds, obstacle)
            or ids[obstacle.id] then return false end
        ids[obstacle.id] = true
        if obstacle.pointOfInterestId then
            if owners[obstacle.pointOfInterestId] then return false end
            owners[obstacle.pointOfInterestId] = true
        end
        if overlaps(spawn, obstacle) then return false end
    end

    for _, point in ipairs(value.pointsOfInterest) do
        if not validPointOfInterest(point) or not within(value.bounds, point.trigger)
            or ids[point.id] or points[point.id] then return false end
        ids[point.id] = true
        points[point.id] = true
        for _, obstacle in ipairs(value.obstacles) do
            if overlaps(point.trigger, obstacle) then return false end
        end
    end
    for pointId in pairs(owners) do if not points[pointId] then return false end end
    for pointId in pairs(points) do if not owners[pointId] then return false end end
    return plain(value)
end

assert(MapDefinition.validate(layout), "invalid Academy Garden map definition")

function MapDefinition.get()
    return copy(layout)
end

return MapDefinition
