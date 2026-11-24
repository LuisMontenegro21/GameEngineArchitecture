-- Map-owned positions for daily character locations. Schedules reference only
-- these stable location IDs; each location can later expose more than one slot.
local CharacterPlacement = {}

local placements = {
    ancient_library = { primary = { x = 345, y = 370, w = 18, h = 24 } },
    student_commons = { primary = { x = 670, y = 350, w = 18, h = 24 } },
    astral_court = { primary = { x = 260, y = 150, w = 18, h = 24 } },
    astral_court_entrance = { primary = { x = 315, y = 180, w = 18, h = 24 } },
    quiet_garden = { primary = { x = 770, y = 210, w = 18, h = 24 } },
}

local function copy(value)
    return { x = value.x, y = value.y, w = value.w, h = value.h }
end

function CharacterPlacement.get(locationId, slot)
    slot = slot or "primary"
    local location = placements[locationId]
    local placement = location and location[slot]
    assert(placement ~= nil,
        ("no character placement for %s (%s)"):format(tostring(locationId), tostring(slot)))
    return copy(placement)
end

function CharacterPlacement.has(locationId, slot)
    local location = placements[locationId]
    return location ~= nil and location[slot or "primary"] ~= nil
end

return CharacterPlacement
