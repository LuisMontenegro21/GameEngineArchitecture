-- Runtime coordinator for one World and one Scheduler.

local Runtime = {}
Runtime.__index = Runtime

local states = setmetatable({}, { __mode = "k" })

local function stateOf(runtime)
    local state = states[runtime]
    assert(state ~= nil, "invalid Runtime")
    return state
end

local function ensureOpen(runtime, operation)
    local state = stateOf(runtime)
    assert(not state.disposed,
        "cannot " .. operation .. " on disposed runtime")
    return state
end

local function traceback(message)
    if debug and debug.traceback then
        return debug.traceback(message, 3)
    end
    return tostring(message)
end

function Runtime.new(options)
    options = options or {}
    assert(type(options) == "table", "runtime options must be a table")
    assert(options.world ~= nil, "Runtime requires a World")
    assert(options.scheduler ~= nil, "Runtime requires a Scheduler")
    assert(type(options.world.commands) == "function",
        "Runtime world does not implement the World API")
    assert(type(options.scheduler.addSystem) == "function",
        "Runtime scheduler does not implement the Scheduler API")

    local runtime = setmetatable({}, Runtime)
    states[runtime] = {
        world = options.world,
        scheduler = options.scheduler,
        ownsWorld = options.ownsWorld == true,
        clock = options.clock,
        trace = options.trace,
        timing = {},
        metrics = { stages = {}, systems = {}, flushes = 0 },
        enabled = {},
        initializedSystems = {},
        built = false,
        initialized = false,
        shutDown = false,
        disposed = false,
    }
    return runtime
end

function Runtime:addSystem(definition)
    local state = ensureOpen(self, "add system")
    assert(not state.built, "cannot add systems after runtime build")
    return state.scheduler:addSystem(definition)
end

function Runtime:build()
    local state = ensureOpen(self, "build runtime")
    assert(not state.initialized, "cannot rebuild an initialized runtime")
    state.scheduler:build()
    state.built = true
    state.shutDown = false
    return true
end

function Runtime:isBuilt()
    return stateOf(self).built
end

function Runtime:isInitialized()
    return stateOf(self).initialized
end

function Runtime:world()
    return stateOf(self).world
end

function Runtime:scheduler()
    return stateOf(self).scheduler
end

function Runtime:_context(system, stage, dt)
    local state = stateOf(self)
    return {
        world = state.world,
        runtime = self,
        scheduler = state.scheduler,
        system = system.name,
        stage = stage,
        dt = dt or 0,
        commands = state.world:commands(),
        emit = function(name, payload)
            return state.world:emit(name, payload)
        end,
    }
end

local function invoke(runtime, system, hook, context, stage)
    local callback = system[hook]
    if not callback then
        return
    end
    local ok, message = xpcall(function()
        callback(context)
    end, traceback)
    if not ok then
        error(("system %s failed during %s: %s"):format(
            system.name, stage, tostring(message)), 0)
    end
end

function Runtime:initialize()
    local state = ensureOpen(self, "initialize runtime")
    assert(state.built, "runtime must be built before initialization")
    assert(not state.initialized, "runtime is already initialized")

    for _, stage in ipairs(state.scheduler:stages()) do
        for _, system in ipairs(state.scheduler:systemsFor(stage)) do
            if state.enabled[system.name] ~= false then
                invoke(self, system, "initialize", self:_context(system, stage, 0), "initialize")
                state.initializedSystems[system.name] = true
            end
            if state.enabled[system.name] == nil then
                state.enabled[system.name] = true
            end
        end
    end
    state.initialized = true
    state.shutDown = false
    return true
end

function Runtime:runStage(stage, dt)
    local state = ensureOpen(self, "run stage")
    assert(state.built, "runtime must be built before running stages")
    assert(state.initialized, "runtime must be initialized before running stages")

    local systems = state.scheduler:systemsFor(stage)
    state.metrics.stages[stage] = (state.metrics.stages[stage] or 0) + 1
    if state.trace then state.trace({ kind = "stage.begin", stage = stage, dt = dt or 0 }) end
    local function execute()
        for _, system in ipairs(systems) do
            if state.enabled[system.name] ~= false then
                local context = self:_context(system, stage, dt)
                local start = state.clock and state.clock() or nil
                invoke(self, system, "run", context, stage)
                state.metrics.systems[system.name] = (state.metrics.systems[system.name] or 0) + 1
                if state.trace then state.trace({ kind = "system.run", system = system.name, stage = stage, dt = dt or 0 }) end
                if start then
                    state.timing[system.name] = (state.timing[system.name] or 0)
                        + state.clock() - start
                end
            end
        end
    end
    if stage == "render" and type(state.world.withReadOnly) == "function" then
        state.world:withReadOnly(execute)
        assert(state.world:commands():pending() == 0,
            "render systems cannot queue commands")
    else
        execute()
    end

    -- This is the default Phase 8 boundary policy. Commands recorded by the
    -- stage become visible first; events emitted by those commands become
    -- current only after the flush completes.
    state.metrics.flushes = state.metrics.flushes + state.world:flush()
    state.world:advanceEvents()
    if state.trace then state.trace({ kind = "stage.end", stage = stage, dt = dt or 0 }) end
    return true
end

function Runtime:runAll(dt)
    local state = ensureOpen(self, "run runtime")
    assert(state.initialized, "runtime must be initialized before running stages")
    for _, stage in ipairs(state.scheduler:stages()) do
        if stage ~= "shutdown" then
            self:runStage(stage, dt)
        end
    end
end

function Runtime:setSystemEnabled(name, enabled)
    local state = ensureOpen(self, "set system state")
    assert(type(enabled) == "boolean", "system enabled state must be boolean")
    local known = false
    for _, systemName in ipairs(state.scheduler:systemNames()) do
        if systemName == name then
            known = true
            break
        end
    end
    assert(known, "unknown system: " .. tostring(name))
    state.enabled[name] = enabled
end

function Runtime:isSystemEnabled(name)
    local state = stateOf(self)
    local value = state.enabled[name]
    return value == nil and true or value
end

function Runtime:timings()
    local result = {}
    for name, elapsed in pairs(stateOf(self).timing) do
        result[name] = elapsed
    end
    return result
end

function Runtime:setTrace(callback)
    assert(callback == nil or type(callback) == "function", "trace must be a function or nil")
    ensureOpen(self, "set trace").trace = callback
end

function Runtime:metrics()
    local source = stateOf(self).metrics; local result = { stages = {}, systems = {}, flushes = source.flushes }
    for k, v in pairs(source.stages) do result.stages[k] = v end
    for k, v in pairs(source.systems) do result.systems[k] = v end
    return result
end

function Runtime:shutdown()
    local state = ensureOpen(self, "shutdown runtime")
    if not state.initialized or state.shutDown then
        return false
    end

    local stages = state.scheduler:stages()
    for stageIndex = #stages, 1, -1 do
        local stage = stages[stageIndex]
        local systems = state.scheduler:systemsFor(stage)
        for i = #systems, 1, -1 do
            local system = systems[i]
            if state.initializedSystems[system.name] then
                invoke(self, system, "shutdown", self:_context(system, stage, 0), "shutdown")
                state.initializedSystems[system.name] = nil
            end
        end
    end
    state.shutDown = true
    state.initialized = false
    return true
end

function Runtime:dispose()
    local state = stateOf(self)
    if state.disposed then
        return false
    end
    if state.initialized then
        self:shutdown()
    end
    if state.ownsWorld and not state.world:isDisposed() then
        state.world:dispose()
    end
    state.disposed = true
    return true
end

return Runtime
