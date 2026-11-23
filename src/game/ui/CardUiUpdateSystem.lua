-- Converts card-screen navigation and confirmation input into UI focus,
-- selection-change, acquisition, and day-advance requests. Card data remains
-- owned by card gameplay systems.
local CardUiUpdateSystem = {}

function CardUiUpdateSystem.install(scheduler)
    scheduler:addSystem({
        name = "cardUiUpdate",
        stage = "fixedUpdate",
        readsResources = { "gameSession", "generatedCardSelection", "collectionSelection", "cardFocus" },
        writesResources = { "cardFocus" },
        run = function(context)
            local world = context.world
            local session = world:requireResource("gameSession")
            local focus = world:requireResource("cardFocus")
            for event in world:events("keyPressed") do
                local key = event.payload.key
                if key == "tab" then
                    focus = focus == "generated" and "collection" or "generated"
                    world:setResource("cardFocus", focus)
                elseif key == "left" or key == "a" then
                    if focus == "generated" then
                        context.emit("generatedCardSelectionChanged", {
                            index = math.max(1, world:requireResource("generatedCardSelection") - 1),
                        })
                    else
                        context.emit("collectionSelectionChanged", {
                            index = math.max(1, world:requireResource("collectionSelection") - 1),
                        })
                    end
                elseif key == "right" or key == "d" then
                    if focus == "generated" then
                        context.emit("generatedCardSelectionChanged", {
                            index = math.min(math.max(1, #session.generatedCards),
                                world:requireResource("generatedCardSelection") + 1),
                        })
                    else
                        context.emit("collectionSelectionChanged", {
                            index = math.min(math.max(1, #session.collection),
                                world:requireResource("collectionSelection") + 1),
                        })
                    end
                elseif (key == "return" or key == "space") and focus == "generated"
                    and #session.generatedCards > 0 then
                    if session.cardChosenThisDay then
                        context.emit("dayAdvanceRequested")
                    else
                        context.emit("cardAcquisitionRequested", {
                            index = world:requireResource("generatedCardSelection"),
                        })
                    end
                end
            end
        end,
    })
end

return CardUiUpdateSystem
