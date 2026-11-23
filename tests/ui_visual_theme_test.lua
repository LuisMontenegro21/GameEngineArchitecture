local UiTheme = require("src.game.ui.UiTheme")

return function()
    assert(UiTheme.colors.background and UiTheme.colors.panel and UiTheme.colors.selection,
        "the shared UI theme must define background, panel, and selection colors")
    assert(UiTheme.colors.title and UiTheme.colors.text and UiTheme.colors.muted,
        "the shared UI theme must define a readable text hierarchy")
    assert(UiTheme.spacing > 0 and UiTheme.borderWidth > 0,
        "the shared UI theme must define reusable spacing and border tokens")
end
