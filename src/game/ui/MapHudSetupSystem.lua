-- Initializes screen-space HUD state. PointOfInterestSystem remains the only
-- producer of active location information after movement/collision.
local MapHudSetupSystem = {}

function MapHudSetupSystem.install(scheduler)
    scheduler:addSystem({
        name = "mapHudSetup",
        stage = "startup",
        after = { "mapSetup" },
        writesResources = { "nearbyPointOfInterest", "mapHudLocation" },
        run = function(context)
            context.world:setResource("nearbyPointOfInterest", false)
            context.world:setResource("mapHudLocation", false)
        end,
    })
end

return MapHudSetupSystem
