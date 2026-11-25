-- Shared row convention for the Academy's 3-by-4 directional character sheets.
-- Rows are down, right, up, left. A nil result means there was no movement.
local SpriteFacing = {}

function SpriteFacing.rowForDelta(dx, dy)
    if dx == 0 and dy == 0 then return nil end
    if math.abs(dx) > math.abs(dy) then return dx > 0 and 2 or 4 end
    return dy > 0 and 1 or 3
end

return SpriteFacing
