local TrainingScene = require("src.game.scenes.TrainingScene")
local GameSession = require("src.game.session.GameSession")
local TrainingRenderSystem = require("src.game.ui.TrainingRenderSystem")

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
    press(scene, "up")
    assert(world:requireResource("trainingSelection") == 1,
        "training selection must clamp at the first activity")
    press(scene, "down")
    press(scene, "down")
    press(scene, "down")
    assert(world:requireResource("trainingSelection") == 4,
        "all four activities must be selectable")
    press(scene, "up")
    press(scene, "up")
    press(scene, "up")
    press(scene, "w")
    assert(world:requireResource("trainingSelection") == 1,
        "W must be an alias for upward training selection")
    press(scene, "s")
    assert(world:requireResource("trainingSelection") == 2,
        "S must be an alias for downward training selection")
    press(scene, "w")

    assert(TrainingRenderSystem.costText(require("src.game.progression.Activities").all()[1]) == "1 energy")
    assert(TrainingRenderSystem.effectText(require("src.game.progression.Activities").all()[1])
        :find("Confidence +2", 1, true), "Training UI must describe each activity effect")

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
    scene:draw(0)
    assert(world:validate(), "training UI render must remain read-only and headless-safe")
    scene:dispose()
end
