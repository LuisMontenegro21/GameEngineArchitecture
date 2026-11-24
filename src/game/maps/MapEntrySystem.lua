-- Training-side entry point for the Academy Garden. It owns only the scene
-- request and deliberately leaves progression state unchanged.
local MapEntrySystem = {}

function MapEntrySystem.install(scheduler)
    scheduler:addSystem({
        name = "mapEntry",
        stage = "fixedUpdate",
        after = { "trainingUiUpdate" },
        readsResources = { "gameSession" },
        run = function(context)
            local world = context.world
            for event in world:events("keyPressed") do
                if event.payload.key == "m" then
                    context.emit("sceneRequest", {
                        to = "academyMap",
                        payload = {
                            session = world:requireResource("gameSession"),
                            returnTo = "training",
                        },
                    })
                    break
                end
            end
        end,
    })
end

return MapEntrySystem
