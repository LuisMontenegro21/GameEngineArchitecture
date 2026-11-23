-- Validation and construction for authored, plain-data terrain sources.
local TileGrid = require("src.game.maps.TileGrid")

local TerrainDefinition = {}

local function finite(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
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

local function validLegend(legend)
    if type(legend) ~= "table" then return false end
    local count = 0
    for glyph, terrain in pairs(legend) do
        if type(glyph) ~= "string" or #glyph ~= 1
            or not (terrain == false or (type(terrain) == "string" and terrain ~= "")) then
            return false
        end
        count = count + 1
    end
    return count > 0
end

function TerrainDefinition.validate(value)
    if type(value) ~= "table" or not finite(value.cell) or value.cell <= 0
        or type(value.origin) ~= "table" or not finite(value.origin.x) or not finite(value.origin.y)
        or not validLegend(value.legend) or type(value.rows) ~= "table" or #value.rows == 0 then
        return false
    end

    local width = nil
    for _, row in ipairs(value.rows) do
        if type(row) ~= "string" or row == "" then return false end
        width = width or #row
        if #row ~= width then return false end
        for index = 1, width do
            local glyph = row:sub(index, index)
            if value.legend[glyph] == nil and value.legend[glyph] ~= false then return false end
        end
    end
    return plain(value)
end

function TerrainDefinition.build(value)
    assert(TerrainDefinition.validate(value), "invalid terrain definition")
    return TileGrid.fromRows(value.rows, value.legend)
end

function TerrainDefinition.dimensions(value)
    assert(TerrainDefinition.validate(value), "invalid terrain definition")
    return #value.rows[1], #value.rows
end

return TerrainDefinition
