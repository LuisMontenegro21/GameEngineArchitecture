-- Breakout event definitions. Payloads remain plain data so headless tests and
-- the LOVE adapter share exactly the same boundary.
local Events = {}

local function keyPayload(value)
    return type(value) == "table" and type(value.key) == "string" and value.key ~= ""
end

function Events.register(world)
    world:registerEvent("keyPressed", { validate = keyPayload, maxQueue = 64 })
    world:registerEvent("keyReleased", { validate = keyPayload, maxQueue = 64 })
    world:registerEvent("sceneRequest", {
        validate = function(value)
            return type(value) == "table" and type(value.to) == "string" and value.to ~= ""
                and (value.payload == nil or type(value.payload) == "table")
        end,
        maxQueue = 4,
    })
    world:registerEvent("roundWon", { validate = function(value) return value == nil or type(value) == "table" end, maxQueue = 1 })
    world:registerEvent("roundLost", { validate = function(value) return value == nil or type(value) == "table" end, maxQueue = 1 })
end

return Events
