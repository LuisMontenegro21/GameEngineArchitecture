-- LOVE-facing render systems. They are no-ops without LOVE so scenes remain
-- available to headless tests.
local RenderSystems = {}

local function graphics() return love and love.graphics or nil end
local function assets(context, factory)
    local world, value = context.world, context.world:getResource("renderAssets") or {}
    if factory then for name, create in pairs(factory) do value[name] = create() end; world:setResource("renderAssets", value) end
    return value
end

function RenderSystems.installPlay(scheduler)
    scheduler:addSystem({ name = "shapeRender", stage = "render", run = function(context)
        local g = graphics(); if not g then return end; g.setColor(1, 1, 1, 1)
        for _, position, size in context.world:query({ all = { "position", "size", "renderShape" }, none = { "brick" } }):each() do g.rectangle("fill", position.x, position.y, size.w, size.h) end
    end })
    scheduler:addSystem({ name = "brickRender", stage = "render", after = { "shapeRender" }, run = function(context)
        local g = graphics(); if not g then return end
        for _, position, size, color in context.world:query({ all = { "position", "size", "color", "brick" } }):each() do g.setColor(color.r, color.g, color.b, 1); g.rectangle("fill", position.x, position.y, size.w, size.h) end
        g.setColor(1, 1, 1, 1)
    end })
    scheduler:addSystem({ name = "hudRender", stage = "render", after = { "brickRender" },
        initialize = function(context) local g = graphics(); assets(context, g and { hudFont = function() return g.newFont(16) end } or nil) end,
        shutdown = function(context) context.world:removeResource("renderAssets") end,
        run = function(context)
            local g = graphics(); if not g then return end
            local asset, screen, match = assets(context), context.world:requireResource("screen"), context.world:requireResource("match")
            g.setColor(1, 1, 1, 1); g.setFont(asset.hudFont); g.printf(("Bricks: %d"):format(match.remainingBricks), 16, screen.h - 28, screen.w - 32, "right")
        end,
    })
end

function RenderSystems.installMenu(scheduler)
    scheduler:addSystem({ name = "menuRender", stage = "render",
        initialize = function(context) local g = graphics(); assets(context, g and { titleFont = function() return g.newFont(72) end, smallFont = function() return g.newFont(16) end } or nil) end,
        shutdown = function(context) context.world:removeResource("renderAssets") end,
        run = function(context)
            local g = graphics(); if not g then return end
            local asset, screen = assets(context), context.world:requireResource("screen")
            g.setColor(1, 1, 1, 1); g.setFont(asset.titleFont); g.printf("BREAKOUT", 0, screen.h * 0.28, screen.w, "center")
            g.setFont(asset.smallFont); g.printf("press SPACE to play  -  ESC quits", 0, screen.h * 0.62, screen.w, "center")
        end,
    })
end

function RenderSystems.installGameOver(scheduler)
    scheduler:addSystem({ name = "gameOverRender", stage = "render",
        initialize = function(context) local g = graphics(); assets(context, g and { titleFont = function() return g.newFont(48) end, smallFont = function() return g.newFont(16) end } or nil) end,
        shutdown = function(context) context.world:removeResource("renderAssets") end,
        run = function(context)
            local g = graphics(); if not g then return end
            local asset, screen, match = assets(context), context.world:requireResource("screen"), context.world:requireResource("match")
            g.setColor(1, 1, 1, 1); g.setFont(asset.titleFont); g.printf(match.status == "won" and "You win!" or "Game Over", 0, screen.h * 0.35, screen.w, "center")
            g.setFont(asset.smallFont); g.printf("press SPACE for the menu", 0, screen.h * 0.62, screen.w, "center")
        end,
    })
end

return RenderSystems
