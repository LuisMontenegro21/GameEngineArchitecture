-- Selects the one closest interactable whose trigger overlaps the player
-- after collision resolution. It owns no dialogue or progression policy.
local InteractionTargetSystem = {}

local function overlaps(left, right)
    return left.x < right.x + right.w and left.x + left.w > right.x
        and left.y < right.y + right.h and left.y + left.h > right.y
end

local function distanceSquared(position, size, trigger)
    local playerX = position.x + size.w / 2
    local playerY = position.y + size.h / 2
    local targetX = trigger.x + trigger.w / 2
    local targetY = trigger.y + trigger.h / 2
    local dx, dy = playerX - targetX, playerY - targetY
    return dx * dx + dy * dy
end

local function copyTarget(target)
    local dialogue = {}
    for index, line in ipairs(target.dialogue) do dialogue[index] = line end
    return {
        id = target.id,
        kind = target.kind,
        name = target.name,
        prompt = target.prompt,
        dialogue = dialogue,
        activityId = target.activityId,
    }
end

function InteractionTargetSystem.install(scheduler)
    scheduler:addSystem({
        name = "interactionTarget",
        stage = "fixedUpdate",
        after = { "mapCollision", "pointOfInterest" },
        reads = { "mapPosition", "mapSize", "mapInteractable" },
        writesResources = { "nearbyInteraction" },
        run = function(context)
            local world = context.world
            local playerPosition, playerSize = nil, nil
            local playerQuery = world:query({
                all = { "mapPlayer", "mapPosition", "mapSize" },
            })
            for _, _, position, size in playerQuery:each() do
                playerPosition, playerSize = position, size
                break
            end
            playerQuery:close()
            if not playerPosition then
                world:setResource("nearbyInteraction", false)
                return
            end

            local player = {
                x = playerPosition.x,
                y = playerPosition.y,
                w = playerSize.w,
                h = playerSize.h,
            }
            local selected, selectedDistance = nil, nil
            for _, target in world:query({ all = { "mapInteractable" } }):each() do
                if overlaps(player, target.trigger) then
                    local distance = distanceSquared(playerPosition, playerSize, target.trigger)
                    if not selected or distance < selectedDistance
                        or (distance == selectedDistance and target.id < selected.id) then
                        selected, selectedDistance = target, distance
                    end
                end
            end
            world:setResource("nearbyInteraction", selected and copyTarget(selected) or false)
        end,
    })
end

InteractionTargetSystem.copyTarget = copyTarget
return InteractionTargetSystem
