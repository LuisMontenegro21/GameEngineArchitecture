# ECS Breakout

A small Breakout game built in Lua with LOVE 11.5. The project uses a custom
Entity Component System (ECS), scene factories, event entities, and fixed-step
physics.

## Gameplay

The player controls one paddle at the bottom of the screen. Keep the ball in
play and destroy all 50 bricks.

- The paddle moves horizontally and cannot leave the screen.
- The ball bounces from the left, right, and top edges.
- Paddle hits send the ball upward and influence its horizontal direction.
- A brick disappears when the ball hits it.
- Letting the ball reach the bottom displays `Game Over`.
- Destroying every brick displays `You win!`.
- Each new game reconstructs the complete board and state.

## Requirements

- [LOVE 11.5](https://love2d.org/)
- Windows, macOS, or Linux

No external Lua packages are required for normal gameplay.

## Running the game

Open a terminal in the repository root and run:

```sh
love .
```

On Windows PowerShell, if `love` is not on `PATH`, run:

```powershell
& "C:\Program Files\LOVE\love.exe" .
```

To open a console for runtime errors on Windows:

```powershell
& "C:\Program Files\LOVE\love.exe" --console .
```

## Controls

| Action | Keys |
|---|---|
| Start the game | `Space` |
| Move left | `Left Arrow` or `A` |
| Move right | `Right Arrow` or `D` |
| Return to the menu after a round | `Space` |
| Quit | `Escape` |

## Scene flow

```text
MenuScene --Space--> PlayScene
PlayScene --ball lost--> GameOverScene (Game Over)
PlayScene --all bricks destroyed--> GameOverScene (You win!)
GameOverScene --Space--> MenuScene
```

`src/game/Game.lua` owns the active scene. Systems request a transition by spawning
a `switchRequest` entity. The Game applies that request after the current scene
update finishes, avoiding scene destruction during system iteration.

## ECS architecture

The ECS consists of:

- **Entities:** numeric identifiers returned by `Registry:spawn`.
- **Components:** plain Lua tables stored by component name and entity ID.
- **Systems:** small modules with optional `setup`, `update`, `draw`, and
  `unload` functions.
- **Resources:** singleton scene data accessed with `setResource` and
  `resource`.
- **Scenes:** an ordered system list with its own Registry.

Important gameplay components include:

```text
position         x/y coordinates
size             rectangle width/height
velocity         horizontal/vertical speed in pixels per second
moves            enables fixed-step movement
paddle           paddle speed and key bindings
ball             identifies the ball
brick            identifies a brick and stores its color
clampHorizontal  keeps the paddle inside the screen
renderShape      selects generic rectangle rendering
```

The PlayScene owns one `breakout` resource:

```lua
{
    remainingBricks = 50,
    status = "playing", -- playing, lost, or won
}
```

## PlayScene system order

System order is significant because later systems process the state produced by
earlier systems:

```text
BreakoutSetupSystem
PaddleControlSystem
MovementSystem
ClampSystem
BallWallBounceSystem
PaddleHitsSystem
BrickCollisionSystem
BallLossSystem
WinCheckSystem
ShapeRenderSystem
BrickRenderSystem
HudRenderSystem
```

The systems remain intentionally focused. Input writes velocity, movement
integrates position, collision systems resolve individual collision types, and
render systems draw only their assigned data.

## Timing and delta time

LOVE supplies a variable frame delta to `love.update(dt)`. `src/engine/loop/FixedStep.lua`
accumulates that time and advances gameplay at a fixed rate:

```text
Physics frequency: 120 Hz
Physics step:      1 / 120 second
Maximum frame dt:  0.25 second
Rendering:         controlled independently by LOVE/VSync
```

Movement uses pixels per second:

```lua
position.x = position.x + velocity.vx * dt
position.y = position.y + velocity.vy * dt
```

Fixed physics reduces collision tunneling and makes movement independent from
the render frame rate. The game does not currently enforce a 10 FPS rendering
cap.

## Collision behavior

- Wall collision clamps the ball outside the wall before assigning the correct
  velocity direction.
- Paddle collision only accepts a descending ball, pushes it above the paddle,
  and modifies horizontal velocity based on hit position.
- Brick collision resolves the smallest overlap axis and processes at most one
  brick per ball per physics step.
- Bottom-edge contact is a loss and never reflects the ball upward.

## Project structure

```text
main.lua                    LOVE callbacks and fixed-step integration
conf.lua                    window title, resolution, and LOVE version
src/engine/ecs/             new ECS API, entity manager, and component stores
src/engine/legacy/          temporary Registry/Scene used during migration
src/engine/loop/            reusable fixed-step timing utility
src/game/Game.lua           scene registration and transitions
src/game/Screen.lua         logical 960x540 resolution
src/game/scenes/            menu, play, and result scene factories
src/game/systems/           Breakout gameplay and rendering systems
```

## Manual verification checklist

1. Start the game and press `Space`.
2. Confirm the paddle moves with arrows and A/D.
3. Confirm the paddle remains inside both horizontal edges.
4. Confirm the ball bounces from the top and side walls.
5. Confirm paddle contact sends the ball upward.
6. Confirm struck bricks disappear and the HUD count decreases.
7. Miss the ball and confirm `Game Over` appears.
8. Clear every brick and confirm `You win!` appears.
9. Press `Space` on the result screen and start another game.
10. Confirm the new game contains all 50 bricks.

## Headless ECS checks

Phase 0 includes a dependency-free sanity suite for the new ECS boundary. Run
it with Lua or LuaJIT from the repository root:

```sh
lua tests/run.lua
```

The new ECS is currently only a public import boundary. Breakout still runs on
the temporary implementation under `src/engine/legacy` until the migration
phase in `planning.md`.

## Current scope

The playable game includes the complete Breakout loop. Sound effects, lives,
score persistence, visual effects, and the optional ImGui-based debug overlay
are outside the current gameplay scope.
