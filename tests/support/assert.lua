local Assert = {}

local function describe(value)
    return tostring(value)
end

function Assert.fail(message)
    error(message or "assertion failed", 2)
end

function Assert.truthy(value, message)
    if not value then
        Assert.fail(message or ("expected a truthy value, got " .. describe(value)))
    end
end

function Assert.falsy(value, message)
    if value then
        Assert.fail(message or ("expected a falsy value, got " .. describe(value)))
    end
end

function Assert.equals(expected, actual, message)
    if expected ~= actual then
        Assert.fail(message or ("expected " .. describe(expected) .. ", got " .. describe(actual)))
    end
end

function Assert.isTable(value, message)
    Assert.equals("table", type(value), message or "expected a table")
end

return Assert
