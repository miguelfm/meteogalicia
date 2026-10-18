--!strict
-- Shared utilities, constants and MeteoGalicia mapping tables.

local shared = {}

shared.API_KEY = "eyJ4NXQiOiJObUU1TXpSbVpXSmtNREZtT1RJeFlqWTFNRE00TmpnM1pqVmlOR0k1WkdZM09HTXpPVEJsTURNelpUQmhOalJtWVdJNE9HUmpOR1ZpTldKak1qZGpZUSIsImtpZCI6ImdhdGV3YXlfY2VydGlmaWNhdGVfYWxpYXMiLCJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhZG1pbkBjYXJib24uc3VwZXIiLCJhcHBsaWNhdGlvbiI6eyJvd25lciI6ImFkbWluIiwidGllclF1b3RhVHlwZSI6bnVsbCwidGllciI6IlVubGltaXRlZCIsIm5hbWUiOiJ3X21ldGVvMiIsImlkIjozMzAxLCJ1dWlkIjoiMmNhMDI4N2ItNWYzYy00NGMzLTg3ZGEtOWY5ODg3NWZjNjk5In0sImlzcyI6Imh0dHBzOlwvXC9wcmQtd3NvMmFwaW0tYzAxLTAwMDEueHVudGEubG9jYWw6OTQ0NFwvb2F1dGgyXC90b2tlbiIsInRpZXJJbmZvIjp7IlB1YmxpYyI6eyJ0aWVyUXVvdGFUeXBlIjoicmVxdWVzdENvdW50IiwiZ3JhcGhRTE1heENvbXBsZXhpdHkiOjAsImdyYXBoUUxNYXhEZXB0aCI6MCwic3RvcE9uUXVvdGFSZWFjaCI6dHJ1ZSwic3Bpa2VBcnJlc3RMaW1pdCI6MCwic3Bpa2VBcnJlc3RVbml0Ijoic2VjIn19LCJrZXl0eXBlIjoiUFJPRFVDVElPTiIsInBlcm1pdHRlZFJlZmVyZXIiOiIiLCJzdWJzY3JpYmVkQVBJcyI6W3sic3Vic2NyaWJlclRlbmFudERvbWFpbiI6ImNhcmJvbi5zdXBlciIsIm5hbWUiOiJNRVRFTzJfQVBJIiwiY29udGV4dCI6IlwvbWV0ZW8yYXBpXC92MSIsInB1Ymxpc2hlciI6IkFNVEVHQVwvdWUwODIwNSIsInZlcnNpb24iOiJ2MSIsInN1YnNjcmlwdGlvblRpZXIiOiJQdWJsaWMifV0sInBlcm1pdHRlZElQIjoiIiwiaWF0IjoxNjk0MDk1MzMzLCJqdGkiOiI1NzkwYmM5NC04M2Y2LTQ4YTgtODg3Yy02MmQyNDJiMTJmZDYifQ==.W9Uc6D5te5GhMcWb-ewkiuor8rpNX5S3P89LSvrewNxNffwkQ5LC47OiSIwx0NOhZ9YKSiOf0i5L2MDjA8Roezp1xkPzC1Cx6ESkuTaXtIgu0iP4mUo6pCmwywWLhDO7_fz58k6PnPAYyehQ6R8r85nEx3Wr9F9e1u-WZx2zGTFGpqvTU9jFA1d4rlcTjTK7eGuIFSbQn6goko8elKFe3GajzGy8r6NtJLMvSgxhSpftsykx-tpGyoUVVH90dTiEul927JiYvqgOsCKa4FU1tVVY3Y9t8AJByJqsOeTz64R7KIe9A8C2WB29IewjKxDkrsypFODpOQHkIbEDhZ5g8Q=="

shared.BASE_API = "https://apis-ext.xunta.gal/meteo2api/v1/api/"

export type SkyInfo = {
    glyph: string,
    desc: string,
    color: string,
}

