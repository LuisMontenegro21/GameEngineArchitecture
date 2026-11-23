local Components = require("src.game.maps.Components")
local Resources = require("src.game.maps.Resources")
local Events = require("src.game.maps.Events")

return function(world)
    Components.register(world)
    Resources.register(world)
    Events.register(world)
    return world
end
