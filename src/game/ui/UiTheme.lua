-- Shared presentation tokens for Wizard Academia screen-space interfaces.
-- This module owns neither game state nor LOVE resources, so render systems can
-- use it safely and tests can inspect the values without a graphics context.
local UiTheme = {}

UiTheme.colors = {
    background = { r = 0.06, g = 0.04, b = 0.12, a = 1 },
    panel = { r = 0.10, g = 0.08, b = 0.17, a = 0.96 },
    panelBorder = { r = 0.63, g = 0.55, b = 0.82, a = 1 },
    title = { r = 0.90, g = 0.82, b = 1, a = 1 },
    heading = { r = 0.80, g = 0.90, b = 1, a = 1 },
    text = { r = 1, g = 1, b = 1, a = 1 },
    muted = { r = 0.70, g = 0.70, b = 0.76, a = 1 },
    unavailable = { r = 0.55, g = 0.55, b = 0.60, a = 1 },
    warning = { r = 0.92, g = 0.52, b = 0.50, a = 1 },
    selection = { r = 0.38, g = 0.24, b = 0.60, a = 1 },
    feedback = { r = 0.80, g = 0.90, b = 1, a = 1 },
    positive = { r = 0.58, g = 0.90, b = 0.71, a = 1 },
}

UiTheme.categoryColors = {
    confidence = { r = 0.74, g = 0.44, b = 0.95, a = 1 },
    empathy = { r = 0.42, g = 0.78, b = 0.67, a = 1 },
    knowledge = { r = 0.38, g = 0.63, b = 0.96, a = 1 },
    balanced = { r = 0.76, g = 0.70, b = 0.44, a = 1 },
}

UiTheme.spacing = 12
UiTheme.borderWidth = 1

function UiTheme.setColor(graphics, color, alpha)
    graphics.setColor(color.r, color.g, color.b, alpha or color.a or 1)
end

function UiTheme.categoryColor(category)
    return UiTheme.categoryColors[category] or UiTheme.categoryColors.balanced
end

-- Draw a consistently dark, bordered panel. A selected panel receives a
-- slightly larger accent frame, keeping selection readable without fonts or
-- sprite assets.
function UiTheme.drawPanel(graphics, x, y, width, height, selected)
    if selected then
        UiTheme.setColor(graphics, UiTheme.colors.selection)
        graphics.rectangle("fill", x - 4, y - 4, width + 8, height + 8)
    end
    UiTheme.setColor(graphics, UiTheme.colors.panel)
    graphics.rectangle("fill", x, y, width, height)
    UiTheme.setColor(graphics, UiTheme.colors.panelBorder)
    graphics.rectangle("line", x, y, width, height)
end

return UiTheme
