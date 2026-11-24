-- Executes every production scene's render systems against a minimal LOVE
-- graphics surface. This catches render-time API errors while keeping the
-- suite asset-free and deterministic.
local AcademyMapScene = require("src.game.scenes.AcademyMapScene")
local AcademyLocationScene = require("src.game.scenes.AcademyLocationScene")
local ArcaneCompleteScene = require("src.game.scenes.ArcaneCompleteScene")
local CardAcquisitionScene = require("src.game.scenes.CardAcquisitionScene")
local FinalConversationScene = require("src.game.scenes.FinalConversationScene")
local TrainingScene = require("src.game.scenes.TrainingScene")
local CardCatalog = require("src.game.cards.CardCatalog")
local ImageManager = require("src.game.graphics.ImageManager")
local SpriteSheet = require("src.game.graphics.SpriteSheet")
local GameSession = require("src.game.session.GameSession")
local LocationCatalog = require("src.game.locations.LocationCatalog")

local function completedSession()
    local session = GameSession.new({ dayPhase = "complete" })
    session.complete = true
    session.endingId = "promising_friendship"
    assert(GameSession.validate(session), "completed render fixture must remain valid")
    return session
end

local function finalSession()
    local session = GameSession.new({ dayPhase = "finalConversation" })
    session.collection = {
        CardCatalog.forCategory("confidence")[1],
        CardCatalog.forCategory("empathy")[1],
        CardCatalog.forCategory("knowledge")[1],
    }
    assert(GameSession.validate(session), "final render fixture must remain valid")
    return session
end

return function()
    local previousLove = love
    local drawCalls = 0
    _G.love = {
        graphics = {
            newImage = function() error("optional test assets are intentionally absent") end,
            setColor = function() drawCalls = drawCalls + 1 end,
            clear = function() drawCalls = drawCalls + 1 end,
            rectangle = function() drawCalls = drawCalls + 1 end,
            ellipse = function() drawCalls = drawCalls + 1 end,
            printf = function() drawCalls = drawCalls + 1 end,
        },
    }
    ImageManager.clear()
    SpriteSheet.clear()

    local scenes = {
        AcademyMapScene({ session = GameSession.new() }),
        AcademyMapScene({ session = GameSession.new({ dayPhase = "socialConversation" }) }),
        TrainingScene({ session = GameSession.new() }),
        CardAcquisitionScene({ session = GameSession.new({ dayPhase = "cardAcquisition" }) }),
        FinalConversationScene({ session = finalSession() }),
        ArcaneCompleteScene({ session = completedSession() }),
    }
    for _, locationId in ipairs(LocationCatalog.ids()) do
        scenes[#scenes + 1] = AcademyLocationScene({
            session = GameSession.new(),
            locationId = locationId,
            returnTo = "academyMap",
            mapReturnPosition = { x = 220, y = 235 },
        })
    end
    local challengeScene = AcademyLocationScene({
        session = GameSession.new(),
        locationId = "astral_court",
        returnTo = "academyMap",
        mapReturnPosition = { x = 220, y = 235 },
    })
    challengeScene:initialize()
    challengeScene:world():setResource("activityChallengeState", {
        activityId = "practice_spells", mode = "timing", title = "Spell Rehearsal",
        prompt = "Release the spell inside the focus zone.", steps = nil, currentStep = 1,
        options = nil, selection = 1, visualId = "spellRehearsalTiming",
        timing = { markerPosition = 0.5, direction = 1, speed = 0.85, targetStart = 0.42, targetEnd = 0.58 },
        completionFeedback = "Your timing holds the spell perfectly in focus.", feedback = "Press E in the focus zone.",
    })
    challengeScene:draw(0)
    assert(challengeScene:world():validate(),
        "the activity challenge overlay must remain headless-safe and read-only")
    challengeScene:dispose()
    for _, scene in ipairs(scenes) do
        scene:initialize()
        scene:draw(0)
        assert(scene:world():validate(),
            "rendering must not corrupt the " .. scene:name() .. " scene world")
        scene:dispose()
    end
    assert(drawCalls > 0, "the LOVE render smoke test must execute drawing calls")

    _G.love = previousLove
    ImageManager.clear()
    SpriteSheet.clear()
end
