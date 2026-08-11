local Screen = require("src.state.Screen")

local FADE_TIME = 2

local FadeRenderSystem = { name = "FadeRenderSystem" }

function FadeRenderSystem.draw(scene)
    local day = scene.registry:resource("dayloop")
    if day.phase == "fade" then
        local alpha
        love.graphics.setColor(0,0,0,alpha)
        love.graphics.rectangle("fill", 0,0, Screen.w, Screen.h)
    end
end
