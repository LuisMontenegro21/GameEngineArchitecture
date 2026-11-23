local AcademyGardenTiles = require("src.game.maps.AcademyGardenTiles")
local AcademyGardenTilesets = require("src.game.maps.AcademyGardenTilesets")
local TerrainDefinition = require("src.game.maps.TerrainDefinition")
local TerrainTilesets = require("src.game.maps.TerrainTilesets")

local function pathReachable(grid, start, target)
    local queue = { { x = start.x, y = start.y } }
    local visited = { [start.x .. ":" .. start.y] = true }
    local cursor = 1
    while queue[cursor] do
        local point = queue[cursor]
        cursor = cursor + 1
        if point.x == target.x and point.y == target.y then return true end
        for _, direction in ipairs({ { 0, -1 }, { -1, 0 }, { 1, 0 }, { 0, 1 } }) do
            local x, y = point.x + direction[1], point.y + direction[2]
            local key = x .. ":" .. y
            if not visited[key] and grid:get(x, y) == "path" then
                visited[key] = true
                queue[#queue + 1] = { x = x, y = y }
            end
        end
    end
    return false
end

return function()
    assert(TerrainDefinition.validate(AcademyGardenTiles))
    assert(TerrainTilesets.validate(AcademyGardenTilesets))
    assert(AcademyGardenTilesets.grass and AcademyGardenTilesets.path,
        "grass and path must both have declared tilesets")

    local grid = TerrainDefinition.build(AcademyGardenTiles)
    local connections = AcademyGardenTiles.connections
    assert(grid:get(connections.entrance.x, connections.entrance.y) == "path",
        "the Academy Entrance must sit on the path network")
    for _, name in ipairs({ "ancientLibrary", "studentCommons", "astralCourt", "quietGarden" }) do
        local target = connections[name]
        assert(grid:get(target.x, target.y) == "path", name .. " must sit on a path cell")
        assert(pathReachable(grid, connections.entrance, target),
            name .. " must be connected to the Academy Entrance by path cells")
    end
end
