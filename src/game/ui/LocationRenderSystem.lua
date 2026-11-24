-- Read-only placeholder presentation for the reusable Academy location Scene.
local Screen = require("src.game.Screen")
local Activities = require("src.game.progression.Activities")
local SceneBackground = require("src.game.graphics.SceneBackground")
local UiTheme = require("src.game.ui.UiTheme")
local MapSpriteRenderSystem = require("src.game.ui.MapSpriteRenderSystem")

local LocationRenderSystem = {}

local function focusPrompt(state)
    return state.focusKind == "exit"
        and "FOCUS: Exit to Academy Garden"
        or (state.focusKind == "character" and "FOCUS: Character" or "FOCUS: Activity Station")
end

-- Interaction information lives in screen-space side panels so it never
-- obscures room scenery or characters. World positions remain available for
-- later interior movement/sprite work, but are not used as placeholder UI.
local function drawActivityPanel(g, location, state)
    local activity = assert(Activities.get(location.activityId))
    local x, y, width, height = 18, 112, 214, 102
    UiTheme.drawPanel(g, x, y, width, height, state.focusKind == "activity")
    g.setColor(location.fallbackColor.r, location.fallbackColor.g,
        location.fallbackColor.b, location.fallbackColor.a)
    g.rectangle("fill", x, y, width, 20)
    UiTheme.setColor(g, UiTheme.colors.heading)
    g.printf("ACTIVITY", x + 8, y + 5, width - 16, "center")
    UiTheme.setColor(g, UiTheme.colors.text)
    g.printf(activity.name, x + 12, y + 38, width - 24, "center")
    g.printf("E / ENTER: practice", x + 12, y + 68, width - 24, "center")
end

local function collectCharacters(world)
    local result = {}
    local query = world:query({
        all = { "locationPosition", "locationSize", "locationCharacter", "locationSprite" },
    })
    for _, position, size, character, sprite in query:each() do
        result[#result + 1] = {
            position = position,
            size = size,
            character = character,
            sprite = sprite,
        }
    end
    query:close()
    table.sort(result, function(left, right) return left.character.id < right.character.id end)
    return result
end

local function drawCharacters(g, characters, state)
    for index, entry in ipairs(characters) do
        local position, size = entry.position, entry.size
        if state.focusKind == "character" and state.focusIndex == index then
            UiTheme.setColor(g, UiTheme.colors.selection)
            g.rectangle("line", position.x - 6, position.y - 8, size.w + 12, size.h + 12)
        end
        MapSpriteRenderSystem.drawSpriteOrFallback(g, position, size, entry.sprite)
    end
end

