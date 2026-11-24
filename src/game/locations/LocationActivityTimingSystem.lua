-- Advances only timing challenges using delta time. Its state is transient,
-- leaving activity rewards and progression to the existing activity systems.
local LocationActivityTimingSystem = {}

function LocationActivityTimingSystem.install(scheduler)
    scheduler:addSystem({
        name = "locationActivityTiming",
        stage = "fixedUpdate",
        after = { "locationInput" },
        readsResources = { "activityChallengeState" },
        writesResources = { "activityChallengeState" },
        run = function(context)
            local world = context.world
            local challenge = world:requireResource("activityChallengeState")
            if not challenge or challenge.mode ~= "timing" then return end
            local timing = challenge.timing
            local position = timing.markerPosition + timing.direction * timing.speed * context.dt
            if position >= 1 then
                position, timing.direction = 1, -1
            elseif position <= 0 then
                position, timing.direction = 0, 1
            end
            timing.markerPosition = position
            world:setResource("activityChallengeState", challenge)
        end,
    })
end

return LocationActivityTimingSystem
