local TextBoxSystem = { name = "textBox"}

function TextBoxSystem.update(scene, dt)
    for _, textbox in scene.registry:each('textbox') do
        textbox.visibleChars = #textbox.visibleCHars + textbox.speed * dt
        local cut = math.floor(textbox.visibleChars)
        textbox.visibleText = textbox.text:sub(1, cut + 1)
    end    
end


return TextBoxSystem