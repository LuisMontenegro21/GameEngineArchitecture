-- Screen-space map information. It intentionally does not draw world objects.
local Screen = require("src.game.Screen")

local MapHudRenderSystem = {}

local function graphics()
    return love and love.graphics or nil
end

function MapHudRenderSystem.install(scheduler)
    scheduler:addSystem({
        name = "mapHudRender",
        stage = "render",
        readsResources = { "nearbyPointOfInterest" },
        after = { "mapLabelRender" },
        run = function(context)
            local g = graphics()
            if not g then return end
            local nearby = context.world:requireResource("nearbyPointOfInterest")

            g.setColor(0.90, 0.82, 1, 1)
            g.printf("WIZARD ACADEMIA - ACADEMY GARDEN", 0, 12, Screen.w, "center")
            g.setColor(0.92, 0.92, 0.92, 1)
            g.printf("WASD / ARROWS: explore     BACKSPACE: return to training",
                0, Screen.h - 22, Screen.w, "center")
            if nearby then
                g.setColor(0.06, 0.08, 0.14, 0.88)
                g.rectangle("fill", 190, 34, 580, 24)
                g.setColor(0.80, 0.88, 1, 1)
                g.printf(nearby.name .. " -” " .. nearby.subtitle, 200, 39, 560, "center")
            end
        end,
    })
end

return MapHudRenderSystem
