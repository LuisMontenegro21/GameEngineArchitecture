-- World-object fallback renderer. M11 will resolve mapSprite assets here while
-- preserving the same physical footprints and deterministic depth ordering.
local MapSpriteRenderSystem = {}
local SpriteCatalog = require("src.game.maps.SpriteCatalog")
local SpriteSheet = require("src.game.graphics.SpriteSheet")

local LAYER_ORDER = {
    groundDecoration = 1,
    scenery = 2,
    locations = 2,
    actors = 2,
    foreground = 3,
}

local function graphics()
    return love and love.graphics or nil
end

local function layerRank(layer)
    return LAYER_ORDER[layer] or LAYER_ORDER.scenery
end

local function drawFallback(g, position, size, render)
    local color = render.color
    g.setColor(color.r, color.g, color.b, color.a or 1)
    if render.shape == "circle" then
        g.ellipse("fill", position.x + size.w / 2, position.y + size.h / 2,
            size.w / 2, size.h / 2)
    else
        g.rectangle("fill", position.x, position.y, size.w, size.h)
    end
end

local function drawSpriteOrFallback(g, position, size, sprite)
    local definition = SpriteCatalog.get(sprite.key)
    local sheet = definition and SpriteSheet.get(definition.path, definition.frameW, definition.frameH)
    local quad = sheet and sheet:quad((sprite.frame or 1) - 1, (sprite.row or 1) - 1)
    if quad and type(g.draw) == "function" then
        g.setColor(1, 1, 1, 1)
        g.draw(sheet.image, quad, position.x + (sprite.offsetX or 0), position.y + (sprite.offsetY or 0),
            0, sprite.scaleX or 1, sprite.scaleY or 1)
        return true
    end
    drawFallback(g, position, size, sprite.fallback)
    return false
end

local function sortDrawables(drawables)
    table.sort(drawables, function(left, right)
        if left.layerRank ~= right.layerRank then return left.layerRank < right.layerRank end
        if left.sortKey ~= right.sortKey then return left.sortKey < right.sortKey end
        return left.id < right.id
    end)
    return drawables
end

local function collectDrawables(world)
    local drawables = {}
    for entity, position, size, sprite in world:query({
        all = { "mapPosition", "mapSize", "mapSprite" },
    }):each() do
        drawables[#drawables + 1] = {
            id = entity.id,
            position = position,
            size = size,
            sprite = sprite,
            layerRank = layerRank(sprite.layer),
            sortKey = position.y + size.h,
        }
    end
    return sortDrawables(drawables)
end

local function drawSocialTargetHighlight(g, world, state)
    if not state or state.resolved then return end
    local query = world:query({
        all = { "mapPosition", "mapSize", "mapCharacter" },
    })
    for _, position, size, character in query:each() do
        if character.id == state.targetCharacterId then
            g.setColor(0.95, 0.82, 0.30, 1)
            g.rectangle("line", position.x - 4, position.y - 4, size.w + 8, size.h + 8)
            query:close()
            return
        end
    end
    query:close()
end

function MapSpriteRenderSystem.install(scheduler)
    scheduler:addSystem({
        name = "mapSpriteRender",
        stage = "render",
        reads = { "mapPosition", "mapSize", "mapSprite", "mapCharacter" },
        readsResources = { "dailyConversationState" },
        after = { "mapTerrainRender" },
        before = { "mapLabelRender" },
        run = function(context)
            local g = graphics()
            if not g then return end
            drawSocialTargetHighlight(g, context.world,
                context.world:requireResource("dailyConversationState"))
            for _, drawable in ipairs(collectDrawables(context.world)) do
                drawSpriteOrFallback(g, drawable.position, drawable.size, drawable.sprite)
            end
        end,
    })
end

MapSpriteRenderSystem.collectDrawables = collectDrawables
MapSpriteRenderSystem.drawSpriteOrFallback = drawSpriteOrFallback
MapSpriteRenderSystem.drawSocialTargetHighlight = drawSocialTargetHighlight
MapSpriteRenderSystem.layerRank = layerRank
MapSpriteRenderSystem.sortDrawables = sortDrawables
return MapSpriteRenderSystem
