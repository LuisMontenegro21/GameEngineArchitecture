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

local function dialogueLines(value)
    if type(value) ~= "table" or #value == 0 then return false end
    for _, line in ipairs(value) do
        if type(line) ~= "string" or line == "" then return false end
    end
    return true
end

local function nearbyInteraction(value)
    return value == false or (type(value) == "table"
        and type(value.id) == "string" and value.id ~= ""
        and (value.kind == "location" or value.kind == "character")
        and type(value.name) == "string" and value.name ~= ""
        and type(value.prompt) == "string" and value.prompt ~= ""
        and dialogueLines(value.dialogue)
        and (value.activityId == nil or (type(value.activityId) == "string"
            and value.activityId ~= "")))
end

local function dialogueState(value)
    return value == false or (type(value) == "table"
        and type(value.targetId) == "string" and value.targetId ~= ""
        and type(value.targetName) == "string" and value.targetName ~= ""
        and dialogueLines(value.lines)
        and type(value.lineIndex) == "number" and value.lineIndex % 1 == 0
        and value.lineIndex >= 1 and value.lineIndex <= #value.lines
        and (value.activityId == nil or (type(value.activityId) == "string"
            and value.activityId ~= "")))
end

local function dailyConversationState(value)
    return value == false or (type(value) == "table"
        and type(value.day) == "number" and value.day % 1 == 0 and value.day >= 1
        and type(value.targetCharacterId) == "string" and value.targetCharacterId ~= ""
        and type(value.targetName) == "string" and value.targetName ~= ""
        and (value.preferredCategory == "confidence" or value.preferredCategory == "empathy"
            or value.preferredCategory == "knowledge" or value.preferredCategory == "balanced")
        and type(value.prompt) == "string" and value.prompt ~= ""
        and type(value.open) == "boolean"
        and type(value.resolved) == "boolean"
        and type(value.transitionQueued) == "boolean"
        and type(value.feedback) == "string")
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
    world:registerResource("mapReturnEnabled", {
        transient = true,
        validate = function(value) return type(value) == "boolean" end,
    })
    world:registerResource("nearbyPointOfInterest", {
        transient = true,
        validate = nearbyPointOfInterest,
    })
    world:registerResource("nearbyInteraction", {
        transient = true,
        validate = nearbyInteraction,
    })
    world:registerResource("dialogueState", {
        transient = true,
        validate = dialogueState,
    })
    world:registerResource("mapActivityFeedback", {
        transient = true,
        validate = function(value) return type(value) == "string" end,
    })
    world:registerResource("mapActivityTransitionQueued", {
        transient = true,
        validate = function(value) return type(value) == "boolean" end,
    })
    world:registerResource("dailyConversationState", {
        transient = true,
        validate = dailyConversationState,
    })
    world:registerResource("dailyConversationSelection", {
        transient = true,
        validate = function(value)
            return type(value) == "number" and value % 1 == 0 and value >= 1
        end,
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