local SKY_TABLE: { [number]: SkyInfo } = {
    -- Diúrno (101 - 126)
    [101] = { glyph = "sun", desc = "Despexado", color = "tertiary" },
    [102] = { glyph = "cloud-sun", desc = "Nubes altas", color = "tertiary" },
    [103] = { glyph = "cloud-sun", desc = "Nubes e claros", color = "primary" },
    [104] = { glyph = "cloud", desc = "Nubrado", color = "on_surface_variant" },
    [105] = { glyph = "cloud", desc = "Moi nubrado", color = "on_surface_variant" },
    [106] = { glyph = "cloud-fog", desc = "Néboas", color = "on_surface_variant" },
    [107] = { glyph = "cloud-rain", desc = "Chuvasco", color = "secondary" },
    [108] = { glyph = "cloud-rain", desc = "Nubrado con chuvascos", color = "secondary" },
    [109] = { glyph = "cloud-snow", desc = "Chuvasco de neve", color = "secondary" },
    [110] = { glyph = "cloud-rain", desc = "Orballo", color = "secondary" },
    [111] = { glyph = "cloud-rain", desc = "Chuvia", color = "secondary" },
    [112] = { glyph = "snowflake", desc = "Neve", color = "secondary" },
    [113] = { glyph = "cloud-storm", desc = "Treboada", color = "error" },
    [114] = { glyph = "cloud-fog", desc = "Brétema", color = "on_surface_variant" },
    [115] = { glyph = "cloud-fog", desc = "Bancos de néboa", color = "on_surface_variant" },
    [116] = { glyph = "clouds", desc = "Cuberto", color = "on_surface_variant" },
    [117] = { glyph = "cloud-rain", desc = "Chuvia débil", color = "secondary" },
    [118] = { glyph = "cloud-rain", desc = "Chuvascos débiles", color = "secondary" },
    [119] = { glyph = "cloud-storm", desc = "Treboada con claros", color = "error" },
    [120] = { glyph = "cloud-snow", desc = "Chuvasco auganeve", color = "secondary" },
    [121] = { glyph = "cloud-rain", desc = "Sarabia", color = "secondary" },
    [122] = { glyph = "cloud-rain", desc = "Chuvia ocasional", color = "secondary" },
    [123] = { glyph = "cloud-snow", desc = "Nubrado con neve", color = "secondary" },
    [124] = { glyph = "sun", desc = "Calixe seca", color = "tertiary" },
    [125] = { glyph = "clouds", desc = "Cuberto", color = "on_surface_variant" },
    [126] = { glyph = "cloud-storm", desc = "Chuvia intensa", color = "secondary" },

    -- Nocturno (201 - 226)
    [201] = { glyph = "moon", desc = "Despexado", color = "primary" },
    [202] = { glyph = "moon-stars", desc = "Nubes altas", color = "primary" },
    [203] = { glyph = "moon-stars", desc = "Nubes e claros", color = "primary" },
    [204] = { glyph = "cloud", desc = "Nubrado", color = "on_surface_variant" },
    [205] = { glyph = "cloud", desc = "Moi nubrado", color = "on_surface_variant" },
    [206] = { glyph = "cloud-fog", desc = "Néboas", color = "on_surface_variant" },
    [207] = { glyph = "cloud-rain", desc = "Chuvasco", color = "secondary" },
    [208] = { glyph = "cloud-rain", desc = "Nubrado con chuvascos", color = "secondary" },
    [209] = { glyph = "cloud-snow", desc = "Chuvasco de neve", color = "secondary" },
    [210] = { glyph = "cloud-rain", desc = "Orballo", color = "secondary" },
    [211] = { glyph = "cloud-rain", desc = "Chuvia", color = "secondary" },
    [212] = { glyph = "snowflake", desc = "Neve", color = "secondary" },
    [213] = { glyph = "cloud-storm", desc = "Treboada", color = "error" },
    [214] = { glyph = "cloud-fog", desc = "Brétemas", color = "on_surface_variant" },
    [215] = { glyph = "cloud-fog", desc = "Bancos de néboa", color = "on_surface_variant" },
    [217] = { glyph = "cloud-rain", desc = "Chuvia débil", color = "secondary" },
    [218] = { glyph = "cloud-rain", desc = "Chuvia ocasional", color = "secondary" },
    [219] = { glyph = "cloud-storm", desc = "Treboada", color = "error" },
    [220] = { glyph = "cloud-snow", desc = "Auganeve", color = "secondary" },
    [221] = { glyph = "cloud-rain", desc = "Sarabia", color = "secondary" },
    [222] = { glyph = "cloud-rain", desc = "Chuvia ocasional", color = "secondary" },
    [223] = { glyph = "cloud-snow", desc = "Nubrado con neve", color = "secondary" },
    [224] = { glyph = "moon-stars", desc = "Calixe seca", color = "primary" },
    [225] = { glyph = "clouds", desc = "Cuberto", color = "on_surface_variant" },
    [226] = { glyph = "cloud-storm", desc = "Chuvia intensa", color = "secondary" },
}

