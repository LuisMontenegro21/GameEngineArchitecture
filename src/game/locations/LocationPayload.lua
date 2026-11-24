-- Contract for the future reusable Academy location Scene. It intentionally
-- contains only plain session/navigation data and no location implementation.
local GameSession = require("src.game.session.GameSession")
local LocationCatalog = require("src.game.locations.LocationCatalog")

local LocationPayload = {}

local function finite(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

local function validReturnPosition(value)
    return type(value) == "table" and finite(value.x) and finite(value.y)
end

function LocationPayload.isKnownLocation(id)
    return LocationCatalog.get(id) ~= nil
end

function LocationPayload.locationIds()
    return LocationCatalog.ids()
end

function LocationPayload.validate(payload)
    return type(payload) == "table"
        and GameSession.validate(payload.session)
        and LocationPayload.isKnownLocation(payload.locationId)
        and type(payload.returnTo) == "string" and payload.returnTo ~= ""
        and validReturnPosition(payload.mapReturnPosition)
end

function LocationPayload.assertValid(payload)
    assert(type(payload) == "table", "academy location payload must be a table")
    assert(GameSession.validate(payload.session),
        "academy location payload requires a valid game session")
    assert(LocationPayload.isKnownLocation(payload.locationId),
        "academy location payload has an unknown location ID: " .. tostring(payload.locationId))
    assert(type(payload.returnTo) == "string" and payload.returnTo ~= "",
        "academy location payload requires a non-empty return target")
    assert(validReturnPosition(payload.mapReturnPosition),
        "academy location payload requires a finite map return position")
    return payload
end

return LocationPayload
