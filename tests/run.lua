-- Dependency-free headless test runner.
-- Run from the repository root with: lua tests/run.lua
-- The same script is valid under LuaJIT, which is the Lua runtime used by LOVE.

package.path = "./?.lua;./?/init.lua;" .. package.path

local tests = {
    "tests.ecs.phase0_test",
    "tests.ecs.entity_test",
    "tests.ecs.component_test",
    "tests.ecs.world_test",
    "tests.ecs.query_test",
    "tests.ecs.command_test",
    "tests.ecs.resource_test",
    "tests.ecs.event_test",
    "tests.ecs.runtime_test",
    "tests.ecs.loop_test",
    "tests.ecs.relationship_test",
    "tests.ecs.snapshot_test",
    "tests.ecs.diagnostics_test",
}

local passed = 0
local failed = 0

for _, name in ipairs(tests) do
    io.write("[TEST] " .. name .. " ... ")

    local loaded, test = pcall(require, name)
    if not loaded then
        failed = failed + 1
        io.write("FAIL\n")
        io.write(test .. "\n")
    elseif type(test) ~= "function" then
        failed = failed + 1
        io.write("FAIL\n")
        io.write("test module must return a function\n")
    else
        local ran, message = pcall(test)
        if ran then
            passed = passed + 1
            io.write("OK\n")
        else
            failed = failed + 1
            io.write("FAIL\n")
            io.write(message .. "\n")
        end
    end
end

io.write(("\n%d passed, %d failed\n"):format(passed, failed))
if failed > 0 then
    os.exit(1)
end
