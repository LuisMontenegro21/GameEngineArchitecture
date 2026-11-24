local ECS = require("src.engine.ecs")
local GameSession = require("src.game.session.GameSession")
local Activities = require("src.game.progression.Activities")
local CardCatalog = require("src.game.cards.CardCatalog")
local Definitions = require("src.game.progression.Definitions")

return function()
    local first = GameSession.new()
    local second = GameSession.new()
    first.stats.confidence = 9
    first.collection[1] = CardCatalog.forCategory("confidence")[1]
    first.finalRapport = 9
    first.endingId = "growing_connection"
    assert(second.stats.confidence == 0, "sessions must not share stats")
    assert(#second.collection == 0, "sessions must not share collections")
    assert(second.finalRapport == 0 and second.endingId == nil,
        "sessions must not share final encounter results")
    assert(GameSession.validate(first))

    local completedEncounter = GameSession.new({
        finalRapport = 12,
        endingId = "arcane_hearts",
    })
    assert(completedEncounter.finalRapport == 12 and completedEncounter.endingId == "arcane_hearts",
        "sessions must retain valid final encounter results")

    local invalid = GameSession.copy(second)
    invalid.feedback = function() end
    assert(not GameSession.validate(invalid), "sessions must remain plain data")
    invalid = GameSession.copy(second)
    invalid.collection[1] = { id = "not_a_card" }
    assert(not GameSession.validate(invalid), "sessions must reject malformed cards")
    invalid = GameSession.copy(second)
    invalid.finalRapport = -1
    assert(not GameSession.validate(invalid), "sessions must reject negative final rapport")
    invalid = GameSession.copy(second)
    invalid.finalRapport = 1.5
    assert(not GameSession.validate(invalid), "sessions must reject fractional final rapport")
    invalid = GameSession.copy(second)
    invalid.endingId = "unknown_ending"
    assert(not GameSession.validate(invalid), "sessions must reject unknown ending identifiers")
    assert(not pcall(function()
        GameSession.new({ finalRapport = 2, endingId = "unknown_ending" })
    end), "new sessions must reject invalid final encounter options")

    local activities = Activities.all()
    assert(#activities == 4, "four training activities are required")
    activities[1].effects.confidence = 999
    assert(Activities.get(activities[1].id).effects.confidence == 2,
        "activity callers must receive copies")
    assert(Activities.get("unknown") == nil)

    assert(CardCatalog.count() == 12, "the catalog needs twelve cards")
    for _, category in ipairs(CardCatalog.categories()) do
        local cards = CardCatalog.forCategory(category)
        assert(#cards == 3, "each category needs three cards")
        assert(CardCatalog.validate(cards[1]))
        cards[1].name = "changed"
        assert(CardCatalog.forCategory(category)[1].name ~= "changed",
            "card callers must receive copies")
    end

    local world = ECS.World.new()
    Definitions.registerArcaneHearts(world)
    world:setResource("gameSession", GameSession.new())
    assert(not pcall(function()
        world:setResource("gameSession", { day = 0 })
    end), "invalid session resources must be rejected")
    assert(not pcall(function()
        world:emit("trainingActivityRequested", { activityId = 42 })
    end), "invalid event payloads must be rejected")
    assert(not pcall(function()
        world:emit("cardsGenerated", { cards = { CardCatalog.forCategory("confidence")[1] } })
    end), "invalid card event payloads must be rejected")
    assert(not pcall(function()
        world:emit("cardPlayRequested", { collectionIndex = "first" })
    end), "invalid card-play requests must be rejected")
    assert(not pcall(function()
        world:emit("cardPlayed", {
            collectionIndex = 1,
            cardId = "dazzling_introduction",
            promptId = "unknown_prompt",
            categoryMatched = true,
            focusSpent = 1,
            focusRemaining = 4,
            rapportGained = 4,
            rapport = 4,
        })
    end), "card-play results must reference a known prompt")
    assert(not pcall(function()
        world:emit("conversationCompleted", { finalRapport = 8, endingId = "unknown_ending" })
    end), "conversation completion must reference a known ending")
    world:emit("cardsGenerated", {
        cards = {
            CardCatalog.forCategory("confidence")[1],
            CardCatalog.forCategory("empathy")[1],
            CardCatalog.forCategory("balanced")[1],
        },
    })
    world:emit("cardPlayRequested", { collectionIndex = 1 })
    world:emit("cardPlayed", {
        collectionIndex = 1,
        cardId = "dazzling_introduction",
        promptId = "astral_theory",
        categoryMatched = false,
        focusSpent = 1,
        focusRemaining = 4,
        rapportGained = 2,
        rapport = 2,
    })
    world:emit("cardPlayRejected", { collectionIndex = 1, reason = "Card already used." })
    world:emit("conversationPromptAdvanced", { round = 2, promptId = "quiet_confession" })
    world:emit("conversationCompleted", { finalRapport = 12, endingId = "arcane_hearts" })
    assert(world:validate())
    world:dispose()
end
