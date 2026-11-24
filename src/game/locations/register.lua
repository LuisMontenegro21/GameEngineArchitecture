local Resources = require("src.game.locations.Resources")
local Events = require("src.game.locations.Events")
local Components = require("src.game.locations.Components")

return function(world)
    Components.register(world)
    Resources.register(world)
    Events.register(world)
    return world
end
