-- Read-only fixed-camera presentation for reusable Academy location scenes.
local Screen = require("src.game.Screen")
local Activities = require("src.game.progression.Activities")
local SceneBackground = require("src.game.graphics.SceneBackground")
local ImageManager = require("src.game.graphics.ImageManager")
local ActivityChallengePresentationCatalog = require("src.game.graphics.ActivityChallengePresentationCatalog")
local UiTheme = require("src.game.ui.UiTheme")
local MapSpriteRenderSystem = require("src.game.ui.MapSpriteRenderSystem")

local LocationRenderSystem = {}

local function promptFor(nearby)
    return nearby and nearby.prompt or "Move near an activity, character, or exit."
end

local function collectCharacters(world)
    local result = {}
    local query = world:query({
        all = { "locationPosition", "locationSize", "locationCharacter", "locationSprite" },
    })
    for _, position, size, character, sprite in query:each() do
        result[#result + 1] = {
            position = position, size = size, character = character, sprite = sprite,
        }
    end
    query:close()
    table.sort(result, function(left, right) return left.character.id < right.character.id end)
    return result
end

local function drawPlayer(g, world)
    local query = world:query({ all = { "locationPlayer", "locationPosition", "locationSize", "locationSprite" } })
    for _, _, position, size, sprite in query:each() do
        MapSpriteRenderSystem.drawSpriteOrFallback(g, position, size, sprite)
    end
    query:close()
end

local function drawCharacters(g, characters, nearby)
    for _, entry in ipairs(characters) do
        if nearby and nearby.kind == "character" and nearby.id == entry.character.id then
            UiTheme.setColor(g, UiTheme.colors.selection)
            g.rectangle("line", entry.position.x - 6, entry.position.y - 8,
                entry.size.w + 12, entry.size.h + 12)
        end
        MapSpriteRenderSystem.drawSpriteOrFallback(g, entry.position, entry.size, entry.sprite)
    end
end

local function drawWorldTargets(g, world, nearby)
    local query = world:query({ all = { "locationPosition", "locationSize", "locationInteractable" } })
    for _, position, size, target in query:each() do
        if target.kind == "activity" then
            UiTheme.setColor(g, nearby and nearby.id == target.id and UiTheme.colors.selection or UiTheme.colors.heading)
            g.rectangle("line", position.x - 4, position.y - 4, size.w + 8, size.h + 8)
            g.rectangle("fill", position.x, position.y, size.w, size.h)
            UiTheme.setColor(g, UiTheme.colors.background)
            g.printf("*", position.x, position.y + 7, size.w, "center")
        elseif target.kind == "exit" then
            UiTheme.setColor(g, nearby and nearby.kind == "exit" and UiTheme.colors.selection or UiTheme.colors.muted)
            g.rectangle("line", position.x, position.y, size.w, size.h)
        end
    end
    query:close()
end

local function drawActivityPanel(g, location, nearby, session)
    local activity = assert(Activities.get(location.activityId))
    local x, y, width, height = 18, 112, 214, 102
    UiTheme.drawPanel(g, x, y, width, height, nearby and nearby.kind == "activity")
    g.setColor(location.fallbackColor.r, location.fallbackColor.g, location.fallbackColor.b, location.fallbackColor.a)
    g.rectangle("fill", x, y, width, 20)
    UiTheme.setColor(g, UiTheme.colors.heading)
    g.printf("ACTIVITY", x + 8, y + 5, width - 16, "center")
    UiTheme.setColor(g, UiTheme.colors.text)
    g.printf(activity.name, x + 12, y + 38, width - 24, "center")
    UiTheme.setColor(g, UiTheme.colors.muted)
    local completed = session.completedActivities[activity.id]
    g.printf(completed and "Completed today" or (nearby and nearby.kind == "activity"
        and "E / ENTER: practice" or "Approach the marker"),
        x + 12, y + 68, width - 24, "center")
end

