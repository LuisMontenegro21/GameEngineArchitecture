-- Public entry point for the new ECS implementation.
--
-- The existing Registry/Scene implementation lives in src.engine.legacy while
-- the new World, Scheduler, and Runtime are developed phase by phase. Keeping
-- this namespace independent prevents the legacy API from defining the new ECS
-- design.
--
local Entity = require("src.engine.ecs.Entity")
local ComponentRegistry = require("src.engine.ecs.ComponentRegistry")
local ComponentStore = require("src.engine.ecs.ComponentStore")

local ECS = {
    version = "0.1.0-dev",
    Entity = Entity,
    ComponentRegistry = ComponentRegistry,
    ComponentStore = ComponentStore,
    validationModes = {
        off = "off",
        warn = "warn",
        strict = "strict",
    },
}

return ECS
