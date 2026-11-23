-- Map-owned input and transition events. Payloads are plain data so the map
-- can be tested headlessly and use the shared SceneManager boundary.
local Events = {}

local function plain(value, seen)
    local kind = type(value)
    if kind == "nil" or kind == "boolean" or kind == "number" or kind == "string" then
        return true
    end
    if kind ~= "table" then return false end
    seen = seen or {}
    if seen[value] then return false end
    seen[value] = true
    for key, item in pairs(value) do
        if not plain(key, seen) or not plain(item, seen) then return false end
    end
    seen[value] = nil
    return true
end

local function keyPayload(value)
    return type(value) == "table" and type(value.key) == "string" and value.key ~= ""
        and plain(value)
end

function Events.register(world)
    world:registerEvent("keyPressed", { validate = keyPayload, maxQueue = 32 })
    world:registerEvent("keyReleased", { validate = keyPayload, maxQueue = 32 })
    world:registerEvent("mapExitRequested", {
        validate = function(value) return value == nil end,
        maxQueue = 2,
    })
    world:registerEvent("sceneRequest", {
        validate = function(value)
            return type(value) == "table" and type(value.to) == "string" and value.to ~= ""
                and plain(value)
        end,
        maxQueue = 2,
    })
end

return Events
