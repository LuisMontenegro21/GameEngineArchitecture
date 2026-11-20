# Game layer

The `engine` directory is reusable infrastructure. Everything under `game` is
replaceable for a new title.

Recommended model:

```text
game/
├── ecs/           components, resources, events, gameplay/render systems
├── progression/   objectives, rewards, unlocks, and persistent cycle state
├── maps/          map data, loading, navigation, encounters, exits
├── ui/            HUD and menu presentation
├── scenes/        World/Scheduler/Runtime composition factories
└── Game.lua       application and input/scene coordination
```

For a new game, keep `src/engine`, replace the Breakout definitions and scenes,
then define the first progression plan. Install progression systems into the
new play scene's Scheduler before Scene initialization.

Build one vertical slice first:

1. start one objective;
2. load one map or room;
3. emit `objectiveProgress` from gameplay/map systems;
4. complete or fail the objective;
5. grant one reward;
6. show the state in a minimal UI;
7. snapshot/save the progression resource.
