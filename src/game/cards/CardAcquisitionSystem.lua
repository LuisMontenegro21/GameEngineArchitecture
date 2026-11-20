local CardAcquisitionSystem = {}

local function copyCard(card)
    return {
        id = card.id,
        name = card.name,
        description = card.description,
        category = card.category,
        power = card.power,
        cost = card.cost,
        symbol = card.symbol,
    }
end

function CardAcquisitionSystem.install(scheduler)
    scheduler:addSystem({
        name = "cardAcquisition",
        stage = "postFixedUpdate",
        readsResources = { "gameSession", "generatedCardSelection" },
        writesResources = { "gameSession", "collectionSelection" },
        run = function(context)
            local world = context.world
            local session = world:requireResource("gameSession")
            for event in world:events("cardAcquisitionRequested") do
                if not session.cardChosenThisDay then
                    local index = event.payload.index
                    local card = session.generatedCards[index]
                    if card and index == world:requireResource("generatedCardSelection") then
                        local acquired = copyCard(card)
                        session.collection[#session.collection + 1] = acquired
                        session.collectionSelection = #session.collection
                        session.cardChosenThisDay = true
                        world:setResource("gameSession", session)
                        world:setResource("collectionSelection", session.collectionSelection)
                        context.emit("cardAcquired", { card = acquired })
                    end
                end
            end
        end,
    })
end

return CardAcquisitionSystem
