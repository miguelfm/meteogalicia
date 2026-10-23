--!strict
-- MeteoGalicia expects a local calendar date, even though its parameter ends in Z.
local forecast = {}

function forecast.localTimestamp(parts: any): number
    -- Luau's os.time interprets fields as UTC; os.date("*t") is local.
    -- Correct by the observed offset, then repeat for a possible DST boundary.
    local target = os.time(parts)
    local timestamp = target
    for _ = 1, 2 do
        timestamp += target - os.time(os.date("*t", timestamp))
    end
    return timestamp
end

function forecast.localDate(nowSec: number, dayOffset: number): string
    local parts = os.date("*t", nowSec)
    -- Anchor at noon so adding calendar days stays on the intended date across DST.
    local noon = forecast.localTimestamp({ year = parts.year, month = parts.month, day = parts.day, hour = 12, min = 0, sec = 0 })
    return os.date("%Y-%m-%d", noon + dayOffset * 86400)
end

function forecast.hourlyDate(nowSec: number, dayOffset: number): string
    return forecast.localDate(nowSec, dayOffset) .. "T00%3A00%3A00.000Z"
end

function forecast.rainProbability(value: any): number?
    local n = tonumber(value)
    return if n and n >= 0 and n <= 100 then n else nil
end

function forecast.rainText(value: any): string
    local n = forecast.rainProbability(value)
    return if n then string.format("%d%%", n) else "—"
end

-- Each chart column is a local calendar day, including across DST changes.
function forecast.chartSlot(days: { any }, timestamp: number): number?
    local t = os.date("*t", timestamp)
    for i, d in ipairs(days) do
        if d.year == t.year and d.month == t.month and d.day == t.day then
            return (i - 1) * 24 + t.hour + t.min / 60 + t.sec / 3600
        end
    end
    return nil
end

function forecast.slotTimestamp(days: { any }, slot: number): number
    local d = days[math.floor(slot / 24) + 1]
    return forecast.localTimestamp({ year = d.year, month = d.month, day = d.day, hour = slot % 24, min = 0, sec = 0 })
end

function forecast.chartHours(days: { any }, hours: { any }): { [number]: any }
    local slots: { [number]: any } = {}
    for _, h in ipairs(hours) do
        local ts = tonumber(h.timestamp)
        local slot = ts and forecast.chartSlot(days, ts)
        if slot then
            local k = math.floor(slot)
            -- The repeated autumn hour occupies one calendar slot; keep the later reading.
            if not slots[k] or ts > slots[k].timestamp then
                slots[k] = h
            end
        end
    end
    return slots
end

function forecast.decode(body: any, field: string, decoder: (string) -> any): (any, string?)
    -- An expired forecast can return HTTP 200 with an empty body.
    if type(body) ~= "string" or string.match(body, "^%s*$") then
        return nil, "empty"
    end
    local ok, data = pcall(decoder, body)
    if not ok or type(data) ~= "table" or type(data[field]) ~= "table" then
        return nil, "invalid"
    end
    if #data[field] == 0 then
        return nil, "empty"
    end
    return data, nil
end

return forecast
