# Wizard Academia

Wizard Academia is a small keyboard-driven fantasy dating-sim progression loop
written in Lua for LOVE 11.5. It uses this repository's custom ECS, scheduler,
runtime, and scene manager rather than an external ECS library.

The game is intentionally scoped to the assignment's progression cycle:

```text
Train at the academy
    → improve attributes and manage energy
    → receive three conversation cards influenced by training
    → acquire one card for a persistent collection
    → begin the next day
```

After five academy days, the game shows a completion screen.

## Requirements

- [LOVE 11.5](https://love2d.org/) to play.
- Lua 5.1, LuaJIT, or a compatible Lua runtime for headless tests.

No external Lua package is required for normal gameplay.

## Run

From the repository root:

```sh
love .
```

On Windows PowerShell, when LOVE is not on `PATH`:

```powershell
& "C:\Program Files\LOVE\love.exe" .
```

## Controls

| Scene | Action | Keys |
| --- | --- | --- |
| Training | Select an activity | `Up`/`Down` or `W`/`S` |
| Training | Perform selected activity | `Enter` or `Space` |
| Card Acquisition | Change selected generated card or collection card | `Left`/`Right` or `A`/`D` |
| Card Acquisition | Switch generated-card / collection focus | `Tab` |
| Card Acquisition | Acquire selected card; after acquisition, start the next day | `Enter` or `Space` |
| Any scene | Quit | `Escape` |

Training has two actions each day:

| Activity | Cost | Effect |
| --- | --- | --- |
| Practice Illusions | 1 energy | Confidence +2 |
| Care for a Familiar | 1 energy | Empathy +2 |
| Study Ancient Runes | 1 energy | Arcane Knowledge +2 |
| Meditate | 1 action | Energy +2, capped at the maximum |

## Card generation

There are twelve conversation cards: three in each of `confidence`, `empathy`,
`knowledge`, and `balanced` categories. Each acquisition scene deterministically
generates three unique choices:

1. The strongest attribute's category; ties choose `balanced`.
2. The category associated with the last training activity.
3. A `balanced` card.

This makes the effect of player decisions visible both in the session stats and
in the card choices.

## Architecture

```text
src/engine/ecs/                 reusable custom ECS core
src/engine/scene/               ECS Scene and deferred SceneManager
src/game/session/GameSession.lua persistent plain-data run state
src/game/progression/           training definitions and systems
src/game/cards/                 generation, acquisition, navigation, day flow
src/game/scenes/                Training, Card Acquisition, completion factories
src/game/ui/                    read-only LOVE render systems
tests/                          ECS, legacy, and Wizard Academia headless tests
```

The shared `GameSession` exists above individual scene Worlds. Each scene owns
its own ECS World, but receives the same validated plain-data session object so
stats, generated cards, and the collection persist across transitions.

For detailed implementation phases and exit criteria, see [planning.md](planning.md).
For submission screenshots/GIF guidance and direct source links, see
[PORTFOLIO_EVIDENCE.md](PORTFOLIO_EVIDENCE.md).

## Tests

Run the complete suite from the repository root:

```powershell
& "C:\Program Files (x86)\Lua\5.1\lua.exe" tests\run.lua
```

The Wizard Academia coverage includes session isolation, validated events,
training success/rejection feedback, deterministic card generation, collection
persistence, navigation bounds, and the complete five-day scene-manager loop.

## AI assistance disclosure

This repository has used AI-assisted development tools, including OpenAI Codex,
for planning, code generation, refactoring, testing, documentation, and review.
All generated changes should be reviewed and manually verified by the project
owner before submission or release.

### Wizard Academia progression-cycle disclosure

The Wizard Academia progression cycle—including the session contract, training
and card systems, scene wiring, automated tests, and supporting repository
documentation—was implemented with AI assistance. The project owner is
responsible for reviewing the code, validating gameplay in LOVE, and writing
their own portfolio explanation of the design and implementation.

## Repository information and documentation index

This repository contains both a reusable, custom ECS engine and game-layer
examples built on it. Wizard Academia is the active LOVE entry point; older
Breakout and generic-progression materials remain useful as engine and test
coverage while the project evolves.

| Documentation | Contents |
| --- | --- |
| [README.md](README.md) | Wizard Academia setup, controls, game loop, card rule, tests, and disclosure. |
| [planning.md](planning.md) | Wizard Academia scope, architecture, implementation phases, and exit criteria. |
| [src/engine/README.md](src/engine/README.md) | Reusable ECS, scheduler, runtime, scenes, timing, snapshots, and diagnostics. |
| [src/game/README.md](src/game/README.md) | Boundaries between reusable engine code and replaceable game code. |
| [src/game/progression/README.md](src/game/progression/README.md) | Existing generic progression-cycle package and its contracts. |
| [src/game/cards/README.md](src/game/cards/README.md) | Wizard Academia card-data boundary and plain-data rule. |
| [src/game/ui/README.md](src/game/ui/README.md) | UI-system ownership rules. |
| [src/game/maps/README.md](src/game/maps/README.md) | Future map/exploration extension point; not part of the current assignment scope. |
| [tests/README.md](tests/README.md) | Headless test-runner conventions. |
| [PORTFOLIO_EVIDENCE.md](PORTFOLIO_EVIDENCE.md) | Source links and the manual visual-evidence checklist. |
| [assets/demo/arcane-hearts/README.md](assets/demo/arcane-hearts/README.md) | Required screenshot and GIF/video filenames and capture targets. |
