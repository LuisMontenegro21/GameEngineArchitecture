-- Transient state owned by the reusable Academy location Scene.
local GameSession = require("src.game.session.GameSession")
local LocationCatalog = require("src.game.locations.LocationCatalog")

local Resources = {}

local function finite(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

local function point(value)
    return type(value) == "table" and finite(value.x) and finite(value.y)
end

local function locationState(value)
    local dialogue = value and value.dialogue
    local validDialogue = dialogue == false or (type(dialogue) == "table"
        and type(dialogue.characterId) == "string" and dialogue.characterId ~= ""
        and type(dialogue.targetName) == "string" and dialogue.targetName ~= ""
        and type(dialogue.lines) == "table" and #dialogue.lines > 0
        and type(dialogue.lineIndex) == "number" and dialogue.lineIndex % 1 == 0
        and dialogue.lineIndex >= 1 and dialogue.lineIndex <= #dialogue.lines)
    return type(value) == "table"
        and (value.focusKind == "activity" or value.focusKind == "character" or value.focusKind == "exit")
        and type(value.focusIndex) == "number" and value.focusIndex % 1 == 0 and value.focusIndex >= 1
        and validDialogue
        and type(value.feedback) == "string"
        and type(value.transitionQueued) == "boolean"
end

local function dailyConversationState(value)
    return value == false or (type(value) == "table"
        and type(value.day) == "number" and value.day % 1 == 0 and value.day >= 1
        and type(value.targetCharacterId) == "string" and value.targetCharacterId ~= ""
        and type(value.targetName) == "string" and value.targetName ~= ""
        and type(value.targetLocationId) == "string" and value.targetLocationId ~= ""
        and type(value.targetLocationName) == "string" and value.targetLocationName ~= ""
        and (value.preferredCategory == "confidence" or value.preferredCategory == "empathy"
            or value.preferredCategory == "knowledge" or value.preferredCategory == "balanced")
        and type(value.prompt) == "string" and value.prompt ~= ""
        and type(value.open) == "boolean"
        and type(value.resolved) == "boolean"
        and type(value.transitionQueued) == "boolean"
        and type(value.feedback) == "string")
end

function Resources.register(world)
    world:registerResource("gameSession", { validate = GameSession.validate })
    world:registerResource("locationDefinition", {
        validate = function(value)
            return LocationCatalog.validateEntry(value)
        end,
    })
    world:registerResource("locationReturnTarget", {
        validate = function(value) return type(value) == "string" and value ~= "" end,
    })
    world:registerResource("mapReturnPosition", { transient = true, validate = point })
    world:registerResource("locationState", { transient = true, validate = locationState })
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
end

return Resources
