-- Daily character placement uses location IDs only. The map resolves those IDs
-- through CharacterPlacement, leaving schedules free of rendering coordinates.
local CharacterSchedule = {}

local days = {
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

local function copy(value)
    local result = {}
    for key, item in pairs(value) do result[key] = item end
    return result
end

function CharacterSchedule.forDay(day)
    local schedule = days[day]
    assert(schedule ~= nil, "no character schedule for day: " .. tostring(day))
    return copy(schedule)
end

function CharacterSchedule.locationFor(day, characterId)
    return CharacterSchedule.forDay(day)[characterId]
end

function CharacterSchedule.days()
    local result = {}
    for day = 1, #days do result[day] = copy(days[day]) end
    return result
end

return CharacterSchedule
