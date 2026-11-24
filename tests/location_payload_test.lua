local GameSession = require("src.game.session.GameSession")
local LocationPayload = require("src.game.locations.LocationPayload")
local MapDefinition = require("src.game.maps.MapDefinition")

local function failsWith(callback, fragment)
    local ok, message = pcall(callback)
    assert(not ok, "expected invalid location payload to fail")
    assert(tostring(message):find(fragment, 1, true),
        "expected error to mention " .. fragment .. ", got: " .. tostring(message))
end

return function()
    local map = MapDefinition.get()
    local expected = {}
    for _, point in ipairs(map.pointsOfInterest) do expected[point.id] = true end

    local ids = LocationPayload.locationIds()
    assert(#ids == 4, "Beta 0 must preserve four stable location IDs")
    for _, id in ipairs(ids) do
        assert(expected[id], "location payload ID must match an Academy Garden POI: " .. id)
        expected[id] = nil
    end
    assert(next(expected) == nil,
        "every Academy Garden POI must have a future location-scene payload ID")

    local payload = {
        session = GameSession.new(),
        locationId = "astral_court",
        returnTo = "academyMap",
        mapReturnPosition = { x = 220, y = 235 },
    }
    assert(LocationPayload.validate(payload))
    assert(LocationPayload.assertValid(payload) == payload,
        "a valid payload must preserve session identity and navigation data")

    failsWith(function()
        LocationPayload.assertValid({
            session = payload.session,
            locationId = "missing_room",
            returnTo = "academyMap",
            mapReturnPosition = { x = 1, y = 1 },
        })
    end, "unknown location ID")
    failsWith(function()
        LocationPayload.assertValid({
            session = {}, locationId = "astral_court", returnTo = "academyMap",
            mapReturnPosition = { x = 1, y = 1 },
        })
    end, "valid game session")
    failsWith(function()
        LocationPayload.assertValid({
            session = payload.session, locationId = "astral_court", returnTo = "",
            mapReturnPosition = { x = 1, y = 1 },
        })
    end, "non-empty return target")
    failsWith(function()
        LocationPayload.assertValid({
            session = payload.session, locationId = "astral_court", returnTo = "academyMap",
            mapReturnPosition = { x = math.huge, y = 1 },
        })
    end, "finite map return position")
end
