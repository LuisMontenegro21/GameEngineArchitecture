-- Finds the closest map location whose trigger overlaps the player's ground
-- footprint. It updates only transient display state; activities remain out of
-- scope until a later game phase.
local PointOfInterestSystem = {}

local function overlaps(left, right)
    return left.x < right.x + right.w and left.x + left.w > right.x
        and left.y < right.y + right.h and left.y + left.h > right.y
end

local function distanceSquared(position, size, trigger)
    local playerX = position.x + size.w / 2
    local playerY = position.y + size.h / 2
    local triggerX = trigger.x + trigger.w / 2
    local triggerY = trigger.y + trigger.h / 2
    local dx, dy = playerX - triggerX, playerY - triggerY
    return dx * dx + dy * dy
end

function PointOfInterestSystem.install(scheduler)
    scheduler:addSystem({
        name = "pointOfInterest",
        stage = "fixedUpdate",
        after = { "mapCollision" },
        reads = { "mapPosition", "mapSize", "pointOfInterest" },
        writesResources = { "nearbyPointOfInterest" },
        run = function(context)
            local world = context.world
            local playerPosition, playerSize = nil, nil
            for _, _, position, size in world:query({
                all = { "mapPlayer", "mapPosition", "mapSize" },
            }):each() do
                playerPosition, playerSize = position, size
            end
            if not playerPosition then return end

            local player = {
                x = playerPosition.x,
                y = playerPosition.y,
                w = playerSize.w,
                h = playerSize.h,
            }
            local selected, selectedDistance = nil, nil
            for _, point in world:query({ all = { "pointOfInterest" } }):each() do
                local trigger = point.trigger
                if overlaps(player, trigger) then
                    local distance = distanceSquared(playerPosition, playerSize, trigger)
                    if not selected or distance < selectedDistance
                        or (distance == selectedDistance and point.id < selected.id) then
                        selected = {
                            id = point.id,
                            name = point.name,
                            subtitle = point.subtitle,
                        }
                        selectedDistance = distance
                    end
                end
            end
            world:setResource("nearbyPointOfInterest", selected or false)
        end,
    })
end

return PointOfInterestSystem
