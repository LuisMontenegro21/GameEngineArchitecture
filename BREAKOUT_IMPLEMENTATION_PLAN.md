# Breakout Implementation Plan

## Objective

Build a small Breakout game in Lua and LOVE 11.5 using the repository's
current ECS architecture. Reuse working Pong-era code where it genuinely
matches Breakout, while keeping systems small and single-purpose.

The completed game must provide:

- One keyboard-controlled paddle that moves horizontally and stays onscreen.
- Delta-time-based movement.
- One rectangular ball that moves continuously.
- Ball reflection from the top, left, and right edges.
- A loss when the ball crosses the bottom edge, displaying `Game Over`.
- A grid of rectangular bricks that disappear when hit.
- A win when all bricks are destroyed, displaying `You win!`.

## Current repository baseline

### Reuse without redesign

- `src/ecs/Registry.lua`
  - Entity creation and destruction.
  - Component lookup and queries.
  - Snapshot iteration through `each`.
  - Singleton resources.
  - Reflection helpers for debug tools.
- `src/ecs/Scene.lua`
  - Ordered systems.
  - `setup`, `update`, `draw`, and `unload` lifecycle.
  - Per-scene registries and debug system toggles.
- `src/Game.lua`
  - Scene factories.
  - Deferred scene switching through `switchRequest` entities.
  - One-frame keyboard events.
- `src/Screen.lua`
  - One logical screen size shared by gameplay systems.
- `src/systems/MovementSystem.lua`
  - Generic delta-time integration for `position + velocity` entities.
- `src/systems/PaddleHitsSystem.lua`
  - Its AABB overlap test and push-out idea are reusable, although the bounce
    axis must change from Pong's horizontal bounce to Breakout's vertical one.
- Menu and result-screen concepts.
  - The existing scene transition pattern can remain.

### Repair before adding gameplay

- `main.lua` currently contains a duplicate of `Game.lua` instead of LOVE
  callbacks and scene registration.
- `src/scenes/GameOverScene.lua` also contains a duplicate of `Game.lua`.
- `src/systems/WinCheckSystem.lua` is a duplicate of `ScoringSystem.lua`.
- Several systems still implement Pong behavior rather than Breakout behavior.
- Debug mode requires `lib/imlove.lua`, which is not currently present. Debug
  attachment must remain disabled until that dependency is restored.

Do not debug bricks or collision behavior until these boot blockers are fixed.

## Target architecture

```text
LOVE callbacks (main.lua)
+-- Game
    +-- MenuScene
    +-- PlayScene
    |   +-- Registry
    |   +-- Ordered Breakout systems
    +-- GameOverScene
        +-- result resource: "won" or "lost"
        +-- result input/render systems
```

### Entity component shapes

```lua
-- Paddle
{
    position = { x = 0, y = 0 },
    size = { w = 96, h = 16 },
    velocity = { vx = 0, vy = 0 },
    paddle = { speed = 420, leftKey = "left", rightKey = "right" },
    clampHorizontal = {},
}

-- Ball
{
    position = { x = 0, y = 0 },
    size = { w = 12, h = 12 },
    velocity = { vx = 220, vy = -220 },
    ball = {},
}

-- Brick
{
    position = { x = 0, y = 0 },
    size = { w = 64, h = 20 },
    brick = { row = 1, color = { 1, 1, 1 } },
}
```

### Scene resources

```lua
registry:setResource("breakout", {
    remainingBricks = 0,
    status = "playing",
})
```

The resource holds scene-wide state. Positions and velocities remain ordinary
components because they belong to individual entities.

## Implementation phases

## Phase 1 - Restore a runnable application shell

### 1. Replace `main.lua` with LOVE callbacks

The entry point should:

1. Require `src.Game` and all three scene factories.
2. Register `menu`, `play`, and `gameover`.
3. Start the menu scene from `love.load`.
4. Forward `love.update`, `love.draw`, `love.keypressed`, and `love.quit` to
   `Game`.
