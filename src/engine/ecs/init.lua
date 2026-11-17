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
local World = require("src.engine.ecs.World")
local CommandBuffer = require("src.engine.ecs.CommandBuffer")
local Resources = require("src.engine.ecs.Resources")
local Events = require("src.engine.ecs.Events")
local System = require("src.engine.ecs.System")
local Scheduler = require("src.engine.ecs.Scheduler")
local Runtime = require("src.engine.ecs.Runtime")
local Snapshot = require("src.engine.ecs.Snapshot")
local Prefab = require("src.engine.ecs.Prefab")

local ECS = {
    version = "1.0.0",
    apiVersion = 1,
    Entity = Entity,
    ComponentRegistry = ComponentRegistry,
    ComponentStore = ComponentStore,
    World = World,
    CommandBuffer = CommandBuffer,
    Resources = Resources,
    Events = Events,
    System = System,
    Scheduler = Scheduler,
    Runtime = Runtime,
    Snapshot = Snapshot,
    Prefab = Prefab,
    validationModes = {
        off = "off",
        warn = "warn",
        strict = "strict",
    },
}

return ECS
