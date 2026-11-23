local SceneManager = require("src.engine.scene.SceneManager")
local GameSession = require("src.game.session.GameSession")
local CardCatalog = require("src.game.cards.CardCatalog")
local TrainingScene = require("src.game.scenes.TrainingScene")
local AcademyMapScene = require("src.game.scenes.AcademyMapScene")

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

local function sameTable(left, right)
    if type(left) ~= type(right) then return false end
    if type(left) ~= "table" then return left == right end
    for key, value in pairs(left) do
        if not sameTable(value, right[key]) then return false end
    end
    for key in pairs(right) do
        if left[key] == nil then return false end
    end
    return true
end

return function()
    local manager = SceneManager.new()
    manager:register("training", TrainingScene)
    manager:register("academyMap", AcademyMapScene)

    local session = GameSession.new()
    session.actionsRemaining = 1
    session.energy = 4
    session.stats.confidence = 2
    session.stats.empathy = 3
    session.stats.arcaneKnowledge = 1
    session.feedback = "Ready to explore."
    session.collection[1] = CardCatalog.forCategory("empathy")[1]
    local before = GameSession.copy(session)
    manager:start("training", { session = session })

    press(manager, "m")
    assert(manager:current():name() == "academyMap",
        "Training must enter the map through normal SceneManager flow")
    assert(manager:current():world():requireResource("gameSession") == session,
        "map entry must preserve the exact shared session object")

    press(manager, "backspace")
    assert(manager:current():name() == "training",
        "Backspace must return from the map through normal SceneManager flow")
    assert(manager:current():world():requireResource("gameSession") == session)
    assert(sameTable(session, before),
        "a map round trip must not mutate progression data")
    manager:quit()

    local direct = AcademyMapScene({ session = GameSession.new(), returnTo = "training" })
    direct:initialize()
    local world = direct:world()
    world:emit("mapExitRequested")
    world:emit("mapExitRequested")
    direct:fixedUpdate(1 / 60)
    direct:postFixedUpdate(1 / 60)
    assert(world:requireResource("mapTransitionQueued"),
        "the first exit request must queue a transition")
    assert(world:eventCount("sceneRequest") == 1,
        "repeated exit requests must produce at most one scene request")
    direct:dispose()
end
