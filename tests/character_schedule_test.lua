local AcademyMapScene = require("src.game.scenes.AcademyMapScene")
local CharacterCatalog = require("src.game.characters.CharacterCatalog")
local CharacterPlacement = require("src.game.maps.CharacterPlacement")
local CharacterSchedule = require("src.game.characters.CharacterSchedule")
local GameSession = require("src.game.session.GameSession")
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
        outgoing_peer = "astral_court_entrance", studious_peer = "ancient_library",
    },
    [4] = {
        mentor = "astral_court", crush = "quiet_garden",
        outgoing_peer = "student_commons", studious_peer = "astral_court_entrance",
    },
    [5] = {
        mentor = "astral_court", crush = "student_commons",
        outgoing_peer = "quiet_garden", studious_peer = "ancient_library",
    },
}

local function charactersById(world)
    local result = {}
    for _, position, size, character, interaction, sprite in world:query({
        all = { "mapPosition", "mapSize", "mapCharacter", "mapInteractable", "mapSprite" },
    }):each() do
        result[character.id] = {
            position = position,
            size = size,
            character = character,
            interaction = interaction,
            sprite = sprite,
        }
    end
    return result
end

local function player(world)
    local query = world:query({ all = { "mapPlayer", "mapPosition", "mapSize" } })
    local position, size = nil, nil
    for _, _, currentPosition, currentSize in query:each() do
        position, size = currentPosition, currentSize
        break
    end
    query:close()
    return position, size
end

local function press(scene, key)
    scene:world():emit("keyPressed", { key = key })
    scene:preUpdate(0)
    scene:fixedUpdate(1 / 60)
end

return function()
    local catalog = CharacterCatalog.all()
    assert(#catalog == 4, "the alpha requires four characters")
    for _, character in ipairs(catalog) do
        assert(SpriteCatalog.has(character.spriteKey),
            "every character must use a stable sprite catalog key")
        assert(character.fallback and character.fallback.color,
            "every character must define a sprite-safe fallback")
    end

    for day = 1, 5 do
        local schedule = CharacterSchedule.forDay(day)
        for characterId, locationId in pairs(expected[day]) do
            assert(schedule[characterId] == locationId and type(locationId) == "string",
                "daily schedules must contain stable location IDs only")
            assert(CharacterPlacement.has(locationId),
                "each scheduled location must resolve through map placement data")
        end

        local scene = AcademyMapScene({ session = GameSession.new({ day = day }) })
        scene:initialize()
        local characters = charactersById(scene:world())
        local count = 0
        for characterId, locationId in pairs(expected[day]) do
            local spawned = characters[characterId]
            local placement = CharacterPlacement.get(locationId)
            assert(spawned and spawned.character.locationId == locationId,
                "the map must spawn the character at that day's scheduled location")
            assert(spawned.position.x == placement.x and spawned.position.y == placement.y
                and spawned.size.w == placement.w and spawned.size.h == placement.h,
                "placement coordinates must remain owned by CharacterPlacement")
            assert(spawned.interaction.kind == "character"
                and spawned.interaction.id == characterId and #spawned.interaction.dialogue > 0,
                "each character must receive an interactable flavor dialogue")
            count = count + 1
        end
        assert(count == 4 and characters.mentor.character.locationId == "astral_court",
            "the mentor must remain at the Astral Practice Court every day")
        scene:dispose()
    end

    local scene = AcademyMapScene({ session = GameSession.new({ day = 1 }) })
    scene:initialize()
    local world = scene:world()
    local characterEntities = charactersById(world)
    local playerPosition, playerSize = player(world)
    for _, character in ipairs(CharacterCatalog.all()) do
        local target = characterEntities[character.id].interaction
        playerPosition.x = target.trigger.x + (target.trigger.w - playerSize.w) / 2
        playerPosition.y = target.trigger.y + (target.trigger.h - playerSize.h) / 2
        scene:fixedUpdate(1 / 60)
        assert(world:requireResource("nearbyInteraction").id == character.id,
            "each scheduled character must win its own interaction range")
        press(scene, "e")
        local dialogue = world:requireResource("dialogueState")
        assert(dialogue.targetId == character.id and dialogue.lines[1] == character.dialogue[1],
            "E must open the correct plain-data character dialogue")
        press(scene, "escape")
        assert(world:requireResource("dialogueState") == false)
    end
    scene:draw(0)
    assert(world:validate(), "missing optional character sprites must remain headless-safe")
    scene:dispose()
end