local function drawCharacterPanel(g, characters, state)
    local x, y, width = 728, 112, 214
    local height = math.max(66, 30 + #characters * 58)
    UiTheme.drawPanel(g, x, y, width, height, state.focusKind == "character")
    UiTheme.setColor(g, UiTheme.colors.heading)
    g.printf("PEOPLE HERE", x + 8, y + 6, width - 16, "center")
    if #characters == 0 then
        UiTheme.setColor(g, UiTheme.colors.muted)
        g.printf("No one is here.", x + 8, y + 36, width - 16, "center")
        return
    end
    for index, entry in ipairs(characters) do
        local rowY = y + 30 + (index - 1) * 58
        local selected = state.focusKind == "character" and state.focusIndex == index
        UiTheme.drawPanel(g, x + 8, rowY, width - 16, 48, selected)
        UiTheme.setColor(g, UiTheme.colors.text)
        g.printf(entry.character.displayName, x + 16, rowY + 7, width - 32, "center")
        UiTheme.setColor(g, UiTheme.colors.muted)
        g.printf(selected and "E / ENTER: speak" or "available", x + 16, rowY + 27, width - 32, "center")
    end
end

local function drawDailyConversation(g, session, state, selection)
    local collection = session.collection
    local card = collection[selection]
    UiTheme.drawPanel(g, 86, 320, 788, 154, true)
    UiTheme.setColor(g, UiTheme.colors.heading)
    g.printf("CONVERSATION: " .. state.targetName, 106, 332, 748, "center")
    UiTheme.setColor(g, UiTheme.colors.text)
    g.printf(state.prompt, 116, 358, 728, "center")

    if card then
        local color = UiTheme.categoryColor(card.category)
        g.setColor(color.r, color.g, color.b, color.a)
        g.rectangle("fill", 128, 394, 704, 26)
        UiTheme.setColor(g, UiTheme.colors.background)
        g.printf(("[%d/%d] %s  |  %s  |  Power %d  |  Cost %d"):format(
            selection, #collection, card.name, card.category, card.power, card.cost),
            140, 400, 680, "center")
    else
        UiTheme.setColor(g, UiTheme.colors.warning)
        g.printf("No collected cards are available.", 0, 398, Screen.w, "center")
    end
    UiTheme.setColor(g, state.resolved and UiTheme.colors.positive or UiTheme.colors.feedback)
    g.printf(state.feedback, 116, 430, 728, "center")
    UiTheme.setColor(g, UiTheme.colors.muted)
    local controls = state.resolved and "Resolving the next day..."
        or "LEFT / RIGHT: select card     E / ENTER: play card     ESC: close"
    g.printf(controls, 0, 452, Screen.w, "center")
end

function LocationRenderSystem.install(scheduler)
    scheduler:addSystem({
        name = "locationRender",
        stage = "render",
        reads = { "locationPosition", "locationSize", "locationCharacter", "locationSprite" },
        readsResources = { "gameSession", "locationDefinition", "locationState", "dailyConversationState", "dailyConversationSelection" },
        run = function(context)
            local g = love and love.graphics or nil
            if not g then return end
            local location = context.world:requireResource("locationDefinition")
            local state = context.world:requireResource("locationState")
            local daily = context.world:requireResource("dailyConversationState")
            SceneBackground.draw(g, location.backgroundId)
            UiTheme.setColor(g, UiTheme.colors.title)
            g.printf(location.name, 0, 34, Screen.w, "center")
            UiTheme.setColor(g, UiTheme.colors.muted)
            g.printf(focusPrompt(state), 0, 70, Screen.w, "center")
            local characters = collectCharacters(context.world)
            drawCharacters(g, characters, state)
            drawActivityPanel(g, location, state)
            drawCharacterPanel(g, characters, state)
            UiTheme.drawPanel(g, 18, 385, 214, 54, state.focusKind == "exit")
            UiTheme.setColor(g, UiTheme.colors.heading)
            g.printf("EXIT: Academy Garden", 26, 395, 198, "center")
            UiTheme.setColor(g, UiTheme.colors.text)
            g.printf(state.feedback, 130, 457, 700, "center")
            if daily and daily.open then
                drawDailyConversation(g, context.world:requireResource("gameSession"), daily,
                    context.world:requireResource("dailyConversationSelection"))
            elseif state.dialogue then
                UiTheme.drawPanel(g, 110, 350, 740, 102, true)
                UiTheme.setColor(g, UiTheme.colors.heading)
                g.printf(state.dialogue.targetName, 130, 360, 700, "center")
                UiTheme.setColor(g, UiTheme.colors.text)
                g.printf(state.dialogue.lines[state.dialogue.lineIndex], 136, 388, 688, "center")
                UiTheme.setColor(g, UiTheme.colors.muted)
                g.printf("E / ENTER: continue     ESC: close", 0, 424, Screen.w, "center")
            end
            UiTheme.drawPanel(g, 80, 496, 800, 32, false)
            UiTheme.setColor(g, UiTheme.colors.muted)
            g.printf("ARROWS / TAB: change focus     BACKSPACE: return to Academy Garden",
                0, 505, Screen.w, "center")
        end,
    })
end

LocationRenderSystem.focusPrompt = focusPrompt

return LocationRenderSystem
