local ArcaneCompleteScene = require("src.game.scenes.ArcaneCompleteScene")
local CardCatalog = require("src.game.cards.CardCatalog")
local EncounterDefinitions = require("src.game.encounters.EncounterDefinitions")
local FinalConversationScene = require("src.game.scenes.FinalConversationScene")
local GameSession = require("src.game.session.GameSession")

local function card(category, index)
    return CardCatalog.forCategory(category)[index]
end

local function play(scene, collectionIndex)
    local world = scene:world()
    world:emit("cardPlayRequested", { collectionIndex = collectionIndex })
    scene:preUpdate(0)
    scene:postFixedUpdate(1 / 60)
    scene:update(1 / 60)
end

local function resolveRun(collection, readiness)
    local session = GameSession.new({
        dayPhase = "finalConversation",
        homecomingReadiness = readiness or 0,
    })
    session.collection = collection
    local scene = FinalConversationScene({ session = session })
    scene:initialize()
    local state = scene:world():requireResource("encounterState")
    for index = 1, #collection do play(scene, index) end
    state = scene:world():requireResource("encounterState")
    assert(state.complete and session.complete,
        "three valid final cards must complete the homecoming invitation")
    scene:dispose()
    return session, state
end

return function()
    local low, lowState = resolveRun({
        card("balanced", 1), card("balanced", 2), card("balanced", 3),
    })
    assert(low.finalRapport == 7 and low.endingId == "promising_friendship"
        and low.endingId == EncounterDefinitions.endingForRapport(low.finalRapport).id,
        "three valid mismatched cards must keep the low homecoming outcome reachable")
    assert(lowState.startingRapportBonus == 0)

    local medium = resolveRun({
        card("knowledge", 1), card("balanced", 1), card("balanced", 2),
    })
    assert(medium.finalRapport == 8 and medium.endingId == "growing_connection",
        "a mixed valid response sequence must keep the medium outcome reachable")

    local high, highState = resolveRun({
        card("knowledge", 1), card("empathy", 1), card("confidence", 1),
    }, 15)
    assert(highState.startingRapportBonus == 3 and highState.rapport == 15
        and high.finalRapport == 15 and high.endingId == "arcane_hearts",
        "capped readiness must contribute before matching final card scores")
    assert(high.homecomingReadiness == 15 and #high.collection == 3
        and GameSession.validate(high),
        "final readiness and collection data must remain valid persistent plain state")

    local result = ArcaneCompleteScene({ session = high })
    result:initialize()
    result:draw(0)
    assert(result:world():validate(),
        "the homecoming result presentation must remain read-only and headless-safe")
    result:dispose()
end
