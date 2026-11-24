local SceneManager = require("src.engine.scene.SceneManager")
local GameSession = require("src.game.session.GameSession")
local CardAcquisitionScene = require("src.game.scenes.CardAcquisitionScene")
local FinalConversationScene = require("src.game.scenes.FinalConversationScene")
local ArcaneCompleteScene = require("src.game.scenes.ArcaneCompleteScene")
local EncounterDefinitions = require("src.game.encounters.EncounterDefinitions")
local AcademyMapScene = require("src.game.scenes.AcademyMapScene")

local function tick(manager)
    manager:preUpdate(1 / 60)
    manager:fixedUpdate(1 / 60)
    manager:postFixedUpdate(1 / 60)
    manager:update(1 / 60)
    manager:postUpdate(1 / 60)
end

local function press(manager, key)
    manager:current():world():emit("keyPressed", { key = key })
    tick(manager)
end

local function player(world)
    local query = world:query({ all = { "mapPlayer", "mapPosition", "mapSize" } })
    local position, size = nil, nil
    for _, _, current, currentSize in query:each() do
        position, size = current, currentSize
        break
    end
    query:close()
    assert(position and size, "map player is missing")
    return position, size
end

local function performMapActivity(manager, pointId)
    local scene = manager:current()
    assert(scene:name() == "academyMap", "activities must be performed on the map")
    local world = scene:world()
    local map = world:requireResource("mapDefinition")
    local position, size = player(world)
    local point = nil
    for _, candidate in ipairs(map.pointsOfInterest) do
        if candidate.id == pointId then point = candidate break end
    end
    assert(point, "unknown activity point: " .. pointId)
    position.x = point.trigger.x + (point.trigger.w - size.w) / 2
    position.y = point.trigger.y + (point.trigger.h - size.h) / 2
    tick(manager)
    press(manager, "e")
    press(manager, "e")
    press(manager, "e")
end

local function resolveDailyConversation(manager)
    local scene = manager:current()
    assert(scene:name() == "academyMap", "daily conversation must occur on the map")
    local world = scene:world()
    local state = world:requireResource("dailyConversationState")
    local playerPosition, playerSize = player(world)
    local target = nil
    local characterQuery = world:query({
        all = { "mapCharacter", "mapInteractable" },
    })
    for _, _, interaction in characterQuery:each() do
        if interaction.id == state.targetCharacterId then target = interaction break end
    end
    characterQuery:close()
    assert(target, "scheduled daily target must exist on the map")
    playerPosition.x = target.trigger.x + (target.trigger.w - playerSize.w) / 2
    playerPosition.y = target.trigger.y + (target.trigger.h - playerSize.h) / 2
    tick(manager)
    press(manager, "e")
    assert(world:requireResource("dailyConversationState").open,
        "E must open the scheduled daily conversation")
    press(manager, "return")
end

return function()
    local manager = SceneManager.new()
    manager:register("academyMap", AcademyMapScene)
    manager:register("cardAcquisition", CardAcquisitionScene)
    manager:register("finalConversation", FinalConversationScene)
    manager:register("arcaneComplete", ArcaneCompleteScene)
    local session = GameSession.new()
    manager:start("academyMap", { session = session })

    for day = 1, session.maxDays do
        assert(manager:current():name() == "academyMap"
            and session.dayPhase == "activities" and session.day == day,
            "each normal day must begin on the map in the activities phase")
        local world = manager:current():world()
        local spawn = world:requireResource("mapDefinition").spawn
        local position = player(world)
        assert(position.x == spawn.x and position.y == spawn.y,
            "every map re-entry must use the map's configured spawn point")

        performMapActivity(manager, "astral_court")
        assert(manager:current():name() == "academyMap" and session.actionsRemaining == 1,
            "one map activity must retain the map until the second action")
        performMapActivity(manager, "quiet_garden")
        assert(manager:current():name() == "cardAcquisition"
            and session.dayPhase == "cardAcquisition" and #session.generatedCards == 3,
            "two map activities must transition once to card acquisition")
        press(manager, "return")
        assert(session.cardChosenThisDay and #session.collection == day,
            "one generated card must join the persistent collection each day")
        press(manager, "return")

        if day < session.maxDays then
            assert(manager:current():name() == "academyMap"
                and session.dayPhase == "socialConversation",
                "days one through four must enter map social conversations after acquisition")
            resolveDailyConversation(manager)
            assert(manager:current():name() == "academyMap"
                and session.day == day + 1 and session.dayPhase == "activities"
                and session.actionsRemaining == session.actionsPerDay,
                "a resolved social conversation must return to the next map day")
            assert(not session.cardChosenThisDay and #session.generatedCards == 0,
                "next-day map state must reset daily card-draft fields")
        end
    end

    assert(manager:current():name() == "finalConversation")
    assert(not session.complete and session.day == session.maxDays,
        "day five must enter the final encounter without an extra map day")
    assert(manager:current():world():requireResource("gameSession") == session,
        "the final encounter must receive the existing shared session")
    assert(manager:current():world():requireResource("encounterState").promptIndex == 1,
        "the final encounter must begin at its first prompt")
    assert(#session.collection == session.maxDays and session.stats.confidence == 10,
        "map activities and acquired cards must persist through the full run")

    press(manager, "return")
    assert(manager:current():name() == "finalConversation")
    press(manager, "right")
    press(manager, "return")
    assert(manager:current():name() == "finalConversation")
    press(manager, "right")
    press(manager, "return")

    assert(manager:current():name() == "arcaneComplete",
        "the completed encounter must transition to the result scene")
    local ending = EncounterDefinitions.endingForRapport(session.finalRapport)
    assert(session.complete and session.endingId == ending.id,
        "the selected day-seeded cards must resolve to their rapport-based ending")
    assert(manager:current():world():requireResource("gameSession") == session,
        "the result scene must preserve the completed shared session")
    manager:draw(0)
    manager:quit()
end
