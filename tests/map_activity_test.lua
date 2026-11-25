local ActivityRules = require("src.game.progression.ActivityRules")
local AcademyMapScene = require("src.game.scenes.AcademyMapScene")
local GameSession = require("src.game.session.GameSession")

local function player(world)
    local query = world:query({ all = { "mapPlayer", "mapPosition", "mapSize" } })
    local position, size = nil, nil
    for _, _, currentPosition, currentSize in query:each() do
        position, size = currentPosition, currentSize
        break
    end
    query:close()
    assert(position and size, "map player is missing")
    return position, size
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

local function press(scene, key)
    scene:world():emit("keyPressed", { key = key })
    scene:preUpdate(0)
    scene:fixedUpdate(1 / 60)
    scene:postFixedUpdate(1 / 60)
end

local function approach(scene, pointId)
    local world = scene:world()
    local map = world:requireResource("mapDefinition")
    local position, size = player(world)
    for _, point in ipairs(map.pointsOfInterest) do
        if point.id == pointId then
            position.x = point.trigger.x + (point.trigger.w - size.w) / 2
            position.y = point.trigger.y + (point.trigger.h - size.h) / 2
            scene:fixedUpdate(1 / 60)
            return world:requireResource("nearbyInteraction")
        end
    end
    error("unknown point of interest: " .. pointId)
end

-- Beta 4 moves player-facing POI entry to location scenes. Keep this test
-- focused on the existing authoritative map activity resolver until Beta 6
-- delegates room activity input to the same request boundary.
local function requestMapActivity(scene, activityId)
    scene:world():emit("mapActivityRequested", { activityId = activityId })
    scene:preUpdate(0)
    scene:postFixedUpdate(1 / 60)
end

local function freshScene()
    local scene = AcademyMapScene()
    scene:initialize()
    return scene, scene:world():requireResource("gameSession")
end

return function()
    local pureSession = GameSession.new()
    local beforeResolve = GameSession.copy(pureSession)
    local resolved = ActivityRules.resolve(pureSession, "practice_spells")
    assert(resolved.success and sameTable(pureSession, beforeResolve),
        "activity resolution must be pure until its result is applied")
    ActivityRules.apply(pureSession, resolved)
    assert(pureSession.actionsRemaining == 1 and pureSession.energy == 2
        and pureSession.stats.confidence == 2 and pureSession.completedActivities.practice_spells,
        "the shared rules must apply the established spell-practice result")
    local repeated = ActivityRules.resolve(pureSession, "practice_spells")
    assert(not repeated.success and repeated.reason:find("already completed", 1, true),
        "a completed activity must be unavailable until the next academy day")

    local cases = {
        {
            pointId = "astral_court", activityId = "practice_spells",
            verify = function(session)
                return session.stats.confidence == 2 and session.energy == 2
            end,
        },
        {
            pointId = "student_commons", activityId = "help_a_classmate",
            verify = function(session)
                return session.stats.empathy == 2 and session.energy == 2
            end,
        },
        {
            pointId = "ancient_library", activityId = "study_ancient_runes",
            verify = function(session)
                return session.stats.arcaneKnowledge == 2 and session.energy == 2
            end,
        },
        {
            pointId = "quiet_garden", activityId = "meditate",
            verify = function(session)
                return session.energy == 5
            end,
        },
    }

    for _, case in ipairs(cases) do
        local scene, session = freshScene()
        local target = approach(scene, case.pointId)
        assert(target.activityId == case.activityId,
            "each POI must declare its intended existing activity")
        requestMapActivity(scene, case.activityId)
        assert(session.actionsRemaining == 1 and session.lastActivity == case.activityId
            and case.verify(session),
        "map activity results must match the shared Training rules for " .. case.pointId)
        assert(scene:world():requireResource("mapActivityFeedback") == session.feedback,
            "map HUD feedback must use the resolved activity feedback")
        assert(scene:world():requireResource("dialogueState") == false,
            "the final dialogue step must close before resolving the activity")
        scene:dispose()
    end

    local rejectedScene, rejectedSession = freshScene()
    rejectedSession.energy = 0
    rejectedScene:world():setResource("gameSession", rejectedSession)
    approach(rejectedScene, "astral_court")
    requestMapActivity(rejectedScene, "practice_spells")
    assert(rejectedSession.actionsRemaining == 2 and rejectedSession.stats.confidence == 0,
        "insufficient energy must not consume an action or modify stats")
    assert(rejectedSession.feedback:find("enough energy", 1, true),
        "map rejection feedback must explain insufficient energy")
    rejectedScene:dispose()

    local transitionScene, transitionSession = freshScene()
    approach(transitionScene, "astral_court")
    requestMapActivity(transitionScene, "practice_spells")
    approach(transitionScene, "ancient_library")
    requestMapActivity(transitionScene, "study_ancient_runes")
    local transitionWorld = transitionScene:world()
    assert(transitionSession.actionsRemaining == 0
        and transitionSession.dayPhase == "cardAcquisition",
        "two successful map actions must enter the card-acquisition phase")
    assert(transitionWorld:requireResource("mapActivityTransitionQueued")
        and transitionWorld:eventCount("sceneRequest") == 1,
        "exhausting map actions must request Card Acquisition exactly once")
    transitionScene:postFixedUpdate(1 / 60)
    assert(transitionWorld:eventCount("sceneRequest") == 0,
        "later map activity ticks must not request a second transition")
    assert(transitionWorld:validate())
    transitionScene:dispose()

    local guardedSession = GameSession.new({ actionsRemaining = 1 })
    local guardedScene = AcademyMapScene({
        session = guardedSession,
        returnTo = "training",
    })
    guardedScene:initialize()
    local guardedWorld = guardedScene:world()
    approach(guardedScene, "astral_court")
    guardedWorld:emit("mapActivityRequested", { activityId = "practice_spells" })
    guardedWorld:emit("mapExitRequested")
    guardedScene:preUpdate(0)
    guardedScene:postFixedUpdate(1 / 60)
    assert(guardedSession.dayPhase == "cardAcquisition"
        and guardedWorld:requireResource("mapTransitionQueued")
        and guardedWorld:eventCount("sceneRequest") == 1,
        "activity completion and debug Backspace must not request conflicting transitions")
    guardedScene:dispose()
end
