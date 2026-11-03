local imlove = require('lib.imlove')
local Game = require('engine.Game')

local DebugOverlay = {}

local visible = false

function DebugOverlay.toggle()
  visible = not visible
end

function DebugOverlay.beginFrame(scene)
  imlove.NewFrame()
  if visible then
    if imlove.Begin('Inspector') then
      imlove.Text('FPS: %d', love.timer.getFPS())
    end
    imlove.End()
  end
end

function DebugOverlay.shouldUpdate()
  return true -- no pause yet; this gets real in beat 9
end

function DebugOverlay.draw()
  imlove.Render()
end

function DebugOverlay.keypressed(key)
  if key == 'f1' then
    DebugOverlay.toggle()
    return true
  end
  return imlove.keypressed(key)
end

function DebugOverlay.textinput(text)
  return imlove.textinput(text)
end

function DebugOverlay.mousepressed(x, y, button)
  return imlove.mousepressed(x, y, button)
end

function DebugOverlay.mousereleased(x, y, button)
  return imlove.mousereleased(x, y, button)
end

function DebugOverlay.wheelmoved(dx, dy)
  return imlove.wheelmoved(dx, dy)
end

return DebugOverlay