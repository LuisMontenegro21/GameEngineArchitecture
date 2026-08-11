local MenuInputSystem = { name = "menuInput"}

function MenuInputSystem.update(scene, dt)
    for _, event in scene.registry:each("event") do
        local event = e.keyPressed
        for _, menu in scene.registry:each("menu")do
            if event.key == "right" then
                menu.cursor = menu.cursor % #menu.cursor + 1
            end
            if event.key == "left" then
                menu.cursor = (menu.cursor - 2) % #menu.options + 1
            end
            if event.key == "enter"  or event.key == "space" then
                scene.registry:spanw({
                    event = { activityPicked = {selected = menu.options[menu.cursor]}}
                })
            end
        end

    end
end


return MenuInputSystem