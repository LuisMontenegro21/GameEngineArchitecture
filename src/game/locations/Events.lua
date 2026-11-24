-- Location-scene input and transition events remain plain data at the scene
-- boundary, matching the map and other ECS-backed scenes.
local Events = {}
local GameSession = require("src.game.session.GameSession")

local function plain(value, seen)
    local kind = type(value)
    if kind == "nil" or kind == "boolean" or kind == "number" or kind == "string" then return true end
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

function Events.register(world)
    world:registerEvent("keyPressed", {
        validate = function(value)
            return type(value) == "table" and type(value.key) == "string" and value.key ~= ""
                and plain(value)
        end,
        maxQueue = 32,
    })
    world:registerEvent("keyReleased", {
        validate = function(value)
            return type(value) == "table" and type(value.key) == "string" and value.key ~= ""
                and plain(value)
        end,
        maxQueue = 32,
    })
    world:registerEvent("locationExitRequested", {
        validate = function(value) return value == nil end,
        maxQueue = 2,
    })
    world:registerEvent("locationActivityRequested", {
        validate = function(value)
            return type(value) == "table" and type(value.activityId) == "string"
                and value.activityId ~= ""
                and (value.challengeFeedback == nil or (type(value.challengeFeedback) == "string"
                    and value.challengeFeedback ~= ""))
                and plain(value)
        end,
        maxQueue = 2,
    })
    world:registerEvent("locationActivityChallengeRequested", {
        validate = function(value)
            return type(value) == "table" and type(value.activityId) == "string"
                and value.activityId ~= "" and plain(value)
        end,
        maxQueue = 2,
    })
    world:registerEvent("locationCharacterInteractionRequested", {
        validate = function(value)
            return type(value) == "table" and type(value.characterId) == "string"
                and value.characterId ~= "" and plain(value)
        end,
        maxQueue = 2,
    })
    world:registerEvent("locationDialogueAdvanceRequested", {
        validate = function(value) return value == nil end,
        maxQueue = 2,
    })
    world:registerEvent("locationDailyConversationOpenRequested", {
        validate = function(value)
            return type(value) == "table" and type(value.characterId) == "string"
                and value.characterId ~= "" and plain(value)
        end,
        maxQueue = 2,
    })
    world:registerEvent("dailyCardPlayRequested", {
        validate = function(value)
            return type(value) == "table" and type(value.collectionIndex) == "number"
                and value.collectionIndex % 1 == 0 and value.collectionIndex >= 1 and plain(value)
        end,
        maxQueue = 2,
    })
    world:registerEvent("dailyConversationResolved", {
        validate = function(value)
            return type(value) == "table"
                and type(value.targetCharacterId) == "string" and value.targetCharacterId ~= ""
                and type(value.cardId) == "string" and value.cardId ~= ""
                and type(value.categoryMatched) == "boolean"
                and type(value.readinessGained) == "number" and value.readinessGained % 1 == 0
                and value.readinessGained >= 0
                and type(value.homecomingReadiness) == "number"
                and value.homecomingReadiness % 1 == 0 and value.homecomingReadiness >= 0
                and plain(value)
        end,
        maxQueue = 1,
    })
    world:registerEvent("dayAdvanceRequested", {
        validate = function(value) return value == nil end,
        maxQueue = 1,
    })
    world:registerEvent("dayPhaseChanged", {
        validate = function(value)
            return type(value) == "table" and GameSession.isDayPhase(value.from)
                and GameSession.isDayPhase(value.to) and value.from ~= value.to
                and type(value.day) == "number" and value.day % 1 == 0 and value.day >= 1
                and plain(value)
        end,
        maxQueue = 2,
    })
    world:registerEvent("sceneRequest", {
        validate = function(value)
            return type(value) == "table" and type(value.to) == "string" and value.to ~= ""
                and plain(value)
        end,
        maxQueue = 2,
    })
end

return Events
