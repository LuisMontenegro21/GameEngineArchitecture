# Engine modules

`src.engine` contains reusable, game-agnostic infrastructure.

- `ecs/`: the new ECS public API and its implementation, developed according to
  `planning.md`. Phases 1-8 currently provide generational entity handles,
  component definitions, sparse-set stores, the private-state World facade,
  normalized query views, deferred command buffers, dedicated resources, and
  double-buffered event channels, plus the Scheduler and Runtime execution
  layers. Phase 9 adds `loop/FixedStep`, a `Time` resource and `LoveRunner`:
  simulation ticks are fixed-rate and capped while rendering remains variable.
- `legacy/`: the current Registry/Scene implementation retained temporarily so
  Breakout remains playable during migration. New engine code must not depend on
  it.
- `loop/`: timing and application-loop utilities that do not depend on game
  modules or LOVE.
- `scene/`: reserved for the future Scene and SceneStack layer. It will compose
  Worlds and Runtimes without becoming part of the ECS core.

Game-specific code belongs in `src.game`. The root `main.lua` and `conf.lua`
are the only LOVE entry points.

`LoveRunner` is a thin adapter: it updates the transient `time` resource and
invokes Runtime stages. Render stages execute in a read-only World scope;
mutation or command flushing from render code is rejected.

World relationships support deterministic parent/child traversal, cycle-safe
reparenting, and `cascade`, `orphan`, or `reject` destruction policies. These
operations are also available through the deferred command buffer.

`Snapshot.capture` produces versioned plain Lua data containing opted-in
components, serializable resources, and relationship references. `Snapshot`
loading validates and prepares all records before mutating the destination;
component migration hooks handle older schema versions. `Prefab.capture` and
`Prefab.instantiate` provide independent entity graphs with root overrides.
Encoding and filesystem persistence remain outside the ECS.

Diagnostics are exposed through `world:inspect()` and
`world:validateDetailed()`, without private-state access. Runtime tracing can
be enabled with `Runtime.new({ trace = function(event) ... end })` or changed
with `runtime:setTrace(callback)`; `runtime:metrics()` reports stage/system
execution counts and flush totals. Tracing is observational and does not alter
simulation state.

Creation baseline on the reference Lua 5.1 environment (one scalar component):
1k entities: 0.004s, 10k: 0.028s, 100k: 0.279s. These are indicative rather
than hard performance guarantees.
