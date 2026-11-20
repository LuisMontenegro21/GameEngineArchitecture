-- Draws white rectangles for non-brick world entities such as the paddle and
-- ball. Brick color and presentation belong to BrickRenderSystem.
local ShapeRenderSystem = { name = "shapeRender" }

function ShapeRenderSystem.draw(scene)
    local registry = scene.registry

    love.graphics.setColor(1, 1, 1, 1)
    for _, position, size in registry:each("position", "size", "renderShape") do
        love.graphics.rectangle("fill", position.x, position.y, size.w, size.h)
    end
end

return ShapeRenderSystem
