# Wizard Academia evidencia de portafolio

## Flujo
Correr `love .` desde la raiz del repo. El juego comienza con la escena de entrenamiento.
Luego de completar dos acciones de entrenamiento, se elige una carta de conversación, se presiona Enter
nuevamente para iniciar un nuevo día. El proceso termina en el día 5. 

## Enlaces de implementación

1. Shared run data: [GameSession.lua](src/game/session/GameSession.lua)
2. Training Scene: [TrainingScene.lua](src/game/scenes/TrainingScene.lua)
3. Training logic: [Systems.lua](src/game/progression/Systems.lua)
4. Deterministic card generation: [CardGenerationSystem.lua](src/game/cards/CardGenerationSystem.lua)
5. Card Acquisition Scene: [CardAcquisitionScene.lua](src/game/scenes/CardAcquisitionScene.lua)
6. Daily transition and completion: [DayAdvanceSystem.lua](src/game/cards/DayAdvanceSystem.lua)
7. End-to-end test: [arcane_daily_cycle_test.lua](tests/arcane_daily_cycle_test.lua)

## Capture checklist

Use the asset checklist in [assets/demo/wizard-academia](assets/demo/wizard-academia/README.md).
The evidence should show the relationship between training attributes and the
categories of the generated cards, card persistence in the collection, and
the final completion screen.
