local Components = require("src.game.ecs.Components")
local Resources = require("src.game.ecs.Resources")
local Events = require("src.game.ecs.Events")

return function(world)
    Components.register(world)
    Resources.register(world)
    Events.register(world)
    return world
end
