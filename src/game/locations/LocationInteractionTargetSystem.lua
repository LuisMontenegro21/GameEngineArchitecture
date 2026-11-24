-- Selects the nearest overlapping activity, character, or exit target.
local LocationInteractionTargetSystem = {}

local function overlaps(left, right)
    return left.x < right.x + right.w and left.x + left.w > right.x
        and left.y < right.y + right.h and left.y + left.h > right.y
end

local function distanceSquared(position, size, trigger)
    local px, py = position.x + size.w / 2, position.y + size.h / 2
    local tx, ty = trigger.x + trigger.w / 2, trigger.y + trigger.h / 2
    local dx, dy = px - tx, py - ty
    return dx * dx + dy * dy
end

local function copyTarget(target)
    return {
        id = target.id, kind = target.kind, name = target.name,
        prompt = target.prompt, activityId = target.activityId,
    }
end

function LocationInteractionTargetSystem.install(scheduler)
    scheduler:addSystem({
        name = "locationInteractionTarget",
        stage = "fixedUpdate",
        after = { "locationCollision" },
        reads = { "locationPosition", "locationSize", "locationInteractable" },
        writesResources = { "nearbyLocationInteraction" },
        run = function(context)
            local world = context.world
            local playerPosition, playerSize
            local playerQuery = world:query({ all = { "locationPlayer", "locationPosition", "locationSize" } })
            for _, _, position, size in playerQuery:each() do playerPosition, playerSize = position, size break end
            playerQuery:close()
            if not playerPosition then
                world:setResource("nearbyLocationInteraction", false)
                return
            end
            local player = { x = playerPosition.x, y = playerPosition.y, w = playerSize.w, h = playerSize.h }
            local selected, selectedDistance
            local query = world:query({ all = { "locationInteractable" } })
            for _, target in query:each() do
                if overlaps(player, target.trigger) then
                    local distance = distanceSquared(playerPosition, playerSize, target.trigger)
                    if not selected or distance < selectedDistance
                        or (distance == selectedDistance and target.id < selected.id) then
                        selected, selectedDistance = target, distance
                    end
                end
            end
            query:close()
            world:setResource("nearbyLocationInteraction", selected and copyTarget(selected) or false)
        end,
    })
end

LocationInteractionTargetSystem.copyTarget = copyTarget
return LocationInteractionTargetSystem
