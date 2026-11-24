-- Computes safe player positions for returning from a dedicated location Scene.
-- It is pure plain-data logic so map entry/return behavior is testable without LOVE.
local MapReturnPosition = {}

local PADDING = 8

local function finite(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

local function overlaps(left, right)
    return left.x < right.x + right.w and left.x + left.w > right.x
        and left.y < right.y + right.h and left.y + left.h > right.y
end

local function playerRect(map, position)
    return {
        x = position.x,
        y = position.y,
        w = map.playerFootprint.w,
        h = map.playerFootprint.h,
    }
end

local function inBounds(map, rectangle)
    local bounds = map.bounds
    return rectangle.x >= bounds.x and rectangle.y >= bounds.y
        and rectangle.x + rectangle.w <= bounds.x + bounds.w
        and rectangle.y + rectangle.h <= bounds.y + bounds.h
end

function MapReturnPosition.clamp(map, position)
    if type(position) ~= "table" or not finite(position.x) or not finite(position.y) then return false end
    local bounds, footprint = map.bounds, map.playerFootprint
    return {
        x = math.max(bounds.x, math.min(position.x, bounds.x + bounds.w - footprint.w)),
        y = math.max(bounds.y, math.min(position.y, bounds.y + bounds.h - footprint.h)),
    }
end

function MapReturnPosition.isSafe(map, position)
    local rectangle = playerRect(map, position)
    if not inBounds(map, rectangle) then return false end
    for _, obstacle in ipairs(map.obstacles) do
        if overlaps(rectangle, obstacle) then return false end
    end
    for _, point in ipairs(map.pointsOfInterest) do
        if overlaps(rectangle, point.trigger) then return false end
    end
    return true
end

local function pointById(map, pointId)
    for _, point in ipairs(map.pointsOfInterest) do
        if point.id == pointId then return point end
    end
    return nil
end

function MapReturnPosition.forLocation(map, locationId)
    local point = assert(pointById(map, locationId),
        "unknown Academy Garden location: " .. tostring(locationId))
    local footprint = map.playerFootprint
    local centeredX = point.trigger.x + (point.trigger.w - footprint.w) / 2
    local centeredY = point.trigger.y + (point.trigger.h - footprint.h) / 2
    local candidates = {
        { x = centeredX, y = point.trigger.y + point.trigger.h + PADDING },
        { x = centeredX, y = point.trigger.y - footprint.h - PADDING },
        { x = point.trigger.x + point.trigger.w + PADDING, y = centeredY },
        { x = point.trigger.x - footprint.w - PADDING, y = centeredY },
    }
    for _, candidate in ipairs(candidates) do
        local clamped = MapReturnPosition.clamp(map, candidate)
        if MapReturnPosition.isSafe(map, clamped) then return clamped end
    end
    error("no safe map return position for location: " .. locationId)
end

function MapReturnPosition.resolve(map, locationId, requestedPosition)
    local clamped = MapReturnPosition.clamp(map, requestedPosition)
    if clamped and MapReturnPosition.isSafe(map, clamped) then return clamped end
    if locationId ~= nil then return MapReturnPosition.forLocation(map, locationId) end
    return false
end

return MapReturnPosition
