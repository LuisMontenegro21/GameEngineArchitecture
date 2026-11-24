-- Covers Beta location-only resource and event contracts without LOVE.
local ECS = require("src.engine.ecs")
local registerLocation = require("src.game.locations.register")

local function invalid(action, message)
    assert(not pcall(action), message)
end

return function()
    local world = ECS.World.new({ identity = "location-contract" })
    registerLocation(world)

    world:setResource("dailyConversationState", false)
    world:setResource("dailyConversationSelection", 1)
    invalid(function() world:setResource("dailyConversationSelection", 0) end,
        "daily card selection must be a positive index")
    invalid(function()
        world:setResource("dailyConversationState", {
            day = 1, targetCharacterId = "outgoing_peer", targetName = "Mira",
        })
    end, "daily room state must include its complete plain-data contract")
    invalid(function()
        world:setResource("locationState", {
            dialogue = { characterId = "x" }, feedback = "", transitionQueued = false,
        })
    end, "location dialogue state must remain complete and valid")
    invalid(function()
        world:setResource("locationInput", { up = false, down = false, left = false })
    end, "location movement input must include every direction")

    world:emit("locationDailyConversationOpenRequested", { characterId = "outgoing_peer" })
    world:emit("dailyCardPlayRequested", { collectionIndex = 1 })
    world:emit("dailyConversationResolved", {
        targetCharacterId = "outgoing_peer", cardId = "dazzling_introduction",
        categoryMatched = true, readinessGained = 4, homecomingReadiness = 4,
    })
    world:emit("dayPhaseChanged", { from = "socialConversation", to = "activities", day = 2 })
    world:advanceEvents()
    assert(world:eventCount("locationDailyConversationOpenRequested") == 1
        and world:eventCount("dailyCardPlayRequested") == 1
        and world:eventCount("dailyConversationResolved") == 1,
        "valid location conversation events must be accepted")

    invalid(function() world:emit("locationDailyConversationOpenRequested", {}) end,
        "daily opening requests require a character ID")
    invalid(function() world:emit("dailyCardPlayRequested", { collectionIndex = 0 }) end,
        "daily card requests require a positive selection")
    invalid(function()
        world:emit("dailyConversationResolved", {
            targetCharacterId = "outgoing_peer", cardId = "dazzling_introduction",
            categoryMatched = true, readinessGained = -1, homecomingReadiness = 0,
        })
    end, "resolved daily conversations cannot report a negative reward")
    invalid(function()
        world:emit("dayPhaseChanged", { from = "activities", to = "activities", day = 1 })
    end, "location phase changes must represent an actual transition")
    world:dispose()
end
