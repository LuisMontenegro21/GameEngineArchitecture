-- World-space map labels, deliberately separate from screen-space HUD content.
local Screen = require("src.game.Screen")

local MapLabelRenderSystem = {}

local function graphics()
    return love and love.graphics or nil
end

function MapLabelRenderSystem.install(scheduler)
    scheduler:addSystem({
        name = "mapLabelRender",
        stage = "render",
        reads = { "mapPosition", "mapSize", "pointOfInterest", "mapCharacter" },
        readsResources = { "mapBounds" },
        after = { "mapSpriteRender" },
        before = { "mapHudRender" },
        run = function(context)
            local g = graphics()
            if not g then return end
            local world = context.world
            local bounds = world:requireResource("mapBounds")

            for _, position, size, point in world:query({
                all = { "mapPosition", "mapSize", "pointOfInterest" },
            }):each() do
                g.setColor(1, 1, 1, 1)
                g.printf(point.name, position.x - 25, position.y - 20, size.w + 50, "center")
            end

            for _, position, size, character in world:query({
                all = { "mapPosition", "mapSize", "mapCharacter" },
            }):each() do
                g.setColor(1, 1, 1, 1)
                g.printf(character.displayName, position.x - 24, position.y - 16,
                    size.w + 48, "center")
            end

            g.setColor(0.92, 0.92, 0.92, 1)
            g.printf("Academy Entrance", 0, bounds.y + bounds.h - 25, Screen.w, "center")
            g.printf("Ancient Tree", 0, 236, Screen.w, "center")
        end,
    })
end

return MapLabelRenderSystem
