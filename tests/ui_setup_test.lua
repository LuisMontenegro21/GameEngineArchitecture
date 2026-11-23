local AcademyMapScene = require("src.game.scenes.AcademyMapScene")
local CardAcquisitionScene = require("src.game.scenes.CardAcquisitionScene")
local GameSession = require("src.game.session.GameSession")
local TrainingScene = require("src.game.scenes.TrainingScene")

local function systemNames(scene)
    local names = {}
    for _, system in ipairs(scene:scheduler():systemsFor("startup")) do
        names[#names + 1] = system.name
    end
    return table.concat(names, ",")
end

return function()
    local training = TrainingScene({ session = GameSession.new() })
    training:world():setResource("trainingSelection", 999)
    training:initialize()
    assert(training:world():requireResource("trainingSelection") == 4,
        "training UI setup must clamp a resumed selection")
    assert(systemNames(training):find("trainingUiSetup", 1, true),
        "Training Scene must install an explicit UI setup system")
    training:dispose()

    local cardSession = GameSession.new()
    cardSession.collectionSelection = 999
    local cards = CardAcquisitionScene({ session = cardSession })
    cards:initialize()
    local cardWorld = cards:world()
    assert(#cardSession.generatedCards == 3)
    assert(cardWorld:requireResource("generatedCardSelection") == 1)
    assert(cardWorld:requireResource("collectionSelection") == 1,
        "card UI setup must clamp an empty resumed collection selection")
    assert(cardSession.collectionSelection == 1,
        "card UI setup must persist a normalized resumed collection selection")
    assert(cardWorld:requireResource("cardFocus") == "generated")
    assert(systemNames(cards):find("cardGeneration,cardUiSetup", 1, true),
        "card UI setup must run after card generation")
    cards:dispose()

    local map = AcademyMapScene({ session = GameSession.new() })
    map:initialize()
    assert(map:world():requireResource("nearbyPointOfInterest") == false,
        "map HUD setup must begin with no active location panel")
    assert(systemNames(map):find("mapSetup,mapHudSetup", 1, true),
        "map HUD setup must run after world-map setup")
    map:dispose()
end
