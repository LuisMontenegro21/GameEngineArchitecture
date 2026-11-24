-- Screen-space map information. It intentionally does not draw world objects.
local Screen = require("src.game.Screen")
local UiTheme = require("src.game.ui.UiTheme")

local MapHudRenderSystem = {}

local function graphics()
    return love and love.graphics or nil
end

local function promptText(location)
    return location.name .. " - " .. location.subtitle
end

local function interactionPrompt(target)
    if not target then return nil end
    return ("[E] %s: %s"):format(target.prompt, target.name)
end

local function dialogueLine(state)
    if not state then return nil end
    return state.lines[state.lineIndex]
end

local function objectiveText(session, dailyConversation)
    if session.dayPhase == "activities" then
        return ("OBJECTIVE: Spend %d activity action(s) to prepare for homecoming."):format(
            session.actionsRemaining)
    end
    if session.dayPhase == "socialConversation" and dailyConversation then
        if dailyConversation.targetLocationName then
            return "OBJECTIVE: Visit " .. dailyConversation.targetLocationName
                .. " to find " .. dailyConversation.targetName .. "."
        end
        return "OBJECTIVE: Find and talk with " .. dailyConversation.targetName .. "."
    end
    return "OBJECTIVE: Continue your academy day."
end

function MapHudRenderSystem.install(scheduler)
    scheduler:addSystem({
        name = "mapHudRender",
        stage = "render",
        readsResources = {
            "gameSession", "mapHudLocation", "nearbyInteraction", "dialogueState",
            "mapActivityFeedback", "dailyConversationState", "dailyConversationSelection",
            "mapReturnEnabled",
        },
        after = { "mapLabelRender" },
        run = function(context)
            local g = graphics()
            if not g then return end
            local location = context.world:requireResource("mapHudLocation")
            local interaction = context.world:requireResource("nearbyInteraction")
            local dialogue = context.world:requireResource("dialogueState")
            local feedback = context.world:requireResource("mapActivityFeedback")
            local session = context.world:requireResource("gameSession")
            local dailyConversation = context.world:requireResource("dailyConversationState")
            local dailySelection = context.world:requireResource("dailyConversationSelection")
            local returnEnabled = context.world:requireResource("mapReturnEnabled")

            UiTheme.setColor(g, UiTheme.colors.title)
            g.printf("WIZARD ACADEMIA - ACADEMY GARDEN", 0, 12, Screen.w, "center")
            UiTheme.drawPanel(g, 100, Screen.h - 36, 760, 26, false)
            UiTheme.setColor(g, UiTheme.colors.muted)
            g.printf(returnEnabled
                and "WASD / ARROWS: explore     BACKSPACE: return to training"
                or "WASD / ARROWS: explore     E: interact",
                0, Screen.h - 22, Screen.w, "center")
            UiTheme.drawPanel(g, 170, 76, 620, 30, false)
            UiTheme.setColor(g, UiTheme.colors.heading)
            g.printf(objectiveText(session, dailyConversation), 182, 85, 596, "center")
            if location then
                UiTheme.drawPanel(g, 170, 34, 620, 34, true)
                UiTheme.setColor(g, UiTheme.colors.heading)
                g.printf("LOCATION: " .. promptText(location), 182, 43, 596, "center")
            end
            if dailyConversation and dailyConversation.open then
                local card = session.collection[dailySelection]
                UiTheme.drawPanel(g, 90, Screen.h - 220, 780, 162, true)
                UiTheme.setColor(g, UiTheme.colors.heading)
                g.printf("Conversation with " .. dailyConversation.targetName,
                    110, Screen.h - 210, 740, "center")
                UiTheme.setColor(g, UiTheme.colors.text)
                g.printf(dailyConversation.prompt, 125, Screen.h - 184, 710, "center")
                UiTheme.setColor(g, UiTheme.colors.heading)
                if card then
                    g.printf(("Card %d/%d: %s [%s]   Power %d   Cost %d"):format(
                        dailySelection, #session.collection, card.name, string.upper(card.category),
                        card.power, card.cost), 125, Screen.h - 146, 710, "center")
                else
                    g.printf("No cards in your collection.", 125, Screen.h - 146, 710, "center")
                end
                UiTheme.setColor(g, UiTheme.colors.feedback)
                g.printf(dailyConversation.feedback, 125, Screen.h - 116, 710, "center")
                UiTheme.setColor(g, UiTheme.colors.muted)
                g.printf("LEFT / RIGHT: select card     ENTER: respond     ESC: close",
                    0, Screen.h - 76, Screen.w, "center")
            elseif dialogue then
                UiTheme.drawPanel(g, 110, Screen.h - 150, 740, 92, true)
                UiTheme.setColor(g, UiTheme.colors.heading)
                g.printf(dialogue.targetName, 130, Screen.h - 140, 700, "center")
                UiTheme.setColor(g, UiTheme.colors.text)
                g.printf(dialogueLine(dialogue), 136, Screen.h - 116, 688, "center")
                UiTheme.setColor(g, UiTheme.colors.muted)
                g.printf("E / ENTER: continue     ESC: close", 0, Screen.h - 76,
                    Screen.w, "center")
            elseif interaction then
                UiTheme.drawPanel(g, 210, Screen.h - 76, 540, 30, true)
                UiTheme.setColor(g, UiTheme.colors.heading)
                g.printf(interactionPrompt(interaction), 222, Screen.h - 67, 516, "center")
            end
            if feedback ~= "" and not dialogue then
                UiTheme.drawPanel(g, 160, 112, 640, 36, false)
                UiTheme.setColor(g, UiTheme.colors.feedback)
                g.printf(feedback, 174, 123, 612, "center")
            end
        end,
    })
end

MapHudRenderSystem.promptText = promptText
MapHudRenderSystem.interactionPrompt = interactionPrompt
MapHudRenderSystem.dialogueLine = dialogueLine
MapHudRenderSystem.objectiveText = objectiveText
return MapHudRenderSystem