local function drawCharacterPanel(g, characters, nearby)
    local x, y, width = 728, 112, 214
    local height = math.max(66, 30 + #characters * 58)
    UiTheme.drawPanel(g, x, y, width, height, nearby and nearby.kind == "character")
    UiTheme.setColor(g, UiTheme.colors.heading)
    g.printf("PEOPLE HERE", x + 8, y + 6, width - 16, "center")
    if #characters == 0 then
        UiTheme.setColor(g, UiTheme.colors.muted)
        g.printf("No one is here.", x + 8, y + 36, width - 16, "center")
        return
    end
    for index, entry in ipairs(characters) do
        local rowY = y + 30 + (index - 1) * 58
        local selected = nearby and nearby.kind == "character" and nearby.id == entry.character.id
        UiTheme.drawPanel(g, x + 8, rowY, width - 16, 48, selected)
        UiTheme.setColor(g, UiTheme.colors.text)
        g.printf(entry.character.displayName, x + 16, rowY + 7, width - 32, "center")
        UiTheme.setColor(g, UiTheme.colors.muted)
        g.printf(selected and "E / ENTER: speak" or "approach", x + 16, rowY + 27, width - 32, "center")
    end
end

local function drawDailyConversation(g, session, state, selection)
    local card = session.collection[selection]
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
            selection, #session.collection, card.name, card.category, card.power, card.cost),
            140, 400, 680, "center")
    else
        UiTheme.setColor(g, UiTheme.colors.warning)
        g.printf("No collected cards are available.", 0, 398, Screen.w, "center")
    end
    UiTheme.setColor(g, state.resolved and UiTheme.colors.positive or UiTheme.colors.feedback)
    g.printf(state.feedback, 116, 430, 728, "center")
    UiTheme.setColor(g, UiTheme.colors.muted)
    g.printf(state.resolved and "Resolving the next day..."
        or "LEFT / RIGHT: select card     E / ENTER: play card     ESC: close", 0, 452, Screen.w, "center")
end

local function displayKey(key)
    return string.upper(key)
end

local function hasDimensions(image, width, height)
    if not image or type(image.getDimensions) ~= "function" then return false end
    local imageWidth, imageHeight = image:getDimensions()
    return imageWidth == width and imageHeight == height
end

local function drawTimingTrack(g, challenge)
    local presentation = ActivityChallengePresentationCatalog.get(challenge.visualId)
    local x, y, width, height = 200, 401, 560, 24
    local track = presentation and ImageManager.get(presentation.trackPath) or nil
    if track and hasDimensions(track, presentation.trackW, presentation.trackH) and type(g.draw) == "function" then
        g.setColor(1, 1, 1, 1)
        g.draw(track, x, y)
    else
        UiTheme.setColor(g, UiTheme.colors.panel)
        g.rectangle("fill", x, y, width, height)
        UiTheme.setColor(g, UiTheme.colors.panelBorder)
        g.rectangle("line", x, y, width, height)
    end
    local timing = challenge.timing
    UiTheme.setColor(g, UiTheme.colors.positive)
    g.rectangle("fill", x + timing.targetStart * width, y + 3,
        (timing.targetEnd - timing.targetStart) * width, height - 6)
    local markerX = x + timing.markerPosition * width
    local marker = presentation and ImageManager.get(presentation.markerPath) or nil
    if marker and hasDimensions(marker, presentation.markerW, presentation.markerH) and type(g.draw) == "function" then
        g.setColor(1, 1, 1, 1)
        g.draw(marker, markerX - presentation.markerW / 2, y - 4)
    else
        UiTheme.setColor(g, UiTheme.colors.title)
        g.rectangle("fill", markerX - 5, y - 5, 10, height + 10)
    end
end

