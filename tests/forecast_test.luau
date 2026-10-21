local forecast = require("../forecast")

local checks = 0
local function equal(actual, expected)
    checks += 1
    assert(actual == expected, "expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

-- Run with TZ=Europe/Madrid. Fixed UTC timestamps exercise the local midnight bug,
-- both DST transitions, month/year rollover and leap day without a mocked clock.
local cases = {
    { 1792620600, "2026-10-22", "2026-10-23", "2026-10-24", "2026-10-25", "2026-10-21" }, -- 00:10 CEST
    { 1792706100, "2026-10-22", "2026-10-23", "2026-10-24", "2026-10-25", "2026-10-21" }, -- 23:55 CEST
    { 1792879500, "2026-10-25", "2026-10-26", "2026-10-27", "2026-10-28", "2026-10-24" }, -- DST ends, 00:05
    { 1792968900, "2026-10-25", "2026-10-26", "2026-10-27", "2026-10-28", "2026-10-24" }, -- DST ends, 23:55
    { 1774739100, "2026-03-29", "2026-03-30", "2026-03-31", "2026-04-01", "2026-03-28" }, -- DST starts, 00:05
    { 1774821300, "2026-03-29", "2026-03-30", "2026-03-31", "2026-04-01", "2026-03-28" }, -- DST starts, 23:55
    { 1798757700, "2026-12-31", "2027-01-01", "2027-01-02", "2027-01-03", "2026-12-30" },
    { 1835391900, "2028-02-29", "2028-03-01", "2028-03-02", "2028-03-03", "2028-02-28" },
}
equal(os.date("%H:%M", cases[1][1]), "00:10")
equal(os.date("!%Y-%m-%d", cases[1][1]), "2026-10-21")
for _, case in ipairs(cases) do
    for offset = 0, 3 do
        equal(forecast.localDate(case[1], offset), case[offset + 2])
        equal(forecast.hourlyDate(case[1], offset), case[offset + 2] .. "T00%3A00%3A00.000Z")
    end
    equal(forecast.localDate(case[1], -1), case[6])
end

local function unusedDecoder(_body)
    error("decoder must not be called for an empty body")
end
for _, body in ipairs({ "", " \n\t" }) do
    local data, reason = forecast.decode(body, "forecastDataTime", unusedDecoder)
    equal(data, nil)
    equal(reason, "empty")
end
local data, reason = forecast.decode(nil, "forecastDataTime", unusedDecoder)
equal(data, nil)
equal(reason, "empty")

local function checkDecoded(decoded, expectedReason)
    local result, err = forecast.decode("response", "forecastDataTime", function() return decoded end)
    equal(result, nil)
    equal(err, expectedReason)
end
checkDecoded(nil, "invalid")
checkDecoded("unexpected JSON string", "invalid")
checkDecoded(42, "invalid")
checkDecoded(false, "invalid")
checkDecoded({}, "invalid")
checkDecoded({ forecastDataTime = "not an array" }, "invalid")
checkDecoded({ forecastDataTime = {} }, "empty")

data, reason = forecast.decode("<html>server error</html>", "forecastDataTime", function()
    error("JSON parse error")
end)
equal(data, nil)
equal(reason, "invalid")

for _, field in ipairs({ "forecastDataTime", "forecastDataShortTerm", "forecastDataMediumTerm" }) do
    local expected = { [field] = { { date = 1792620000000 } } }
    data, reason = forecast.decode("response", field, function() return expected end)
    equal(data, expected)
    equal(reason, nil)
end
print("forecast: " .. checks .. " checks passed")
