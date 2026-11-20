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
    assert(second.stats.confidence == 0, "sessions must not share stats")
    assert(#second.collection == 0, "sessions must not share collections")
    assert(GameSession.validate(first))

    local invalid = GameSession.copy(second)
    invalid.feedback = function() end
    assert(not GameSession.validate(invalid), "sessions must remain plain data")
    invalid = GameSession.copy(second)
    invalid.collection[1] = { id = "not_a_card" }
    assert(not GameSession.validate(invalid), "sessions must reject malformed cards")

    local activities = Activities.all()
    assert(#activities == 4, "four training activities are required")
    activities[1].effects.confidence = 999
    assert(Activities.get("practice_illusions").effects.confidence == 2,
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
    world:emit("cardsGenerated", {
        cards = {
            CardCatalog.forCategory("confidence")[1],
            CardCatalog.forCategory("empathy")[1],
            CardCatalog.forCategory("balanced")[1],
        },
    })
    assert(world:validate())
    world:dispose()
end
