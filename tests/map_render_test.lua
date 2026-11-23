local MapSpriteRenderSystem = require("src.game.ui.MapSpriteRenderSystem")

return function()
    local drawables = {
        { id = 8, layerRank = 2, sortKey = 120 },
        { id = 3, layerRank = 2, sortKey = 40 },
        { id = 2, layerRank = 2, sortKey = 120 },
        { id = 1, layerRank = 1, sortKey = 999 },
        { id = 9, layerRank = 3, sortKey = 1 },
    }
    MapSpriteRenderSystem.sortDrawables(drawables)
    assert(drawables[1].id == 1, "layer rank must be applied before world depth")
    assert(drawables[2].id == 3, "bottom edge must sort within a layer")
    assert(drawables[3].id == 2 and drawables[4].id == 8,
        "same-layer, same-depth drawables must use stable entity-ID ordering")
    assert(drawables[5].id == 9, "foreground must render after actors and scenery")
    assert(MapSpriteRenderSystem.layerRank("actors") == 2)
    assert(MapSpriteRenderSystem.layerRank("foreground") == 3)
end
