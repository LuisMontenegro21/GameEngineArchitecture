local Screen = require("src.Screen")

local MenuRenderSystem = { name = "menuRender" }

local titleFont, smallFont

function MenuRenderSystem.setup(scene)
    titleFont = love.graphics.newFont(72)
    smallFont = love.graphics.newFont(16)
end

function MenuRenderSystem.unload(scene)
    titleFont, smallFont = nil, nil
end

function MenuRenderSystem.draw(scene)
    local screenW = Screen.w
    local screenH = Screen.h

    love.graphics.setFont(titleFont)
    love.graphics.printf("BREAKOUT", 0, screenH * 0.28, screenW, "center")

    love.graphics.setFont(smallFont)
    love.graphics.printf("press SPACE to play  -  ESC quits",
        0, screenH * 0.62, screenW, "center")
end

return MenuRenderSystem
