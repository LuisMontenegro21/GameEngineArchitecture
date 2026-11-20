# Wizard Academia portfolio evidence

## Playable flow

Run `love .` from the repository root. The game begins in the Training Scene.
Complete two training actions, choose a generated conversation card, and press
Enter again to start the next academy day. The run ends after day five.

## Relevant implementation links

- Shared run data: [GameSession.lua](src/game/session/GameSession.lua)
- Training Scene: [TrainingScene.lua](src/game/scenes/TrainingScene.lua)
- Training logic: [Systems.lua](src/game/progression/Systems.lua)
- Deterministic card generation: [CardGenerationSystem.lua](src/game/cards/CardGenerationSystem.lua)
- Card Acquisition Scene: [CardAcquisitionScene.lua](src/game/scenes/CardAcquisitionScene.lua)
- Daily transition and completion: [DayAdvanceSystem.lua](src/game/cards/DayAdvanceSystem.lua)
- End-to-end test: [arcane_daily_cycle_test.lua](tests/arcane_daily_cycle_test.lua)
- Design and phase criteria: [planning.md](planning.md)

## Capture checklist

Use the asset checklist in [assets/demo/arcane-hearts](assets/demo/arcane-hearts/README.md).
The evidence should show the relationship between training attributes and the
categories of the generated cards, card persistence in the collection, and
the final completion screen.
