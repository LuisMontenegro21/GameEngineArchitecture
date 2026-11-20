local CollectionNavigationSystem = {}

local function clamp(index, count)
    return math.max(1, math.min(index, math.max(1, count)))
end

function CollectionNavigationSystem.install(scheduler)
    scheduler:addSystem({
        name = "collectionNavigation",
        stage = "postFixedUpdate",
        after = { "cardAcquisition" },
        readsResources = { "gameSession", "generatedCardSelection", "collectionSelection" },
        writesResources = { "gameSession", "generatedCardSelection", "collectionSelection" },
        run = function(context)
            local world = context.world
            local session = world:requireResource("gameSession")
            local generated = world:requireResource("generatedCardSelection")
            local collection = world:requireResource("collectionSelection")
            for event in world:events("generatedCardSelectionChanged") do
                generated = clamp(event.payload.index, #session.generatedCards)
            end
            for event in world:events("collectionSelectionChanged") do
                collection = clamp(event.payload.index, #session.collection)
            end
            generated = clamp(generated, #session.generatedCards)
            collection = clamp(collection, #session.collection)
            session.generatedSelection = generated
            session.collectionSelection = collection
            world:setResource("generatedCardSelection", generated)
            world:setResource("collectionSelection", collection)
            world:setResource("gameSession", session)
        end,
    })
end

return CollectionNavigationSystem