local function drawActivityChallenge(g, challenge)
    UiTheme.drawPanel(g, 110, 320, 740, 154, true)
    UiTheme.setColor(g, UiTheme.colors.heading)
    g.printf(challenge.title, 130, 332, 700, "center")
    UiTheme.setColor(g, UiTheme.colors.text)
    g.printf(challenge.prompt, 142, 358, 676, "center")
    if challenge.mode == "timing" then
        drawTimingTrack(g, challenge)
        UiTheme.setColor(g, UiTheme.colors.muted)
        g.printf("Press E / ENTER while the rune is in the green focus zone.", 0, 435, Screen.w, "center")
    elseif challenge.mode == "sequence" then
        local keys = {}
        for index, key in ipairs(challenge.steps) do
            local label = "[" .. displayKey(key) .. "]"
            if index == challenge.currentStep then label = "> " .. label .. " <" end
            keys[#keys + 1] = label
        end
        UiTheme.setColor(g, UiTheme.colors.title)
        g.printf(table.concat(keys, "  "), 0, 398, Screen.w, "center")
        UiTheme.setColor(g, UiTheme.colors.muted)
        g.printf("Use the arrow keys to trace the rune sequence.", 0, 426, Screen.w, "center")
    else
        for index, option in ipairs(challenge.options) do
            local y = 390 + (index - 1) * 22
            UiTheme.setColor(g, index == challenge.selection and UiTheme.colors.selection or UiTheme.colors.text)
            g.printf((index == challenge.selection and "> " or "  ") .. option.label,
                150, y, 660, "center")
        end
        UiTheme.setColor(g, UiTheme.colors.muted)
        g.printf("LEFT / RIGHT: choose     E / ENTER: confirm", 0, 456, Screen.w, "center")
    end
    if challenge.mode == "sequence" or challenge.mode == "timing" then
        UiTheme.setColor(g, UiTheme.colors.feedback)
        g.printf(challenge.feedback, 140, 446, 680, "center")
    end
end

function LocationRenderSystem.install(scheduler)
    scheduler:addSystem({
        name = "locationRender",
        stage = "render",
        reads = { "locationPosition", "locationSize", "locationCharacter", "locationSprite", "locationInteractable" },
        readsResources = {
            "gameSession", "locationDefinition", "locationState", "dailyConversationState",
            "dailyConversationSelection", "nearbyLocationInteraction", "activityChallengeState",
        },
        run = function(context)
            local g = love and love.graphics or nil
            if not g then return end
            local world = context.world
            local location = world:requireResource("locationDefinition")
            local state = world:requireResource("locationState")
            local daily = world:requireResource("dailyConversationState")
            local nearby = world:requireResource("nearbyLocationInteraction")
            local challenge = world:requireResource("activityChallengeState")
            SceneBackground.draw(g, location.backgroundId)
            UiTheme.setColor(g, UiTheme.colors.title)
            g.printf(location.name, 0, 34, Screen.w, "center")
            UiTheme.setColor(g, UiTheme.colors.muted)
            g.printf(promptFor(nearby), 0, 70, Screen.w, "center")
            local characters = collectCharacters(world)
            drawWorldTargets(g, world, nearby)
            drawCharacters(g, characters, nearby)
            drawPlayer(g, world)
            drawActivityPanel(g, location, nearby, world:requireResource("gameSession"))
            drawCharacterPanel(g, characters, nearby)
            UiTheme.drawPanel(g, 18, 385, 214, 54, nearby and nearby.kind == "exit")
            UiTheme.setColor(g, UiTheme.colors.heading)
            g.printf("EXIT: Academy Garden", 26, 395, 198, "center")
            UiTheme.setColor(g, UiTheme.colors.text)
            g.printf(state.feedback, 130, 457, 700, "center")
            if daily and daily.open then
                drawDailyConversation(g, world:requireResource("gameSession"), daily,
                    world:requireResource("dailyConversationSelection"))
            elseif challenge then
                drawActivityChallenge(g, challenge)
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
            g.printf("WASD / ARROWS: move     E: interact     BACKSPACE: return to Academy Garden",
                0, 505, Screen.w, "center")
        end,
    })
end

LocationRenderSystem.promptFor = promptFor
LocationRenderSystem.collectCharacters = collectCharacters
return LocationRenderSystem
