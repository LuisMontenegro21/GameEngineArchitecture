-- Normalizes Final Conversation presentation selection after authoritative
-- encounter state exists. It does not select cards for gameplay resolution.
local CardUseUiSetupSystem = {}

local function firstPlayableIndex(session, state)
    for index, card in ipairs(session.collection) do
        if not state.usedCollectionIndexes[index] and card.cost <= state.focus then
            return index
        end
    end
    return 1
end

function CardUseUiSetupSystem.install(scheduler)
    scheduler:addSystem({
        name = "cardUseUiSetup",
        stage = "startup",
        after = { "encounterSetup" },
        readsResources = { "gameSession", "encounterState" },
        writesResources = { "encounterCollectionSelection" },
        run = function(context)
            local world = context.world
            local session = world:requireResource("gameSession")
            local state = world:requireResource("encounterState")
            world:setResource("encounterCollectionSelection", firstPlayableIndex(session, state))
        end,
    })
end

CardUseUiSetupSystem.firstPlayableIndex = firstPlayableIndex
return CardUseUiSetupSystem
