-- Draws the result of a Breakout round. The scene factory owns the `result`
-- resource, so this system only renders it.

local Screen = require("src.Screen")

local GameOverRenderSystem = { name = "gameOverRender" }

local bigFont, smallFont

function GameOverRenderSystem.setup(scene)
    bigFont = love.graphics.newFont(48)
    smallFont = love.graphics.newFont(16)
end

function GameOverRenderSystem.unload(scene)
    -- drop the references; the GC collects them. See RenderSystem.unload
    -- for why we never release() fonts.
    bigFont, smallFont = nil, nil
end

function GameOverRenderSystem.draw(scene)
    local result = scene.registry:resource("result")
    local screenW = Screen.w
    local screenH = Screen.h
    local message = result == "won" and "You win!" or "Game Over"

    love.graphics.setFont(bigFont)
    love.graphics.printf(message, 0, screenH * 0.35, screenW, "center")

    love.graphics.setFont(smallFont)
    love.graphics.printf("press SPACE for the menu",
        0, screenH * 0.62, screenW, "center")
end

return GameOverRenderSystem
