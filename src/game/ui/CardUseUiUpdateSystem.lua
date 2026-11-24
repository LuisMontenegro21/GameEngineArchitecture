-- Translates Final Conversation keyboard input into selection state and
-- card-play requests. Encounter systems remain authoritative for outcomes.
local CardUseUiUpdateSystem = {}

local function clamp(index, count)
    return math.max(1, math.min(index, math.max(1, count)))
end

function CardUseUiUpdateSystem.install(scheduler)
    scheduler:addSystem({
        name = "cardUseUiUpdate",
        stage = "fixedUpdate",
        readsResources = { "gameSession", "encounterState", "encounterCollectionSelection" },
        writesResources = { "encounterCollectionSelection" },
        run = function(context)
            local world = context.world
            local session = world:requireResource("gameSession")
            local state = world:requireResource("encounterState")
            local selected = world:requireResource("encounterCollectionSelection")

            for event in world:events("keyPressed") do
                local key = event.payload.key
                if key == "left" or key == "a" then
                    selected = clamp(selected - 1, #session.collection)
                elseif key == "right" or key == "d" then
                    selected = clamp(selected + 1, #session.collection)
                elseif (key == "return" or key == "space") and not state.complete then
                    context.emit("cardPlayRequested", { collectionIndex = selected })
                end
            end
            world:setResource("encounterCollectionSelection", selected)
        end,
    })
end

CardUseUiUpdateSystem.clamp = clamp
return CardUseUiUpdateSystem
