local SceneManager = require("src.engine.scene.SceneManager")
local GameSession = require("src.game.session.GameSession")
local TrainingScene = require("src.game.scenes.TrainingScene")
local CardAcquisitionScene = require("src.game.scenes.CardAcquisitionScene")
local FinalConversationScene = require("src.game.scenes.FinalConversationScene")
local ArcaneCompleteScene = require("src.game.scenes.ArcaneCompleteScene")

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

return function()
    local manager = SceneManager.new()
    manager:register("training", TrainingScene)
    manager:register("cardAcquisition", CardAcquisitionScene)
    manager:register("finalConversation", FinalConversationScene)
    manager:register("arcaneComplete", ArcaneCompleteScene)
    local session = GameSession.new()
    manager:start("training", { session = session })

    for day = 1, session.maxDays do
        assert(manager:current():name() == "training")
        assert(manager:current():world():requireResource("gameSession") == session,
            "scene recreation must preserve the shared session object")
        press(manager, "return")
        assert(manager:current():name() == "training" and session.actionsRemaining == 1,
            "card acquisition must remain unavailable until all training actions are used")
        press(manager, "down")
        press(manager, "down")
        press(manager, "down")
        press(manager, "return")
        assert(manager:current():name() == "cardAcquisition",
            "two training actions must be required before card acquisition; got "
                .. manager:current():name() .. " with " .. session.actionsRemaining .. " actions")
        assert(#session.generatedCards == 3)
        press(manager, "return")
        assert(session.cardChosenThisDay and #session.collection == day)
        press(manager, "return")
        if day < session.maxDays then
            assert(manager:current():name() == "training")
            assert(session.day == day + 1 and session.actionsRemaining == session.actionsPerDay)
            assert(not session.cardChosenThisDay and #session.generatedCards == 0)
        end
    end

    assert(manager:current():name() == "finalConversation")
    assert(not session.complete and session.day == session.maxDays,
        "the final day must enter the encounter without starting an extra Training day")
    assert(manager:current():world():requireResource("gameSession") == session,
        "the final encounter must receive the existing shared session")
    assert(manager:current():world():requireResource("encounterState").promptIndex == 1,
        "the final encounter must begin at its first prompt")
    assert(#session.collection == session.maxDays and session.stats.confidence == 10,
        "all daily rewards and training changes must persist through the run")

    -- The deterministic training route above collected confidence cards. They
    -- only match the last prompt, so this complete application path produces a
    -- different outcome than the fully matching Arcane Hearts system test.
    press(manager, "return")
    assert(manager:current():name() == "finalConversation")
    press(manager, "right")
    press(manager, "return")
    assert(manager:current():name() == "finalConversation")
    press(manager, "right")
    press(manager, "return")

    assert(manager:current():name() == "arcaneComplete",
        "the completed encounter must transition to the result scene")
    assert(session.complete and session.finalRapport == 8
        and session.endingId == "growing_connection",
        "a different card-match sequence must produce its rapport-based ending")
    assert(manager:current():world():requireResource("gameSession") == session,
        "the result scene must preserve the completed shared session")
    manager:draw(0)
    manager:quit()
end
