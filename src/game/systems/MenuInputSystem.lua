local MenuInputSystem = { name = "menuInput"}

function MenuInputSystem.update(scene, dt)
    for _, event in scene.registry:each("keyPressed") do
        if event.key == "right" then
            menu.cursor = menu.cursor + 1
        end
        if event.key == "left" then
            menu.cursor = menu.cursor - 1
        end
    end
end


return MenuInputSystem