5. Attach debug tooling only when `--debug` is requested and the required
   library is actually available.

Expected callback flow:

```text
love.load       -> register scenes -> Game.start("menu")
love.update(dt) -> Game.update(dt)
love.draw       -> Game.draw()
love.keypressed -> Game.keypressed(key)
love.quit       -> Game.quit()
```

### 2. Restore `GameOverScene.lua` as a scene factory

The scene factory should:

1. Create `Scene.new("gameover")`.
2. Convert its payload into a `result` resource.
3. Add the result input and rendering systems.
4. Use safe defaults if entered directly from debug tooling.

Suggested payload:

```lua
{
    result = "won", -- or "lost"
}
```

### 3. Smoke-test the engine lifecycle

Before implementing Breakout, use temporary minimal scene systems or the menu
to confirm:

- `love .` opens without a module error.
- SPACE changes from menu to play.
- ESC exits.
- A `switchRequest` is applied after the current update.
- Re-entering a scene creates a fresh registry.

**Phase 1 exit condition:** menu, empty play scene, and result scene can switch
between each other without crashing.

## Phase 2 - Establish reliable timing

### 1. Use LOVE's delta time

Continue using the existing movement equation:

```lua
position.x = position.x + velocity.vx * dt
position.y = position.y + velocity.vy * dt
```

Speeds are pixels per second. Systems must not call `os.clock()` independently.

### 2. Separate render FPS from physics frequency

The requested presentation cap is 10 FPS, but a Breakout ball can cross a thin
brick during a 0.1-second update. Use a fixed physics step even if rendering is
capped:

```text
render target: 10 FPS
simulation step: 1/120 second
maximum accepted frame delta: 0.25 second
```

Maintain an accumulator in `main.lua` and call `Game.update(1 / 120)` until it
has consumed the frame delta. Use `love.timer.sleep` for an eventual frame cap;
do not use a busy-wait loop.

Initially, leave the default LOVE/VSync render rate enabled. Add the 10 FPS cap
only after collisions are correct, so timing bugs are easier to diagnose.

**Phase 2 exit condition:** a test entity travels the same distance per second
at different render rates.

## Phase 3 - Create the initial Breakout world

Add a dedicated `BreakoutSetupSystem` or adapt the ownership of the existing
setup systems. Its `setup(scene)` should create:

1. One paddle centered near the bottom.
2. One ball above the paddle.
3. A brick grid near the top.
4. The `breakout` resource with the exact number of spawned bricks.

### Brick layout

Define constants in the setup system:

```text
rows
columns
brick width and height
horizontal and vertical gap
top margin
```

Compute the grid's total width first and center it using `Screen.w`. Do not
hardcode every brick position.

**Phase 3 exit condition:** paddle, ball, and centered brick grid render as
rectangles, even before any movement or collision logic is enabled.

## Phase 4 - Convert paddle control from Pong to Breakout

Adapt `PaddleControlSystem.lua`:

1. Spawn only one paddle, or move spawning into `BreakoutSetupSystem`.
2. Read left/right keys instead of up/down keys.
3. Write only `velocity.vx`; always set `velocity.vy = 0`.
4. Support arrow keys and optionally A/D.
5. Keep movement in `MovementSystem`; input must not directly change position.

Adapt `ClampSystem.lua` or create `HorizontalClampSystem.lua`:

```lua
position.x = math.max(0, math.min(Screen.w - size.w, position.x))
```

Keeping horizontal and vertical clamp behavior in separate atomic systems is
preferable to filling one system with game-specific branches.

**Phase 4 exit condition:** the paddle moves smoothly left/right and cannot
leave either side of the screen.

## Phase 5 - Implement ball movement and screen boundaries

Reuse `MovementSystem` unchanged.

Replace Pong's boundary behavior with two atomic systems:

### `BallWallBounceSystem`

For each ball:

- Left: clamp `x = 0`, then set `vx = abs(vx)`.
- Right: clamp `x = Screen.w - width`, then set `vx = -abs(vx)`.
- Top: clamp `y = 0`, then set `vy = abs(vy)`.

