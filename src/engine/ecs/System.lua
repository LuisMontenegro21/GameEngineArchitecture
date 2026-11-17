-- Normalized system definition/instance.

local System = {}
System.__index = System

local function copyList(values)
    local result = {}
    if values then
        for i, value in ipairs(values) do
            result[i] = value
        end
    end
    return result
end

function System.new(definition)
    if type(definition) == "function" then
        definition = definition()
    end
    assert(type(definition) == "table", "system definition must be a table")
    assert(type(definition.name) == "string" and definition.name ~= "",
        "system name must be a non-empty string")
    assert(type(definition.run) == "function",
        "system must define a run(context) function: " .. definition.name)

    local instance = setmetatable({
        name = definition.name,
        stage = definition.stage or "update",
        run = definition.run,
        initialize = definition.initialize,
        shutdown = definition.shutdown,
        before = copyList(definition.before),
        after = copyList(definition.after),
        reads = copyList(definition.reads),
        writes = copyList(definition.writes),
        readsResources = copyList(definition.readsResources),
        writesResources = copyList(definition.writesResources),
    }, System)

    if instance.initialize ~= nil then
        assert(type(instance.initialize) == "function",
            "system initialize must be a function: " .. instance.name)
    end
    if instance.shutdown ~= nil then
        assert(type(instance.shutdown) == "function",
            "system shutdown must be a function: " .. instance.name)
    end
    assert(type(instance.stage) == "string" and instance.stage ~= "",
        "system stage must be a non-empty string: " .. instance.name)
    return instance
end

function System:metadata()
    return {
        name = self.name,
        stage = self.stage,
        before = copyList(self.before),
        after = copyList(self.after),
        reads = copyList(self.reads),
        writes = copyList(self.writes),
        readsResources = copyList(self.readsResources),
        writesResources = copyList(self.writesResources),
    }
end

return System
