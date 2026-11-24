local ECS = require("src.engine.ecs")
local GameSession = require("src.game.session.GameSession")
local Definitions = require("src.game.progression.Definitions")
local AcademyMapScene = require("src.game.scenes.AcademyMapScene")

return function()
    local fresh = GameSession.new()
    assert(fresh.runSeed == 1, "fresh sessions must use a stable default seed")
    assert(fresh.dayPhase == "activities", "fresh sessions must begin with activities")
    assert(fresh.homecomingReadiness == 0, "fresh sessions must begin with zero readiness")
    assert(fresh.dailyConversationCompleted == false,
        "fresh sessions must not complete a social conversation")

    local resumed = GameSession.new({
        runSeed = 718,
        dayPhase = "socialConversation",
        homecomingReadiness = 6,
        dailyConversationCompleted = true,
    })
    local copied = GameSession.copy(resumed)
    assert(copied ~= resumed, "copy must create a separate session table")
    assert(copied.runSeed == 718 and copied.dayPhase == "socialConversation"
        and copied.homecomingReadiness == 6 and copied.dailyConversationCompleted,
        "copy must preserve all alpha session state")

    local invalid = GameSession.copy(resumed)
    invalid.runSeed = -1
    assert(not GameSession.validate(invalid), "negative seeds must be rejected")
    invalid = GameSession.copy(resumed)
    invalid.runSeed = 1.5
    assert(not GameSession.validate(invalid), "fractional seeds must be rejected")
    invalid = GameSession.copy(resumed)
    invalid.dayPhase = "unknown"
    assert(not GameSession.validate(invalid), "unknown day phases must be rejected")
    invalid = GameSession.copy(resumed)
    invalid.homecomingReadiness = -1
    assert(not GameSession.validate(invalid), "negative readiness must be rejected")
    invalid = GameSession.copy(resumed)
    invalid.dailyConversationCompleted = "true"
    assert(not GameSession.validate(invalid), "non-boolean completion flags must be rejected")
    assert(not pcall(function()
        GameSession.new({ dayPhase = "unknown" })
    end), "new sessions must reject invalid alpha state")

    local map = AcademyMapScene({ session = resumed, returnTo = "training" })
    map:initialize()
    local reconstructed = map:world():requireResource("gameSession")
    assert(reconstructed == resumed and reconstructed.runSeed == 718
        and reconstructed.dayPhase == "socialConversation"
        and reconstructed.homecomingReadiness == 6
        and reconstructed.dailyConversationCompleted,
        "scene reconstruction must preserve alpha session state")
    map:dispose()

    local world = ECS.World.new()
    Definitions.registerArcaneHearts(world)
    assert(world:hasEventDefinition("dayPhaseChanged"),
        "Arcane definitions must expose the day-phase event")
    world:emit("dayPhaseChanged", {
        from = "activities",
        to = "cardAcquisition",
        day = 1,
    })
    assert(not pcall(function()
        world:emit("dayPhaseChanged", {
            from = "activities",
            to = "invalid",
            day = 1,
        })
    end), "day-phase events must reject invalid phases")
    assert(not pcall(function()
        world:emit("dayPhaseChanged", {
            from = "activities",
            to = "activities",
            day = 1,
        })
    end), "day-phase events must represent a state change")
    assert(world:validate(), "alpha session contracts must remain valid world data")
    world:dispose()
end
