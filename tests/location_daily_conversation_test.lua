-- Beta 7 acceptance: daily card conversations occur in the scheduled room,
-- retain collection cards, and advance through the existing next-day route.
local AcademyLocationScene = require("src.game.scenes.AcademyLocationScene")
local AcademyMapScene = require("src.game.scenes.AcademyMapScene")
local CardCatalog = require("src.game.cards.CardCatalog")
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

local function fixed(scene)
    scene:preUpdate(0)
    scene:fixedUpdate(1 / 60)
    scene:postFixedUpdate(1 / 60)
end

local function press(scene, key)
    scene:world():emit("keyPressed", { key = key })
    fixed(scene)
end

local function moveToTarget(scene, id)
    local world = scene:world()
    local position, size, target
    local playerQuery = world:query({ all = { "locationPlayer", "locationPosition", "locationSize" } })
    for _, _, currentPosition, currentSize in playerQuery:each() do position, size = currentPosition, currentSize break end
    playerQuery:close()
    local targetQuery = world:query({ all = { "locationInteractable" } })
    for _, candidate in targetQuery:each() do if candidate.id == id then target = candidate break end end
    targetQuery:close()
    assert(position and target, "missing proximity target: " .. tostring(id))
    position.x = target.trigger.x + (target.trigger.w - size.w) / 2
    position.y = target.trigger.y + (target.trigger.h - size.h) / 2
    fixed(scene)
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
    local matching = CardCatalog.forCategory("confidence")[1]
    local alternate = CardCatalog.forCategory("balanced")[1]
    local session = GameSession.new({ day = 1, dayPhase = "socialConversation" })
    session.collection = { matching, alternate }
    local scene = AcademyLocationScene(payload(session, "student_commons"))
    scene:initialize()
    local world = scene:world()
    local state = world:requireResource("dailyConversationState")
    assert(state.targetCharacterId == "outgoing_peer"
        and state.targetLocationId == "student_commons"
        and state.targetLocationName == "Student Commons",
        "the daily objective must identify the target's scheduled room")

    moveToTarget(scene, "outgoing_peer")
    press(scene, "e")
    state = world:requireResource("dailyConversationState")
    assert(state.open and not world:requireResource("locationState").dialogue,
        "E on the scheduled room character must open the card encounter")
    press(scene, "right")
    assert(world:requireResource("dailyConversationSelection") == 2,
        "room card encounters must reuse collection navigation")
    press(scene, "left")

    world:emit("keyPressed", { key = "return" })
    fixed(scene)
    state = world:requireResource("dailyConversationState")
    assert(state.resolved and session.dailyConversationCompleted
        and session.homecomingReadiness == matching.power + 2,
        "a matching room card must retain the shared score and category bonus")
    assert(#session.collection == 2 and session.collection[1].id == matching.id,
        "playing a room card must not remove it from the persistent collection")
    assert(world:eventCount("dayAdvanceRequested") == 1,
        "one room resolution must queue exactly one daily advance")
    scene:update(1 / 60)
    assert(session.day == 2 and state.transitionQueued,
        "the existing advance system must move the room conversation to the next day once")
    press(scene, "return")
    assert(session.day == 2 and session.homecomingReadiness == matching.power + 2,
        "a resolved room conversation cannot award readiness twice")
    scene:dispose()

    local wrongRoom = GameSession.new({ day = 1, dayPhase = "socialConversation" })
    wrongRoom.collection = { matching }
    local wrongScene = AcademyLocationScene(payload(wrongRoom, "astral_court"))
    wrongScene:initialize()
    moveToTarget(wrongScene, "mentor")
    press(wrongScene, "e")
    assert(not wrongScene:world():requireResource("dailyConversationState").open
        and wrongScene:world():requireResource("locationState").dialogue,
        "non-target room characters must keep their ordinary dialogue")
    wrongScene:dispose()

    local manager = SceneManager.new()
    manager:register("academyLocation", AcademyLocationScene)
    manager:register("academyMap", AcademyMapScene)
    local persisted = GameSession.new({ day = 1, dayPhase = "socialConversation" })
    persisted.collection = { matching }
    manager:start("academyLocation", payload(persisted, "student_commons"))
    moveToTarget(manager:current(), "outgoing_peer")
    pressManager(manager, "e")
    pressManager(manager, "return")
    assert(manager:current():name() == "academyMap" and persisted.day == 2
        and persisted.dayPhase == "activities" and not persisted.dailyConversationCompleted,
        "the room conversation must transition through the usual next-day Academy Map route")
    manager:quit()

    local final = GameSession.new({ day = 5, dayPhase = "finalConversation" })
    local finalScene = AcademyLocationScene(payload(final, "quiet_garden"))
    finalScene:initialize()
    assert(finalScene:world():requireResource("dailyConversationState") == false,
        "day five must remain reserved for the final homecoming conversation")
    finalScene:dispose()
end
