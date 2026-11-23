local GameSession = require("src.game.session.GameSession")
local MapDefinition = require("src.game.maps.MapDefinition")
local TileGrid = require("src.game.maps.TileGrid")

local Resources = {}

local function finite(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

local function bounds(value)
    return type(value) == "table"
        and finite(value.x) and finite(value.y)
        and finite(value.w) and value.w > 0
        and finite(value.h) and value.h > 0
end

local function mapInput(value)
    if type(value) ~= "table" then return false end
    for _, key in ipairs({ "up", "down", "left", "right" }) do
        if type(value[key]) ~= "boolean" then return false end
    end
    if value.keys ~= nil then
        if type(value.keys) ~= "table" then return false end
        for _, pressed in pairs(value.keys) do
            if type(pressed) ~= "boolean" then return false end
        end
    end
    return true
end

local function nearbyPointOfInterest(value)
    return value == false or (type(value) == "table"
        and type(value.id) == "string" and value.id ~= ""
        and type(value.name) == "string" and value.name ~= ""
        and type(value.subtitle) == "string" and value.subtitle ~= "")
end

local function mapTerrain(value)
    return type(value) == "table" and TileGrid.validate(value.grid)
        and finite(value.cell) and value.cell > 0
        and finite(value.ox) and finite(value.oy)
end

function Resources.register(world)
    world:registerResource("gameSession", { validate = GameSession.validate })
    world:registerResource("mapDefinition", { validate = MapDefinition.validate })
    world:registerResource("mapTerrain", { transient = true, validate = mapTerrain })
    world:registerResource("mapInput", { transient = true, validate = mapInput })
    world:registerResource("mapBounds", { validate = bounds })
    world:registerResource("mapReturnTarget", {
        validate = function(value) return type(value) == "string" and value ~= "" end,
    })
    world:registerResource("nearbyPointOfInterest", {
        transient = true,
        validate = nearbyPointOfInterest,
    })
    world:registerResource("mapHudLocation", {
        transient = true,
        validate = nearbyPointOfInterest,
    })
    world:registerResource("mapTransitionQueued", {
        transient = true,
        validate = function(value) return type(value) == "boolean" end,
    })
end

return Resources
