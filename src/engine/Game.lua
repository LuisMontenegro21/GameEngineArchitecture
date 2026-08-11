

local Game = {}
local factories = {}


function Game.start(game)
    performSwitch(name, nil)
end

local function clearEvents(game)
    for _, entity in ipairs(scene.registry:query("event"))do
        scene.registry:destroy(entity)
    end
end

function Game.update(dt)
    current:update(dt)
end

function Game.quit()
    if current then
        current:unload()
    end
end

