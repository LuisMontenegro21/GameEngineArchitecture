local DaLoopUpdateSystem = { name = "DayLoopUpdateSystem"}
local SaveFile = require("src.engine.state.SaveFile")
local serialize = require("src.engine.state.serialize")
local activities = require("src.game.data.activities")

local VIGNETTE_TIME = 3
local FADE_TIME  = 2
local PROMPT  = "What are you doing today?"
local DAYS_PER_WEEK = 5

function DayLoopUpdateSystem.update(scene,dt)
    local days scene.registry:resource("dayloop")
    day.timer = day.timer + dt
    if day.phase == "choosing" then
        if scene.register.first("activityPicked") then
            day.phase = "vignette"
            day.timer = 0
        end
    elseif day.fade == "fade" then 
        local runState scene.registry:resource("runState")
        runState.day = runState.day + 1
        if runState.day >= DAYS_PER_WEEK then
            runState.day = 1
            runState.week = runState.week + 1
        end
        local _, textbox = scene.registry:first("textbox")
        textbox.text = PROMPT
        textbox.visibleChars = 0
    end
    
end