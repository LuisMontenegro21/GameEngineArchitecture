# Game layer

The `engine` directory is reusable infrastructure. Everything under `game` is
replaceable for a new title.

Recommended model:

```text
game/
|-- progression/   objectives, rewards, unlocks, and persistent cycle state
|-- maps/          map data, terrain, navigation, encounters, and exits
|-- locations/     reusable room definitions, interaction state, and systems
|-- cards/         card catalog, generation, and collection behavior
|-- graphics/      renderer-side image and sprite-sheet caches
|-- ui/            HUD and menu presentation
|-- scenes/        World/Scheduler/Runtime composition factories
|-- session/       persistent game-run state
`-- Game.lua       application and input/scene coordination
```

For a new game, keep `src/engine`, replace the game-specific packages and
scenes, then define the first progression plan. Install progression systems into
the new scene's Scheduler before Scene initialization.

Build one vertical slice first:

1. Start one objective.
2. Load one map or room.
3. Emit `objectiveProgress` from gameplay or map systems.
4. Complete or fail the objective.
5. Grant one reward.
6. Show the state in a minimal UI.
7. Snapshot or save the progression resource.

## Wizard Academia scene flow

`AcademyMapScene` is the navigation hub. Pressing `E` at one of its four POIs
opens `AcademyLocationScene` with a location ID, the exact shared
`GameSession`, and a safe map return position. The reusable location factory
installs setup, delta-time movement, bounds, proximity interaction, activity,
dialogue, daily-card-conversation, transition, and render systems. It never owns persistent rules: activity resolution,
card scoring, and day advancement remain in their existing game packages.

Location components, resources, events, and catalog data are plain Lua data.
LOVE images and sprite sheets remain in `graphics/` renderer-side caches, so
optional pixel art can be inserted or removed without affecting gameplay.
