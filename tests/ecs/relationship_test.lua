local World = require("src.engine.ecs.World")

return function()
    local world = World.new()
    local a, b, c = world:create(), world:create(), world:create()
    assert(world:setParent(b, a)); assert(world:setParent(c, b))
    assert(world:getParent(c).id == b.id)
    assert(#world:children(a) == 1 and #world:descendants(a) == 2)
    assert(not pcall(function() world:setParent(a, c) end))
    assert(world:setParent(c, nil)); assert(#world:descendants(a) == 1)
    assert(not pcall(function() world:destroy(a, "reject") end))
    world:destroy(a, "orphan"); assert(world:isAlive(b))

    local x, y = world:create(), world:create()
    world:commands():setParent(y, x)
    world:flush(); assert(world:getParent(y).id == x.id)
    world:commands():destroy(x, "cascade"); world:flush(); assert(not world:isAlive(y))
    world:dispose()
end
