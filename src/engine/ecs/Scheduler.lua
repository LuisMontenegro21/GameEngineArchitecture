-- Deterministic system schedule planner.
--
-- Scheduler resolves system order but never owns or mutates a World. Runtime is
-- responsible for invoking the resolved instances.

local System = require("src.engine.ecs.System")

local Scheduler = {}
Scheduler.__index = Scheduler

local states = setmetatable({}, { __mode = "k" })

local DEFAULT_STAGES = {
    "startup",
    "preUpdate",
    "fixedUpdate",
    "postFixedUpdate",
    "update",
    "postUpdate",
    "render",
    "shutdown",
}

local function stateOf(scheduler)
    local state = states[scheduler]
    assert(state ~= nil, "invalid Scheduler")
    return state
end

local function copyList(values)
    local result = {}
    for i, value in ipairs(values or {}) do
        result[i] = value
    end
    return result
end

local function has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end
    return false
end

local function intersects(left, right)
    for _, value in ipairs(left or {}) do
        if has(right, value) then
            return true
        end
    end
    return false
end

local function stageMap(stages)
    local result = {}
    for i, stage in ipairs(stages) do
        assert(type(stage) == "string" and stage ~= "",
            "scheduler stage names must be non-empty strings")
        assert(result[stage] == nil, "duplicate scheduler stage: " .. stage)
        result[stage] = i
    end
    return result
end

function Scheduler.new(options)
    options = options or {}
    assert(type(options) == "table", "scheduler options must be a table")
    local stages = copyList(options.stages or DEFAULT_STAGES)
    local scheduler = setmetatable({}, Scheduler)
    states[scheduler] = {
        stages = stages,
        stageIndex = stageMap(stages),
        definitions = {},
        order = {},
        resolved = {},
        built = false,
        diagnostic = options.diagnostic,
        conflicts = {},
    }
    return scheduler
end

function Scheduler:addSystem(definition)
    local state = stateOf(self)
    assert(not state.built, "cannot add systems after scheduler build")
    local system = System.new(definition)
    assert(state.definitions[system.name] == nil,
        "duplicate system name: " .. system.name)
    assert(state.stageIndex[system.stage] ~= nil,
        "unknown system stage: " .. system.stage)
    state.definitions[system.name] = system
    state.order[#state.order + 1] = system
    return system
end

function Scheduler:build()
    local state = stateOf(self)
    state.resolved = {}
    state.conflicts = {}

    for _, stage in ipairs(state.stages) do
        local nodes = {}
        local byName = {}
        for _, system in ipairs(state.order) do
            if system.stage == stage then
                nodes[#nodes + 1] = system
                byName[system.name] = system
            end
        end

        local edges = {}
        local indegree = {}
        for _, system in ipairs(nodes) do
            edges[system.name] = {}
            indegree[system.name] = 0
        end

        local function addEdge(before, after)
            assert(byName[before] and byName[after],
                "system dependency must target a system in the same stage: "
                    .. before .. " -> " .. after)
            if not has(edges[before], after) then
                edges[before][#edges[before] + 1] = after
                indegree[after] = indegree[after] + 1
            end
        end

        for _, system in ipairs(nodes) do
            for _, target in ipairs(system.before) do
                assert(state.definitions[target] ~= nil,
                    "unknown system dependency: " .. target)
                addEdge(system.name, target)
            end
            for _, target in ipairs(system.after) do
                assert(state.definitions[target] ~= nil,
                    "unknown system dependency: " .. target)
                addEdge(target, system.name)
            end
        end

        local ordered = {}
        local remaining = {}
        for _, system in ipairs(nodes) do
            remaining[system.name] = system
        end
        while #ordered < #nodes do
            local candidate = nil
            for _, system in ipairs(nodes) do
                if remaining[system.name] and indegree[system.name] == 0
                    and not candidate then
                    candidate = system
                end
            end
            assert(candidate ~= nil,
                "system dependency cycle in stage: " .. stage)
            remaining[candidate.name] = nil
            ordered[#ordered + 1] = candidate
            for _, target in ipairs(edges[candidate.name]) do
                indegree[target] = indegree[target] - 1
            end
        end
        state.resolved[stage] = ordered
    end

    -- Access conflicts are diagnostics only because Phase 8 remains
    -- single-threaded. They make an eventual parallel scheduler explicit.
    for _, stage in ipairs(state.stages) do
        local systems = state.resolved[stage]
        for i = 1, #systems do
            for j = i + 1, #systems do
                local left = systems[i]
                local right = systems[j]
                local conflict = intersects(left.writes, right.reads)
                    or intersects(left.writes, right.writes)
                    or intersects(right.writes, left.reads)
                    or intersects(left.writesResources, right.readsResources)
                    or intersects(left.writesResources, right.writesResources)
                    or intersects(right.writesResources, left.readsResources)
                if conflict then
                    local message = ("system access conflict in %s: %s and %s"):
                        format(stage, left.name, right.name)
                    state.conflicts[#state.conflicts + 1] = message
                    if state.diagnostic then
                        state.diagnostic(message)
                    end
                end
            end
        end
    end

    state.built = true
    return true
end

function Scheduler:isBuilt()
    return stateOf(self).built
end

function Scheduler:stages()
    return copyList(stateOf(self).stages)
end

function Scheduler:systemNames()
    local names = {}
    for name in pairs(stateOf(self).definitions) do
        names[#names + 1] = name
    end
    table.sort(names)
    return names
end

function Scheduler:systemsFor(stage)
    local state = stateOf(self)
    assert(state.built, "scheduler must be built before reading resolved systems")
    assert(state.stageIndex[stage] ~= nil, "unknown scheduler stage: " .. tostring(stage))
    local result = {}
    for i, system in ipairs(state.resolved[stage]) do
        result[i] = system
    end
    return result
end

function Scheduler:conflicts()
    return copyList(stateOf(self).conflicts)
end

return Scheduler