Assigning the velocity sign is safer than multiplying by `-1`, because the ball
cannot repeatedly invert while still overlapping a boundary.

### `BallLossSystem`

When `position.y >= Screen.h`:

1. Set the breakout status to `lost`.
2. Spawn one `switchRequest` to `gameover` with `{ result = "lost" }`.
3. Ensure it cannot spawn the request repeatedly.

**Phase 5 exit condition:** the ball reflects from three edges and reaching the
bottom displays `Game Over`.

## Phase 6 - Adapt paddle collision

Reuse the AABB function from `PaddleHitsSystem.lua`, but change the resolution
for a horizontal paddle:

1. Only accept a hit when the ball is moving downward (`vy > 0`).
2. Move the ball to `paddle.y - ball.height`.
3. Set `vy = -abs(vy)`.
4. Calculate the horizontal hit offset from paddle center.
5. Add the offset to `vx`, then constrain the resulting speed if needed.

This one-way check prevents the underside of the paddle from pulling a rising
ball back downward.

**Phase 6 exit condition:** repeated paddle hits never leave the ball embedded
in the paddle, and different hit positions change its horizontal direction.

## Phase 7 - Add brick collision and destruction

Create `BrickCollisionSystem.lua`.

For every ball and brick pair:

1. Test AABB overlap.
2. Determine the collision axis using the ball's previous position or minimum
   penetration depth.
3. Push the ball outside the brick.
4. Reflect `vx` for a side hit or `vy` for a top/bottom hit.
5. Destroy the brick entity.
6. Decrement `breakout.remainingBricks` exactly once.
7. Stop processing that ball for the current physics step after resolving one
   brick, preventing two velocity inversions from cancelling each other.

The Registry's `each` iterator takes a query snapshot, so destroying a brick
during iteration is supported. Still, the system must ensure one brick cannot
be counted twice by multiple balls or collision passes.

**Phase 7 exit condition:** every valid hit removes one brick and produces a
stable bounce without skipped or double-counted bricks.

## Phase 8 - Implement the win condition

Replace the duplicated `WinCheckSystem.lua` with real Breakout logic:

1. Read the `breakout` resource.
2. Do nothing unless `status == "playing"`.
3. When `remainingBricks == 0`, set `status = "won"`.
4. Spawn one scene switch request with `{ result = "won" }`.

The result renderer should display exactly:

```text
won  -> You win!
lost -> Game Over
```

SPACE should return to the menu or immediately start a fresh play scene.

**Phase 8 exit condition:** destroying the final brick displays `You win!`, and
restarting reconstructs the full grid.

## Phase 9 - Split and simplify rendering

Following the repository's atomic-system guideline, prefer:

- `ShapeRenderSystem`: draws positioned rectangles.
- `BrickRenderSystem`: optional row colors for bricks.
- `HudRenderSystem`: status/debug text if needed.
- `ResultRenderSystem`: draws `Game Over` or `You win!`.

Remove Pong-specific center-line and score rendering. Reset graphics color after
colored brick rendering so later entities do not inherit the last brick color.

**Phase 9 exit condition:** rendering contains no Pong court, two-player score,
or Pong-specific instructions.

## Phase 10 - Reintroduce tools and optional persistence

These are post-MVP tasks:

1. Restore/vendor `lib/imlove.lua` before attaching `DebugOverlay`.
2. Verify the inspector can enumerate entities and components through the
   existing Registry reflection functions.
3. Use the scene system toggles to test each atomic system independently.
4. Adapt `SaveFile` only if persistent high scores or settings are wanted.

Serialization and high scores are not required for the first playable
Breakout version and should not block it.

## Final PlayScene system order

System order is behavior in this ECS. Use an explicit order similar to:

