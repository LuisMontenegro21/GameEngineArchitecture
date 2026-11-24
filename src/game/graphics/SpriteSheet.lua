-- Sprite-sheet and quad cache layered over ImageManager.
local ImageManager = require("src.game.graphics.ImageManager")

local SpriteSheet = {}
SpriteSheet.__index = SpriteSheet

local sheets = {}

local function positiveInteger(value)
    return type(value) == "number" and value > 0 and value == math.floor(value)
end

local function graphics()
    return love and love.graphics or nil
end

local function sheetKey(path, frameW, frameH)
    return path .. "\31" .. frameW .. "x" .. frameH
end

function SpriteSheet.get(path, frameW, frameH)
    assert(type(path) == "string" and path ~= "", "sprite sheet path must be a non-empty string")
    assert(positiveInteger(frameW) and positiveInteger(frameH),
        "sprite sheet frame dimensions must be positive integers")
    local key = sheetKey(path, frameW, frameH)
    if sheets[key] ~= nil then return sheets[key] or nil end

    local image = ImageManager.get(path)
    if not image then
        sheets[key] = false
        return nil
    end
    local sheet = setmetatable({
        image = image,
        frameW = frameW,
        frameH = frameH,
        quads = {},
    }, SpriteSheet)
    sheets[key] = sheet
    return sheet
end

function SpriteSheet:quad(col, row)
    assert(type(col) == "number" and col >= 0 and col == math.floor(col),
        "sprite sheet column must be a non-negative integer")
    assert(type(row) == "number" and row >= 0 and row == math.floor(row),
        "sprite sheet row must be a non-negative integer")
    local key = col .. ":" .. row
    if self.quads[key] ~= nil then return self.quads[key] or nil end

    local g = graphics()
    if not g or type(g.newQuad) ~= "function" or type(self.image.getDimensions) ~= "function" then
        return nil
    end
    local imageW, imageH = self.image:getDimensions()
    if (col + 1) * self.frameW > imageW or (row + 1) * self.frameH > imageH then
        self.quads[key] = false
        return nil
    end
    local quad = g.newQuad(col * self.frameW, row * self.frameH,
        self.frameW, self.frameH, imageW, imageH)
    self.quads[key] = quad
    return quad
end

function SpriteSheet.clear()
    sheets = {}
end

function SpriteSheet.count()
    local count = 0
    for _, sheet in pairs(sheets) do if sheet then count = count + 1 end end
    return count
end

return SpriteSheet
