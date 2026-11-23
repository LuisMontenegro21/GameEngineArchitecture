-- Converts held movement input into a frame-rate-independent movement proposal.
-- MapCollisionSystem applies this proposal to the player's position in M3.
local PlayerMovementSystem = {}

local SPEED = 180

function PlayerMovementSystem.install(scheduler)
    scheduler:addSystem({
        name = "playerMovement",
        stage = "fixedUpdate",
        after = { "mapInput" },
        readsResources = { "mapInput" },
        writes = { "desiredMovement" },
        run = function(context)
            local input = context.world:requireResource("mapInput")
            local horizontal = (input.right and 1 or 0) - (input.left and 1 or 0)
            local vertical = (input.down and 1 or 0) - (input.up and 1 or 0)
            local length = math.sqrt(horizontal * horizontal + vertical * vertical)
            if length > 0 then
                horizontal = horizontal / length
                vertical = vertical / length
            end

            for _, _, desired in context.world:query({
                all = { "mapPlayer", "desiredMovement" },
            }):each() do
                desired.dx = horizontal * SPEED * context.dt
                desired.dy = vertical * SPEED * context.dt
            end
        end,
    })
end

PlayerMovementSystem.speed = SPEED
return PlayerMovementSystem
