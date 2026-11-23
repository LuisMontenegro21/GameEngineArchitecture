-- Applies proposed movement after resolving map bounds and solid AABB
-- footprints. Horizontal and vertical axes are processed separately so the
-- player can slide along an unblocked axis.
local MapCollisionSystem = {}

local function overlaps(left, right)
    return left.x < right.x + right.w and left.x + left.w > right.x
        and left.y < right.y + right.h and left.y + left.h > right.y
end

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function solidObstacles(world)
    local result = {}
    for _, position, size in world:query({
        all = { "mapPosition", "mapSize", "mapCollider" },
        none = { "mapPlayer" },
    }):each() do
        result[#result + 1] = { x = position.x, y = position.y, w = size.w, h = size.h }
    end
    return result
end

local function resolveHorizontal(rectangle, delta, bounds, obstacles)
    if delta == 0 then return rectangle.x end
    local x = clamp(rectangle.x + delta, bounds.x, bounds.x + bounds.w - rectangle.w)
    local candidate = { x = x, y = rectangle.y, w = rectangle.w, h = rectangle.h }
    for _, obstacle in ipairs(obstacles) do
        if overlaps(candidate, obstacle) then
            if delta > 0 then
                x = math.min(x, obstacle.x - rectangle.w)
            else
                x = math.max(x, obstacle.x + obstacle.w)
            end
            candidate.x = x
        end
    end
    return x
end

local function resolveVertical(rectangle, delta, bounds, obstacles)
    if delta == 0 then return rectangle.y end
    local y = clamp(rectangle.y + delta, bounds.y, bounds.y + bounds.h - rectangle.h)
    local candidate = { x = rectangle.x, y = y, w = rectangle.w, h = rectangle.h }
    for _, obstacle in ipairs(obstacles) do
        if overlaps(candidate, obstacle) then
            if delta > 0 then
                y = math.min(y, obstacle.y - rectangle.h)
            else
                y = math.max(y, obstacle.y + obstacle.h)
            end
            candidate.y = y
        end
    end
    return y
end

function MapCollisionSystem.install(scheduler)
    scheduler:addSystem({
        name = "mapCollision",
        stage = "fixedUpdate",
        after = { "playerMovement" },
        readsResources = { "mapBounds" },
        reads = { "mapSize", "mapCollider", "desiredMovement" },
        writes = { "mapPosition" },
        run = function(context)
            local world = context.world
            local bounds = world:requireResource("mapBounds")
            local obstacles = solidObstacles(world)
            for _, _, position, size, desired in world:query({
                all = { "mapPlayer", "mapPosition", "mapSize", "desiredMovement" },
            }):each() do
                local rectangle = { x = position.x, y = position.y, w = size.w, h = size.h }
                position.x = resolveHorizontal(rectangle, desired.dx, bounds, obstacles)
                rectangle.x = position.x
                position.y = resolveVertical(rectangle, desired.dy, bounds, obstacles)
            end
        end,
    })
end

return MapCollisionSystem
