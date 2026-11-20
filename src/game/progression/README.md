# Progression cycle

This package is the starting point for a new game's progression rules. It is
game-owned and depends only on public ECS APIs.

A progression plan contains ordered objective stages:

```lua
local plan = {
    id = "main_cycle",
    stages = {
        {
            id = "first_objective",
            required = 3,
            reward = {
                experience = 100,
                currency = 25,
                unlocks = { "second_map" },
            },
        },
    },
}
```

Register the plan and install its systems before initializing a Runtime:

```lua
require("src.game.progression.register")(world, plan)
require("src.game.progression.Systems").install(scheduler)
```

Gameplay emits request/fact events; progression systems own state transitions:

```text
available -> active -> completed -> rewarded -> next objective
                    \-> failed -> active (retry)
```

UI and map code may read the `progression` resource and notification events,
but should not implement reward or transition rules themselves.
