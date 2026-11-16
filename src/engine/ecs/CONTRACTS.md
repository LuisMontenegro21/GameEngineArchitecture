# ECS Phase 0 contracts

This file defines the boundaries that the new ECS implementation must preserve.
It is intentionally independent of Breakout and must remain valid when the
legacy Registry/Scene implementation is removed.

## Public import

Game and engine code imports the ECS through:

```lua
local ECS = require("src.engine.ecs")
```

The directory's `init.lua` is the public facade. Internal modules and storage
tables are private implementation details. The facade currently exposes the
generational `Entity` manager and validation-mode metadata; later phases add
World, Scheduler, and Runtime constructors without changing this import path.

## Entity handles

An entity handle is a plain table containing an integer `id` and positive
integer `generation`. The entity manager owns both values and the caller must
not use an ID by itself as an entity reference.

- `create()` returns a new live handle.
- `isAlive(handle)` is a side-effect-free predicate and returns `false` for
  malformed, stale, destroyed, or disposed handles.
- `destroy(handle)` invalidates the handle, increments that ID's generation, and
  makes the ID eligible for recycling.
- A recycled ID always receives its incremented generation, so an old handle can
  never address the new entity.
- `Entity.equals(a, b)` compares both ID and generation.
- `Entity.toString(handle)` produces a stable diagnostic form such as
  `Entity(12:3)`.
- `entities()` returns fresh handles in ascending ID order; `each()` iterates a
  snapshot and does not expose internal tables.
- `count()` and `stats()` provide live-count diagnostics without revealing
  storage layout.

Entity managers are independent. A handle from one manager is never valid in
another manager, even if both use the same numeric ID and generation.

## Validation modes

Every World/Runtime may select one validation mode:

- `off`: skip optional invariant and schema checks intended only for
  development. Required argument checks may still reject impossible calls.
- `warn`: report invalid or suspicious operations through the configured
  diagnostic callback, then continue when safe.
- `strict`: raise a descriptive error immediately. Errors include the operation,
  entity/component/system when available, and the current world tick.

The default for tests and development is `strict`. A release configuration may
choose `off` after the same test suite passes. Validation mode is configuration,
not gameplay state, and must not change valid simulation results.

## Dependency boundaries

- `src.engine.ecs` must not require `love`, Breakout modules, scenes, or the
  legacy Registry/Scene implementation.
- Engine modules may depend on other engine modules only through documented
  interfaces.
- Game modules may depend on engine APIs, never on engine private storage.
- LOVE callbacks belong in `main.lua` or an engine adapter under `src.engine`;
  core ECS code must run in plain Lua/LuaJIT.
- The old implementation is available only under `src.engine.legacy` during
  migration and must not be imported by new ECS modules.

## Lua 5.1/LuaJIT rules

- Use `unpack`, not `table.unpack`.
- Do not use `goto`, `//`, bitwise operators, or other Lua 5.2+ syntax.
- Do not assume `love` or a global clock exists in core modules.
- Do not keep mutable per-world or per-runtime state in module-level tables;
  `require` caches modules.
- Use explicit ownership and disposal hooks for external resources. Do not rely
  on garbage-collection finalizers for correctness.
- Avoid relying on unordered `pairs` iteration for simulation order. Use stable
  sorting or explicit registration order where determinism matters.
- Keep component data plain and serializable unless a component definition
  explicitly supplies a codec.

## Structural mutation

Creating/destroying entities and adding/removing components are structural
changes. Queries may inspect and mutate component values, but systems must use a
CommandBuffer for structural changes while a query is active. The Runtime owns
normal flush boundaries; arbitrary systems must not flush the buffer.

## Component definitions and stores

Component names are registered once in a `ComponentRegistry`. Registration
returns an immutable definition containing a numeric type ID, schema version,
tag flag, optional default factory, validator, and future serialization hooks.

- Registering a duplicate name fails.
- Requiring an unknown name fails descriptively.
- Mutable defaults must be factory functions. Each `add` call invokes the
  factory and receives an independent value.
- A tag definition uses membership only and cannot declare a default value.
- Store `add` fails when the entity already has the component; `set` fails when
  it does not; `remove` reports whether a value existed.
- Component stores use dense/sparse membership with swap-remove. Iteration order
  is storage order and is not a simulation-order guarantee.
- Tag stores contain no per-entity value array.
- Stores accept numeric entity IDs only. World-level handle/generation checks are
  added when Phase 3 introduces `World`.

