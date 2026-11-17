-- Breakout-owned singleton resource definitions.
local Resources = {}

local VALID_MATCH_STATUS = { playing = true, won = true, lost = true }

function Resources.register(world)
    world:registerResource("match", {
        validate = function(value)
            return type(value) == "table" and VALID_MATCH_STATUS[value.status] == true
                and type(value.remainingBricks) == "number"
                and value.remainingBricks >= 0 and value.remainingBricks % 1 == 0
        end,
    })
    world:registerResource("input", {
        transient = true,
        validate = function(value)
            if type(value) ~= "table" then return false end
            for _, key in ipairs({ "left", "right" }) do
                if value[key] ~= nil and type(value[key]) ~= "boolean" then return false end
            end
            return value.keys == nil or type(value.keys) == "table"
        end,
    })
    world:registerResource("screen", {
        validate = function(value)
            return type(value) == "table" and type(value.w) == "number"
                and type(value.h) == "number" and value.w > 0 and value.h > 0
        end,
    })
    world:registerResource("renderAssets", {
        transient = true,
        serializable = false,
    })
end

return Resources
