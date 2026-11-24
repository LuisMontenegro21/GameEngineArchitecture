local AcademyMapScene = require("src.game.scenes.AcademyMapScene")
local GameSession = require("src.game.session.GameSession")
local MapHudRenderSystem = require("src.game.ui.MapHudRenderSystem")

local function player(world)
    local query = world:query({ all = { "mapPlayer", "mapPosition", "mapSize", "desiredMovement" } })
    local position, size, desired = nil, nil, nil
    for _, _, currentPosition, currentSize, currentDesired in query:each() do
        position, size, desired = currentPosition, currentSize, currentDesired
        break
    end
    query:close()
    assert(position and size and desired, "map player is missing interaction components")
    return position, size, desired
end

local function press(scene, key)
    scene:world():emit("keyPressed", { key = key })
    scene:preUpdate(0)
    scene:fixedUpdate(1 / 60)
end

local function sameTable(left, right)
    if type(left) ~= type(right) then return false end
    if type(left) ~= "table" then return left == right end
    for key, value in pairs(left) do
        if not sameTable(value, right[key]) then return false end
    end
    for key in pairs(right) do
        if left[key] == nil then return false end
    end
    return true
end

return function()
    local scene = AcademyMapScene()
    scene:initialize()
    local world = scene:world()
    local session = world:requireResource("gameSession")
    local before = GameSession.copy(session)
    local position, size, desired = player(world)

    position.x, position.y = 400, 430
    scene:fixedUpdate(1 / 60)
    assert(world:requireResource("nearbyInteraction") == false,
        "no interaction prompt may exist outside a trigger range")
    assert(MapHudRenderSystem.interactionPrompt(false) == nil,
        "the HUD must not build a prompt without a target")
    press(scene, "e")
    assert(world:requireResource("dialogueState") == false,
        "E outside interaction range must not open dialogue")

    local map = world:requireResource("mapDefinition")
    local point = map.pointsOfInterest[1]
    position.x = point.trigger.x + (point.trigger.w - size.w) / 2
    position.y = point.trigger.y + (point.trigger.h - size.h) / 2
    scene:fixedUpdate(1 / 60)
    local target = world:requireResource("nearbyInteraction")
    assert(target.id == point.id and target.kind == "location",
        "the active map location must become an interactable target")
    assert(MapHudRenderSystem.interactionPrompt(target)
        == "[E] Press E to inspect: " .. point.name,
        "the HUD must expose a fixed E prompt for the current target")

    world:create({
        mapInteractable = {
            id = "aaa_overlap", kind = "character", name = "Overlap Student",
            prompt = "Press E to talk",
            trigger = {
                x = point.trigger.x, y = point.trigger.y,
                w = point.trigger.w, h = point.trigger.h,
            },
            dialogue = { "First line.", "Second line." },
        },
    })
    scene:fixedUpdate(1 / 60)
    target = world:requireResource("nearbyInteraction")
    assert(target.id == "aaa_overlap" and target.kind == "character",
        "overlapping interaction ranges must choose the closest, ID-tie-broken target")

    press(scene, "e")
    local dialogue = world:requireResource("dialogueState")
    assert(dialogue.targetId == "aaa_overlap" and dialogue.lineIndex == 1,
        "E must open exactly the selected interaction at its first line")
    assert(MapHudRenderSystem.dialogueLine(dialogue) == "First line.",
        "dialogue rendering must read the current transient line")

    local x, y = position.x, position.y
    press(scene, "right")
    assert(position.x == x and position.y == y and desired.dx == 0 and desired.dy == 0,
        "movement must pause while dialogue is open")

    press(scene, "return")
    dialogue = world:requireResource("dialogueState")
    assert(dialogue.lineIndex == 2 and MapHudRenderSystem.dialogueLine(dialogue) == "Second line.",
        "Enter must advance an open dialogue")
    press(scene, "escape")
    assert(world:requireResource("dialogueState") == false,
        "Escape must close optional dialogue")

    assert(sameTable(session, before),
        "interaction and dialogue must not mutate persistent progression")
    assert(world:validate())
    scene:dispose()
end
