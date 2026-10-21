--!strict
-- MeteoGalicia expects a local calendar date, even though its parameter ends in Z.
local forecast = {}

function forecast.localDate(nowSec: number, dayOffset: number): string
    local parts = os.date("*t", nowSec)
    -- Anchor at noon so adding calendar days stays on the intended date across DST.
    local noon = os.time({ year = parts.year, month = parts.month, day = parts.day, hour = 12, min = 0, sec = 0 })
    return os.date("%Y-%m-%d", noon + dayOffset * 86400)
end

function forecast.hourlyDate(nowSec: number, dayOffset: number): string
    return forecast.localDate(nowSec, dayOffset) .. "T00%3A00%3A00.000Z"
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
