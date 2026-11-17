-- Headless Breakout gameplay built on the Phase 13 ECS APIs.
local ECS = require("src.engine.ecs")
local registerBreakout = require("src.game.ecs.register")
local GameplaySystems = require("src.game.ecs.GameplaySystems")
local Breakout = {}
Breakout.__index = Breakout

local W, H = 800, 600

function Breakout.new(options)
    options = options or {}; local world = ECS.World.new()
    registerBreakout(world)
    world:setResource("match", { status = "playing", remainingBricks = 0 })
    world:setResource("input", {})
    local game = setmetatable({ world = world, width = options.width or W, height = options.height or H }, Breakout)
    world:setResource("screen", { w = game.width, h = game.height })
    world:setResource("renderAssets", {})
    local scheduler = ECS.Scheduler.new(); game.scheduler = scheduler
    GameplaySystems.install(scheduler)
    scheduler:build(); game.runtime = ECS.Runtime.new({ world = world, scheduler = scheduler }); game.runtime:build(); game.runtime:initialize()
    game.runtime:runStage("startup", 0)
    return game
end

function Breakout:step(dt, input) self.world:setResource("input", input or {}); self.runtime:runStage("fixedUpdate", dt); return self.world:requireResource("match").status end
function Breakout:status() return self.world:requireResource("match") end
function Breakout:dispose() self.runtime:dispose() end
return Breakout
