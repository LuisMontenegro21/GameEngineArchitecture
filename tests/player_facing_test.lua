local AcademyMapScene = require("src.game.scenes.AcademyMapScene")
local AcademyLocationScene = require("src.game.scenes.AcademyLocationScene")
local GameSession = require("src.game.session.GameSession")
local SpriteFacing = require("src.game.graphics.SpriteFacing")

local function tick(scene)
    scene:preUpdate(0)
    scene:fixedUpdate(1 / 60)
    scene:postFixedUpdate(1 / 60)
end

local function playerSprite(world, playerComponent, spriteComponent)
    local query = world:query({ all = { playerComponent, spriteComponent } })
    for _, _, sprite in query:each() do
        query:close()
        return sprite
    end
    query:close()
end

return function()
    assert(SpriteFacing.rowForDelta(1, 0) == 2 and SpriteFacing.rowForDelta(-1, 0) == 4
        and SpriteFacing.rowForDelta(0, -1) == 3 and SpriteFacing.rowForDelta(0, 1) == 1
        and SpriteFacing.rowForDelta(0, 0) == nil,
        "the shared player-facing rows must match the four-direction sprite sheets")

    local map = AcademyMapScene({ session = GameSession.new() })
    map:initialize()
    map:world():emit("keyPressed", { key = "right" })
    tick(map)
    assert(playerSprite(map:world(), "mapPlayer", "mapSprite").row == 2,
        "rightward map movement must select the right-facing player row")
    for _ = 1, 9 do tick(map) end
    assert(playerSprite(map:world(), "mapPlayer", "mapSprite").frame == 2,
        "held map movement must advance to the second walk frame using delta time")
    map:world():emit("keyReleased", { key = "right" })
    tick(map)
    local mapSprite = playerSprite(map:world(), "mapPlayer", "mapSprite")
    assert(mapSprite.row == 2 and mapSprite.frame == 1,
        "the map player must retain their last facing row and reset to idle while stopped")
    map:dispose()

    local location = AcademyLocationScene({
        session = GameSession.new(), locationId = "astral_court", returnTo = "academyMap",
        mapReturnPosition = { x = 220, y = 235 },
    })
    location:initialize()
    location:world():emit("keyPressed", { key = "up" })
    tick(location)
    assert(playerSprite(location:world(), "locationPlayer", "locationSprite").row == 3,
        "upward room movement must select the up-facing player row")
    for _ = 1, 9 do tick(location) end
    assert(playerSprite(location:world(), "locationPlayer", "locationSprite").frame == 2,
        "held room movement must advance the walk animation with delta time")
    location:dispose()
end
