-- Map-specific ECS components. These contracts remain independent from other
-- game features and from LOVE presentation objects.
local Components = {}
local SpriteCatalog = require("src.game.maps.SpriteCatalog")

local function finite(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

local function positive(value)
    return finite(value) and value > 0
end

local function rectangle(value)
    return type(value) == "table"
        and finite(value.x) and finite(value.y)
        and positive(value.w) and positive(value.h)
end

local function color(value)
    return type(value) == "table"
        and finite(value.r) and value.r >= 0 and value.r <= 1
        and finite(value.g) and value.g >= 0 and value.g <= 1
        and finite(value.b) and value.b >= 0 and value.b <= 1
        and (value.a == nil or (finite(value.a) and value.a >= 0 and value.a <= 1))
end

local function pointOfInterest(value)
    return type(value) == "table"
        and type(value.id) == "string" and value.id ~= ""
        and type(value.name) == "string" and value.name ~= ""
        and type(value.subtitle) == "string" and value.subtitle ~= ""
        and rectangle(value.trigger)
end

local function dialogueLines(value)
    if type(value) ~= "table" or #value == 0 then return false end
    for _, line in ipairs(value) do
        if type(line) ~= "string" or line == "" then return false end
    end
    return true
end

-- Generic map interaction metadata. Locations use this in Alpha 2; scheduled
-- character entities will reuse the same contract in Alpha 5.
local function mapInteractable(value)
    return type(value) == "table"
        and type(value.id) == "string" and value.id ~= ""
        and (value.kind == "location" or value.kind == "character")
        and type(value.name) == "string" and value.name ~= ""
        and type(value.prompt) == "string" and value.prompt ~= ""
        and rectangle(value.trigger)
        and dialogueLines(value.dialogue)
        and (value.activityId == nil or (type(value.activityId) == "string"
            and value.activityId ~= ""))
end

local function mapCharacter(value)
    return type(value) == "table"
        and type(value.id) == "string" and value.id ~= ""
        and type(value.displayName) == "string" and value.displayName ~= ""
        and type(value.role) == "string" and value.role ~= ""
        and type(value.locationId) == "string" and value.locationId ~= ""
        and type(value.interactionId) == "string" and value.interactionId ~= ""
end

local function sprite(value)
    if type(value) ~= "table" then return false end
    local allowed = {
        key = true, frame = true, row = true, scaleX = true, scaleY = true,
        offsetX = true, offsetY = true, layer = true, fallback = true,
    }
    for key in pairs(value) do
        if not allowed[key] then return false end
    end
    return type(value.key) == "string" and SpriteCatalog.has(value.key)
        and (value.frame == nil or (positive(value.frame) and value.frame == math.floor(value.frame)))
        and (value.row == nil or (positive(value.row) and value.row == math.floor(value.row)))
        and (value.scaleX == nil or positive(value.scaleX))
        and (value.scaleY == nil or positive(value.scaleY))
        and (value.offsetX == nil or finite(value.offsetX))
        and (value.offsetY == nil or finite(value.offsetY))
        and type(value.layer) == "string" and value.layer ~= ""
        and type(value.fallback) == "table"
        and (value.fallback.shape == "rectangle" or value.fallback.shape == "circle")
        and color(value.fallback.color)
end

function Components.register(world)
    world:registerComponent("mapPosition", {
        default = function() return { x = 0, y = 0 } end,
        validate = function(value)
            return type(value) == "table" and finite(value.x) and finite(value.y)
        end,
    })
    world:registerComponent("mapSize", {
        default = function() return { w = 1, h = 1 } end,
        validate = function(value)
            return type(value) == "table" and positive(value.w) and positive(value.h)
        end,
    })
    world:registerComponent("mapPlayer", { tag = true })
    world:registerComponent("mapCollider", {
        validate = function(value) return type(value) == "table" and value.solid == true end,
    })
    world:registerComponent("desiredMovement", {
        default = function() return { dx = 0, dy = 0 } end,
        validate = function(value)
            return type(value) == "table" and finite(value.dx) and finite(value.dy)
        end,
    })
    world:registerComponent("pointOfInterest", { validate = pointOfInterest })
    world:registerComponent("mapInteractable", { validate = mapInteractable })
    world:registerComponent("mapCharacter", { validate = mapCharacter })
    world:registerComponent("mapSprite", { validate = sprite })
end

return Components
