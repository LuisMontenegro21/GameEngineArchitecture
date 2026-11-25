-- Updates only the room player's presentation row from proposed movement.
local SpriteFacing = require("src.game.graphics.SpriteFacing")

local LocationPlayerFacingSystem = {}
local FRAME_DURATION = 0.16

local function copySprite(sprite, row)
    return {
        key = sprite.key, frame = sprite.frame, row = row,
        offsetX = sprite.offsetX, offsetY = sprite.offsetY,
        scaleX = sprite.scaleX, scaleY = sprite.scaleY,
        fallback = sprite.fallback,
    }
end

function LocationPlayerFacingSystem.install(scheduler)
    scheduler:addSystem({
        name = "locationPlayerFacing",
        stage = "fixedUpdate",
        after = { "locationMovement" },
        reads = { "locationPlayer", "locationDesiredMovement", "locationPlayerAnimation", "locationSprite" },
        writes = { "locationPlayerAnimation", "locationSprite" },
        run = function(context)
            local world = context.world
            local query = world:query({ all = { "locationPlayer", "locationDesiredMovement", "locationPlayerAnimation", "locationSprite" } })
            for entity, _, desired, animation, sprite in query:each() do
                local row = SpriteFacing.rowForDelta(desired.dx, desired.dy)
                local frame
                if row then
                    animation.elapsed = animation.elapsed + context.dt
                    frame = math.floor(animation.elapsed / FRAME_DURATION) % 3 + 1
                else
                    animation.elapsed = 0
                    frame = 1
                end
                world:set(entity, "locationPlayerAnimation", animation)
                row = row or sprite.row
                if sprite.row ~= row or sprite.frame ~= frame then
                    local updated = copySprite(sprite, row)
                    updated.frame = frame
                    world:set(entity, "locationSprite", updated)
                end
            end
            query:close()
        end,
    })
end

LocationPlayerFacingSystem.frameDuration = FRAME_DURATION
return LocationPlayerFacingSystem
