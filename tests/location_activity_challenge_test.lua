-- Verifies the reusable sequence and choice activity challenges without
-- duplicating ActivityRules' stat, energy, or transition responsibilities.
local AcademyLocationScene = require("src.game.scenes.AcademyLocationScene")
local GameSession = require("src.game.session.GameSession")

local function payload(session, locationId)
    return {
        session = session,
        locationId = locationId,
        returnTo = "academyMap",
        mapReturnPosition = { x = 220, y = 235 },
    }
end

local function fixed(scene)
    scene:preUpdate(0)
    scene:fixedUpdate(1 / 60)
    scene:postFixedUpdate(1 / 60)
end

local function press(scene, key)
    scene:world():emit("keyPressed", { key = key })
    fixed(scene)
end

local function moveToActivity(scene)
    local world = scene:world()
    local position, size, target
    local playerQuery = world:query({ all = { "locationPlayer", "locationPosition", "locationSize" } })
    for _, _, currentPosition, currentSize in playerQuery:each() do position, size = currentPosition, currentSize break end
    playerQuery:close()
    local activityId = world:requireResource("locationDefinition").activityId
    local targetQuery = world:query({ all = { "locationInteractable" } })
    for _, current in targetQuery:each() do if current.id == activityId then target = current break end end
    targetQuery:close()
    assert(position and target, "activity target is missing")
    position.x = target.trigger.x + (target.trigger.w - size.w) / 2
    position.y = target.trigger.y + (target.trigger.h - size.h) / 2
    fixed(scene)
end

return function()
    local spellSession = GameSession.new()
    local spellScene = AcademyLocationScene(payload(spellSession, "astral_court"))
    spellScene:initialize()
    moveToActivity(spellScene)
    press(spellScene, "e")
    local challenge = spellScene:world():requireResource("activityChallengeState")
    assert(challenge and challenge.mode == "timing" and challenge.timing.markerPosition == 0
        and spellSession.actionsRemaining == 2,
        "spell rehearsal must open its timing challenge before consuming an action")
    fixed(spellScene)
    challenge = spellScene:world():requireResource("activityChallengeState")
    assert(challenge.timing.markerPosition > 0,
        "the spell marker must advance using delta time while the timing challenge is open")
    press(spellScene, "e")
    challenge = spellScene:world():requireResource("activityChallengeState")
    assert(challenge and challenge.feedback:find("slips away", 1, true)
        and spellSession.actionsRemaining == 2,
        "a missed timing press must reset safely without consuming an action")
    challenge.timing.markerPosition = (challenge.timing.targetStart + challenge.timing.targetEnd) / 2
    spellScene:world():setResource("activityChallengeState", challenge)
    press(spellScene, "e")
    assert(spellScene:world():requireResource("activityChallengeState") == false
        and spellSession.actionsRemaining == 1
        and spellSession.feedback:find("timing holds", 1, true),
        "a successful timing press must delegate once to the existing activity rule")
    spellScene:dispose()

    local runeSession = GameSession.new()
    local runeScene = AcademyLocationScene(payload(runeSession, "ancient_library"))
    runeScene:initialize()
    moveToActivity(runeScene)
    press(runeScene, "e")
    challenge = runeScene:world():requireResource("activityChallengeState")
    assert(challenge and challenge.mode == "sequence" and challenge.currentStep == 1,
        "ancient rune study must retain its three-step sequence challenge")
    press(runeScene, "right")
    challenge = runeScene:world():requireResource("activityChallengeState")
    assert(challenge.currentStep == 1 and challenge.feedback:find("fades", 1, true),
        "an incorrect ancient rune input must reset without spending an action")
    for _, key in ipairs(challenge.steps) do press(runeScene, key) end
    assert(runeSession.actionsRemaining == 1,
        "a completed ancient rune sequence must still resolve its activity once")
    runeScene:dispose()

    local peerSession = GameSession.new()
    local peerScene = AcademyLocationScene(payload(peerSession, "student_commons"))
    peerScene:initialize()
    moveToActivity(peerScene)
    press(peerScene, "e")
    challenge = peerScene:world():requireResource("activityChallengeState")
    assert(challenge and challenge.mode == "choice" and challenge.selection == 1,
        "peer support must open a response-choice challenge")
    press(peerScene, "right")
    assert(peerScene:world():requireResource("activityChallengeState").selection == 2,
        "response choices must use safe cyclic keyboard navigation")
    press(peerScene, "e")
    assert(peerScene:world():requireResource("activityChallengeState") == false
        and peerSession.actionsRemaining == 1
        and peerSession.feedback:find("work through", 1, true),
        "the selected response must add its feedback while reusing activity effects")
    peerScene:dispose()
end
