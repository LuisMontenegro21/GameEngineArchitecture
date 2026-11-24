local CardCatalog = require("src.game.cards.CardCatalog")
local CardUseUiSetupSystem = require("src.game.ui.CardUseUiSetupSystem")
local EncounterRenderSystem = require("src.game.ui.EncounterRenderSystem")
local FinalConversationScene = require("src.game.scenes.FinalConversationScene")
local GameSession = require("src.game.session.GameSession")

local function card(category, index)
    return CardCatalog.forCategory(category)[index]
end

local function frame(scene)
    scene:preUpdate(1 / 60)
    scene:fixedUpdate(1 / 60)
    scene:postFixedUpdate(1 / 60)
    scene:update(1 / 60)
end

local function press(scene, key)
    scene:world():emit("keyPressed", { key = key })
    frame(scene)
end

return function()
    local knowledge = card("knowledge", 1)
    local empathy = card("empathy", 1)
    local confidence = card("confidence", 1)
    local session = GameSession.new()
    session.collection = { knowledge, empathy, confidence }
    local scene = FinalConversationScene({ session = session })
    scene:initialize()
    local world = scene:world()

    assert(world:requireResource("encounterCollectionSelection") == 1)
    press(scene, "left")
    assert(world:requireResource("encounterCollectionSelection") == 1,
        "left navigation must clamp at the first collection card")
    press(scene, "d")
    assert(world:requireResource("encounterCollectionSelection") == 2,
        "D must navigate right through Final Conversation cards")
    press(scene, "a")
    assert(world:requireResource("encounterCollectionSelection") == 1,
        "A must navigate left through Final Conversation cards")

    assert(EncounterRenderSystem.selectedDetailText(knowledge):find("Focus Cost 1", 1, true),
        "card-use details must label cost as Focus Cost")
    assert(EncounterRenderSystem.availability(knowledge, 1, {
        focus = 1,
        usedCollectionIndexes = {},
    }) == "playable")
    assert(EncounterRenderSystem.availability(knowledge, 1, {
        focus = 1,
        usedCollectionIndexes = { [1] = true },
    }) == "used")
    assert(EncounterRenderSystem.availability(empathy, 2, {
        focus = 0,
        usedCollectionIndexes = {},
    }) == "unaffordable")

    press(scene, "return")
    local state = world:requireResource("encounterState")
    assert(state.promptIndex == 2 and state.rapport == 4 and state.focus == 4,
        "confirmation must request a matching card play through encounter systems")
    assert(session.collection[1] == knowledge and #session.collection == 3,
        "the UI must not remove or replace persistent cards")

    press(scene, "space")
    state = world:requireResource("encounterState")
    assert(state.promptIndex == 2 and state.rapport == 4
        and state.feedback:find("already been used", 1, true),
        "used-card confirmation must be rejected by encounter logic")

    press(scene, "right")
    state.focus = 0
    world:setResource("encounterState", state)
    press(scene, "return")
    state = world:requireResource("encounterState")
    assert(state.promptIndex == 2 and state.rapport == 4
        and state.feedback:find("enough Focus", 1, true),
        "unaffordable cards must produce encounter feedback without progression")

    state.focus = 3
    world:setResource("encounterState", state)
    press(scene, "space")
    assert(world:requireResource("encounterState").promptIndex == 3)
    press(scene, "right")
    press(scene, "return")
    state = world:requireResource("encounterState")
    assert(state.complete and session.complete and session.endingId == "arcane_hearts",
        "the UI-driven flow must complete the encounter through the correct ending")
    scene:draw(0)
    assert(world:validate(), "Final Conversation rendering must be read-only and headless-safe")
    scene:dispose()

    local emptySession = GameSession.new()
    local emptyScene = FinalConversationScene({ session = emptySession })
    emptyScene:initialize()
    assert(emptyScene:world():requireResource("encounterCollectionSelection") == 1)
    press(emptyScene, "return")
    assert(emptyScene:world():requireResource("encounterState").feedback:find(
        "Select a card", 1, true), "an empty collection must reject safely")
    emptyScene:draw(0)
    assert(emptyScene:world():validate(), "empty Final Conversation UI must remain safe")
    emptyScene:dispose()

    assert(CardUseUiSetupSystem.firstPlayableIndex({ collection = { knowledge, empathy } }, {
        focus = 1,
        usedCollectionIndexes = { [1] = true },
    }) == 2, "resumed UI setup must choose the first playable collection card")
end
