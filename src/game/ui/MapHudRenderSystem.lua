-- Screen-space map information. It intentionally does not draw world objects.
local Screen = require("src.game.Screen")
local UiTheme = require("src.game.ui.UiTheme")

local MapHudRenderSystem = {}

local function graphics()
    return love and love.graphics or nil
end

local function promptText(location)
    return location.name .. " - " .. location.subtitle
end

function MapHudRenderSystem.install(scheduler)
    scheduler:addSystem({
        name = "mapHudRender",
        stage = "render",
        readsResources = { "mapHudLocation" },
        after = { "mapLabelRender" },
        run = function(context)
            local g = graphics()
            if not g then return end
            local location = context.world:requireResource("mapHudLocation")

            UiTheme.setColor(g, UiTheme.colors.title)
            g.printf("WIZARD ACADEMIA - ACADEMY GARDEN", 0, 12, Screen.w, "center")
            UiTheme.drawPanel(g, 100, Screen.h - 36, 760, 26, false)
            UiTheme.setColor(g, UiTheme.colors.muted)
            g.printf("WASD / ARROWS: explore     BACKSPACE: return to training",
                0, Screen.h - 22, Screen.w, "center")
            if location then
                UiTheme.drawPanel(g, 170, 34, 620, 34, true)
                UiTheme.setColor(g, UiTheme.colors.heading)
                g.printf("LOCATION: " .. promptText(location), 182, 43, 596, "center")
            end
        end,
    })
end

MapHudRenderSystem.promptText = promptText
return MapHudRenderSystem
