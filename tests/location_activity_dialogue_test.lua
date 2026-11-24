local AcademyLocationScene = require("src.game.scenes.AcademyLocationScene")
local CardAcquisitionScene = require("src.game.scenes.CardAcquisitionScene")
local GameSession = require("src.game.session.GameSession")
local SceneManager = require("src.engine.scene.SceneManager")

local function payload(session, locationId)
    return {
        session = session,
        locationId = locationId,
        returnTo = "academyMap",
        mapReturnPosition = { x = 220, y = 235 },
    }
end

local function pressScene(scene, key)
    scene:world():emit("keyPressed", { key = key })
    scene:preUpdate(0)
    scene:fixedUpdate(1 / 60)
    scene:postFixedUpdate(1 / 60)
end

local function moveToTarget(scene, id)
    local world = scene:world()
    local playerPosition, playerSize, target = nil, nil, nil
    local playerQuery = world:query({ all = { "locationPlayer", "locationPosition", "locationSize" } })
    for _, _, position, size in playerQuery:each() do playerPosition, playerSize = position, size break end
    playerQuery:close()
    local targetQuery = world:query({ all = { "locationInteractable" } })
    for _, candidate in targetQuery:each() do if candidate.id == id then target = candidate break end end
    targetQuery:close()
    assert(playerPosition and target, "location target is missing: " .. tostring(id))
    playerPosition.x = target.trigger.x + (target.trigger.w - playerSize.w) / 2
    playerPosition.y = target.trigger.y + (target.trigger.h - playerSize.h) / 2
    scene:preUpdate(0)
    scene:fixedUpdate(1 / 60)
end

local function tick(manager)
    manager:preUpdate(0)
    manager:fixedUpdate(1 / 60)
    manager:postFixedUpdate(1 / 60)
    manager:update(1 / 60)
    manager:postUpdate(1 / 60)
end

local function pressManager(manager, key)
    manager:current():world():emit("keyPressed", { key = key })
    tick(manager)
end

return function()
    local cases = {
        { locationId = "astral_court", stat = "confidence", expected = 2 },
        { locationId = "student_commons", stat = "empathy", expected = 2 },
        { locationId = "ancient_library", stat = "arcaneKnowledge", expected = 2 },
        { locationId = "quiet_garden", stat = nil, expected = 5 },
    }
    for _, case in ipairs(cases) do
        local session = GameSession.new()
        local scene = AcademyLocationScene(payload(session, case.locationId))
        scene:initialize()
        moveToTarget(scene, scene:world():requireResource("locationDefinition").activityId)
        pressScene(scene, "e")
        assert(session.actionsRemaining == 1,
            "a successful room activity must consume exactly one action")
        if case.stat then
            assert(session.stats[case.stat] == case.expected and session.energy == 2)
        else
            assert(session.energy == case.expected)
        end
        assert(scene:world():requireResource("locationState").feedback == session.feedback,
            "room feedback must mirror the authoritative shared activity feedback")
        scene:dispose()
    end

    local rejected = GameSession.new()
    rejected.energy = 0
    local rejectedScene = AcademyLocationScene(payload(rejected, "astral_court"))
    rejectedScene:initialize()
    moveToTarget(rejectedScene, "practice_spells")
    pressScene(rejectedScene, "e")
    assert(rejected.actionsRemaining == 2 and rejected.stats.confidence == 0
        and rejected.feedback:find("enough energy", 1, true),
        "insufficient energy must reject safely without consuming a room action")
    rejectedScene:dispose()

    local dialogueScene = AcademyLocationScene(payload(GameSession.new(), "astral_court"))
    dialogueScene:initialize()
    moveToTarget(dialogueScene, "mentor")
    pressScene(dialogueScene, "e")
    local state = dialogueScene:world():requireResource("locationState")
    assert(state.dialogue and state.dialogue.characterId == "mentor" and state.dialogue.lineIndex == 1,
        "E on a focused scheduled character must open their room dialogue")
    pressScene(dialogueScene, "e")
    assert(dialogueScene:world():requireResource("locationState").dialogue.lineIndex == 2,
        "room dialogue must advance one line per confirmation")
    pressScene(dialogueScene, "e")
    assert(dialogueScene:world():requireResource("locationState").dialogue == false,
        "the final dialogue confirmation must close the room dialogue")
    dialogueScene:dispose()

    local manager = SceneManager.new()
    manager:register("academyLocation", AcademyLocationScene)
    manager:register("cardAcquisition", CardAcquisitionScene)
    local session = GameSession.new()
    manager:start("academyLocation", payload(session, "astral_court"))
    moveToTarget(manager:current(), "practice_spells")
    pressManager(manager, "e")
    assert(manager:current():name() == "academyLocation" and session.actionsRemaining == 1,
        "one successful room activity must remain in the room")
    moveToTarget(manager:current(), "practice_spells")
    pressManager(manager, "e")
    assert(manager:current():name() == "cardAcquisition"
        and session.dayPhase == "cardAcquisition" and session.actionsRemaining == 0,
        "the second successful room activity must transition once to card acquisition")
    manager:quit()
end
