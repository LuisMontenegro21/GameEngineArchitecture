local AcademyMapScene = require("src.game.scenes.AcademyMapScene")
local MapHudRenderSystem = require("src.game.ui.MapHudRenderSystem")

local function player(world)
    local query = world:query({
        all = { "mapPlayer", "mapPosition", "mapSize" },
    })
    local resultPosition, resultSize = nil, nil
    for _, _, position, size in query:each() do
        resultPosition, resultSize = position, size
        break
    end
    query:close()
    assert(resultPosition and resultSize, "map player is missing")
    return resultPosition, resultSize
end

return function()
    local scene = AcademyMapScene()
    scene:initialize()
    local world = scene:world()
    local fixed = scene:scheduler():systemsFor("fixedUpdate")
    local pointIndex, hudIndex = nil, nil
    for index, system in ipairs(fixed) do
        if system.name == "pointOfInterest" then pointIndex = index end
        if system.name == "mapHudUpdate" then hudIndex = index end
    end
    assert(pointIndex and hudIndex and pointIndex < hudIndex,
        "map HUD update must run after authoritative POI detection")
    assert(world:requireResource("mapHudLocation") == false,
        "HUD setup must begin with no location panel")

    local map = world:requireResource("mapDefinition")
    local position, size = player(world)
    local point = map.pointsOfInterest[1]
    position.x = point.trigger.x + (point.trigger.w - size.w) / 2
    position.y = point.trigger.y + (point.trigger.h - size.h) / 2
    scene:fixedUpdate(1 / 60)
    local location = world:requireResource("mapHudLocation")
    assert(location.id == point.id)
    assert(MapHudRenderSystem.promptText(location) == point.name .. " - " .. point.subtitle,
        "HUD text must use a clean ASCII separator")
    local session = world:requireResource("gameSession")
    assert(MapHudRenderSystem.objectiveText(session, false):find("Spend 2", 1, true),
        "activity-phase HUD objectives must derive from remaining actions")
    session.dayPhase = "socialConversation"
    assert(MapHudRenderSystem.objectiveText(session, { targetName = "Mira" })
        == "OBJECTIVE: Find and talk with Mira.",
        "social-phase HUD objectives must derive from the scheduled target")
    session.dayPhase = "activities"

    scene:draw(0)
    assert(world:validate(), "map HUD render must remain read-only and headless-safe")
    scene:dispose()
end
