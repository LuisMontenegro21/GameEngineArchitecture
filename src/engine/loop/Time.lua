local Time = {}
function Time.new(fixedDelta)
    return { frameDelta = 0, fixedDelta = fixedDelta or 1 / 60, elapsed = 0,
        tick = 0, alpha = 0, timeScale = 1, paused = false, updateCount = 0 }
end
function Time.copy(target, source)
    for key, value in pairs(source) do target[key] = value end
    return target
end
return Time
