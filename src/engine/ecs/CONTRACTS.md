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
  applied by `World` before storage is touched.

## World facade

`World` is the public state boundary. Its mutable entity manager, component
registry, and stores are held privately; callers use World methods rather than
editing those objects directly.

- `World.new({ identity, validation, diagnostic })` creates an isolated world.
- `create(initialComponents)` preflights every component name, default, and
  validator before allocating an entity. A failed creation leaves entity count,
  stores, and structural version unchanged.
- `add`, `set`, `get`, `require`, `has`, `remove`, and `destroy` validate the
  generational entity handle before touching storage.
- Destroying an entity removes all of its components before invalidating its
  handle.
- `structuralVersion` changes on registration, creation, component add/remove,
  and entity destruction. Mutating a component value with `set` does not change
  it because the entity/component shape is unchanged.
- `validate()` checks component-store indexes and confirms every stored entity
  is alive in the entity manager.
- `clear()` destroys every live entity; `dispose()` clears the world and rejects
  subsequent mutation.
- World instances share no mutable state. A handle from one world is invalid in
  another, even when its ID and generation match.

## Query views

`World:query(specification)` returns a query instance. The specification accepts
`all`, `any`, `none`, `optional`, `changed`, and `stable` fields containing
component-name arrays.

- `all` requires every listed component; `any` requires at least one; `none`
  excludes every listed component.
- `optional` values do not affect membership. Iteration returns component values
  in normalized `all` output order followed by normalized `optional` output
  order. `any` and `none` are filters, not output columns.
- Duplicate names are normalized. A component cannot be both `all` and
  `optional`; unknown names fail when the query is created.
- Queries with required components plan from the smallest required store. A
  query with no required components scans live entities.
- Fast iteration uses dense storage order where possible. `stable = true` sorts
  matching entity IDs in ascending order and is deterministic.
- `each()` returns generational entity handles and output values. Normal
  exhaustion closes the iterator. If iteration stops early, callers must call
  `query:close()` before structural mutation.
- Structural changes while any query iterator is active fail immediately.
  Nested iterators are supported and independently counted.
- `changed` requires each listed component to have been touched since the query
  instance's last completed iteration. `World:set` marks a component changed;
  `World:touch` exists for in-place table edits.

## Command buffers

`World:commands()` returns the world's deferred structural command buffer.
Commands are data until `World:flush()` or `buffer:flush()` is called at a safe
boundary.

- `create` returns a temporary future-entity token. Commands recorded later in
  the same buffer may target that token; it resolves to a generational handle
  when its create command executes.
- `add`, `set`, `remove`, and `destroy` execute in recorded order. Before flush,
  they have no effect on queries, counts, or component values.
- Flushing while a query iterator is active fails. Systems may record commands
  during iteration, then the scheduler may flush after the iterator closes.
- Flush uses prefix-commit semantics: successful commands remain committed; the
  failing command raises a contextual error; the unexecuted suffix is discarded.
- Duplicate adds, updates to missing components, and operations on destroyed
  targets fail through the normal World contract. Removing a missing component
  is a documented no-op returning `false`.
- `clear()` discards pending commands and unresolved future tokens. Tokens are
  valid only for their originating buffer and pending flush.
- Command buffers do not silently flush and do not expose World storage.

## Event channels

`World:registerEvent(name, definition)` creates a double-buffered event channel.
Events are transient facts, not entities or components.

- `World:emit` validates a payload and appends it to the pending buffer. It does
  not allocate an entity ID.
- `World:advanceEvents` swaps pending events into the current buffer and clears
  the previous current buffer. Events are therefore visible only after an
  explicit boundary and expire at the next boundary.
- `World:events(name)` returns a non-destructive iterator over a snapshot of
  current records. Each record has `name`, `payload`, and monotonic `sequence`.
  Multiple readers receive independent snapshots in emission order.
- Events emitted while current events are being processed enter pending and
  cannot extend the current reader's iteration.
- Definitions support `version`, `validate`, and `maxQueue`. Queue-limit and
  payload-validation violations raise contextual errors.
- `eventCount`, `pendingEventCount`, `eventStats`, and `eventDefinition` provide
  diagnostics without exposing channel tables.
- `CommandBuffer:emit`/`emitEvent` defers emission to the normal command flush
  boundary. Event channels are isolated per World.

## Systems, Scheduler, and Runtime

Systems are the ECS behavior pillar. `System.new` normalizes a definition with a
unique name, stage, `run(context)`, optional `initialize`/`shutdown` hooks, and
component/resource access declarations.

- `Scheduler` owns system instances and resolves stage order. It does not own a
  World and cannot execute systems by itself.
- Stage order is explicit. `before` and `after` constraints are resolved by a
  stable topological sort; systems without constraints retain registration
  order. Missing dependencies and cycles fail during `build`.
- Read/write conflicts are reported through the scheduler diagnostic callback;
  Phase 8 remains single-threaded, so conflicts are diagnostics rather than
  parallel-execution failures.
- `Runtime` binds exactly one World to one Scheduler. It must be built and then
  initialized before a stage can run.
- Runtime stage execution supplies `world`, `runtime`, `scheduler`, `system`,
  `stage`, `dt`, `commands`, and an event-emission helper in the context.
- After each stage, Runtime flushes commands and advances event buffers. A
  system may record structural changes while iterating, but cannot force a
  flush through an active query.
- Enable/disable state belongs to the Runtime instance. Disabling a system in
  one Runtime does not affect another Runtime using the same definition.
- Every successfully initialized system receives exactly one shutdown callback,
  even if it was disabled after initialization. Shutdown occurs in reverse
  schedule order.
- Runtime errors identify the system and stage and retain the original
  traceback. Optional clock callbacks accumulate per-system timing diagnostics.

## Resources

Resources are world-level singleton values stored in a dedicated container.
They never allocate entity IDs and never participate in component queries.

- `registerResource(name, definition)` creates immutable metadata. Definitions
  support `version`, `validate`, `transient`, `serializable`, `owned`, and
  `onDispose`.
- `setResource` requires a registered type and a non-nil value. `getResource`
  returns `nil` when absent; `requireResource` raises when absent; `hasResource`
  distinguishes the two cases.
- `removeResource` returns the old value and a boolean, and is a no-op when no
  value is present.
- Transient resources always report `serializable = false`, allowing future
  snapshots to omit services, clocks, and other runtime-only values.
- Replacing, removing, or disposing an owned value clears the stored value
  before calling `onDispose`, so each value's hook runs at most once even if a
  hook raises. Other owned values still receive their hooks during container
  disposal.
- Setting the same object again is a no-op and does not dispose it.
- Resource definitions and values are isolated per World. Resource operations do
  not affect entity counts or component query membership.
- `CommandBuffer:setResource` and `removeResource` defer resource mutations to
  the same explicit flush boundary as entity commands.

