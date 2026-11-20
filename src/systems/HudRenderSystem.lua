local Screen = require("src.Screen")

local HudRenderSystem = { name = "hudRender" }

local font

function HudRenderSystem.setup(scene)
    font = love.graphics.newFont(16)
end

function HudRenderSystem.unload(scene)
    font = nil
end

function HudRenderSystem.draw(scene)
    local breakout = scene.registry:resource("breakout")
    if not breakout then
        return
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(font)
    love.graphics.printf(
        ("Bricks: %d"):format(breakout.remainingBricks),
        16,
        Screen.h - 28,
        Screen.w - 32,
        "right"
    )
end

return HudRenderSystem
