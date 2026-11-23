local GameSession = require("src.game.session.GameSession")
local CardAcquisitionScene = require("src.game.scenes.CardAcquisitionScene")
local CardRenderSystem = require("src.game.ui.CardRenderSystem")

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

local function start(session)
    local scene = CardAcquisitionScene({ session = session })
    scene:initialize()
    frame(scene) -- startup generation request is resolved in preUpdate
    return scene
end

return function()
    local confident = GameSession.new({
        stats = { confidence = 4, empathy = 1, arcaneKnowledge = 0 },
    })
    confident.lastActivity = "help_a_classmate"
    local firstScene = start(confident)
    local fixedSystems = firstScene:scheduler():systemsFor("fixedUpdate")
    assert(fixedSystems[1].name == "cardUiUpdate",
        "Card scene must install the explicit UI update system")
    assert(#confident.generatedCards == 3)
    assert(confident.generatedCards[1].category == "confidence")
    assert(confident.generatedCards[2].category == "empathy")
    assert(confident.generatedCards[3].category == "balanced")
    assert(CardRenderSystem.cardText(nil):find("No cards acquired", 1, true),
        "card UI must provide a clear empty-collection message")
    assert(CardRenderSystem.categoryColor("confidence").r > 0,
        "card UI must provide a visual category identity")
    assert(CardRenderSystem.cardText(confident.generatedCards[1]):find(
        confident.generatedCards[1].name, 1, true),
        "selected-card details must identify the selected card")

    press(firstScene, "tab")
    press(firstScene, "d")
    assert(confident.collectionSelection == 1,
        "an empty collection must remain safe to navigate")
    press(firstScene, "tab")
    press(firstScene, "right")
    assert(confident.generatedSelection == 2)
    press(firstScene, "return")
    assert(#confident.collection == 1 and confident.cardChosenThisDay,
        "one selected card must be copied into the persistent collection")
    local acquired = confident.collection[1].id
    world = firstScene:world()
    world:emit("cardAcquisitionRequested", { index = confident.generatedSelection })
    frame(firstScene)
    assert(#confident.collection == 1 and confident.collection[1].id == acquired,
        "only one card may be acquired per day")
    press(firstScene, "tab")
    press(firstScene, "right")
    assert(confident.collectionSelection == 1,
        "a non-empty collection must keep a valid selected card")
    firstScene:draw(0)
    assert(firstScene:world():validate(), "card UI render must remain read-only and headless-safe")
    firstScene:dispose()

    local empathic = GameSession.new({
        stats = { confidence = 0, empathy = 4, arcaneKnowledge = 1 },
    })
    empathic.lastActivity = "practice_spells"
    local secondScene = start(empathic)
    assert(empathic.generatedCards[1].category == "empathy")
    assert(empathic.generatedCards[2].category == "confidence")
    assert(empathic.generatedCards[1].id ~= confident.generatedCards[1].id,
        "changing training state must change generated results")
    secondScene:dispose()

    local recreated = start(confident)
    assert(#confident.collection == 1 and confident.collection[1].id == acquired,
        "collection cards must survive scene recreation")
    recreated:dispose()
end
