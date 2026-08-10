local MenuRenderSystem = { name = "schedule"}

local pallete = require("src.game.palette")

local COLORS = {
    study = pallete.int,
    grooming = pallete.cha, 
    hobbies = pallete.sen
}


function MenuRenderSystem.draw(scene)
    for _, pos, menu in scene.registry:each("position", "menu") do
        for index, value in ipairs(menu.options) do
            local x = pos.x + (index - 1) * (64 + 20)
            local y = pos.y
            local selected = (index == menu.cursor)
            local color = COLORS[value]
            love.graphics.setColor(color)
            love.graphics.rectangle("fill", x, y, 64, 64, 0, 0)
            if selected then
                love.graphics.setColor(1,1,1)
                love.graphics.rectangle("fill", x, y+64+8, 64, 4)
                local labelFont = love.graphics.newFont(28)
                love.graphics.setFont(labelFont)
                love.graphics.printf(value, pos.x, pos.y + 64 + 8 + 4 + 8, (#menu.options * 64) + ((#menu.options - 1) * 20), "center")
            end
        end
    end
    
end

function MenuRenderSystem.unload(scene)
    
end

return MenuRenderSystem