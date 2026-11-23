local AutoTile = require("src.game.maps.AutoTile")
local TerrainDefinition = require("src.game.maps.TerrainDefinition")
local TerrainTilesets = require("src.game.maps.TerrainTilesets")
local TileGrid = require("src.game.maps.TileGrid")

local function fails(callback, message)
    assert(not pcall(callback), message)
end

return function()
    local terrain = {
        cell = 32,
        origin = { x = 32, y = 56 },
        legend = { G = "grass", P = "path", ["."] = false },
        rows = { "GPG", "G.G", "GGG" },
    }
    assert(TerrainDefinition.validate(terrain), "valid terrain source must validate")
    local width, height = TerrainDefinition.dimensions(terrain)
    assert(width == 3 and height == 3, "terrain dimensions must come from authored rows")

    local grid = TerrainDefinition.build(terrain)
    assert(TileGrid.validate(grid), "built terrain must be a valid tile grid")
    assert(grid.width == 3 and grid.height == 3)
    assert(grid:get(2, 1) == "path")
    assert(grid:get(2, 2) == nil, "false legend entries must become empty cells")
    assert(grid:get(0, 1) == nil and grid:get(4, 1) == nil, "out-of-bounds lookup must be safe")
    assert(grid:count() == 8, "grid iteration must skip empty cells")

    local visited = {}
    for x, y, value in grid:each() do
        visited[x .. ":" .. y] = value
    end
    assert(visited["2:2"] == nil and visited["3:3"] == "grass",
        "grid iteration must be deterministic and omit empty cells")

    local cross = TileGrid.fromRows({ ".G.", "GGG", ".G." }, { G = "grass", ["."] = false })
    assert(AutoTile.maskAt(cross, 2, 2) == 15, "matching four-neighbors must produce mask 15")
    assert(AutoTile.maskAt(grid, 2, 1) == 0, "unlike terrain must not connect")
    assert(AutoTile.maskAt(grid, 2, 2) == 0, "empty terrain has no autotile mask")

    local masks = AutoTile.maskCells()
    for mask = 0, 15 do
        local col, row = AutoTile.quadCell(mask)
        assert(type(col) == "number" and type(row) == "number" and masks[mask] ~= nil,
            "every autotile mask must select a source cell")
    end
    fails(function() AutoTile.quadCell(16) end, "out-of-range masks must fail")

    local invalid = {
        cell = 32, origin = { x = 0, y = 0 }, legend = { G = "grass" }, rows = { "GG", "G" },
    }
    assert(not TerrainDefinition.validate(invalid), "uneven terrain rows must be rejected")
    invalid = {
        cell = 32, origin = { x = 0, y = 0 }, legend = { G = "grass" }, rows = { "GX" },
    }
    assert(not TerrainDefinition.validate(invalid), "unknown terrain glyphs must be rejected")
    fails(function() TileGrid.fromRows({ "GG", "G" }, { G = "grass" }) end,
        "grid construction must reject uneven rows")

    local tilesets = {
        grass = { path = "assets/maps/grass_tiles.png", sourceCell = 16, maskLayout = "standard16" },
        path = { path = "assets/maps/path_tiles.png", sourceCell = 16 },
    }
    assert(TerrainTilesets.validate(tilesets), "plain tilesets must validate")
    tilesets.path.sourceCell = 0
    assert(not TerrainTilesets.validate(tilesets), "invalid tileset dimensions must be rejected")
    tilesets.path.sourceCell = 16
    tilesets.path.unserializable = function() end
    assert(not TerrainTilesets.validate(tilesets), "tileset definitions must remain plain data")
end
