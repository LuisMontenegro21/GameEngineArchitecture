-- Converts an overworld POI entry request into one deferred location-scene
-- transition while preserving the shared session and a safe return position.
local LocationPayload = require("src.game.locations.LocationPayload")
local MapReturnPosition = require("src.game.maps.MapReturnPosition")

local LocationEntrySystem = {}

function LocationEntrySystem.install(scheduler)
    scheduler:addSystem({
        name = "locationEntry",
        stage = "postFixedUpdate",
        after = { "mapActivity" },
        readsResources = {
            "gameSession", "mapDefinition", "locationTransitionQueued", "mapTransitionQueued",
        },
        writesResources = { "locationTransitionQueued", "mapTransitionQueued" },
        run = function(context)
            local world = context.world
            if world:requireResource("locationTransitionQueued") then return end
            for event in world:events("locationEnterRequested") do
                local locationId = event.payload.locationId
                assert(LocationPayload.isKnownLocation(locationId),
                    "map requested an unknown location: " .. tostring(locationId))
                local returnPosition = MapReturnPosition.forLocation(
                    world:requireResource("mapDefinition"), locationId)
                world:setResource("locationTransitionQueued", true)
                world:setResource("mapTransitionQueued", true)
                context.emit("sceneRequest", {
                    to = "academyLocation",
                    payload = {
                        session = world:requireResource("gameSession"),
                        locationId = locationId,
                        returnTo = "academyMap",
                        mapReturnPosition = returnPosition,
                    },
                })
                break
            end
        end,
    })
end

return LocationEntrySystem
