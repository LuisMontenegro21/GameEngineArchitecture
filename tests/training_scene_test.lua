local TrainingScene = require("src.game.scenes.TrainingScene")
local GameSession = require("src.game.session.GameSession")

local function frame(scene)
    scene:preUpdate(1 / 60)
    scene:fixedUpdate(1 / 60)
    scene:postFixedUpdate(1 / 60)
    scene:update(1 / 60)
end

local function press(scene, key)
    local world = scene:world()
    world:emit("keyPressed", { key = key })
    frame(scene)
end

local function resolveDecision(scene)
    -- Input, activity resolution, and feedback run in successive scheduler
    -- stages of one application frame.
    frame(scene)
end

return function()
    local session = GameSession.new()
    local scene = TrainingScene({ session = session })
    scene:initialize()
    local world = scene:world()

    assert(world:requireResource("trainingSelection") == 1)
    press(scene, "down")
    press(scene, "down")
    press(scene, "down")
    assert(world:requireResource("trainingSelection") == 4,
        "all four activities must be selectable")
    press(scene, "up")
    press(scene, "up")
    press(scene, "up")

    press(scene, "return")
    resolveDecision(scene)
    assert(session.stats.confidence == 2 and session.energy == 2
        and session.actionsRemaining == 1, "a valid activity must apply its effect")
    assert(session.feedback:find("Confidence", 1, true),
        "successful training must provide feedback")

    session.energy = 0
    world:setResource("gameSession", session)
    press(scene, "return")
    resolveDecision(scene)
    assert(session.actionsRemaining == 1 and session.stats.confidence == 2,
        "insufficient energy must not consume an action or modify stats")
    assert(session.feedback:find("enough energy", 1, true),
        "rejected training must provide feedback")

    session.energy = 1
    world:setResource("gameSession", session)
    press(scene, "down")
    press(scene, "down")
    press(scene, "down")
    assert(world:requireResource("trainingSelection") == 4)
    press(scene, "space")
    assert(session.actionsRemaining == 0)
    assert(world:requireResource("trainingTransitionQueued"))
    assert(world:eventCount("sceneRequest") == 1,
        "exhausting actions must request Card Acquisition exactly once")

    frame(scene)
    assert(world:eventCount("sceneRequest") == 0,
        "the transition system must not request a second transition")
    scene:dispose()
end
