-- Location-scene entities are presentation and interaction anchors only.
-- They retain plain data so sprites remain renderer-side cache objects.
local Components = {}
local SpriteCatalog = require("src.game.maps.SpriteCatalog")

local function finite(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

local function positive(value)
    return finite(value) and value > 0
end

local function color(value)
    return type(value) == "table"
        and finite(value.r) and value.r >= 0 and value.r <= 1
        and finite(value.g) and value.g >= 0 and value.g <= 1
        and finite(value.b) and value.b >= 0 and value.b <= 1
        and (value.a == nil or (finite(value.a) and value.a >= 0 and value.a <= 1))
end

local function locationCharacter(value)
    return type(value) == "table"
        and type(value.id) == "string" and value.id ~= ""
        and type(value.displayName) == "string" and value.displayName ~= ""
        and type(value.role) == "string" and value.role ~= ""
end

local function locationSprite(value)
    return type(value) == "table"
        and type(value.key) == "string" and SpriteCatalog.has(value.key)
        and type(value.frame) == "number" and value.frame >= 1 and value.frame % 1 == 0
        and type(value.row) == "number" and value.row >= 1 and value.row % 1 == 0
        and finite(value.offsetX) and finite(value.offsetY)
        and positive(value.scaleX) and positive(value.scaleY)
        and type(value.fallback) == "table"
        and (value.fallback.shape == "rectangle" or value.fallback.shape == "circle")
        and color(value.fallback.color)
end

function Components.register(world)
    world:registerComponent("locationPosition", {
        validate = function(value)
            return type(value) == "table" and finite(value.x) and finite(value.y)
        end,
    })
    world:registerComponent("locationSize", {
        validate = function(value)
            return type(value) == "table" and positive(value.w) and positive(value.h)
        end,
    })
    world:registerComponent("locationCharacter", { validate = locationCharacter })
    world:registerComponent("locationSprite", { validate = locationSprite })
end

return Components
