-- Returns from the Academy Garden exactly once after a map exit request.
local MapTransitionSystem = {}

function MapTransitionSystem.install(scheduler)
    scheduler:addSystem({
        name = "mapTransition",
        stage = "postFixedUpdate",
        readsResources = { "gameSession", "mapReturnTarget", "mapTransitionQueued" },
        writesResources = { "mapTransitionQueued" },
        run = function(context)
            local world = context.world
            if world:requireResource("mapTransitionQueued") then return end
            for _ in world:events("mapExitRequested") do
                world:setResource("mapTransitionQueued", true)
                context.emit("sceneRequest", {
                    to = world:requireResource("mapReturnTarget"),
                    payload = { session = world:requireResource("gameSession") },
                })
                break
            end
        end,
    })
end

return MapTransitionSystem
