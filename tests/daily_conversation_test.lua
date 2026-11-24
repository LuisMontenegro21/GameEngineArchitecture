local AcademyMapScene = require("src.game.scenes.AcademyMapScene")
local CardCatalog = require("src.game.cards.CardCatalog")
local CharacterCatalog = require("src.game.characters.CharacterCatalog")
local DailyConversationDefinitions = require("src.game.conversations.DailyConversationDefinitions")
local GameSession = require("src.game.session.GameSession")
local SceneManager = require("src.engine.scene.SceneManager")

local function tickScene(scene)
    scene:preUpdate(0)
    scene:fixedUpdate(1 / 60)
    scene:postFixedUpdate(1 / 60)
end

local function pressScene(scene, key)
    scene:world():emit("keyPressed", { key = key })
    tickScene(scene)
end

local function tickManager(manager)
    manager:preUpdate(0)
    manager:fixedUpdate(1 / 60)
    manager:postFixedUpdate(1 / 60)
    manager:update(1 / 60)
    manager:postUpdate(1 / 60)
end

local function pressManager(manager, key)
    manager:current():world():emit("keyPressed", { key = key })
    tickManager(manager)
end

local function player(world)
    local query = world:query({ all = { "mapPlayer", "mapPosition", "mapSize" } })
    local position, size = nil, nil
    for _, _, currentPosition, currentSize in query:each() do
        position, size = currentPosition, currentSize
        break
    end
    query:close()
    assert(position and size, "map player is missing")
    return position, size
end

local function interactionFor(world, characterId)
    local query = world:query({ all = { "mapCharacter", "mapInteractable" } })
    local result = nil
    for _, _, interaction in query:each() do
        if interaction.id == characterId then
            result = interaction
            break
        end
    end
    query:close()
    assert(result, "missing scheduled character: " .. characterId)
    return result
end

local function approach(world, characterId)
    local position, size = player(world)
    local interaction = interactionFor(world, characterId)
    position.x = interaction.trigger.x + (interaction.trigger.w - size.w) / 2
    position.y = interaction.trigger.y + (interaction.trigger.h - size.h) / 2
end

local function socialSession(day, collection)
    local session = GameSession.new({ day = day, dayPhase = "socialConversation" })
    session.collection = collection or {}
    return session
end

