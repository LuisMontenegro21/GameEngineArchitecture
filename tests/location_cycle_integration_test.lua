-- Complete authoritative five-day run through dedicated rooms, not map test
-- fixtures. It verifies activity, card acquisition, daily room conversations,
-- final conversation, and session preservation as one player-facing route.
local AcademyLocationScene = require("src.game.scenes.AcademyLocationScene")
local AcademyMapScene = require("src.game.scenes.AcademyMapScene")
local ArcaneCompleteScene = require("src.game.scenes.ArcaneCompleteScene")
local CardAcquisitionScene = require("src.game.scenes.CardAcquisitionScene")
local FinalConversationScene = require("src.game.scenes.FinalConversationScene")
local GameSession = require("src.game.session.GameSession")
local SceneManager = require("src.engine.scene.SceneManager")

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
    local position, size
    for _, _, currentPosition, currentSize in query:each() do
        position, size = currentPosition, currentSize
        break
    end
    query:close()
    assert(position and size, "map player is missing")
    return position, size
end

local function enterLocation(manager, locationId)
    assert(manager:current():name() == "academyMap", "locations are entered from the map")
    local world = manager:current():world()
    local position, size = player(world)
    local point
    for _, candidate in ipairs(world:requireResource("mapDefinition").pointsOfInterest) do
        if candidate.id == locationId then point = candidate break end
    end
    assert(point, "unknown location: " .. tostring(locationId))
    position.x = point.trigger.x + (point.trigger.w - size.w) / 2
    position.y = point.trigger.y + (point.trigger.h - size.h) / 2
    tick(manager)
    press(manager, "e")
    assert(manager:current():name() == "academyLocation")
end

local function performActivity(manager, locationId)
    enterLocation(manager, locationId)
    press(manager, "e")
end

local function roomCharacterIndex(world, characterId)
    local characters = {}
    local query = world:query({ all = { "locationCharacter" } })
    for _, character in query:each() do characters[#characters + 1] = character end
    query:close()
    table.sort(characters, function(left, right) return left.id < right.id end)
    for index, character in ipairs(characters) do
        if character.id == characterId then return index end
    end
    error("scheduled conversation target is absent from its location")
end

local function resolveRoomConversation(manager)
    local mapWorld = manager:current():world()
    local state = mapWorld:requireResource("dailyConversationState")
    enterLocation(manager, state.targetLocationId)
    local roomWorld = manager:current():world()
    for _ = 1, roomCharacterIndex(roomWorld, state.targetCharacterId) do press(manager, "right") end
    press(manager, "e")
    assert(roomWorld:requireResource("dailyConversationState").open,
        "the scheduled character must open the room card conversation")
    press(manager, "return")
end

return function()
    local manager = SceneManager.new()
    manager:register("academyMap", AcademyMapScene)
    manager:register("academyLocation", AcademyLocationScene)
    manager:register("cardAcquisition", CardAcquisitionScene)
    manager:register("finalConversation", FinalConversationScene)
    manager:register("arcaneComplete", ArcaneCompleteScene)
    local session = GameSession.new()
    manager:start("academyMap", { session = session })

    for day = 1, session.maxDays do
        assert(manager:current():name() == "academyMap" and session.day == day
            and session.dayPhase == "activities", "each day must begin on the Academy Map")
        performActivity(manager, "astral_court")
        assert(manager:current():name() == "academyLocation" and session.actionsRemaining == 1,
            "the first room activity must remain in its room")
        press(manager, "backspace")
        performActivity(manager, "quiet_garden")
        assert(manager:current():name() == "cardAcquisition" and session.dayPhase == "cardAcquisition",
            "the second room activity must enter card acquisition")
        press(manager, "return")
        assert(session.cardChosenThisDay and #session.collection == day,
            "each day must add exactly one persistent card")
        press(manager, "return")

        if day < session.maxDays then
            assert(manager:current():name() == "academyMap" and session.dayPhase == "socialConversation",
                "days one through four must return to map guidance for a room conversation")
            resolveRoomConversation(manager)
            assert(manager:current():name() == "academyMap" and session.day == day + 1
                and session.dayPhase == "activities" and not session.dailyConversationCompleted,
                "one resolved room conversation must advance to the next activity day")
        end
    end

    assert(manager:current():name() == "finalConversation" and session.day == session.maxDays
        and #session.collection == session.maxDays,
        "day five must preserve the collection and enter final homecoming")
    press(manager, "return")
    press(manager, "right")
    press(manager, "return")
    press(manager, "right")
    press(manager, "return")
    assert(manager:current():name() == "arcaneComplete" and session.complete,
        "the five-day room route must still reach a completed homecoming ending")
    assert(manager:current():world():requireResource("gameSession") == session,
        "all room and final transitions must retain the exact session object")
    manager:quit()
end
