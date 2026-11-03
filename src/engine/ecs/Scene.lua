local Registry = require("src.engine.ecs.Registry")

local Scene = {}
Scene.__index = Scene

function Scene.new(name)
    -- assert(type(name) == "string", "scene names must be strings")
    local self = setmetatable({
        name = name,
        registry = Registry.new(),
        systems = {},
    }, Scene)
    return self

end

function Scene:addSystem(system)
    -- assert(type(system) == "table", "systems must be tables")
    -- assert(not self.isUnloaded, "cannot add a system to an unloaded scene")
    self.systems[#self.systems + 1] = system
    -- A system added to an active scene must be initialized immediately so it
    -- has the same lifecycle guarantees as the systems added before setup.
    -- if self.isSetup and system.setup then
    --     system.setup(self)
    -- end

    return system
end

function Scene:load()
    for _, system in ipairs(self.systems) do
        if system.load then 
            system.load()
        end
    end
end

function Scene:unload()
    for _, system in ipairs(self.systems) do
        if system.load then 
            system.unload()
        end
    end
end

function Scene:update(dt)
    for _, system in ipairs(self.systems) do
        if system.update then
            system.update(dt)
        end
    end

end

function Scene:render()
    for _, system in ipairs(self.systems) do
        if system.draw then
            system.draw(self)
        end
    end
end


return Scene
