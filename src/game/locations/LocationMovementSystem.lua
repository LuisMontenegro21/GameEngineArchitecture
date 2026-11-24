-- Produces time-based fixed-camera room movement; collision applies it later.
local LocationMovementSystem = {}
local SPEED = 180

function LocationMovementSystem.install(scheduler)
    scheduler:addSystem({
        name = "locationMovement",
        stage = "fixedUpdate",
        after = { "locationInput" },
        readsResources = { "locationInput", "locationState", "dailyConversationState" },
        writes = { "locationDesiredMovement" },
        run = function(context)
            local input = context.world:requireResource("locationInput")
            local horizontal = (input.right and 1 or 0) - (input.left and 1 or 0)
            local vertical = (input.down and 1 or 0) - (input.up and 1 or 0)
            local daily = context.world:requireResource("dailyConversationState")
            if context.world:requireResource("locationState").dialogue or (daily and daily.open) then
                horizontal, vertical = 0, 0
            end
            local length = math.sqrt(horizontal * horizontal + vertical * vertical)
            if length > 0 then horizontal, vertical = horizontal / length, vertical / length end
            local query = context.world:query({ all = { "locationPlayer", "locationDesiredMovement" } })
            for _, _, desired in query:each() do
                desired.dx, desired.dy = horizontal * SPEED * context.dt, vertical * SPEED * context.dt
            end
            query:close()
        end,
    })
end

LocationMovementSystem.speed = SPEED
return LocationMovementSystem
