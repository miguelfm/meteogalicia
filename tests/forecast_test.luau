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
equal(forecast.rainProbability(nil), nil)
equal(forecast.rainProbability(-9999), nil)
equal(forecast.rainProbability(101), nil)
equal(forecast.rainText(nil), "—")
equal(forecast.rainText(-9999), "—")
equal(forecast.rainText(0), "0%")
equal(forecast.rainText(55), "55%")

local days = {}
for day = 23, 26 do
    days[#days + 1] = { year = 2026, month = 10, day = day }
end
local hours = {}
for k = 0, 95 do
    local ts = forecast.slotTimestamp(days, k)
    hours[#hours + 1] = { timestamp = ts, temp = 15 }
    equal(forecast.chartSlot(days, ts), k)
end
local slots = forecast.chartHours(days, hours)
equal(slots[0], hours[1])
equal(slots[95], hours[96])
equal(forecast.chartSlot(days, forecast.slotTimestamp(days, 72) + 1800), 72.5)
equal(forecast.chartSlot(days, forecast.slotTimestamp(days, 0) - 3600), nil)

-- Missing the first day must not move later forecasts under today's heading.
local missingFirst = {}
local missingLast = {}
for i, h in ipairs(hours) do
    if i > 24 then missingFirst[#missingFirst + 1] = h end
    if i <= 72 then missingLast[#missingLast + 1] = h end
end
equal(forecast.chartHours(days, missingFirst)[0], nil)
equal(forecast.chartHours(days, missingFirst)[24], hours[25])
equal(forecast.chartHours(days, missingLast)[71], hours[72])
equal(forecast.chartHours(days, missingLast)[72], nil)

-- Repeated autumn hour maps to a single calendar slot; later reading wins
-- independently of response order. The next day still starts at slot 72.
local repeated = forecast.slotTimestamp(days, 50)
local other = if os.date("%H", repeated + 3600) == "02" then repeated + 3600 else repeated - 3600
local early = { timestamp = math.min(repeated, other), temp = 14 }
local late = { timestamp = math.max(repeated, other), temp = 15 }
equal(forecast.chartSlot(days, early.timestamp), 50)
equal(forecast.chartSlot(days, late.timestamp), 50)
equal(forecast.chartHours(days, { late, early })[50], late)
equal(forecast.chartSlot(days, forecast.slotTimestamp(days, 72)), 72)

-- Spring's skipped local hour remains empty without moving the following day.
local spring = { { year = 2026, month = 3, day = 29 }, { year = 2026, month = 3, day = 30 } }
local before = forecast.slotTimestamp(spring, 1)
local after = before + 3600
equal(forecast.chartSlot(spring, after), 3)
equal(forecast.chartHours(spring, { { timestamp = before }, { timestamp = after } })[2], nil)
equal(forecast.chartSlot(spring, forecast.slotTimestamp(spring, 24)), 24)

print("forecast: " .. checks .. " checks passed")