function shared.getSky(code: number?): SkyInfo
    if code ~= nil and SKY_TABLE[code] ~= nil then
        return SKY_TABLE[code]
    end
    return { glyph = "cloud", desc = "Descoñecido", color = "on_surface_variant" }
end

function shared.cleanHtml(text: string?): string
    if type(text) ~= "string" then return "" end
    local clean = text:gsub("<br%s*/?>", "\n"):gsub("&lt;br%s*/?&gt;", "\n")
    clean = clean:gsub("&amp;", "&"):gsub("&quot;", '"'):gsub("&#39;", "'")
    clean = clean:gsub("<[^>]+>", "")
    return (clean:gsub("^%s+", ""):gsub("%s+$", ""))
end

shared.WEEKDAYS_GL = {
    [0] = "Domingo",
    [1] = "Luns",
    [2] = "Martes",
    [3] = "Mércores",
    [4] = "Xoves",
    [5] = "Venres",
    [6] = "Sábado",
}

shared.WEEKDAYS_EN = {
    [0] = "Sunday",
    [1] = "Monday",
    [2] = "Tuesday",
    [3] = "Wednesday",
    [4] = "Thursday",
    [5] = "Friday",
    [6] = "Saturday",
}

shared.MONTHS_GL = {
    [1] = "xan", [2] = "feb", [3] = "mar", [4] = "abr",
    [5] = "mai", [6] = "xuñ", [7] = "xul", [8] = "ago",
    [9] = "set", [10] = "out", [11] = "nov", [12] = "dec",
}

shared.MONTHS_EN = {
    [1] = "Jan", [2] = "Feb", [3] = "Mar", [4] = "Apr",
    [5] = "May", [6] = "Jun", [7] = "Jul", [8] = "Aug",
    [9] = "Sep", [10] = "Oct", [11] = "Nov", [12] = "Dec",
}

shared.DEFAULT_LAT = 43.475156
shared.DEFAULT_LON = -8.167317

