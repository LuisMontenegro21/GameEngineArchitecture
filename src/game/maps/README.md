# Academy Garden map systems

This directory contains Wizard Academia's static Academy Garden map data and
focused map systems. The current map supports keyboard movement, boundaries,
solid obstacles, points of interest, and safe return to the Training Scene.

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
- Map exploration does not consume training actions or modify `GameSession`.
- Future location interactions should emit requests or progression facts rather
  than directly owning training/card rules.
