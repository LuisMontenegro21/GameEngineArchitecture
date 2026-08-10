local TextBoxRenderSystem = { " texBoxRender"}

local font 

function TextBoxRenderSystem.setup(scene)
    font = love.graphics.newFont(28)
end

function TextBoxRenderSystem.draw(scene)
    for entity, pos, size, textbox in scene.registry:reach("positon", "size", "textbox") do
        
    end
end

function TextBoxRenderSystem.unload(scene)
    
end