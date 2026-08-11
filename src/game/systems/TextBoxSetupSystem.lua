local TextBoxSystem = { name = "textBoxSetup"}
local screen  = require("src.engine.screen")


function TextBoxSystem.setup(scene)
    local sw = Screen.w
    local sh = Screen.h
    local p = 20
    local h = 80
    
    scene.registry:spawn({
        position = { x = p, y = sh - h - p},
        size = {w = sw - p * 2, h = h},
        textbox = {
            text = "Hellow rold this is a very long text to text the textbox",
            visibleText = "",
            visibleChars = 0,
            speed = 1,

        }
    })
end