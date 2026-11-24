-- Initializes card-screen focus and safe display selections after authoritative
-- card generation completes.
local CardUiSetupSystem = {}

local function clamp(index, count)
    return math.max(1, math.min(index, math.max(1, count)))
end

function CardUiSetupSystem.install(scheduler)
    scheduler:addSystem({
        name = "cardUiSetup",
        stage = "startup",
        after = { "cardGeneration" },
        readsResources = { "gameSession", "generatedCardSelection", "collectionSelection" },
        writesResources = {
            "gameSession", "generatedCardSelection", "collectionSelection", "cardFocus",
        },
        run = function(context)
            local world = context.world
            local session = world:requireResource("gameSession")
            local generated = clamp(
                world:requireResource("generatedCardSelection"), #session.generatedCards)
            local collection = clamp(
                world:requireResource("collectionSelection"), #session.collection)
            session.generatedSelection = generated
            session.collectionSelection = collection
            world:setResource("gameSession", session)
            world:setResource("generatedCardSelection", generated)
            world:setResource("collectionSelection", collection)
            world:setResource("cardFocus", "generated")
        end,
    })
end

CardUiSetupSystem.clamp = clamp
return CardUiSetupSystem
