local Breakout = require("src.game.BreakoutECS")

return function()
    local game = Breakout.new({ width = 320, height = 240 })
    assert(game:status().remainingBricks == 50)
    for _ = 1, 5 do game:step(1 / 60, {}) end
    local status = game:status(); status.remainingBricks = 0
    game:step(1 / 60, {}); assert(game:status().status == "won")
    game:dispose()
end