-- Cálculo astronómico oficial de orto (amencer) e ocaso (solpor) segundo algoritmo solar NOAA
function shared.calcSolar(lat: number?, lon: number?, ts: number?): (string, string)
    local effectiveLat = lat or shared.DEFAULT_LAT
    local effectiveLon = lon or shared.DEFAULT_LON
    local effectiveTs = ts or os.time()

    local d = os.date("*t", effectiveTs)
    local year = d.year
    local month = d.month
    local day = d.day

    local N1 = math.floor(275 * month / 9)
    local N2 = math.floor((month + 9) / 12)
    local N3 = 1 + math.floor((year - 4 * math.floor(year / 4) + 2) / 3)
    local N = N1 - (N2 * N3) + day - 30

    local lngHour = effectiveLon / 15.0

    local function getTime(isRise: boolean): string
        local t = N + ((isRise and 6.0 or 18.0) - lngHour) / 24.0
        local M = (0.9856 * t) - 3.289
        local Mrad = math.rad(M)
        local L = M + (1.916 * math.sin(Mrad)) + (0.020 * math.sin(2 * Mrad)) + 282.634
        L = L % 360.0
        local Lrad = math.rad(L)
        local RA = math.deg(math.atan(0.91764 * math.tan(Lrad))) % 360.0
        local Lquadrant = math.floor(L / 90.0) * 90.0
        local RAquadrant = math.floor(RA / 90.0) * 90.0
        RA = (RA + (Lquadrant - RAquadrant)) / 15.0
        local sinDec = 0.39782 * math.sin(Lrad)
        local cosDec = math.cos(math.asin(sinDec))
        local latRad = math.rad(effectiveLat)
        local cosH = (math.cos(math.rad(90.8333)) - (sinDec * math.sin(latRad))) / (cosDec * math.cos(latRad))
        if cosH > 1 or cosH < -1 then
            return "--:--"
        end
        local H = isRise and (360.0 - math.deg(math.acos(cosH))) or math.deg(math.acos(cosH))
        H = H / 15.0
        local T = H + RA - (0.06571 * t) - 6.622
        local UT = (T - lngHour) % 24.0

        local utc = os.date("!*t", effectiveTs)
        local loc = os.date("*t", effectiveTs)
        local utcSec = os.time({ year = utc.year, month = utc.month, day = utc.day, hour = utc.hour, min = utc.min, sec = utc.sec, isdst = false })
        local locSec = os.time({ year = loc.year, month = loc.month, day = loc.day, hour = loc.hour, min = loc.min, sec = loc.sec, isdst = false })
        local tzOffset = os.difftime(locSec, utcSec) / 3600.0

        local localHours = (UT + tzOffset) % 24.0
        local hh = math.floor(localHours)
        local mm = math.floor(((localHours - hh) * 60) + 0.5)
        if mm >= 60 then
            hh = (hh + 1) % 24
            mm = 0
        end
        return string.format("%02d:%02d", hh, mm)
    end

    return getTime(true), getTime(false)
end

function shared.getWindAngle(windDesc: string?): number
    if type(windDesc) ~= "string" then return 0 end
    local desc = windDesc:lower()
    if desc:find("nordés") or desc:find("nordeste") or desc:find("ne") then
        return 225
    elseif desc:find("noroeste") or desc:find("no") or desc:find("nw") then
        return 135
    elseif desc:find("sudoeste") or desc:find("so") or desc:find("sw") then
        return 45
    elseif desc:find("sueste") or desc:find("se") then
        return 315
    elseif desc:find("norte") then
        return 180
    elseif desc:find("sur") then
        return 0
    elseif desc:find("oeste") then
        return 90
    elseif desc:find("leste") or desc:find("este") then
        return 270
    end
    return 0
end

type ChartPoint = { x: number, y: number }

