-- Breakout-owned component definitions. These modules contain no LOVE calls
-- and can be registered into any ECS World.
local Components = {}

local function number(value)
    return type(value) == "number"
end

local function point(value)
    return type(value) == "table" and number(value.x) and number(value.y)
end

function Components.register(world)
    world:registerComponent("position", {
        default = function() return { x = 0, y = 0 } end,
        validate = point,
    })
    world:registerComponent("size", {
        default = function() return { w = 1, h = 1 } end,
        validate = function(value)
            return type(value) == "table" and number(value.w) and number(value.h)
                and value.w > 0 and value.h > 0
        end,
    })
    world:registerComponent("velocity", {
        default = function() return { vx = 0, vy = 0 } end,
        validate = function(value)
            return type(value) == "table" and number(value.vx) and number(value.vy)
        end,
    })
    world:registerComponent("paddle", { tag = true })
    world:registerComponent("ball", { tag = true })
    world:registerComponent("brick", { tag = true })
    world:registerComponent("moves", { tag = true })
    world:registerComponent("renderShape", { tag = true })
    world:registerComponent("color", {
        default = function() return { r = 1, g = 1, b = 1 } end,
        validate = function(value)
            return type(value) == "table" and number(value.r) and number(value.g)
                and number(value.b)
        end,
    })
end

return Components
