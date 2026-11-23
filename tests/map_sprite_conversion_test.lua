local AcademyMapScene = require("src.game.scenes.AcademyMapScene")
local MapSpriteRenderSystem = require("src.game.ui.MapSpriteRenderSystem")

return function()
    local scene = AcademyMapScene()
    scene:initialize()
    local world = scene:world()
    local map = world:requireResource("mapDefinition")

    assert(not world:hasComponentType("mapRenderable"),
        "production map presentation must no longer register mapRenderable")

    local playerCount, playerSprite = 0, nil
    for _, _, position, size, sprite in world:query({
        all = { "mapPlayer", "mapPosition", "mapSize", "mapSprite" },
    }):each() do
        playerCount = playerCount + 1
        playerSprite = sprite
        assert(position.x == map.spawn.x and position.y == map.spawn.y)
        assert(size.w == map.playerFootprint.w and size.h == map.playerFootprint.h,
            "player sprite metadata must not change its physical footprint")
    end
    assert(playerCount == 1 and playerSprite.key == "player_idle"
        and playerSprite.offsetX == -7 and playerSprite.offsetY == -34,
        "player art must be anchored above the feet collider")

    local sprites, points = 0, {}
    for _, _, _, sprite, point in world:query({
        all = { "mapPosition", "mapSize", "mapSprite" },
        optional = { "pointOfInterest" },
    }):each() do
        sprites = sprites + 1
        assert(sprite.fallback and sprite.fallback.shape and sprite.fallback.color,
            "every production sprite must retain an intentional fallback")
        if point then points[point.id] = point end
    end
    assert(sprites == 1 + #map.obstacles,
        "every player or obstacle must have exactly one drawable sprite owner")
    assert(points.ancient_library and points.student_commons
        and points.astral_court and points.quiet_garden,
        "POI metadata must live on their matching visible structures")

    local triggerOnly = world:query({
        all = { "pointOfInterest" },
        none = { "mapSprite" },
    }):count()
    assert(triggerOnly == 0,
        "current POIs should not create duplicate trigger-only entities")

    local playerPosition = nil
    for _, _, position in world:query({ all = { "mapPlayer", "mapPosition" } }):each() do
        playerPosition = position
    end
    playerPosition.y = 250
    local beforeTree = MapSpriteRenderSystem.collectDrawables(world)
    local playerIndex, treeIndex = nil, nil
    for index, drawable in ipairs(beforeTree) do
        if drawable.sprite.key == "player_idle" then playerIndex = index end
        if drawable.sprite.key == "academy_tree" then treeIndex = index end
    end
    assert(playerIndex < treeIndex, "player must draw behind the tree above its footprint")
    playerPosition.y = 340
    local afterTree = MapSpriteRenderSystem.collectDrawables(world)
    for index, drawable in ipairs(afterTree) do
        if drawable.sprite.key == "player_idle" then playerIndex = index end
        if drawable.sprite.key == "academy_tree" then treeIndex = index end
    end
    assert(playerIndex > treeIndex, "player must draw in front below the tree footprint")
    assert(world:validate())
    scene:dispose()
end
