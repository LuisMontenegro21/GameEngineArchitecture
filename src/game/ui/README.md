# Wizard Academia UI systems

The UI package owns presentation state, visual hierarchy, and rendering. It
does not own progression effects, card generation, map collision, or POI
detection.

Explicit setup systems initialize UI state for each assignment interface:

- `TrainingUiSetupSystem.lua` clamps the activity selection.
- `TrainingUiUpdateSystem.lua` converts Training navigation/confirmation input
  into selection state and activity requests without applying progression.
- `CardUiUpdateSystem.lua` converts card focus/navigation/confirmation input
  into selection, acquisition, and day-advance requests without changing card
  data directly.
- `CardUiSetupSystem.lua` normalizes focus and card/collection selections after
  card generation.
- `MapHudSetupSystem.lua` initializes the empty nearby-location HUD state after
  map setup.
- `MapHudUpdateSystem.lua` mirrors authoritative POI discovery into
  screen-space HUD display state without rechecking collision or triggers.
- `UiTheme.lua` defines the shared dark-panel palette, text hierarchy,
  spacing, borders, and selected-panel treatment used by all three interfaces.
- `CardUseUiSetupSystem.lua` and `CardUseUiUpdateSystem.lua` initialize and
  drive Final Conversation card selection without resolving encounter rules.
- `EncounterRenderSystem.lua` renders prompt, Focus, rapport, card
  availability, feedback, and controls from encounter state.

The existing render systems remain read-only and safely no-op outside LOVE.