return function()
    local dayOne = DailyConversationDefinitions.get(1)
    assert(dayOne.targetCharacterId == "outgoing_peer"
        and dayOne.preferredCategory == "confidence",
        "day one must target the outgoing peer with a confidence response")
    assert(DailyConversationDefinitions.get(5) == nil,
        "day five must reserve its interaction for the final encounter")

    local matchingCard = CardCatalog.forCategory("confidence")[1]
    local alternateCard = CardCatalog.forCategory("confidence")[2]
    local session = socialSession(1, { matchingCard, alternateCard })
    local scene = AcademyMapScene({ session = session })
    scene:initialize()
    local world = scene:world()
    local state = world:requireResource("dailyConversationState")
    assert(state.targetCharacterId == "outgoing_peer" and not state.open,
        "a social-phase map must initialize its scheduled target and highlight state")

    approach(world, "crush")
    scene:fixedUpdate(1 / 60)
    pressScene(scene, "e")
    assert(not world:requireResource("dailyConversationState").open
        and world:requireResource("dialogueState").targetId == "crush",
        "only the scheduled character may open the daily card conversation")
    pressScene(scene, "escape")

    approach(world, state.targetCharacterId)
    scene:fixedUpdate(1 / 60)
    pressScene(scene, "e")
    state = world:requireResource("dailyConversationState")
    assert(state.open and world:requireResource("dialogueState") == false,
        "E on the scheduled target must open the card conversation instead of flavor dialogue")
    pressScene(scene, "right")
    assert(world:requireResource("dailyConversationSelection") == 2,
        "daily conversation cards must be selectable with the shared collection controls")
    pressScene(scene, "left")
    assert(world:requireResource("dailyConversationSelection") == 1)

    -- Resolve only through fixed and post-fixed stages so the daily result can
    -- be inspected before its update-stage transition consumes the request.
    world:emit("keyPressed", { key = "return" })
    scene:preUpdate(0)
    scene:fixedUpdate(1 / 60)
    scene:postFixedUpdate(1 / 60)
    state = world:requireResource("dailyConversationState")
    local gained = matchingCard.power + 2
    assert(state.resolved and session.dailyConversationCompleted
        and session.homecomingReadiness == gained,
        "a matching card must add its power and the two-point category bonus")
    assert(#session.collection == 2 and session.collection[1].id == matchingCard.id,
        "daily card use must not remove a persistent collection card")
    assert(world:eventCount("dayAdvanceRequested") == 1,
        "one resolved daily card must request advancement exactly once")
    scene:update(1 / 60)
    assert(session.day == 2 and state.transitionQueued,
        "the resolved daily conversation must advance its day exactly once")
    pressScene(scene, "return")
    assert(session.day == 2 and session.homecomingReadiness == gained
        and world:eventCount("dayAdvanceRequested") == 0,
        "duplicate confirmation must not award readiness or advance a second time")
    scene:dispose()

    local mismatchCard = CardCatalog.forCategory("confidence")[1]
    local mismatchSession = socialSession(2, { mismatchCard })
    local mismatchScene = AcademyMapScene({ session = mismatchSession })
    mismatchScene:initialize()
    local mismatchWorld = mismatchScene:world()
    local mismatchState = mismatchWorld:requireResource("dailyConversationState")
    approach(mismatchWorld, mismatchState.targetCharacterId)
    mismatchScene:fixedUpdate(1 / 60)
    pressScene(mismatchScene, "e")
    mismatchWorld:emit("keyPressed", { key = "return" })
    mismatchScene:preUpdate(0)
    mismatchScene:fixedUpdate(1 / 60)
    mismatchScene:postFixedUpdate(1 / 60)
    assert(mismatchWorld:requireResource("dailyConversationState").resolved
        and mismatchSession.homecomingReadiness == mismatchCard.power,
        "a mismatch must remain valid and grant card power without the bonus")
    mismatchScene:dispose()

    local emptySession = socialSession(3)
    local emptyScene = AcademyMapScene({ session = emptySession })
    emptyScene:initialize()
    local emptyWorld = emptyScene:world()
    local emptyState = emptyWorld:requireResource("dailyConversationState")
    approach(emptyWorld, emptyState.targetCharacterId)
    emptyScene:fixedUpdate(1 / 60)
    pressScene(emptyScene, "e")
    pressScene(emptyScene, "return")
    emptyState = emptyWorld:requireResource("dailyConversationState")
    assert(not emptyState.resolved and emptySession.homecomingReadiness == 0
        and emptyState.feedback:find("Select a card", 1, true),
        "empty collections must reject card play safely without progression changes")
    emptyScene:dispose()

    local manager = SceneManager.new()
    manager:register("academyMap", AcademyMapScene)
    local persisted = socialSession(1, { CardCatalog.forCategory("confidence")[1] })
    manager:start("academyMap", { session = persisted })
    local mapWorld = manager:current():world()
    local target = mapWorld:requireResource("dailyConversationState").targetCharacterId
    approach(mapWorld, target)
    tickManager(manager)
    pressManager(manager, "e")
    pressManager(manager, "return")
    assert(manager:current():name() == "academyMap" and persisted.day == 2
        and persisted.dayPhase == "activities" and persisted.homecomingReadiness > 0,
        "readiness must survive the daily map-to-next-day scene transition")
    assert(not persisted.dailyConversationCompleted
        and manager:current():world():requireResource("gameSession") == persisted,
        "the new day must reset its completion flag while retaining the shared session")
    manager:quit()

    assert(CharacterCatalog.get("outgoing_peer"), "daily targets must be catalog characters")
end
