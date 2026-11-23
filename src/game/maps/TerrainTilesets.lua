-- Plain-data validation for future terrain image-sheet declarations.
local TerrainTilesets = {}

local function positiveInteger(value)
    return type(value) == "number" and value > 0 and value == math.floor(value)
end

local function nonNegativeInteger(value)
    return type(value) == "number" and value >= 0 and value == math.floor(value)
end

local function nonEmptyString(value)
    return type(value) == "string" and value ~= ""
end

local function plain(value, seen)
    local kind = type(value)
    if kind == "nil" or kind == "boolean" or kind == "number" or kind == "string" then return true end
    if kind ~= "table" then return false end
    seen = seen or {}
    if seen[value] then return false end
    seen[value] = true
    for key, item in pairs(value) do
        if not plain(key, seen) or not plain(item, seen) then return false end
    end
    seen[value] = nil
    return true
end

local function validMaskCells(value)
    if value == nil then return true end
    if type(value) ~= "table" then return false end
    for mask = 0, 15 do
        local cell = value[mask]
        if type(cell) ~= "table" or not nonNegativeInteger(cell.col) or not nonNegativeInteger(cell.row) then
            return false
        end
    end
    return true
end

function TerrainTilesets.validate(value)
    if type(value) ~= "table" then return false end
    local count = 0
    for terrain, tileset in pairs(value) do
        if not nonEmptyString(terrain) or type(tileset) ~= "table"
            or not nonEmptyString(tileset.path) or not positiveInteger(tileset.sourceCell)
            or (tileset.maskLayout ~= nil and not nonEmptyString(tileset.maskLayout))
            or not validMaskCells(tileset.maskCells) then
            return false
        end
        count = count + 1
    end
    return count > 0 and plain(value)
end

return TerrainTilesets
