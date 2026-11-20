# ECS 1.0 release gate

## Supported entry point

```lua
local ECS = require("src.engine.ecs")
```

The public API is version `1.0.0` (`ECS.apiVersion == 1`). Snapshot data uses
schema version `1` (`Snapshot.schemaVersion == "1.0"`). Components and
resources may declare their own integer schema versions and component migration
hooks.

## Verification command

From the repository root:

```text
"C:\Program Files (x86)\Lua\5.1\lua.exe" tests\run.lua
```

The test runner is headless and does not require LOVE. It covers ECS contracts,
runtime scheduling, fixed-step timing, relationships, snapshots, prefabs,
diagnostics, and ECS-native Breakout transitions.

## Manual LOVE checklist

1. Launch with `love .`.
2. Start a play round from the menu.
3. Move the paddle with Left/Right or A/D and verify screen clamping.
4. Verify ball wall/paddle/brick collisions and brick disappearance.
5. Miss the ball and verify `Game Over`.
6. Clear all bricks and verify `You win!`.
7. Restart and verify a fresh full brick layout.
8. Return to the menu and quit cleanly.

## Known limitations and migration policy

- The ECS core is LOVE- and Breakout-independent.
- `src.game.BreakoutECS` provides headless ECS gameplay; the existing LOVE
  scene/render adapter remains legacy until visual parity migration is complete.
- Snapshot encoding and filesystem persistence are intentionally separate.
- Future schema changes must increment the relevant version, provide a
  validation-first migration hook, and add a round-trip regression test.
- Public API changes require updating `CONTRACTS.md`, this release gate, and
  the complete test suite.
