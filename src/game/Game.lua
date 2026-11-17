-- Application facade for the ECS-backed scene manager. LOVE callbacks only
-- enqueue input; scene systems receive it through registered event channels.
local SceneManager = require("src.engine.scene.SceneManager")

local Game = {}
local manager = SceneManager.new()
local inputQueue = {}

function Game.registerScene(name, factory) manager:register(name, factory) end
function Game.start(name) return manager:start(name) end

local function drainInput()
    local scene = manager:current()
    if not scene then return end
    local world = scene:world()
    for _, record in ipairs(inputQueue) do
        local event = record.kind == "keypressed" and "keyPressed" or "keyReleased"
        if world:hasEventDefinition(event) then world:emit(event, { key = record.key }) end
    end
    inputQueue = {}
end

-- The legacy main loop currently calls this once per fixed tick. LoveRunner
-- takes over frame orchestration after the remaining callback migration.
function Game.update(dt)
    drainInput()
    manager:preUpdate(dt)
    manager:fixedUpdate(dt)
    manager:postFixedUpdate(dt)
    manager:update(dt)
    return manager:postUpdate(dt)
end

function Game.draw(alpha) return manager:draw(alpha or 0) end
function Game.keypressed(key)
    if key == "escape" then if love and love.event then love.event.quit() end; return end
    inputQueue[#inputQueue + 1] = { kind = "keypressed", key = key }
end
function Game.keyreleased(key) inputQueue[#inputQueue + 1] = { kind = "keyreleased", key = key } end
function Game.quit() inputQueue = {}; return manager:quit() end
function Game.current() return manager:current() end
function Game.sceneNames() return manager:sceneNames() end
function Game.manager() return manager end

return Game
