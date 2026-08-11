local VignetteUpdateSystem = {name = "VignetteUpdateSystem"}

local activities = require("src.game.data.activities")

function VignetteUpdateSystem.update(scene, dt)
    for _, event in scene.registry:each("event") do
        if event.activityPicked then
            local _, textbox = scene.registry:first("textbox")
            local pool = activities[event.activityPicked.selected].dialogues
            textbox.text = pool[love.math.random(#pool)]
            textbox.visibleChars = 0
        end
    end
    
end