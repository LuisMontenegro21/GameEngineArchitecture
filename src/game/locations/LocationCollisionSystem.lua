-- Keeps the player in the fixed room rectangle. Room scenery can later add
-- collider entities without changing movement or interaction code.
local LocationCollisionSystem = {}

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

function LocationCollisionSystem.install(scheduler)
    scheduler:addSystem({
        name = "locationCollision",
        stage = "fixedUpdate",
        after = { "locationMovement" },
        readsResources = { "locationBounds" },
        reads = { "locationSize", "locationDesiredMovement" },
        writes = { "locationPosition" },
        run = function(context)
            local bounds = context.world:requireResource("locationBounds")
            local query = context.world:query({
                all = { "locationPlayer", "locationPosition", "locationSize", "locationDesiredMovement" },
            })
            for _, _, position, size, desired in query:each() do
                position.x = clamp(position.x + desired.dx, bounds.x, bounds.x + bounds.w - size.w)
                position.y = clamp(position.y + desired.dy, bounds.y, bounds.y + bounds.h - size.h)
            end
            query:close()
        end,
    })
end

return LocationCollisionSystem
