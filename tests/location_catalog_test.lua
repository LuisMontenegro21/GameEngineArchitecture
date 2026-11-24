local Activities = require("src.game.progression.Activities")
local LocationCatalog = require("src.game.locations.LocationCatalog")
local LocationPayload = require("src.game.locations.LocationPayload")
local MapDefinition = require("src.game.maps.MapDefinition")
local ScenePresentationCatalog = require("src.game.graphics.ScenePresentationCatalog")

return function()
    local locations = LocationCatalog.all()
    assert(LocationCatalog.validate(locations), "the four location definitions must validate")
    assert(#locations == 4, "Beta 1 must define exactly four Academy locations")

    local mapIds = {}
    for _, point in ipairs(MapDefinition.get().pointsOfInterest) do mapIds[point.id] = true end
    for _, location in ipairs(locations) do
        assert(mapIds[location.id], "every location must resolve an Academy Garden POI")
        assert(Activities.get(location.activityId), "every location must resolve an activity")
        assert(ScenePresentationCatalog.get(location.backgroundId),
            "every location must resolve a scene presentation")
        assert(LocationPayload.isKnownLocation(location.id),
            "location payload validation must use the location catalog")
        mapIds[location.id] = nil
    end
    assert(next(mapIds) == nil, "every Academy Garden POI must resolve a location definition")

    local library = LocationCatalog.get("ancient_library")
    library.name = "Changed"
    library.characterSlots[1].x = -1
    assert(LocationCatalog.get("ancient_library").name == "Ancient Library"
        and LocationCatalog.get("ancient_library").characterSlots[1].x == 330,
        "catalog accessors must return isolated copies")

    local invalid = LocationCatalog.all()
    invalid[1].activityId = "missing_activity"
    assert(not LocationCatalog.validate(invalid), "unknown activities must be rejected")
    invalid = LocationCatalog.all()
    invalid[1].backgroundId = "missing_background"
    assert(not LocationCatalog.validate(invalid), "unknown presentations must be rejected")
    invalid = LocationCatalog.all()
    invalid[2].id = invalid[1].id
    assert(not LocationCatalog.validate(invalid), "duplicate location IDs must be rejected")
    invalid = LocationCatalog.all()
    invalid[1].characterSlots[2].id = invalid[1].characterSlots[1].id
    assert(not LocationCatalog.validate(invalid), "duplicate character slot IDs must be rejected")
    invalid = LocationCatalog.all()
    invalid[1].fallbackColor.r = math.huge
    assert(not LocationCatalog.validate(invalid), "non-finite fallback colors must be rejected")
end
