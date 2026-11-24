-- Maintains continuous directional input. Movement and collision remain in
-- their own systems so input never changes map positions directly.
local MapInputSystem = {}

local function setDirections(input)
    local keys = input.keys or {}
    input.up = keys.up == true or keys.w == true
    input.down = keys.down == true or keys.s == true
    input.left = keys.left == true or keys.a == true
    input.right = keys.right == true or keys.d == true
end

function MapInputSystem.install(scheduler)
    scheduler:addSystem({
        name = "mapInput",
        stage = "fixedUpdate",
        readsResources = {
            "gameSession", "dialogueState", "dailyConversationState", "mapReturnEnabled",
        },
        writesResources = { "mapInput" },
        run = function(context)
            local world = context.world
            local input = world:requireResource("mapInput")
            local session = world:requireResource("gameSession")
            local dailyConversation = world:requireResource("dailyConversationState")
            local returnEnabled = world:requireResource("mapReturnEnabled")
            input.keys = input.keys or {}
            local changed = false

            for event in world:events("keyPressed") do
                local key = event.payload.key
                if key == "backspace" and not world:requireResource("dialogueState")
                    and not (dailyConversation and dailyConversation.open)
                    and session.dayPhase == "activities" and returnEnabled then
                    context.emit("mapExitRequested")
                else
                    input.keys[key] = true
                    changed = true
                end
            end
            for event in world:events("keyReleased") do
                input.keys[event.payload.key] = nil
                changed = true
            end

            if changed then
                setDirections(input)
                world:setResource("mapInput", input)
            end
        end,
    })
end

return MapInputSystem
