-- Renderer-side LOVE image cache. No cached object is ever placed in ECS data.
local ImageManager = {}

local images = {}

local function graphics()
    return love and love.graphics or nil
end

local function validPath(path)
    return type(path) == "string" and path ~= ""
end

function ImageManager.get(path)
    assert(validPath(path), "image path must be a non-empty string")
    if images[path] ~= nil then
        return images[path] or nil
    end

    local g = graphics()
    if not g or type(g.newImage) ~= "function" then return nil end
    local ok, image = pcall(g.newImage, path)
    if not ok then
        images[path] = false
        return nil
    end
    if type(image.setFilter) == "function" then image:setFilter("nearest", "nearest") end
    images[path] = image
    return image
end

function ImageManager.clear()
    images = {}
end

function ImageManager.count()
    local count = 0
    for _, image in pairs(images) do
        if image then count = count + 1 end
    end
    return count
end

return ImageManager
