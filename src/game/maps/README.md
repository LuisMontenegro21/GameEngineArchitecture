# Academy Garden map systems

This directory contains Wizard Academia's static Academy Garden map data and
focused map systems. The map supports keyboard movement, boundaries, solid
obstacles, points of interest, and safe transitions into dedicated academy
location scenes.

The map remains separate from progression rules:

- `MapDefinition.lua` contains plain static data.
- `TileGrid.lua`, `AutoTile.lua`, `TerrainDefinition.lua`, and
  `TerrainTilesets.lua` provide headless terrain foundations.
- `AcademyGardenTiles.lua` describes the aligned 28-by-14 ground grid, and
  `MapTerrainRenderSystem` draws its fallback grass and path tiles behind map
  objects. `AcademyGardenTilesets.lua` declares future image-sheet metadata
  without loading images yet.
- `MapSpriteRenderSystem`, `MapLabelRenderSystem`, and `MapHudRenderSystem`
  own fallback world objects, world-space labels, and screen-space UI in that
  explicit order.
- `SpriteCatalog.lua` stores plain sprite metadata. `src/game/graphics/`
  contains the renderer-side image, sheet, and quad caches; LOVE objects never
  enter map components, resources, events, or sessions.
- Input, movement, collision, proximity, and transitions live in independent
  systems.
- Map exploration and entering a room do not consume training actions.
- `LocationEntrySystem.lua` turns POI interaction into a deferred
  `academyLocation` request with a safe return position.
- Scheduled NPCs live in location Scenes, not on the overworld. During the
  social phase, map HUD guidance highlights the room containing the target.
- Room activity, dialogue, and card scoring stay outside map systems; the map
  only provides navigation and transition context.
