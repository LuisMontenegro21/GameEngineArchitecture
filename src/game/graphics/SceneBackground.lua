-- Draws an optional scene background. A missing image intentionally falls back
-- to the catalog's plain color so every scene remains playable asset-free.
local ImageManager = require("src.game.graphics.ImageManager")
local ScenePresentationCatalog = require("src.game.graphics.ScenePresentationCatalog")

local SceneBackground = {}

local function hasNativeDimensions(image, presentation)
    if type(image.getDimensions) ~= "function" then return false end
    local width, height = image:getDimensions()
    return width == presentation.nativeW and height == presentation.nativeH
end

function SceneBackground.draw(graphics, sceneId)
    local presentation = assert(ScenePresentationCatalog.get(sceneId),
        "unknown scene presentation: " .. tostring(sceneId))
    local image = ImageManager.get(presentation.path)
    if image and hasNativeDimensions(image, presentation) and type(graphics.draw) == "function" then
        graphics.setColor(1, 1, 1, 1)
        graphics.draw(image, 0, 0)
        return true
    end
    local color = presentation.fallback
    graphics.clear(color.r, color.g, color.b, color.a)
    return false
end

return SceneBackground
