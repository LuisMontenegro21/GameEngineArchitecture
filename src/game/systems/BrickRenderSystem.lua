-- Draws only brick entities. Their colors stay with their brick data instead
-- of being mixed into generic shape rendering.
local BrickRenderSystem = { name = "brickRender" }

function BrickRenderSystem.draw(scene)
    local registry = scene.registry

    for _, position, size, brick in registry:each("position", "size", "brick") do
        local color = brick.color or { 1, 1, 1 }
        love.graphics.setColor(color[1], color[2], color[3], 1)
        love.graphics.rectangle("fill", position.x, position.y, size.w, size.h)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return BrickRenderSystem