local function buildSmoothBezierPath(pts: { ChartPoint }): string
    local n = #pts
    if n < 2 then return "" end
    local parts = { string.format("M %.1f %.1f", pts[1].x, pts[1].y) }
    for i = 1, n - 1 do
        local p0 = (i > 1) and pts[i - 1] or pts[i]
        local p1 = pts[i]
        local p2 = pts[i + 1]
        local p3 = (i + 2 <= n) and pts[i + 2] or p2

        local cp1x = p1.x + (p2.x - p0.x) / 5.0
        local cp1y = p1.y + (p2.y - p0.y) / 5.0
        local cp2x = p2.x - (p3.x - p1.x) / 5.0
        local cp2y = p2.y - (p3.y - p1.y) / 5.0

        parts[#parts + 1] = string.format(" C %.1f %.1f, %.1f %.1f, %.1f %.1f", cp1x, cp1y, cp2x, cp2y, p2.x, p2.y)
    end
    return table.concat(parts)
end

function shared.renderWeatherSvgIcon(glyph: string, cx: number, cy: number): string
    local g = (glyph or "cloud"):lower()
    if g:find("storm") then
        return string.format([[<g transform="translate(%.1f, %.1f)">
          <path d="M 6 15 A 6 6 0 0 1 11 7 A 8 8 0 0 1 22 9 A 6 6 0 0 1 24 15 Z" fill="#94a3b8"/>
          <path d="M 15 15 L 12 21 L 16 21 L 13 27" fill="none" stroke="#eab308" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        </g>]], cx - 14, cy - 12)
    elseif g:find("rain") then
        return string.format([[<g transform="translate(%.1f, %.1f)">
          <path d="M 6 15 A 6 6 0 0 1 11 7 A 8 8 0 0 1 22 9 A 6 6 0 0 1 24 15 Z" fill="#94a3b8"/>
          <line x1="9" y1="18" x2="7" y2="23" stroke="#38bdf8" stroke-width="2" stroke-linecap="round"/>
          <line x1="15" y1="18" x2="13" y2="23" stroke="#38bdf8" stroke-width="2" stroke-linecap="round"/>
          <line x1="21" y1="18" x2="19" y2="23" stroke="#38bdf8" stroke-width="2" stroke-linecap="round"/>
        </g>]], cx - 14, cy - 12)
    elseif g:find("snow") then
        return string.format([[<g transform="translate(%.1f, %.1f)">
          <path d="M 6 15 A 6 6 0 0 1 11 7 A 8 8 0 0 1 22 9 A 6 6 0 0 1 24 15 Z" fill="#94a3b8"/>
          <circle cx="9" cy="20" r="1.5" fill="#bae6fd"/>
          <circle cx="15" cy="22" r="1.5" fill="#bae6fd"/>
          <circle cx="21" cy="20" r="1.5" fill="#bae6fd"/>
        </g>]], cx - 14, cy - 12)
    elseif g:find("fog") then
        return string.format([[<g transform="translate(%.1f, %.1f)">
          <path d="M 6 13 A 6 6 0 0 1 11 6 A 8 8 0 0 1 22 8 A 6 6 0 0 1 24 13 Z" fill="#94a3b8"/>
          <line x1="6" y1="17" x2="24" y2="17" stroke="#94a3b8" stroke-width="2" stroke-linecap="round"/>
          <line x1="8" y1="21" x2="22" y2="21" stroke="#94a3b8" stroke-width="2" stroke-linecap="round"/>
        </g>]], cx - 14, cy - 12)
    elseif g:find("cloud") and g:find("sun") then
        return string.format([[<g transform="translate(%.1f, %.1f)">
          <circle cx="20" cy="8" r="5" fill="#f59e0b"/>
          <line x1="20" y1="1" x2="20" y2="2" stroke="#f59e0b" stroke-width="2" stroke-linecap="round"/>
          <line x1="26" y1="8" x2="27" y2="8" stroke="#f59e0b" stroke-width="2" stroke-linecap="round"/>
          <line x1="25" y1="3" x2="24" y2="4" stroke="#f59e0b" stroke-width="2" stroke-linecap="round"/>
          <path d="M 5 17 A 6 6 0 0 1 10 9 A 8 8 0 0 1 21 11 A 6 6 0 0 1 23 17 Z" fill="#94a3b8"/>
        </g>]], cx - 14, cy - 12)
    elseif g:find("sun") then
        return string.format([[<g transform="translate(%.1f, %.1f)">
          <circle cx="12" cy="12" r="6" fill="#f59e0b"/>
          <path d="M12 1v3M12 20v3M1 12h3M20 12h3M4.2 4.2l2.1 2.1M17.7 17.7l2.1 2.1M4.2 19.8l2.1-2.1M17.7 6.3l2.1-2.1" stroke="#f59e0b" stroke-width="2" stroke-linecap="round"/>
        </g>]], cx - 12, cy - 12)
    else
        return string.format([[<g transform="translate(%.1f, %.1f)">
          <path d="M 6 18 A 6 6 0 0 1 11 10 A 8 8 0 0 1 22 12 A 6 6 0 0 1 24 18 Z" fill="#94a3b8"/>
        </g>]], cx - 14, cy - 12)
    end
end

function shared.generateDailyChartSvg(dailyDays: { any }, width: number, height: number, opts: any?): string
    opts = opts or {}
    local isEn = opts.isEn == true
    local weekdaysTable = isEn and shared.WEEKDAYS_EN or shared.WEEKDAYS_GL
    local monthsTable = isEn and shared.MONTHS_EN or shared.MONTHS_GL
    local todayLabel = opts.todayLabel or (isEn and "Today" or "Hoxe")
    local tomorrowLabel = opts.tomorrowLabel or (isEn and "Tomorrow" or "Mañá")

    local n = #dailyDays
    if n == 0 then return "" end

    local padLeft = 48
    local padRight = 52
    local availW = width - padLeft - padRight
    local colW = availW / n
    local xs = {}
    for i = 1, n do
        xs[i] = padLeft + colW * (i - 0.5)
    end

    local minVal = 999
    local maxVal = -999
    for _, d in ipairs(dailyDays) do
        local tMin = tonumber(d.tempMin) or 0
        local tMax = tonumber(d.tempMax) or 0
        if tMin < minVal then minVal = tMin end
        if tMax > maxVal then maxVal = tMax end
    end
    if minVal == 999 then minVal = 10 end
    if maxVal == -999 then maxVal = 20 end

    local tMin = minVal - 2
    local tMax = maxVal + 2
    if tMax <= tMin then tMax = tMin + 5 end

    -- Zonas verticais ben diferenciadas para evitar solapamentos
    local chartTop = math.floor(height * 0.31)
    local chartBot = math.floor(height * 0.58)

    local function yTemp(t: number): number
        return chartBot - ((t - tMin) / (tMax - tMin)) * (chartBot - chartTop)
    end

    local maxPts: { ChartPoint } = {}
    local minPts: { ChartPoint } = {}
    for i, d in ipairs(dailyDays) do
        local tMax = tonumber(d.tempMax) or 0
        local tMinD = tonumber(d.tempMin) or 0
        maxPts[i] = { x = xs[i], y = yTemp(tMax) }
        minPts[i] = { x = xs[i], y = yTemp(tMinD) }
    end

    local maxCurve = buildSmoothBezierPath(maxPts)
    local minCurve = buildSmoothBezierPath(minPts)

    local revMinPts: { ChartPoint } = {}
    for i = #minPts, 1, -1 do
        revMinPts[#revMinPts + 1] = minPts[i]
    end
    local revMinCurve = buildSmoothBezierPath(revMinPts)
    local areaPath = maxCurve .. string.format(" L %.1f %.1f ", minPts[#minPts].x, minPts[#minPts].y) .. string.sub(revMinCurve, 2) .. " Z"

    -- Zona de choiva (eixo secundario 0% a 100%)
    local rainTopY = math.floor(height * 0.65)
    local rainBaselineY = math.floor(height * 0.85)
    local rainMaxH = rainBaselineY - rainTopY

    local function yRain(prob: number): number
        return rainBaselineY - (prob / 100.0) * rainMaxH
    end

    local rainPts: { ChartPoint } = {}
    for i, d in ipairs(dailyDays) do
        local r = tonumber(d.rainProb) or 0
        rainPts[i] = { x = xs[i], y = yRain(r) }
    end
    local rainCurve = buildSmoothBezierPath(rainPts)

    local svgParts = {}
    svgParts[#svgParts + 1] = string.format([[<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d" font-family="system-ui, -apple-system, sans-serif">
  <defs>
    <linearGradient id="tempArea" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%%" stop-color="#ff7849" stop-opacity="0.32"/>
      <stop offset="100%%" stop-color="#38bdf8" stop-opacity="0.10"/>
    </linearGradient>
    <linearGradient id="rainBarGrad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%%" stop-color="#38bdf8" stop-opacity="0.65"/>
      <stop offset="100%%" stop-color="#0284c7" stop-opacity="0.18"/>
    </linearGradient>
  </defs>

  <!-- Fondo da tarxeta -->
  <rect width="%d" height="%d" rx="14" fill="#141720" stroke="#252b3b" stroke-width="1.2"/>
]], width, height, width, height, width, height)

    -- Liñas de separación entre días
    for i = 1, n - 1 do
        local sepX = padLeft + colW * i
        svgParts[#svgParts + 1] = string.format('  <line x1="%.1f" y1="12" x2="%.1f" y2="%d" stroke="#1c2230" stroke-width="1"/>\n', sepX, sepX, height - 12)
    end

    -- Eixo esquerdo: Temperatura (°C)
    svgParts[#svgParts + 1] = string.format('  <text x="%d" y="%d" fill="#ff9800" font-size="10" font-weight="bold" text-anchor="end">°C</text>\n', padLeft - 10, chartTop - 12)
    local gridTemps = { math.floor(tMin + 2), math.floor((tMin + tMax) / 2), math.floor(tMax - 2) }
    for _, tVal in ipairs(gridTemps) do
        local gy = yTemp(tVal)
        svgParts[#svgParts + 1] = string.format([[
    <line x1="%d" y1="%.1f" x2="%d" y2="%.1f" stroke="#222838" stroke-width="1" stroke-dasharray="4,4"/>
    <text x="%d" y="%.1f" fill="#64748b" font-size="11" font-weight="500" text-anchor="end">%d°</text>
]], padLeft - 6, gy, width - padRight + 6, gy, padLeft - 10, gy + 4, tVal)
    end

    -- Eixo dereito: Probabilidade de choiva (0%% a 100%%)
    svgParts[#svgParts + 1] = string.format([[
  <text x="%d" y="%d" fill="#38bdf8" font-size="10" font-weight="bold" text-anchor="end">💧 %%</text>
  <line x1="%d" y1="%d" x2="%d" y2="%d" stroke="#1e3a5f" stroke-width="1.2" stroke-dasharray="3,3"/>
  <text x="%d" y="%.1f" fill="#38bdf8" opacity="0.8" font-size="10" font-weight="bold" text-anchor="end">0%%</text>
  <text x="%d" y="%.1f" fill="#38bdf8" opacity="0.8" font-size="10" font-weight="bold" text-anchor="end">50%%</text>
  <text x="%d" y="%.1f" fill="#38bdf8" opacity="0.8" font-size="10" font-weight="bold" text-anchor="end">100%%</text>
]], width - 12, rainTopY - 12, padLeft - 6, rainBaselineY, width - padRight + 6, rainBaselineY,
    width - 12, yRain(0) + 3, width - 12, yRain(50) + 3, width - 12, yRain(100) + 3)

    -- Barras verticais de choiva ancoradas na base 0%%
    local barW = math.floor(colW * 0.28)
    for i, d in ipairs(dailyDays) do
        local x = xs[i]
        local rain = tonumber(d.rainProb) or 0
        local barH = math.max(6.0, (rain / 100.0) * rainMaxH)
        local barY = rainBaselineY - barH
        svgParts[#svgParts + 1] = string.format([[
    <rect x="%.1f" y="%.1f" width="%d" height="%.1f" rx="4" fill="url(#rainBarGrad)" stroke="#38bdf8" stroke-width="1.2" stroke-opacity="0.7"/>
    <text x="%.1f" y="%.1f" fill="#38bdf8" font-size="11" font-weight="bold" text-anchor="middle">💧 %d%%</text>
]], x - barW / 2, barY, barW, barH, x, barY - 6, rain)
    end

    -- Liña de tendencia de choiva conectando as barras
    svgParts[#svgParts + 1] = string.format('  <path d="%s" fill="none" stroke="#38bdf8" stroke-width="1.8" stroke-dasharray="5,4" opacity="0.85"/>\n', rainCurve)

    -- Curvas e degradado de temperaturas
    svgParts[#svgParts + 1] = string.format([[
  <!-- Rango térmico -->
  <path d="%s" fill="url(#tempArea)"/>
  <path d="%s" fill="none" stroke="#ff7849" stroke-width="3.2" stroke-linecap="round"/>
  <path d="%s" fill="none" stroke="#38bdf8" stroke-width="3.2" stroke-linecap="round"/>
]], areaPath, maxCurve, minCurve)

    -- Puntos térmicos con números limpos (sen frechas redundantes)
    for i, d in ipairs(dailyDays) do
        local mx, my = maxPts[i].x, maxPts[i].y
        local nx, ny = minPts[i].x, minPts[i].y
        local tMax = tonumber(d.tempMax) or 0
        local tMinD = tonumber(d.tempMin) or 0
        svgParts[#svgParts + 1] = string.format([[
    <!-- Máxima -->
    <circle cx="%.1f" cy="%.1f" r="5" fill="#141720" stroke="#ff7849" stroke-width="2.8"/>
    <text x="%.1f" y="%.1f" fill="#ff7849" font-size="13" font-weight="bold" text-anchor="middle">%d°</text>

    <!-- Mínima -->
    <circle cx="%.1f" cy="%.1f" r="5" fill="#141720" stroke="#38bdf8" stroke-width="2.8"/>
    <text x="%.1f" y="%.1f" fill="#38bdf8" font-size="13" font-weight="bold" text-anchor="middle">%d°</text>
]], mx, my, mx, my - 8, tMax, nx, ny, nx, ny + 17, tMinD)
    end

    -- Cabeceira de cada día (Día, Data, Icona meteorolóxica SVG e Descrición)
    for i, d in ipairs(dailyDays) do
        local x = xs[i]
        local isToday = (d.reach == 0)
        local dayTitle = "Hoxe"
        if d.reach == 0 then
            dayTitle = todayLabel
        elseif d.reach == 1 then
            dayTitle = tomorrowLabel
        else
            dayTitle = weekdaysTable[d.weekday] or ("Día " .. tostring(d.reach))
        end

        local dateSub = ""
        if d.day and d.day > 0 and d.month and d.month > 0 then
            dateSub = string.format("%d %s", d.day, monthsTable[d.month] or "")
        end

        local dayColor = isToday and "#ff9800" or "#f8fafc"
        local skyClean = shared.cleanHtml(d.skyDesc or ""):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
        local iconSvg = shared.renderWeatherSvgIcon(d.glyph or "cloud", x, 56)

        svgParts[#svgParts + 1] = string.format([[
    <text x="%.1f" y="24" fill="%s" font-size="14" font-weight="bold" text-anchor="middle">%s</text>
    <text x="%.1f" y="40" fill="#94a3b8" font-size="11" text-anchor="middle">%s</text>
    %s
    <text x="%.1f" y="80" fill="#cbd5e1" font-size="12" font-weight="500" text-anchor="middle">%s</text>
]], x, dayColor, dayTitle, x, dateSub, iconSvg, x, skyClean)
    end

    -- Franxa inferior para o vento
    svgParts[#svgParts + 1] = string.format('  <line x1="16" y1="%d" x2="%d" y2="%d" stroke="#222838" stroke-width="1"/>\n', height - 40, width - 16, height - 40)
    for i, d in ipairs(dailyDays) do
        local x = xs[i]
        local windDesc = tostring(d.windDesc or "")
        if windDesc == "" then windDesc = "Calma" end
        local deg = shared.getWindAngle(windDesc)
        local cleanWind = windDesc:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
        local halfW = math.floor((#cleanWind * 6.5 + 26) / 2)

        svgParts[#svgParts + 1] = string.format([[
    <g transform="translate(%.1f, %d)">
      <circle cx="10" cy="10" r="10" fill="#1e2330"/>
      <g transform="rotate(%d, 10, 10)">
        <path d="M 10 3 L 15 16 L 10 13 L 5 16 Z" fill="#94a3b8"/>
      </g>
      <text x="26" y="14" fill="#cbd5e1" font-size="12" font-weight="500">%s</text>
    </g>
]], x - halfW, height - 26, deg, cleanWind)
    end

    svgParts[#svgParts + 1] = "</svg>"
    return table.concat(svgParts)
end

return shared