```lua
scene:addSystem(BreakoutSetupSystem)       -- setup only
scene:addSystem(PaddleControlSystem)       -- input -> velocity
scene:addSystem(MovementSystem)            -- integrate using dt
scene:addSystem(HorizontalClampSystem)     -- keep paddle onscreen
scene:addSystem(BallWallBounceSystem)      -- left/right/top boundaries
scene:addSystem(PaddleHitsSystem)          -- paddle collision
scene:addSystem(BrickCollisionSystem)      -- brick collision/destruction
scene:addSystem(BallLossSystem)            -- bottom boundary loses
scene:addSystem(WinCheckSystem)            -- no bricks wins
scene:addSystem(ShapeRenderSystem)          -- draw world
scene:addSystem(HudRenderSystem)            -- draw UI last
```

If the ball can cross the paddle and bottom boundary within one step, keep the
fixed simulation step small and process paddle collision before loss detection.

## Suggested file disposition

| Current file | Action |
|---|---|
| `main.lua` | Replace duplicate Game module with LOVE bootstrap |
| `src/Game.lua` | Keep; harden only if a concrete issue appears |
| `src/ecs/Registry.lua` | Keep |
| `src/ecs/Scene.lua` | Keep |
| `src/scenes/MenuScene.lua` | Reuse with Breakout title text |
| `src/scenes/PlayScene.lua` | Rebuild system list for Breakout |
| `src/scenes/GameOverScene.lua` | Replace duplicate Game module with result scene |
| `MovementSystem.lua` | Reuse unchanged |
| `PaddleControlSystem.lua` | Convert to one horizontal paddle |
| `ClampSystem.lua` | Replace or specialize for horizontal clamping |
| `BounceWallsSystem.lua` | Replace with Breakout wall behavior |
| `PaddleHitsSystem.lua` | Reuse AABB; change bounce axis |
| `ScoringSystem.lua` | Remove from PlayScene; Pong-only |
| `WinCheckSystem.lua` | Replace duplicate with remaining-bricks check |
| `BallSpawnSystem.lua` | Adapt or replace with setup-owned single ball |
| `RenderSystem.lua` | Remove Pong UI; split into atomic render systems |
| `HighScoreSystem.lua` | Defer until after MVP |

## Verification checklist

### Boot and lifecycle

- [ ] `love .` starts at the menu without module errors.
- [ ] SPACE starts a fresh Breakout scene.
- [ ] ESC exits normally.
- [ ] Restarting creates a complete new brick grid.

### Movement and input

- [ ] Paddle movement uses `speed * dt`.
- [ ] Paddle cannot leave the left or right edge.
- [ ] Ball speed is consistent at different render frame rates.

### Collision

- [ ] Ball reflects from left, right, and top boundaries.
- [ ] Ball does not reflect from the bottom boundary.
- [ ] Ball reflects upward from the paddle.
- [ ] Ball is pushed out of colliders and does not jitter inside them.
- [ ] One brick is removed and counted per collision.
- [ ] Fast movement does not tunnel through bricks under the fixed step.

### Outcomes

- [ ] Crossing the bottom displays `Game Over`.
- [ ] Destroying the final brick displays `You win!`.
- [ ] Terminal transitions occur once, not once per frame.
- [ ] SPACE from the result screen allows another game.

### Cleanup

- [ ] No Pong score, center line, two-player controls, or serve logic remains
      active in PlayScene.
- [ ] Every system has one clear responsibility.
- [ ] No debug dependency is required during normal play.

## Recommended implementation milestones

1. **Bootable shell:** repaired main and scenes.
2. **Playable loop:** paddle, moving ball, three-wall bounce, bottom loss.
3. **Breakout core:** brick grid, brick collision, win condition.
4. **Stability:** fixed-step simulation and collision edge cases.
5. **Presentation:** menu/result text, colors, restart flow.
6. **Optional tooling:** inspector, frame controls, settings/high score.

Do not begin milestone 3 until milestone 2 is reliable. A brick grid makes
collision problems harder to isolate; the single paddle and wall loop is the
smallest useful environment for validating movement and response first.
