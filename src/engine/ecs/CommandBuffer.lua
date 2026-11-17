-- Deferred structural commands for one World.
--
-- Commands are recorded while systems or query iterators run and are applied
-- only when World:flush reaches a safe boundary. A failed flush commits its
-- successful prefix, reports the failing command, and discards the remaining
-- suffix together with unresolved temporary entity tokens.

local CommandBuffer = {}
CommandBuffer.__index = CommandBuffer

local states = setmetatable({}, { __mode = "k" })

local function stateOf(buffer)
    local state = states[buffer]
    assert(state ~= nil, "invalid CommandBuffer")
    return state
end

local function append(state, kind, fields)
    fields.kind = kind
    state.commands[#state.commands + 1] = fields
end

function CommandBuffer.new(world)
    assert(world ~= nil, "CommandBuffer requires a World")
    local buffer = setmetatable({}, CommandBuffer)
    states[buffer] = {
        world = world,
        commands = {},
        tokens = {},
    }
    return buffer
end

function CommandBuffer:create(initialComponents)
    local state = stateOf(self)
    local token = {}
    state.tokens[token] = { token = token, resolved = nil }
    append(state, "create", {
        components = initialComponents,
        token = token,
    })
    return token
end

CommandBuffer.spawn = CommandBuffer.create

function CommandBuffer:add(target, name, value)
    append(stateOf(self), "add", {
        target = target,
        name = name,
        value = value,
    })
end

function CommandBuffer:set(target, name, value)
    append(stateOf(self), "set", {
        target = target,
        name = name,
        value = value,
    })
end

function CommandBuffer:remove(target, name)
    append(stateOf(self), "remove", {
        target = target,
        name = name,
    })
end

function CommandBuffer:destroy(target, policy)
    append(stateOf(self), "destroy", {
        target = target,
        policy = policy,
    })
end

function CommandBuffer:setParent(child, parent)
    append(stateOf(self), "setParent", { target = child, parent = parent })
end
CommandBuffer.reparent = CommandBuffer.setParent

function CommandBuffer:setResource(name, value)
    append(stateOf(self), "setResource", {
        name = name,
        value = value,
    })
end

function CommandBuffer:removeResource(name)
    append(stateOf(self), "removeResource", {
        name = name,
    })
end

function CommandBuffer:emit(name, payload)
    append(stateOf(self), "emit", {
        name = name,
        payload = payload,
    })
end

CommandBuffer.emitEvent = CommandBuffer.emit

function CommandBuffer:count()
    return #stateOf(self).commands
end

function CommandBuffer:pending()
    return self:count()
end

function CommandBuffer:_resolve(target)
    local state = stateOf(self)
    local token = state.tokens[target]
    if token then
        assert(token.resolved ~= nil,
            "future entity token has not been created yet")
        return token.resolved
    end
    return target
end

function CommandBuffer:_execute(command)
    local state = stateOf(self)
    local world = state.world

    if command.kind == "create" then
        local handle = world:create(command.components)
        state.tokens[command.token].resolved = handle
        return
    end

    if command.kind == "setResource" then
        world:setResource(command.name, command.value)
        return
    end

    if command.kind == "removeResource" then
        world:removeResource(command.name)
        return
    end

    if command.kind == "emit" then
        world:emit(command.name, command.payload)
        return
    end

    local target = self:_resolve(command.target)
    if command.kind == "setParent" then
        local parent = command.parent and self:_resolve(command.parent) or nil
        world:setParent(target, parent)
        return
    end
    if command.kind == "add" then
        world:add(target, command.name, command.value)
    elseif command.kind == "set" then
        world:set(target, command.name, command.value)
    elseif command.kind == "remove" then
        world:remove(target, command.name)
    elseif command.kind == "destroy" then
        world:destroy(target, command.policy)
    else
        error("unknown command kind: " .. tostring(command.kind), 0)
    end
end

function CommandBuffer:_retireTokens()
    local state = stateOf(self)
    state.tokens = {}
end

function CommandBuffer:_flush()
    local state = stateOf(self)
    assert(state.world:isDisposed() == false,
        "cannot flush commands into a disposed world")

    local commands = state.commands
    state.commands = {}
    local executed = 0

    for index, command in ipairs(commands) do
        local ok, message = pcall(function()
            self:_execute(command)
        end)
        if not ok then
            self:_retireTokens()
            error(("command %d (%s) failed: %s"):format(
                index, command.kind, tostring(message)), 0)
        end
        executed = executed + 1
    end

    self:_retireTokens()
    return executed
end

function CommandBuffer:flush()
    return stateOf(self).world:flush()
end

function CommandBuffer:clear()
    local state = stateOf(self)
    state.commands = {}
    self:_retireTokens()
end

return CommandBuffer
