local AcademyLocationScene = require("src.game.scenes.AcademyLocationScene")
local GameSession = require("src.game.session.GameSession")
local Facing = require("src.game.locations.LocationCharacterFacingSystem")
local SpriteCatalog = require("src.game.maps.SpriteCatalog")

local function tick(scene)
    scene:preUpdate(0)
    scene:fixedUpdate(1 / 60)
    scene:postFixedUpdate(1 / 60)
end

local function find(world, required, predicate)
    local query = world:query({ all = required })
    for entity, first, second, third, fourth in query:each() do
        if predicate(entity, first, second, third, fourth) then
            query:close()
            return entity, first, second, third, fourth
        end
    end
    query:close()
end

return function()
    assert(SpriteCatalog.get("outgoing_peer_overworld").path == "assets/wizard_academia/characters/mira-walk.png"
        and SpriteCatalog.get("studious_peer_overworld").path == "assets/wizard_academia/characters/tomas-walk-32.png",
        "Mira and Tomas must use compatible four-direction character sheets")
    assert(Facing.facingRow({ x = 10, y = 40 }, { w = 18, h = 24 },
        { x = 10, y = 10 }, { w = 18, h = 24 }) == 1,
        "a character must use the down-facing row for a player below them")
    assert(Facing.facingRow({ x = 0, y = 10 }, { w = 18, h = 24 },
        { x = 40, y = 10 }, { w = 18, h = 24 }) == 4,
        "a character must use the left-facing row for a player to their left")

    local scene = AcademyLocationScene({
        session = GameSession.new(), locationId = "astral_court", returnTo = "academyMap",
        mapReturnPosition = { x = 220, y = 235 },
    })
    scene:initialize()
    local world = scene:world()
    local _, _, playerPosition = find(world, { "locationPlayer", "locationPosition" }, function() return true end)
    local characterEntity, character, characterPosition = find(world,
        { "locationCharacter", "locationPosition" }, function(_, entry) return entry.id == "mentor" end)
    assert(playerPosition and characterEntity, "Astral Court must contain a player and Professor Elian")
    playerPosition.x, playerPosition.y = characterPosition.x, characterPosition.y + 35
    tick(scene)
    world:emit("keyPressed", { key = "e" })
    tick(scene)
    local sprite = world:require(characterEntity, "locationSprite")
    assert(sprite.row == 1, "an interacting character must face a player below them")
    playerPosition.x, playerPosition.y = characterPosition.x - 45, characterPosition.y
    tick(scene)
    sprite = world:require(characterEntity, "locationSprite")
    assert(sprite.row == 4, "the active character must keep facing the player's changed position")
    scene:dispose()
end
