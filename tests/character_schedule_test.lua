local AcademyLocationScene = require("src.game.scenes.AcademyLocationScene")
local AcademyMapScene = require("src.game.scenes.AcademyMapScene")
local CharacterCatalog = require("src.game.characters.CharacterCatalog")
local CharacterSchedule = require("src.game.characters.CharacterSchedule")
local GameSession = require("src.game.session.GameSession")
local LocationCatalog = require("src.game.locations.LocationCatalog")
local SpriteCatalog = require("src.game.maps.SpriteCatalog")

local expected = {
    [1] = {
        mentor = "astral_court", crush = "quiet_garden",
        outgoing_peer = "student_commons", studious_peer = "ancient_library",
    },
    [2] = {
        mentor = "astral_court", crush = "ancient_library",
        outgoing_peer = "quiet_garden", studious_peer = "student_commons",
    },
    [3] = {
        mentor = "astral_court", crush = "student_commons",
        outgoing_peer = "astral_court", studious_peer = "ancient_library",
    },
    [4] = {
        mentor = "astral_court", crush = "quiet_garden",
        outgoing_peer = "student_commons", studious_peer = "astral_court",
    },
    [5] = {
        mentor = "astral_court", crush = "student_commons",
        outgoing_peer = "quiet_garden", studious_peer = "ancient_library",
    },
}

local function payload(session, locationId)
    return {
        session = session,
        locationId = locationId,
        returnTo = "academyMap",
        mapReturnPosition = { x = 220, y = 235 },
    }
end

local function charactersById(world)
    local result = {}
    local query = world:query({
        all = { "locationPosition", "locationSize", "locationCharacter", "locationSprite" },
    })
    for _, position, size, character, sprite in query:each() do
        result[character.id] = {
            position = position,
            size = size,
            character = character,
            sprite = sprite,
        }
    end
    query:close()
    return result
end

return function()
    local catalog = CharacterCatalog.all()
    assert(#catalog == 4, "the beta requires four characters")
    for _, character in ipairs(catalog) do
        assert(SpriteCatalog.has(character.spriteKey),
            "every character must use a stable sprite catalog key")
        assert(character.fallback and character.fallback.color,
            "every character must define a sprite-safe fallback")
    end

    for day = 1, 5 do
        local schedule = CharacterSchedule.forDay(day)
        local seen = {}
        for characterId, locationId in pairs(expected[day]) do
            assert(schedule[characterId] == locationId and LocationCatalog.get(locationId),
                "daily schedules must use stable dedicated location IDs")
        end

        local map = AcademyMapScene({ session = GameSession.new({ day = day }) })
        map:initialize()
        assert(map:world():query({ all = { "mapCharacter" } }):count() == 0,
            "scheduled characters must not duplicate onto the Academy Garden")
        map:dispose()

        for _, locationId in ipairs(LocationCatalog.ids()) do
            local scene = AcademyLocationScene(payload(GameSession.new({ day = day }), locationId))
            scene:initialize()
            local characters = charactersById(scene:world())
            for characterId, spawned in pairs(characters) do
                assert(expected[day][characterId] == locationId,
                    "a room may spawn only characters scheduled there that day")
                assert(not seen[characterId], "a character must not be duplicated between rooms")
                assert(spawned.sprite.fallback and spawned.sprite.fallback.color,
                    "missing character sprites must retain an intentional fallback")
                seen[characterId] = true
            end
            scene:draw(0)
            assert(scene:world():validate(), "location character rendering must remain headless-safe")
            scene:dispose()
        end
        for characterId in pairs(expected[day]) do
            assert(seen[characterId], "every scheduled character must appear in one dedicated room")
        end
        assert(expected[day].mentor == "astral_court",
            "Professor Elian must remain available at the Astral Practice Court")
    end
end
