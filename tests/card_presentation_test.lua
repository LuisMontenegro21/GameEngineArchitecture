local CardCatalog = require("src.game.cards.CardCatalog")
local CardPresentationCatalog = require("src.game.graphics.CardPresentationCatalog")
local CardRenderSystem = require("src.game.ui.CardRenderSystem")
local ImageManager = require("src.game.graphics.ImageManager")

return function()
    for _, category in ipairs(CardCatalog.categories()) do
        for _, card in ipairs(CardCatalog.forCategory(category)) do
            local presentation = CardPresentationCatalog.get(card)
            assert(presentation and presentation.base.width == 64 and presentation.icon.width == 32,
                "every catalog card must have a 64-pixel base and 32-pixel icon")
        end
    end

    local previousLove = love
    local draws = 0
    _G.love = {
        graphics = {
            newImage = function(path)
                local size = path:find("/icons/", 1, true) and 32 or 64
                return {
                    setFilter = function() end,
                    getDimensions = function() return size, size end,
                }
            end,
        },
    }
    ImageManager.clear()
    local graphics = {
        setColor = function() end,
        draw = function() draws = draws + 1 end,
    }
    local card = CardCatalog.forCategory("confidence")[1]
    assert(CardRenderSystem.drawCardArt(graphics, card, 0, 0, 190) and draws == 2,
        "valid base and icon assets must render as a paired card crest")
    _G.love = previousLove
    ImageManager.clear()
end
