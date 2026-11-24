-- Map-owned input and transition events. Payloads are plain data so the map
-- can be tested headlessly and use the shared SceneManager boundary.
local Events = {}
local GameSession = require("src.game.session.GameSession")

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

local function keyPayload(value)
    return type(value) == "table" and type(value.key) == "string" and value.key ~= ""
        and plain(value)
end

local function activityRequest(value)
    return type(value) == "table"
        and type(value.activityId) == "string" and value.activityId ~= ""
        and plain(value)
end

local function activityResult(value)
    return type(value) == "table"
        and type(value.activityId) == "string" and value.activityId ~= ""
        and type(value.success) == "boolean"
        and (value.reason == nil or type(value.reason) == "string")
        and plain(value)
end

local function dayPhaseChanged(value)
    return type(value) == "table"
        and GameSession.isDayPhase(value.from)
        and GameSession.isDayPhase(value.to)
        and value.from ~= value.to
        and type(value.day) == "number" and value.day % 1 == 0 and value.day >= 1
        and plain(value)
end

local function positiveIndex(value)
    return type(value) == "table"
        and type(value.collectionIndex) == "number" and value.collectionIndex % 1 == 0
        and value.collectionIndex >= 1 and plain(value)
end

local function dailyConversationResolved(value)
    return type(value) == "table"
        and type(value.targetCharacterId) == "string" and value.targetCharacterId ~= ""
        and type(value.cardId) == "string" and value.cardId ~= ""
        and type(value.categoryMatched) == "boolean"
        and type(value.readinessGained) == "number" and value.readinessGained % 1 == 0
        and value.readinessGained >= 0
        and type(value.homecomingReadiness) == "number"
        and value.homecomingReadiness % 1 == 0 and value.homecomingReadiness >= 0
        and plain(value)
end

function Events.register(world)
    world:registerEvent("keyPressed", { validate = keyPayload, maxQueue = 32 })
    world:registerEvent("keyReleased", { validate = keyPayload, maxQueue = 32 })
    world:registerEvent("mapExitRequested", {
        validate = function(value) return value == nil end,
        maxQueue = 2,
    })
    world:registerEvent("locationEnterRequested", {
        validate = function(value)
            return type(value) == "table" and type(value.locationId) == "string"
                and value.locationId ~= "" and plain(value)
        end,
        maxQueue = 2,
    })
    world:registerEvent("mapActivityRequested", { validate = activityRequest, maxQueue = 4 })
    world:registerEvent("mapActivityResolved", { validate = activityResult, maxQueue = 4 })
    world:registerEvent("dailyCardPlayRequested", { validate = positiveIndex, maxQueue = 4 })
    world:registerEvent("dailyConversationResolved", {
        validate = dailyConversationResolved,
        maxQueue = 1,
    })
    world:registerEvent("dayAdvanceRequested", {
        validate = function(value) return value == nil end,
        maxQueue = 1,
    })
    world:registerEvent("dayPhaseChanged", { validate = dayPhaseChanged, maxQueue = 4 })
    world:registerEvent("sceneRequest", {
        validate = function(value)
            return type(value) == "table" and type(value.to) == "string" and value.to ~= ""
                and plain(value)
        end,
        maxQueue = 2,
    })
end

return Events
