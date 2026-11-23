-- Lightweight, headless grid for repeated map terrain. It stores terrain
-- identities only; rendering assets and ECS entities deliberately stay outside.
local TileGrid = {}
TileGrid.__index = TileGrid

local function positiveInteger(value)
    return type(value) == "number" and value > 0 and value == math.floor(value)
end

local function validTerrain(value)
    return value == nil or (type(value) == "string" and value ~= "")
end

local function validGrid(value)
    if getmetatable(value) ~= TileGrid
        or not positiveInteger(value.width)
        or not positiveInteger(value.height)
        or type(value.cells) ~= "table" then
        return false
    end

    local expected = value.width * value.height
    for index = 1, expected do
        if not validTerrain(value.cells[index]) then return false end
    end
    return true
end

local function indexOf(grid, x, y)
    return (y - 1) * grid.width + x
end

function TileGrid.new(width, height, cells)
    assert(positiveInteger(width), "tile grid width must be a positive integer")
    assert(positiveInteger(height), "tile grid height must be a positive integer")
    assert(type(cells) == "table", "tile grid cells must be a table")

    local expected = width * height
    local copy = {}
    for index = 1, expected do
        assert(validTerrain(cells[index]), "tile grid cells must be terrain strings or nil")
        copy[index] = cells[index]
    end
    assert(cells[expected + 1] == nil, "tile grid has too many cells")

    return setmetatable({ width = width, height = height, cells = copy }, TileGrid)
end

function TileGrid.fromRows(rows, legend)
    assert(type(rows) == "table" and #rows > 0, "terrain rows must be a non-empty array")
    assert(type(legend) == "table", "terrain legend must be a table")

    local width = nil
    local cells = {}
    for y, row in ipairs(rows) do
        assert(type(row) == "string" and row ~= "", "terrain rows must be non-empty strings")
        width = width or #row
        assert(#row == width, "terrain rows must have equal width")
        for x = 1, width do
            local glyph = row:sub(x, x)
            local terrain = legend[glyph]
            assert(terrain ~= nil or legend[glyph] == false,
                "terrain row contains an unknown glyph: " .. glyph)
            assert(terrain == false or validTerrain(terrain),
                "terrain legend values must be non-empty strings or false")
            -- Use the explicit grid index: `#cells + 1` is not reliable after
            -- an empty cell creates a Lua table hole.
            local index = (y - 1) * width + x
            if terrain ~= false then cells[index] = terrain end
        end
    end
    return TileGrid.new(width, #rows, cells)
end

TileGrid.build = TileGrid.fromRows

function TileGrid.validate(value)
    return validGrid(value)
end

function TileGrid:inBounds(x, y)
    return positiveInteger(x) and positiveInteger(y)
        and x <= self.width and y <= self.height
end

function TileGrid:get(x, y)
    if not self:inBounds(x, y) then return nil end
    return self.cells[indexOf(self, x, y)]
end

function TileGrid:each()
    local index = 0
    local total = self.width * self.height
    return function()
        repeat
            index = index + 1
            if index > total then return nil end
        until self.cells[index] ~= nil

        local y = math.floor((index - 1) / self.width) + 1
        local x = ((index - 1) % self.width) + 1
        return x, y, self.cells[index]
    end
end

function TileGrid:count()
    local count = 0
    for _ in self:each() do count = count + 1 end
    return count
end

return TileGrid
