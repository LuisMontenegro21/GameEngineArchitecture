local Scene = require("src.engine.scene.Scene")
local CardCatalog = require("src.game.cards.CardCatalog")
local EncounterProgressionSystem = require("src.game.encounters.EncounterProgressionSystem")
local EncounterResolutionSystem = require("src.game.encounters.EncounterResolutionSystem")
local EncounterSetupSystem = require("src.game.encounters.EncounterSetupSystem")
local Definitions = require("src.game.progression.Definitions")
local GameSession = require("src.game.session.GameSession")

local function card(category, index)
    return CardCatalog.forCategory(category)[index]
end

local function requestPlay(scene, collectionIndex)
    local world = scene:world()
    world:emit("cardPlayRequested", { collectionIndex = collectionIndex })
    world:advanceEvents()
    scene:postFixedUpdate(1 / 60)
    scene:update(1 / 60)
end

return function()
    local knowledge = card("knowledge", 1)
    local empathy = card("empathy", 1)
    local confidence = card("confidence", 1)
    local session = GameSession.new()
    session.collection = { knowledge, empathy, confidence }

    local scene = Scene.new({ name = "encounterSystems" })
    local world = scene:world()
    Definitions.registerArcaneHearts(world)
    world:setResource("gameSession", session)
    EncounterSetupSystem.install(scene:scheduler())
    EncounterResolutionSystem.install(scene:scheduler())
    EncounterProgressionSystem.install(scene:scheduler())
    scene:initialize()

    local state = world:requireResource("encounterState")
    assert(state.promptIndex == 1 and state.focus == 5 and state.rapport == 0)
    assert(world:requireResource("encounterCollectionSelection") == 1)
    assert(world:requireResource("encounterDefinition").prompts[1].id == "astral_theory")

    requestPlay(scene, 1)
    state = world:requireResource("encounterState")
    assert(state.promptIndex == 2 and state.focus == 4 and state.rapport == 4,
        "a matching card must spend Focus, gain power plus the match bonus, and advance")
    assert(state.usedCollectionIndexes[1] == true)
    assert(world:eventCount("conversationPromptAdvanced") == 1,
        "a valid play must announce the next prompt")

    requestPlay(scene, 1)
    state = world:requireResource("encounterState")
    assert(state.promptIndex == 2 and state.focus == 4 and state.rapport == 4,
        "a used card must not change authoritative encounter state")
    assert(state.feedback:find("already been used", 1, true))

    state.focus = 0
    world:setResource("encounterState", state)
    requestPlay(scene, 2)
    state = world:requireResource("encounterState")
    assert(state.promptIndex == 2 and state.focus == 0 and state.rapport == 4,
        "an unaffordable card must not change prompt or rapport")
    assert(state.feedback:find("enough Focus", 1, true))

    state.focus = 3
    world:setResource("encounterState", state)
    requestPlay(scene, 2)
    state = world:requireResource("encounterState")
    assert(state.promptIndex == 3 and state.focus == 2 and state.rapport == 8,
        "a second matching card must advance exactly one prompt")

    requestPlay(scene, 3)
    state = world:requireResource("encounterState")
    assert(state.complete and state.transitionQueued and state.promptIndex == 4)
    assert(session.complete and session.finalRapport == 12 and session.endingId == "arcane_hearts",
        "final completion must persist rapport and the threshold-based ending")
    assert(#session.collection == 3 and session.collection[1] == knowledge,
        "encounter card use must not remove or replace persistent collection cards")
    assert(world:eventCount("conversationCompleted") == 1 and world:eventCount("sceneRequest") == 1,
        "completion must announce one result and one scene transition")

    scene:update(1 / 60)
    assert(world:eventCount("sceneRequest") == 0,
        "encounter completion must not request a second transition")
    assert(world:validate(), "encounter systems must preserve valid world state")
    scene:dispose()
end
