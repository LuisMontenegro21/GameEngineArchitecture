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
    "tests.phase14_release_test",
    "tests.scene_test",
    "tests.scene_runner_test",
    "tests.scene_event_transition_test",
    "tests.progression_cycle_test",
    "tests.arcane_data_test",
    "tests.game_session_alpha_test",
    "tests.training_scene_test",
    "tests.card_acquisition_scene_test",
    "tests.card_generation_alpha_test",
    "tests.arcane_daily_cycle_test",
    "tests.encounter_definitions_test",
    "tests.encounter_systems_test",
    "tests.final_conversation_scene_test",
    "tests.final_conversation_ui_test",
    "tests.homecoming_final_test",
    "tests.arcane_complete_scene_test",
    "tests.ui_setup_test",
    "tests.ui_visual_theme_test",
    "tests.map_data_test",
    "tests.map_tile_foundation_test",
    "tests.map_terrain_paths_test",
    "tests.map_asset_pipeline_test",
    "tests.map_sprite_conversion_test",
    "tests.academy_map_scene_test",
    "tests.map_movement_test",
    "tests.map_collision_test",
    "tests.map_point_of_interest_test",
    "tests.map_hud_ui_test",
    "tests.map_interaction_test",
    "tests.map_activity_test",
    "tests.character_schedule_test",
    "tests.daily_conversation_test",
    "tests.map_scene_integration_test",
    "tests.map_render_test",
    "tests.love_render_smoke_test",
    "tests.location_payload_test",
    "tests.location_catalog_test",
    "tests.academy_location_scene_test",
    "tests.location_presentation_test",
    "tests.location_entry_return_test",
    "tests.location_activity_dialogue_test",
    "tests.location_daily_conversation_test",
    "tests.location_movement_interaction_test",
    "tests.location_contract_test",
    "tests.location_cycle_integration_test",
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
