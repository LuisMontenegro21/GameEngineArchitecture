-- Mirrors authoritative POI discovery data into HUD-owned display state. It
-- deliberately does not inspect map geometry or change gameplay state.
local MapHudUpdateSystem = {}

local function copyLocation(location)
    if not location then return false end
    return {
        id = location.id,
        name = location.name,
        subtitle = location.subtitle,
    }
end

function MapHudUpdateSystem.install(scheduler)
    scheduler:addSystem({
        name = "mapHudUpdate",
        stage = "fixedUpdate",
        after = { "pointOfInterest" },
        readsResources = { "nearbyPointOfInterest" },
        writesResources = { "mapHudLocation" },
        run = function(context)
            local location = context.world:requireResource("nearbyPointOfInterest")
            context.world:setResource("mapHudLocation", copyLocation(location))
        end,
    })
end

MapHudUpdateSystem.copyLocation = copyLocation
return MapHudUpdateSystem
