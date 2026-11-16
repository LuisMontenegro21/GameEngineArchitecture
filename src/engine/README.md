# Engine modules

`src.engine` contains reusable, game-agnostic infrastructure.

- `ecs/`: the new ECS public API and its implementation, developed according to
  `planning.md`. Phases 1-5 currently provide generational entity handles,
  component definitions, sparse-set stores, the private-state World facade,
  normalized query views, and deferred command buffers.
- `legacy/`: the current Registry/Scene implementation retained temporarily so
  Breakout remains playable during migration. New engine code must not depend on
  it.
- `loop/`: timing and application-loop utilities that do not depend on game
  modules or LOVE.
- `scene/`: reserved for the future Scene and SceneStack layer. It will compose
  Worlds and Runtimes without becoming part of the ECS core.

Game-specific code belongs in `src.game`. The root `main.lua` and `conf.lua`
are the only LOVE entry points.
