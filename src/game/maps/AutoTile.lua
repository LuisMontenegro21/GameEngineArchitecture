-- Four-neighbor autotile selection for TileGrid terrain identities.
local AutoTile = {}

local MASK_CELLS = {}
for mask = 0, 15 do
    MASK_CELLS[mask] = { col = mask % 4, row = math.floor(mask / 4) }
end

local function validMask(mask)
    return type(mask) == "number" and mask == math.floor(mask) and mask >= 0 and mask <= 15
end

function AutoTile.maskAt(grid, x, y)
    assert(type(grid) == "table" and type(grid.get) == "function",
        "autotile grid must provide get(x, y)")
    local terrain = grid:get(x, y)
    if terrain == nil then return 0 end

    local mask = 0
    if grid:get(x, y - 1) == terrain then mask = mask + 1 end -- north
    if grid:get(x - 1, y) == terrain then mask = mask + 2 end -- west
    if grid:get(x + 1, y) == terrain then mask = mask + 4 end -- east
    if grid:get(x, y + 1) == terrain then mask = mask + 8 end -- south
    return mask
end

function AutoTile.quadCell(mask)
    assert(validMask(mask), "autotile mask must be an integer from 0 through 15")
    local cell = MASK_CELLS[mask]
    return cell.col, cell.row
end

function AutoTile.maskCells()
    local result = {}
    for mask = 0, 15 do
        local cell = MASK_CELLS[mask]
        result[mask] = { col = cell.col, row = cell.row }
    end
    return result
end

return AutoTile
