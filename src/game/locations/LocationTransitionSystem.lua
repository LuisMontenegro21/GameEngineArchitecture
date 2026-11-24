-- Defers exactly one room exit to the existing scene-manager boundary.
local LocationTransitionSystem = {}

function LocationTransitionSystem.install(scheduler)
    scheduler:addSystem({
        name = "locationTransition",
        stage = "postFixedUpdate",
        readsResources = {
            "gameSession", "locationDefinition", "locationReturnTarget", "mapReturnPosition", "locationState",
        },
        writesResources = { "locationState" },
        run = function(context)
            local world = context.world
            local state = world:requireResource("locationState")
            if state.transitionQueued then return end
            for _ in world:events("locationExitRequested") do
                state.transitionQueued = true
                world:setResource("locationState", state)
                context.emit("sceneRequest", {
                    to = world:requireResource("locationReturnTarget"),
                    payload = {
                        session = world:requireResource("gameSession"),
                        returnLocationId = world:requireResource("locationDefinition").id,
                        mapReturnPosition = world:requireResource("mapReturnPosition"),
                    },
                })
                break
            end
        end,
    })
end

return LocationTransitionSystem
