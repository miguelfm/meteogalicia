--!strict
-- Detailed weather panel for MeteoGalicia.
-- Shows current conditions, interactive 48h hourly forecast with keyboard/scroll navigation,
-- upcoming days forecast with continuous SVG temperature & rain chart, official commentary, and indicators.

local shared = require("./shared.luau")
local concellos = require("./concellos.luau")

local weather = nil
local weatherError = nil
local isLoading = false
local render: () -> () = function() end

local isSearchingConcello = false
local concelloSearchQuery = ""
local selectedProvince: number? = nil

type ScaleConfig = {
    panelPadding: number,
    panelGap: number,
    headerGlyph: number,
    headerTown: number,
    headerBadge: number,
    headerDesc: number,
    headerTemp: number,
    headerDeg: number,
    headerMinMax: number,
    headerSunIcon: number,
    headerSunText: number,
    headerSunTime: number,
    headerSunPadH: number,
    headerSunPadV: number,
    headerSunGap: number,
    headerSunDividerHeight: number,
    sectionIcon: number,
    sectionTitle: number,
    sectionSub: number,
    hourlyWidth: number,
    hourlyPad: number,
    hourlyGap: number,
    hourlyTime: number,
    hourlyGlyph: number,
    hourlyTemp: number,
    hourlyRainIcon: number,
    hourlyRainText: number,
    hourlyRowGap: number,
    dailyPad: number,
    dailyGap: number,
    dailyTitle: number,
    dailyDate: number,
    dailyGlyph: number,
    dailyDesc: number,
    dailyTemp: number,
    dailyRainIcon: number,
    dailyRainText: number,
    dailyWindText: number,
    chartWidth: number,
    chartHeight: number,
    commentTitle: number,
    commentText: number,
    commentPad: number,
    footerIcon: number,
    footerText: number,
    headerBtnGap: number,
    btnSize: string,
}

local SCALES: { [string]: ScaleConfig } = {
    normal = {
        panelPadding = 21,
        panelGap = 12,
        headerGlyph = 46,
        headerTown = 22,
        headerBadge = 10,
        headerDesc = 14,
        headerTemp = 32,
        headerDeg = 18,
        headerMinMax = 13,
        headerBtnGap = 4,
        headerSunIcon = 28,
        headerSunText = 12,
        headerSunTime = 16,
        headerSunPadH = 14,
        headerSunPadV = 8,
        headerSunGap = 14,
        headerSunDividerHeight = 28,
        sectionIcon = 15,
        sectionTitle = 14,
        sectionSub = 11,
        hourlyWidth = 101,
        hourlyPad = 6,
        hourlyGap = 5,
        hourlyTime = 11,
        hourlyGlyph = 20,
        hourlyTemp = 13,
        hourlyRainIcon = 9,
        hourlyRainText = 10,
        hourlyRowGap = 10,
        dailyPad = 8,
        dailyGap = 5,
        dailyTitle = 12,
        dailyDate = 10,
        dailyGlyph = 26,
        dailyDesc = 11,
        dailyTemp = 12,
        dailyRainIcon = 11,
        dailyRainText = 11,
        dailyWindText = 10,
        chartWidth = 1330,
        chartHeight = 260,
        commentTitle = 13,
        commentText = 12,
        commentPad = 12,
        footerIcon = 14,
        footerText = 12,
        btnSize = "sm",
    },
    large = {
        panelPadding = 21,
        panelGap = 14,
        headerGlyph = 58,
        headerTown = 28,
        headerBadge = 11,
        headerDesc = 16,
        headerTemp = 42,
        headerDeg = 24,
        headerMinMax = 16,
        headerBtnGap = 6,
        headerSunIcon = 36,
        headerSunText = 14,
        headerSunTime = 20,
        headerSunPadH = 18,
        headerSunPadV = 10,
        headerSunGap = 16,
        headerSunDividerHeight = 34,
        sectionIcon = 18,
        sectionTitle = 17,
        sectionSub = 13,
        hourlyWidth = 101,
        hourlyPad = 8,
        hourlyGap = 6,
        hourlyTime = 13,
        hourlyGlyph = 28,
        hourlyTemp = 16,
        hourlyRainIcon = 11,
        hourlyRainText = 12,
        hourlyRowGap = 10,
        dailyPad = 12,
        dailyGap = 6,
        dailyTitle = 15,
        dailyDate = 12,
        dailyGlyph = 34,
        dailyDesc = 13,
        dailyTemp = 15,
        dailyRainIcon = 13,
        dailyRainText = 13,
        dailyWindText = 11,
        chartWidth = 1330,
        chartHeight = 280,
        commentTitle = 15,
        commentText = 14,
        commentPad = 14,
        footerIcon = 16,
        footerText = 14,
        btnSize = "md",
    },
    xlarge = {
        panelPadding = 21,
        panelGap = 15,
        headerGlyph = 76,
        headerTown = 40,
        headerBadge = 14,
        headerDesc = 21,
        headerTemp = 60,
        headerDeg = 30,
        headerMinMax = 21,
        headerBtnGap = 8,
        headerSunIcon = 44,
        headerSunText = 18,
        headerSunTime = 28,
        headerSunPadH = 22,
        headerSunPadV = 12,
        headerSunGap = 18,
        headerSunDividerHeight = 42,
        sectionIcon = 24,
        sectionTitle = 23,
        sectionSub = 17,
        hourlyWidth = 101,
        hourlyPad = 10,
        hourlyGap = 8,
        hourlyTime = 17,
        hourlyGlyph = 42,
        hourlyTemp = 23,
        hourlyRainIcon = 15,
        hourlyRainText = 17,
        hourlyRowGap = 10,
        dailyPad = 14,
        dailyGap = 8,
        dailyTitle = 21,
        dailyDate = 16,
        dailyGlyph = 48,
        dailyDesc = 17,
        dailyTemp = 21,
        dailyRainIcon = 17,
        dailyRainText = 17,
        dailyWindText = 15,
        chartWidth = 1330,
        chartHeight = 310,
        commentTitle = 21,
        commentText = 18,
        commentPad = 16,
        footerIcon = 20,
        footerText = 17,
        btnSize = "lg",
    },
}

function onRefresh()
    noctalia.state.set("weather_request_refresh", true)
end

function onPrevHours()
    local curOffset = tonumber(noctalia.state.get("hourly_offset")) or 0
    if curOffset > 0 then
        local newOffset = (curOffset % 12 ~= 0) and (math.floor(curOffset / 12) * 12) or math.max(0, curOffset - 12)
        noctalia.state.set("hourly_offset", newOffset)
        render()
    end
end

function onNextHours()
    local curOffset = tonumber(noctalia.state.get("hourly_offset")) or 0
    local totalHourly = (weather and weather.hourly and #weather.hourly) or 48
    local maxOffset = math.max(0, totalHourly - 12)
    if curOffset < maxOffset then
        local newOffset = math.min(maxOffset, (math.floor(curOffset / 12) + 1) * 12)
        noctalia.state.set("hourly_offset", newOffset)
        render()
    end
end

function onStepPrevHour()
    local curOffset = tonumber(noctalia.state.get("hourly_offset")) or 0
    if curOffset > 0 then
        noctalia.state.set("hourly_offset", curOffset - 1)
        render()
    end
end

function onStepNextHour()
    local curOffset = tonumber(noctalia.state.get("hourly_offset")) or 0
    local totalHourly = (weather and weather.hourly and #weather.hourly) or 48
    local maxOffset = math.max(0, totalHourly - 12)
    if curOffset < maxOffset then
        noctalia.state.set("hourly_offset", curOffset + 1)
        render()
    end
end

function onBlockHours1() noctalia.state.set("hourly_offset", 0); render() end
function onBlockHours2() noctalia.state.set("hourly_offset", 12); render() end
function onBlockHours3() noctalia.state.set("hourly_offset", 24); render() end
function onBlockHours4() noctalia.state.set("hourly_offset", 36); render() end

function onScroll(_axis: string?, steps: number?, _startsGesture: boolean?)
    local s = steps or 0
    if s > 0 then
        onStepNextHour()
    elseif s < 0 then
        onStepPrevHour()
    end
end

function onOpenWeb()
    local id = (weather and weather.concelloId) or 15035
    noctalia.runAsync(string.format("xdg-open 'https://www.meteogalicia.gal/web/predicion/concellos/%d/0'", id))
end

function onOpenSettings()
    if type(panel.close) == "function" then
        panel.close()
    end
    noctalia.runAsync("noctalia msg settings-open-plugin miguelfm/meteogalicia")
end

local function normalizeStr(s: string): string
    local res = s:lower()
    res = res:gsub("á", "a"):gsub("à", "a"):gsub("â", "a"):gsub("ã", "a")
    res = res:gsub("é", "e"):gsub("è", "e"):gsub("ê", "e")
    res = res:gsub("í", "i"):gsub("ì", "i"):gsub("î", "i")
    res = res:gsub("ó", "o"):gsub("ò", "o"):gsub("ô", "o"):gsub("õ", "o")
    res = res:gsub("ú", "u"):gsub("ù", "u"):gsub("ü", "u")
    res = res:gsub("ñ", "n")
    return res
end

local function filterConcellos(): { concellos.Concello }
    local q = normalizeStr(concelloSearchQuery:match("^%s*(.-)%s*$") or "")
    local matches = {}
    for _, c in ipairs(concellos) do
        local provMatch = (selectedProvince == nil) or (c.provinceId == selectedProvince)
        if provMatch then
            if q == "" then
                table.insert(matches, c)
            else
                local normName = normalizeStr(c.name)
                local idStr = tostring(c.id)
                if normName:find(q, 1, true) or idStr:find(q, 1, true) then
                    table.insert(matches, c)
                end
            end
        end
    end
    return matches
end

function onToggleSearchConcello()
    isSearchingConcello = not isSearchingConcello
    if isSearchingConcello then
        concelloSearchQuery = ""
    end
    render()
end

function onConcelloSearchChange(newText: string)
    concelloSearchQuery = tostring(newText or "")
    render()
end

function onConcelloSearchSubmit(_text: string?)
    local matches = filterConcellos()
    if #matches > 0 then
        local first = matches[1]
        onSelectConcello(first.id, first.name)
    end
end

function onSelectProvinceAll()
    selectedProvince = nil
    render()
end

function onSelectProvinceCoruna()
    selectedProvince = (selectedProvince == 15) and nil or 15
    render()
end

function onSelectProvinceLugo()
    selectedProvince = (selectedProvince == 27) and nil or 27
    render()
end

function onSelectProvinceOurense()
    selectedProvince = (selectedProvince == 32) and nil or 32
    render()
end

function onSelectProvincePontevedra()
    selectedProvince = (selectedProvince == 36) and nil or 36
    render()
end

function onSelectConcello(cId: number, cName: string)
    noctalia.state.set("concello_id", tostring(cId))
    noctalia.state.set("concello_name", cName)
    local cmd = string.format("python3 ~/.config/noctalia/plugins/meteogalicia/scripts/set_concello.py %d %q", cId, cName)
    noctalia.runAsync(cmd)
    isSearchingConcello = false
    noctalia.state.set("weather_request_refresh", true)
    render()
end

function onKey(chord: string?, pressed: boolean)
    if not pressed then return end
    local raw = tostring(chord or "")
    local lower = raw:lower()
    local cleanKey = lower:gsub("[_%s%-]", "")

    if cleanKey == "escape" then
        if isSearchingConcello then
            isSearchingConcello = false
            render()
        elseif type(panel.close) == "function" then
            panel.close()
        end
    elseif (cleanKey == "f" or cleanKey == "/") and not isSearchingConcello then
        isSearchingConcello = true
        concelloSearchQuery = ""
        render()
    elseif cleanKey == "r" and not isSearchingConcello then
        onRefresh()
    elseif (cleanKey == "s" or cleanKey == "c") and not isSearchingConcello then
        onOpenSettings()
    elseif not isSearchingConcello then
        if cleanKey == "left" or cleanKey == "arrowleft" or cleanKey == "[" or cleanKey == "bracketleft" or cleanKey:find("%+left$") ~= nil then
            onStepPrevHour()
        elseif cleanKey == "right" or cleanKey == "arrowright" or cleanKey == "]" or cleanKey == "bracketright" or cleanKey:find("%+right$") ~= nil then
            onStepNextHour()
        elseif cleanKey == "pageup" or cleanKey == "prior" or cleanKey:find("pageup$") ~= nil or cleanKey:find("prior$") ~= nil then
            onPrevHours()
        elseif cleanKey == "pagedown" or cleanKey == "next" or cleanKey:find("pagedown$") ~= nil or cleanKey:find("next$") ~= nil then
            onNextHours()
        elseif cleanKey == "home" or cleanKey:find("home$") ~= nil then
            onBlockHours1()
        elseif cleanKey == "end" or cleanKey:find("end$") ~= nil then
            onBlockHours4()
        end
    end
end

local function tr(key: string, fallback: string): string
    if type(noctalia.tr) == "function" then
        local val = noctalia.tr(key)
        if val and val ~= "" and val ~= key then
            return val
        end
    end
    return fallback
end

local function getScale(): ScaleConfig
    local key = tostring(noctalia.getConfig("ui_scale") or "large"):lower()
    return SCALES[key] or SCALES["large"]
end

local function getThemeFills(): (string, string, string, string)
    local opacitySetting = tostring(noctalia.getConfig("panel_opacity") or "opaque"):lower()
    local rootFill = "surface/0.97"
    local cardBgNorm = "surface_variant/0.92"
    local cardBgActive = "primary/0.24"
    local commentaryBg = "surface_variant/0.88"

    if opacitySetting == "subtle" then
        rootFill = "surface/0.88"
        cardBgNorm = "surface_variant/0.75"
        cardBgActive = "primary/0.18"
        commentaryBg = "surface_variant/0.70"
    elseif opacitySetting == "glass" then
        rootFill = "surface/0.65"
        cardBgNorm = "surface_variant/0.50"
        cardBgActive = "primary/0.14"
        commentaryBg = "surface_variant/0.45"
    end

    return rootFill, cardBgNorm, cardBgActive, commentaryBg
end

local function getTimelineGlyphColor(glyphName: string, isDark: boolean): string
    if string.find(glyphName, "storm") or string.find(glyphName, "thunder") then
        return isDark and "#f87171" or "#dc2626"
    elseif string.find(glyphName, "rain") or string.find(glyphName, "snow") or string.find(glyphName, "snowflake") then
        return isDark and "#38bdf8" or "#0284c7"
    elseif string.find(glyphName, "sun") then
        return isDark and "#fbbf24" or "#d97706"
    elseif string.find(glyphName, "moon") then
        return isDark and "#38bdf8" or "#0284c7"
    else
        return isDark and "#e2e8f0" or "#1e293b"
    end
end

local function getWindArrow(windDesc: string?, windSpeed: number?): string
    if not windDesc or windDesc == "" then return "•" end
    local desc = windDesc:lower()
    if desc:find("calm") or (windSpeed ~= nil and windSpeed == 0) then
        return "•"
    end
    if desc:find("nordés") or desc:find("nordeste") or desc:find("northeast") or desc:find("ne") then
        return "↙"
    elseif desc:find("noroeste") or desc:find("northwest") or desc:find("no") or desc:find("nw") then
        return "↘"
    elseif desc:find("sudoeste") or desc:find("southwest") or desc:find("so") or desc:find("sw") then
        return "↗"
    elseif desc:find("sueste") or desc:find("southeast") or desc:find("se") then
        return "↖"
    elseif desc:find("norte") or desc:find("north") then
        return "↓"
    elseif desc:find("sur") or desc:find("south") then
        return "↑"
    elseif desc:find("oeste") or desc:find("west") then
        return "→"
    elseif desc:find("leste") or desc:find("este") or desc:find("east") then
        return "←"
    end
    return "•"
end

local function getWindColor(windSpeed: number, isDark: boolean): string
    if windSpeed <= 0 then
        return isDark and "#64748b" or "#94a3b8"
    elseif windSpeed <= 15 then
        return isDark and "#94a3b8" or "#475569"
    elseif windSpeed <= 30 then
        return isDark and "#38bdf8" or "#0284c7"
    elseif windSpeed <= 45 then
        return isDark and "#fbbf24" or "#d97706"
    else
        return isDark and "#f87171" or "#dc2626"
    end
end

local function formatWindTooltip(windDesc: string?, windSpeed: number?, isEn: boolean): string
    local speed = tonumber(windSpeed) or 0
    local desc = windDesc or ""
    local arrow = getWindArrow(desc, speed)
    local windWord = isEn and "Wind" or "Vento"
    if isEn and desc:lower():find("calm") then
        desc = "Calm"
    end
    if desc ~= "" then
        if speed > 0 then
            return string.format("%s: %s %s (%d km/h)", windWord, arrow, desc, speed)
        else
            return string.format("%s: %s %s", windWord, arrow, desc)
        end
    else
        return string.format("%s: %s %d km/h", windWord, arrow, speed)
    end
end

render = function()
    local s = getScale()
    local rootFill, cardBgNorm, cardBgActive, commentaryBg = getThemeFills()

    if weather == nil or weather.current == nil then
        if weatherError then
            panel.render(ui.column({
                gap = s.panelGap + 4,
                padding = s.panelPadding * 1.5,
                align = "center",
                fill = rootFill,
                radius = 16,
                border = "outline/0.25",
                borderWidth = 1,
                flexGrow = 1,
            }, {
                ui.glyph({ name = "cloud-off", size = s.headerGlyph, color = "error" }),
                ui.label({ text = tr("ui.error_load", "Non se puideron cargar os datos de MeteoGalicia"), fontSize = s.headerDesc, fontWeight = "bold", color = "error" }),
                ui.label({ text = tostring(weatherError), fontSize = s.hourlyTemp, color = "on_surface_variant" }),
                ui.button({ text = tr("ui.retry", "Reintentar"), glyph = "refresh", variant = "primary", controlSize = s.btnSize, onClick = "onRefresh" }),
            }))
        else
            panel.render(ui.column({
                gap = s.panelGap + 4,
                padding = s.panelPadding * 2,
                align = "center",
                fill = rootFill,
                radius = 16,
                border = "outline/0.25",
                borderWidth = 1,
                flexGrow = 1,
            }, {
                ui.glyph({ name = "cloud-rain", size = s.headerGlyph, color = "primary" }),
                ui.label({ text = tr("ui.loading", "Cargando predición de MeteoGalicia…"), fontSize = s.headerDesc, color = "on_surface_variant" }),
            }))
        end
        return
    end

    local cur = weather.current
    local today = weather.today or {}
    local hourly = weather.hourly or {}
    local hoursLimit = tonumber(noctalia.getConfig("hours_count")) or 48

    local isDark = true
    if noctalia.isDarkMode ~= nil then
        isDark = (noctalia.isDarkMode() == true)
    end
    local isEn = (tr("ui.today", "Hoxe") == "Today")

    local rootChildren = {}

    -- ── 1. CABECEIRA PRINCIPAL ───────────────────────────────────────────────
    local sunrise = today.sunrise
    local sunset = today.sunset
    if not sunrise or not sunset then
        local r, s_time = shared.calcSolar(today.latitude, today.longitude, os.time())
        sunrise = sunrise or r
        sunset = sunset or s_time
    end

    local makeHeaderCard = function(iconName: string, iconColor: string, labelText: string, valueText: string, tooltipText: string?)
        return ui.row({
            gap = math.max(6, math.floor(s.headerSunGap * 0.45)),
            align = "center",
            paddingH = math.max(10, math.floor(s.headerSunPadH * 0.65)),
            paddingV = math.max(5, math.floor(s.headerSunPadV * 0.7)),
            radius = 12,
            fill = cardBgNorm,
            border = "outline/0.25",
            borderWidth = 1,
            tooltip = tooltipText,
        }, {
            ui.glyph({
                name = iconName,
                size = math.max(20, math.floor(s.headerSunIcon * 0.72)),
                color = iconColor,
            }),
            ui.column({ gap = 1 }, {
                ui.label({
                    text = labelText,
                    fontSize = math.max(10, math.floor(s.headerSunText * 0.82)),
                    color = "on_surface_variant",
                }),
                ui.label({
                    text = valueText,
                    fontSize = math.max(13, math.floor(s.headerSunTime * 0.72)),
                    fontWeight = "bold",
                    color = "on_surface",
                }),
            }),
        })
    end

    local cardSunrise = makeHeaderCard("weather-sunrise", "tertiary", tr("ui.sunrise", "Orto"), sunrise, tr("ui.solar_tooltip", "Horarios solares: Orto (amencer) e Ocaso (solpor)"))
    local cardSunset = makeHeaderCard("weather-sunset", "secondary", tr("ui.sunset", "Ocaso"), sunset, tr("ui.solar_tooltip", "Horarios solares: Orto (amencer) e Ocaso (solpor)"))

    -- Vento actual
    local curWindSpeed = tonumber(cur.windSpeed) or 0
    local curWindDesc = cur.windDesc or ""
    local curWindArrow = getWindArrow(curWindDesc, curWindSpeed)
    local curWindColor = getWindColor(curWindSpeed, isDark)
    local curWindLabel = tr("ui.wind_title", "Vento")
    local curWindVal = curWindArrow .. " " .. tostring(curWindSpeed) .. " km/h"
    local curWindTip = formatWindTooltip(curWindDesc, curWindSpeed, isEn)
    local cardWind = makeHeaderCard("wind", curWindColor, curWindLabel, curWindVal, curWindTip)

    -- Humidade actual (en tempo real desde a estación máis próxima)
    local humVal = cur.humidity
    local humText = (humVal ~= nil and (tostring(humVal) .. "%") or "--%")
    local humTip = humVal and (tr("ui.humidity_tooltip", "Humidade relativa actual: ") .. tostring(humVal) .. "%" .. (cur.stationName and (" (" .. cur.stationName .. ")") or "")) or tr("ui.no_humidity", "Humidade non dispoñible")
    local cardHumidity = makeHeaderCard("droplet", "secondary", tr("ui.humidity_title", "Humidade"), humText, humTip)

    -- Calidade do aire actual (ICA)
    local icaVal = tonumber(cur.ica or today.ica) or 0
    local icaDesc = isEn and "Good" or "Boa"
    local icaColor = isDark and "#34d399" or "#059669"
    local icaFull = isEn and "Good (ICA 1)" or "Favorable (ICA 1)"
    if icaVal >= 4 then
        icaDesc = isEn and "V.Poor" or "Moi mala"
        icaColor = isDark and "#f87171" or "#dc2626"
        icaFull = isEn and "Very poor (ICA 4)" or "Moi mala (ICA 4)"
    elseif icaVal >= 3 then
        icaDesc = isEn and "Poor" or "Mala"
        icaColor = isDark and "#fb923c" or "#ea580c"
        icaFull = isEn and "Poor (ICA 3)" or "Mala (ICA 3)"
    elseif icaVal >= 2 then
        icaDesc = isEn and "Fair" or "Razoable"
        icaColor = isDark and "#fbbf24" or "#d97706"
        icaFull = isEn and "Fair (ICA 2)" or "Razoable (ICA 2)"
    elseif icaVal == 0 then
        icaDesc = "--"
        icaColor = "on_surface_variant"
        icaFull = isEn and "Not available" or "Non dispoñible"
    end
    local icaTip = tr("ui.air_quality_tooltip", "Calidade do aire: ") .. icaFull
    local cardAirQuality = makeHeaderCard("leaf", icaColor, tr("ui.air_quality_title", "Calidade aire"), icaDesc, icaTip)

    local headerCards = ui.row({ gap = math.max(6, math.floor(s.panelGap * 0.5)), align = "center" }, {
        cardSunrise,
        cardSunset,
        cardWind,
        cardHumidity,
        cardAirQuality,
    })

    local headerRow = ui.row({ gap = 12, align = "center" }, {
        ui.glyph({
            name = cur.glyph or "cloud-sun",
            size = s.headerGlyph,
            color = cur.color or "primary",
        }),
        ui.column({ gap = 3 }, {
            ui.row({ gap = 6, align = "center" }, {
                ui.label({
                    text = weather.officialName or weather.concelloName or "Fene",
                    fontSize = s.headerTown,
                    fontWeight = "bold",
                    color = "on_surface",
                }),
                ui.button({
                    glyph = isSearchingConcello and "x" or "search",
                    variant = isSearchingConcello and "primary" or "ghost",
                    tooltip = isSearchingConcello and tr("ui.search_concello_close", "Pechar busca (Esc)") or tr("ui.search_concello_tooltip", "Buscar concello (F)"),
                    controlSize = s.btnSize,
                    onClick = "onToggleSearchConcello",
                }),
            }),
            ui.label({
                text = cur.skyDesc or "Predición diaria",
                fontSize = s.headerDesc,
                color = "on_surface_variant",
            }),
        }),
        ui.spacer(),
        headerCards,
        ui.spacer(),
        ui.column({ gap = 2, align = "end" }, {
            ui.row({ gap = 4, align = "center" }, {
                ui.label({
                    text = tostring(cur.temp or 0),
                    fontSize = s.headerTemp,
                    fontWeight = "bold",
                    color = "on_surface",
                }),
                ui.label({ text = "°C", fontSize = s.headerDeg, fontWeight = "bold", color = "on_surface_variant" }),
            }),
            ui.row({ gap = 8 }, {
                ui.label({
                    text = "↓ " .. tostring(today.tempMin or 0) .. "°",
                    fontSize = s.headerMinMax,
                    fontWeight = "bold",
                    color = "secondary",
                }),
                ui.label({
                    text = "↑ " .. tostring(today.tempMax or 0) .. "°",
                    fontSize = s.headerMinMax,
                    fontWeight = "bold",
                    color = "error",
                }),
            }),
        }),
        ui.column({ gap = s.headerBtnGap, align = "center" }, {
            ui.button({
                glyph = "settings",
                variant = "ghost",
                tooltip = tr("ui.settings_tooltip", "Axustes de MeteoGalicia (S)"),
                onClick = "onOpenSettings",
            }),
            ui.button({
                glyph = "refresh",
                variant = "ghost",
                tooltip = tr("ui.refresh_tooltip", "Actualizar datos (R)"),
                onClick = "onRefresh",
            }),
        }),
    })

    rootChildren[#rootChildren + 1] = headerRow

    if isSearchingConcello then
        local matches = filterConcellos()
        local curConcelloId = (weather and weather.concelloId) or tonumber(noctalia.state.get("concello_id")) or 15035

        local searchInputRow = ui.row({ gap = 8, align = "center" }, {
            ui.glyph({ name = "search", size = 20, color = "primary" }),
            ui.input({
                value = concelloSearchQuery,
                placeholder = tr("ui.search_concello_placeholder", "Buscar concello ou código INE…"),
                onChange = "onConcelloSearchChange",
                onSubmit = "onConcelloSearchSubmit",
                controlSize = s.btnSize,
                flexGrow = 1,
            }),
            ui.row({ gap = 4, align = "center" }, {
                ui.button({
                    text = tr("ui.all_provinces", "Todas"),
                    variant = (selectedProvince == nil) and "primary" or "ghost",
                    controlSize = s.btnSize,
                    onClick = "onSelectProvinceAll",
                }),
                ui.button({
                    text = tr("ui.province_coruna", "A Coruña"),
                    variant = (selectedProvince == 15) and "primary" or "ghost",
                    controlSize = s.btnSize,
                    onClick = "onSelectProvinceCoruna",
                }),
                ui.button({
                    text = tr("ui.province_lugo", "Lugo"),
                    variant = (selectedProvince == 27) and "primary" or "ghost",
                    controlSize = s.btnSize,
                    onClick = "onSelectProvinceLugo",
                }),
                ui.button({
                    text = tr("ui.province_ourense", "Ourense"),
                    variant = (selectedProvince == 32) and "primary" or "ghost",
                    controlSize = s.btnSize,
                    onClick = "onSelectProvinceOurense",
                }),
                ui.button({
                    text = tr("ui.province_pontevedra", "Pontevedra"),
                    variant = (selectedProvince == 36) and "primary" or "ghost",
                    controlSize = s.btnSize,
                    onClick = "onSelectProvincePontevedra",
                }),
            }),
            ui.button({
                glyph = "x",
                variant = "ghost",
                tooltip = tr("ui.search_concello_close", "Pechar busca (Esc)"),
                controlSize = s.btnSize,
                onClick = "onToggleSearchConcello",
            }),
        })

        local numCols = (s.chartWidth >= 1100) and 4 or 3
        local gridRows = {}
        local currentRow = {}

        for idx, c in ipairs(matches) do
            local isCurrent = (c.id == curConcelloId)
            local card = ui.row({
                gap = 8,
                align = "center",
                justify = "space-between",
                paddingH = 10,
                paddingV = 6,
                radius = 8,
                fill = isCurrent and cardBgActive or cardBgNorm,
                border = isCurrent and "primary" or "outline/0.25",
                borderWidth = 1,
                flexGrow = 1,
                tooltip = string.format("%s (%s • %d)", c.name, c.province, c.id),
                onClick = function()
                    onSelectConcello(c.id, c.name)
                end,
            }, {
                ui.column({ gap = 1, align = "start", flexGrow = 1 }, {
                    ui.label({
                        text = c.name,
                        fontSize = math.max(12, math.floor(s.hourlyTemp * 0.95)),
                        fontWeight = isCurrent and "bold" or "normal",
                        color = isCurrent and "primary" or "on_surface",
                    }),
                    ui.label({
                        text = string.format("%s • %d", c.province, c.id),
                        fontSize = math.max(9, math.floor(s.hourlyTime * 0.85)),
                        color = "on_surface_variant",
                    }),
                }),
                isCurrent and ui.glyph({ name = "check", size = 16, color = "primary" }) or nil,
            })

            table.insert(currentRow, card)

            if #currentRow == numCols or idx == #matches then
                if #currentRow < numCols then
                    for _ = #currentRow + 1, numCols do
                        table.insert(currentRow, ui.spacer({ flexGrow = 1 }))
                    end
                end
                table.insert(gridRows, ui.row({ gap = 6, align = "center" }, currentRow))
                currentRow = {}
            end
        end

        local listContent
        if #matches == 0 then
            listContent = ui.row({ align = "center", justify = "center", padding = 16 }, {
                ui.label({
                    text = tr("ui.no_concellos_found", "Non se atoparon concellos"),
                    fontSize = s.hourlyTemp,
                    color = "on_surface_variant",
                }),
            })
        else
            listContent = ui.column({ gap = 6 }, gridRows)
        end

        local scrollContainer = ui.scroll({
            maxHeight = 220,
            flexGrow = 1,
        }, {
            listContent,
        })

        local pickerBox = ui.column({
            gap = 10,
            padding = 12,
            radius = 14,
            fill = cardBgNorm,
            border = "primary/0.4",
            borderWidth = 1,
        }, {
            searchInputRow,
            ui.separator(),
            scrollContainer,
        })

        rootChildren[#rootChildren + 1] = pickerBox
    end

    -- Variables comúns para a predición horaria e diaria
    local currentHourSec = math.floor(os.time() / 3600) * 3600
    local weekdaysShort = isEn and shared.WEEKDAYS_SHORT_EN or shared.WEEKDAYS_SHORT_GL
    local weekdaysFull = isEn and shared.WEEKDAYS_EN or shared.WEEKDAYS_GL
    local monthsTable = isEn and shared.MONTHS_FULL_EN or shared.MONTHS_FULL_GL
    local totalHourly = math.min(hoursLimit, #hourly)
    local maxOffset = math.max(0, totalHourly - 12)

    -- ── 2. PREDICIÓN POR HORAS (OPCIONAL, POR DEFECTO DESACTIVADA) ───────────
    local showHourlyCards = noctalia.getConfig("show_hourly_cards")
    if showHourlyCards == nil then showHourlyCards = false end

    if showHourlyCards then
        rootChildren[#rootChildren + 1] = ui.separator()

        local hourlyOffset = tonumber(noctalia.state.get("hourly_offset")) or 0
        local numBlocks = math.max(1, math.ceil(totalHourly / 12))
        if hourlyOffset > maxOffset then
            hourlyOffset = maxOffset
        end

        local startIdx = hourlyOffset + 1
        local endIdx = math.min(hourlyOffset + 12, totalHourly)

        local startH = hourly[startIdx]
        local endH = hourly[endIdx]
        local daysCovered = ""
        if startH and endH then
            local w1 = weekdaysFull[startH.weekday] or (startH.isTomorrow and tr("ui.tomorrow", "Mañá") or tr("ui.today", "Hoxe"))
        local w2 = weekdaysFull[endH.weekday] or (endH.isTomorrow and tr("ui.tomorrow", "Mañá") or tr("ui.today", "Hoxe"))
        local m1 = monthsTable[startH.month] or ""

        if startH.day == endH.day then
            if isEn then
                daysCovered = string.format("%s, %s %d", w1, m1, startH.day)
            else
                daysCovered = string.format("%s, %d de %s", w1, startH.day, m1)
            end
        else
            daysCovered = string.format("%s %d → %s %d", w1, startH.day, w2, endH.day)
        end
    end

    -- Controis de navegación da predición horaria (paxinación en bloques de 12h ata 48h)
    local navButtons = {}
    navButtons[#navButtons + 1] = ui.button({
        glyph = "chevron-left",
        variant = (hourlyOffset > 0 and "outline" or "ghost"),
        controlSize = "sm",
        onClick = "onPrevHours",
        tooltip = tr("ui.hours_prev", "Ver 12 horas anteriores"),
    })

    for b = 1, numBlocks do
        local bOffset = (b - 1) * 12
        local bStart = bOffset + 1
        local bEnd = math.min(bOffset + 12, totalHourly)
        local bLabel = string.format("%d–%d h", bStart, bEnd)
        local isExact = (hourlyOffset == bOffset)
        local isInBlock = (hourlyOffset >= bOffset and (b == numBlocks or hourlyOffset < bOffset + 12))
        local btnVariant = isExact and "primary" or (isInBlock and "outline" or "ghost")
        local handler = "onBlockHours" .. tostring(b)

        navButtons[#navButtons + 1] = ui.button({
            text = bLabel,
            variant = btnVariant,
            controlSize = "sm",
            onClick = handler,
            tooltip = string.format(tr("ui.hours_block_tooltip", "Ver horas %d a %d"), bStart, bEnd),
        })
    end

    navButtons[#navButtons + 1] = ui.button({
        glyph = "chevron-right",
        variant = (hourlyOffset < maxOffset and "outline" or "ghost"),
        controlSize = "sm",
        onClick = "onNextHours",
        tooltip = tr("ui.hours_next", "Ver seguintes 12 horas"),
    })

    rootChildren[#rootChildren + 1] = ui.row({ gap = 8, align = "center" }, {
        -- Esquerda: Título da sección
        ui.row({ gap = 6, align = "center" }, {
            ui.glyph({ name = "clock", size = s.sectionIcon, color = "primary" }),
            ui.label({ text = tr("ui.hourly_title", "Por horas"), fontSize = s.sectionTitle, fontWeight = "bold", color = "on_surface" }),
        }),

        -- Espazador que empuxa o día cara o centro
        ui.spacer(),

        -- Centro: Día ou intervalo de días amosado (centrado e sen parénteses)
        ui.row({
            paddingH = 14,
            paddingV = 4,
            radius = 8,
            fill = "surface_variant/0.50",
            border = "outline/0.25",
            borderWidth = 1,
            align = "center",
            gap = 6,
        }, {
            ui.glyph({ name = "calendar", size = s.sectionSub + 1, color = "primary" }),
            ui.label({
                text = daysCovered,
                fontSize = s.sectionSub + 1,
                fontWeight = "bold",
                color = "on_surface",
            }),
        }),

        -- Espazador que empuxa os botóns cara a dereita
        ui.spacer(),

        -- Dereita: Controis de scroll / paxinación
        ui.row({ gap = 4, align = "center" }, navButtons),
    })

    -- Tarxetas horarias con separador visual no cambio de día
    local hourCards = {}

    -- Comprobar se hai cambio de día dentro do tramo visible
    local hasDayChange = false
    for idx = startIdx + 1, endIdx do
        local h = hourly[idx]
        local prev = hourly[idx - 1]
        if h and prev and h.day ~= prev.day then
            hasDayChange = true
            break
        end
    end

    -- Axuste da anchura de cada tarxeta para manter exactamente a grella de s.chartWidth
    local effectiveCardWidth = hasDayChange and (s.hourlyWidth - 2) or s.hourlyWidth

    for idx = startIdx, endIdx do
        local h = hourly[idx]
        if not h then break end

        -- Se hai cambio de día respecto á hora anterior, inserimos un separador discreto
        if idx > startIdx then
            local prevH = hourly[idx - 1]
            if prevH and h.day ~= prevH.day then
                local nextDayName = weekdaysFull[h.weekday] or ""
                local sepTooltip = string.format(tr("ui.day_change_hint", "Cambio de día: %s %d"), nextDayName, h.day)
                local lineH = math.floor(s.hourlyGlyph * 1.1)
                hourCards[#hourCards + 1] = ui.column({
                    width = 14,
                    align = "center",
                    justify = "center",
                    gap = 6,
                    paddingV = 6,
                    tooltip = sepTooltip,
                }, {
                    ui.box({ width = 2, height = lineH, fill = "secondary/0.45", radius = 1 }),
                    ui.glyph({ name = "calendar", size = 12, color = "secondary" }),
                    ui.box({ width = 2, height = lineH, fill = "secondary/0.45", radius = 1 }),
                })
            end
        end

        local isCurrent = (h.timestamp == currentHourSec) or (idx == 1 and hourlyOffset == 0)
        local isStartOfDay = (h.hourNum == 0)
        local cardBg = isCurrent and cardBgActive or cardBgNorm
        local cardBorder = isCurrent and "primary/0.60" or (isStartOfDay and "secondary/0.40" or "outline/0.25")

        local timeColor = "on_surface_variant"
        if isCurrent then
            timeColor = "primary"
        elseif isStartOfDay then
            timeColor = "secondary"
        end

        local dayName = weekdaysFull[h.weekday] or ""
        local atWord = isEn and "at" or "ás"
        local rainWord = isEn and "Rain" or "Choiva"
        local skyPart = (h.skyDesc and h.skyDesc ~= "") and (" · " .. h.skyDesc) or ""
        local windLine = formatWindTooltip(h.windDesc, h.windSpeed, isEn)
        local cardTooltip = string.format("%s, %d %s %s\n%d°C%s\n%s: %d%%\n%s",
            dayName, h.day or 0, atWord, h.time or "--:--",
            tonumber(h.temp) or 0, skyPart,
            rainWord, tonumber(h.rainProb) or 0,
            windLine)

        hourCards[#hourCards + 1] = ui.column({
            width = effectiveCardWidth,
            minWidth = effectiveCardWidth,
            gap = s.hourlyGap,
            align = "center",
            padding = s.hourlyPad,
            radius = 8,
            fill = cardBg,
            border = cardBorder,
            borderWidth = 1,
            tooltip = cardTooltip,
        }, {
            ui.label({
                text = h.time or "--:--",
                fontSize = s.hourlyTime,
                fontWeight = (isCurrent or isStartOfDay) and "bold" or "normal",
                color = timeColor,
            }),
            ui.glyph({
                name = h.glyph or "cloud",
                size = s.hourlyGlyph,
                color = h.color or "on_surface",
            }),
            ui.label({
                text = tostring(h.temp or 0) .. "°",
                fontSize = s.hourlyTemp,
                fontWeight = "bold",
                color = "on_surface",
            }),
            ui.row({ gap = 1, align = "center" }, {
                ui.glyph({ name = "droplet", size = s.hourlyRainIcon, color = "secondary" }),
                ui.label({
                    text = tostring(h.rainProb or 0) .. "%",
                    fontSize = s.hourlyRainText,
                    color = "secondary",
                }),
            }),
            ui.row({ gap = 2, align = "center" }, {
                ui.label({
                    text = getWindArrow(h.windDesc, tonumber(h.windSpeed) or 0),
                    fontSize = s.hourlyRainIcon,
                    fontWeight = "bold",
                    color = getWindColor(tonumber(h.windSpeed) or 0, isDark),
                }),
                ui.label({
                    text = tostring(h.windSpeed or 0),
                    fontSize = s.hourlyRainText,
                    fontWeight = "medium",
                    color = isDark and "#cbd5e1" or "#475569",
                }),
            }),
        })
    end

    rootChildren[#rootChildren + 1] = ui.row({
        gap = s.hourlyRowGap,
        align = "center",
        justify = "center",
    }, hourCards)
    end

    -- ── 3. RESUMO DIARIO (VINDEIROS DÍAS) ────────────────────────────────────
    local showDailySummary = noctalia.getConfig("show_daily_summary")
    if showDailySummary == nil then showDailySummary = true end
    local showDailyHourlyCurve = noctalia.getConfig("show_daily_hourly_curve")
    if showDailyHourlyCurve == nil then showDailyHourlyCurve = true end

    local dailyDays = weather.dailyDays or {}
    if showDailySummary and #dailyDays > 0 then
        rootChildren[#rootChildren + 1] = ui.separator()

        rootChildren[#rootChildren + 1] = ui.row({ gap = 6, align = "center" }, {
            ui.glyph({ name = "calendar", size = s.sectionIcon, color = "primary" }),
            ui.label({ text = tr("ui.daily_title", isEn and "Forecast" or "Resumo dos vindeiros días"), fontSize = s.sectionTitle, fontWeight = "bold", color = "on_surface" }),
        })

        local isDark = true
        if noctalia.isDarkMode ~= nil then
            isDark = (noctalia.isDarkMode() == true)
        end

        local colors = nil
        if noctalia.getColor ~= nil then
            colors = {
                surface = noctalia.getColor("surface"),
                surfaceVariant = noctalia.getColor("surface_variant"),
                onSurface = noctalia.getColor("on_surface"),
                onSurfaceVariant = noctalia.getColor("on_surface_variant"),
                outline = noctalia.getColor("outline"),
                primary = noctalia.getColor("primary"),
                secondary = noctalia.getColor("secondary"),
            }
        end

        local grayGreen = isDark and "#8f9690" or "#58605a"

        local chartSvg = shared.generateDailyChartSvg(dailyDays, s.chartWidth, s.chartHeight, {
            isEn = isEn,
            isXlarge = (s == SCALES["xlarge"]),
            todayLabel = tr("ui.today", "Hoxe"),
            tomorrowLabel = tr("ui.tomorrow", "Mañá"),
            isDark = isDark,
            colors = colors,
            hourly = weather.hourlyCurve or weather.hourly,
            yesterday = weather.yesterday,
            nextDay = weather.nextDay,
            showHourlyLine = showDailyHourlyCurve,
            nowTimestamp = os.time(),
            currentTemp = weather.current and weather.current.temp,
        })
        local themeSuffix = isDark and "dark" or "light"
        local chartPath = string.format("/tmp/meteogalicia_daily_trend_%s.svg", themeSuffix)
        noctalia.writeFile(chartPath, chartSvg)
        noctalia.writeFile("/tmp/meteogalicia_daily_trend.svg", chartSvg)

        local chartWidget = ui.image({
            path = chartPath,
            width = s.chartWidth,
            height = s.chartHeight,
        })

        -- ── 3.1. SELECTOR DISCRETO AO PÉ DO GRÁFICO (TIMELINE SINCRONIZADO) ──
        local curveHours = weather.hourlyCurve or weather.hourly or {}
        if showDailyHourlyCurve and #dailyDays > 0 and #curveHours > 0 then
            local padLeft = shared.CHART_PAD_LEFT or 48
            local padRight = shared.CHART_PAD_RIGHT or 52
            local nDays = #dailyDays
            local availW = s.chartWidth - padLeft - padRight
            local totalSlots = nDays * 24
            local hourW = availW / totalSlots
            local halfHourW = hourW / 2.0
            local leftSpacerW = padLeft - halfHourW
            local rightSpacerW = padRight + halfHourW

            local day0StartTs = 0
            if #curveHours > 0 and curveHours[1].timestamp then
                local firstTs = tonumber(curveHours[1].timestamp) or 0
                local firstH = tonumber(curveHours[1].hourNum) or tonumber(os.date("%H", firstTs)) or 0
                day0StartTs = firstTs - firstH * 3600
            elseif dailyDays[1] and dailyDays[1].year and dailyDays[1].year > 0 then
                day0StartTs = os.time({
                    year = dailyDays[1].year,
                    month = dailyDays[1].month,
                    day = dailyDays[1].day,
                    hour = 0,
                    min = 0,
                    sec = 0,
                })
            else
                local firstTs = tonumber(curveHours[1] and curveHours[1].timestamp) or os.time()
                local tParts = os.date("*t", firstTs)
                day0StartTs = os.time({ year = tParts.year, month = tParts.month, day = tParts.day, hour = 0, min = 0, sec = 0 })
            end

            -- Mapa de horas por timestamp con tolerancia de 30 minutos
            local curveByTs: { [number]: any } = {}
            for _, ch in ipairs(curveHours) do
                local cTs = tonumber(ch.timestamp)
                if cTs then
                    curveByTs[cTs] = ch
                end
            end

            local function findHour(targetTs: number): any
                local exact = curveByTs[targetTs]
                if exact then return exact end
                for cTs, item in pairs(curveByTs) do
                    if math.abs(cTs - targetTs) < 1800 then
                        return item
                    end
                end
                return nil
            end

            local timelineSlots = {}
            local atWord = isEn and "at" or "ás"
            local rainWord = isEn and "Rain" or "Choiva"

            for slotIdx = 0, totalSlots - 1 do
                local slotTs = day0StartTs + slotIdx * 3600
                local dayIdx = math.floor(slotIdx / 24) + 1
                local hNum = slotIdx % 24
                local isStartOfDay = (hNum == 0)

                local h = findHour(slotTs)
                local dRef = dailyDays[dayIdx]

                local tempVal = h and tonumber(h.temp) or (dRef and tonumber(dRef.tempMin) or 0)
                local rainProbVal = h and tonumber(h.rainProb) or (dRef and tonumber(dRef.rainProb) or 0)
                local skyDesc = h and h.skyDesc or (dRef and dRef.skyDesc or "")
                local skyPart = (skyDesc ~= "") and (" · " .. skyDesc) or ""

                local wday = h and h.weekday or (dRef and dRef.weekday or 0)
                local dayNum = h and h.day or (dRef and dRef.day or 0)
                local dayName = weekdaysFull[wday] or (dRef and (dRef.reach == 0 and tr("ui.today", "Hoxe") or (dRef.reach == 1 and tr("ui.tomorrow", "Mañá") or ""))) or ""
                local hTime = h and h.time or string.format("%02d:00", hNum)

                local isCurrent = (slotTs == currentHourSec) or (currentHourSec >= slotTs and currentHourSec < slotTs + 3600)
                local isMajor = (hNum % 6 == 0)

                local windVal = h and tonumber(h.windSpeed) or 0
                local windDesc = h and h.windDesc or (dRef and dRef.windDesc or "")
                local windLine = formatWindTooltip(windDesc, windVal, isEn)

                -- Tooltip estruturado en 4 liñas (Data, Temp/Ceo, Choiva, Vento)
                local tTip = string.format("%s, %d %s %s\n%d°C%s\n%s: %d%%\n%s",
                    dayName, dayNum, atWord, hTime,
                    tempVal, skyPart,
                    rainWord, rainProbVal,
                    windLine)

                -- Altura e deseño proporcional da barra de choiva
                local maxBarH = 20
                local barH = 2
                local barW = 3
                local barRadius = 1
                local barColor = isDark and "#334155" or "#94a3b8"

                if rainProbVal > 0 then
                    barH = math.max(3, math.floor((rainProbVal / 100.0) * maxBarH))
                    barW = 5.0
                    barRadius = 1.6
                    barColor = isDark and "#38bdf8" or "#0284c7"
                elseif isCurrent then
                    barH = 3.5
                    barW = 4
                    barRadius = 1.5
                    barColor = grayGreen
                elseif isStartOfDay and slotIdx > 0 then
                    barH = 5
                    barW = 2
                    barRadius = 1
                    barColor = isDark and "#64748b" or "#475569"
                end

                local clickHandler = function()
                    for oIdx, ph in ipairs(hourly) do
                        if ph.timestamp == slotTs then
                            local newOffset = math.max(0, math.min(oIdx - 1, maxOffset))
                            noctalia.state.set("hourly_offset", newOffset)
                            render()
                            return
                        end
                    end
                    if slotTs > currentHourSec then
                        noctalia.state.set("hourly_offset", maxOffset)
                        render()
                    end
                end

                local rainCol = ui.column({
                    height = maxBarH,
                    justify = "end",
                    align = "center",
                }, {
                    ui.box({
                        width = barW,
                        height = barH,
                        radius = barRadius,
                        fill = barColor,
                    }),
                })

                timelineSlots[#timelineSlots + 1] = ui.column({
                    flexGrow = 1,
                    height = maxBarH + 2,
                    align = "center",
                    justify = "end",
                    tooltip = tTip,
                    onClick = clickHandler,
                }, {
                    rainCol,
                })
            end

            -- Fila de etiquetas horarias con iconas do ceo e posicións exactas
            -- Detectar cambios meteorolóxicos para amosar iconas de xeito dinámico e contextual
            local nowIdx = nil
            if currentHourSec >= day0StartTs then
                local diffH = math.floor((currentHourSec - day0StartTs) / 3600)
                if diffH >= 0 and diffH < totalSlots then
                    nowIdx = diffH
                end
            end

            -- 1. Precalcular datos para cada franxa horaria
            type SlotInfo = {
                k: number,
                hNum: number,
                slotTs: number,
                glyph: string,
                glyphColor: string,
                windSpeed: number,
                windDesc: string,
                windArrow: string,
                isStartOfDay: boolean,
                tooltip: string,
                onClick: () -> (),
            }
            local slotInfo: { [number]: SlotInfo } = {}

            for k = 0, totalSlots - 1 do
                local hNum = k % 24
                local isStartOfDay = (hNum == 0)
                local slotTs = day0StartTs + k * 3600
                local dayIdx = math.floor(k / 24) + 1
                local h = findHour(slotTs)
                local dRef = dailyDays[dayIdx]

                local gName = "cloud"
                local gColor = "on_surface_variant"

                if h and h.glyph then
                    gName = h.glyph
                    gColor = h.color or (isDark and "#94a3b8" or "#64748b")
                elseif dRef then
                    local dg = dRef.glyph or "cloud"
                    local dc = dRef.color or "on_surface_variant"
                    if hNum < 7 or hNum >= 22 then
                        if dg == "sun" then
                            dg = "moon"
                            dc = "primary"
                        elseif dg == "cloud-sun" then
                            dg = "moon-stars"
                            dc = "primary"
                        end
                    end
                    gName = dg
                    gColor = dc
                end

                local tempVal = h and tonumber(h.temp) or (dRef and tonumber(dRef.tempMin) or 0)
                local rainProbVal = h and tonumber(h.rainProb) or (dRef and tonumber(dRef.rainProb) or 0)
                local skyDesc = h and h.skyDesc or (dRef and dRef.skyDesc or "")
                local skyPart = (skyDesc ~= "") and (" · " .. skyDesc) or ""
                local wday = h and h.weekday or (dRef and dRef.weekday or 0)
                local dayNum = h and h.day or (dRef and dRef.day or 0)
                local dayName = weekdaysFull[wday] or ""
                local hTime = h and h.time or string.format("%02d:00", hNum)

                local windVal = h and tonumber(h.windSpeed) or 0
                local windDesc = h and h.windDesc or (dRef and dRef.windDesc or "")
                local windArrow = getWindArrow(windDesc, windVal)
                local windLine = formatWindTooltip(windDesc, windVal, isEn)

                local tTip = string.format("%s, %d %s %s\n%d°C%s\n%s: %d%%\n%s",
                    dayName, dayNum, atWord, hTime,
                    tempVal, skyPart,
                    rainWord, rainProbVal,
                    windLine)

                local lblClickHandler = function()
                    for oIdx, ph in ipairs(hourly) do
                        if ph.timestamp == slotTs then
                            local newOffset = math.max(0, math.min(oIdx - 1, maxOffset))
                            noctalia.state.set("hourly_offset", newOffset)
                            render()
                            return
                        end
                    end
                    if slotTs > currentHourSec then
                        noctalia.state.set("hourly_offset", maxOffset)
                        render()
                    end
                end

                slotInfo[k] = {
                    k = k,
                    hNum = hNum,
                    slotTs = slotTs,
                    glyph = gName,
                    glyphColor = gColor,
                    windSpeed = windVal,
                    windDesc = windDesc,
                    windArrow = windArrow,
                    isStartOfDay = isStartOfDay,
                    tooltip = tTip,
                    onClick = lblClickHandler,
                }
            end

            -- 2. Identificar intervalos continuos do mesmo estado do ceo (runs)
            type RunItem = {
                glyph: string,
                startK: number,
                endK: number,
            }
            local runs: { RunItem } = {}
            local currGlyph = nil
            local currStart = 0
            for k = 0, totalSlots - 1 do
                local g = slotInfo[k].glyph
                if g ~= currGlyph then
                    if currGlyph ~= nil then
                        runs[#runs + 1] = { glyph = currGlyph, startK = currStart, endK = k - 1 }
                    end
                    currGlyph = g
                    currStart = k
                end
            end
            if currGlyph ~= nil then
                runs[#runs + 1] = { glyph = currGlyph, startK = currStart, endK = totalSlots - 1 }
            end

            -- 3. Xerar candidatos con prioridade segundo a importancia meteorolóxica
            type Candidate = {
                priority: number,
                k: number,
                isNow: boolean,
                runIdx: number,
            }
            local candidates: { Candidate } = {}

            -- Candidato prioritario: Agora
            if nowIdx ~= nil and nowIdx >= 0 and nowIdx < totalSlots then
                candidates[#candidates + 1] = {
                    priority = 1000,
                    k = nowIdx,
                    isNow = true,
                    runIdx = -1,
                }
            end

            -- Candidatos nos puntos de cambio de tempo
            for rIdx, run in ipairs(runs) do
                local g = run.glyph
                local w = 60
                if string.find(g, "storm") or string.find(g, "thunder") then
                    w = 250
                elseif string.find(g, "rain") or string.find(g, "snow") or string.find(g, "snowflake") then
                    w = 200
                elseif string.find(g, "sun") or string.find(g, "cloud") or string.find(g, "fog") then
                    w = 100
                end

                candidates[#candidates + 1] = {
                    priority = 50 + w,
                    k = run.startK,
                    isNow = false,
                    runIdx = rIdx,
                }
                -- Se a franxa é longa e hai conflito co inicio, propoñer o seguinte punto coma alternativa
                if run.endK > run.startK then
                    candidates[#candidates + 1] = {
                        priority = 45 + w,
                        k = run.startK + 1,
                        isNow = false,
                        runIdx = rIdx,
                    }
                end
            end

            -- Candidatos de cambio de día (00h)
            for k = 1, totalSlots - 1 do
                if slotInfo[k].hNum == 0 then
                    candidates[#candidates + 1] = {
                        priority = 110,
                        k = k,
                        isNow = false,
                        runIdx = -2,
                    }
                end
            end

            table.sort(candidates, function(a, b)
                return a.priority > b.priority
            end)

            -- 4. Resolución de conflitos de espazo (mínimo 2 slots = ~26px de separación)
            local minSlots = 2
            local acceptedSlots: { [number]: boolean } = {}
            local acceptedRuns: { [number]: boolean } = {}
            local acceptedList: { Candidate } = {}

            for _, cand in ipairs(candidates) do
                if not (cand.runIdx > 0 and acceptedRuns[cand.runIdx]) then
                    local conflict = false
                    for ak, _ in pairs(acceptedSlots) do
                        if math.abs(ak - cand.k) < minSlots then
                            conflict = true
                            break
                        end
                    end
                    if not conflict then
                        acceptedSlots[cand.k] = true
                        if cand.runIdx > 0 then
                            acceptedRuns[cand.runIdx] = true
                        end
                        acceptedList[#acceptedList + 1] = cand
                    end
                end
            end

            table.sort(acceptedList, function(a, b)
                return a.k < b.k
            end)

            -- 5. Encher ocos longos (se hai >= 8 horas continuas sen ningún marcador)
            local filledList: { Candidate } = {}
            for _, item in ipairs(acceptedList) do
                filledList[#filledList + 1] = item
            end

            local gapIdx = 1
            while gapIdx < #filledList do
                local k1 = filledList[gapIdx].k
                local k2 = filledList[gapIdx + 1].k
                if k2 - k1 >= 8 then
                    local midIdeal = math.floor((k1 + k2) / 2)
                    local bestK = nil
                    local bestScore = -999
                    for candK = k1 + minSlots, k2 - minSlots do
                        local h = slotInfo[candK].hNum
                        local score = 100 - math.abs(candK - midIdeal)
                        if h % 6 == 0 then
                            score = score + 50
                        elseif h % 3 == 0 then
                            score = score + 20
                        end
                        if score > bestScore then
                            bestScore = score
                            bestK = candK
                        end
                    end
                    if bestK ~= nil then
                        table.insert(filledList, gapIdx + 1, {
                            priority = 30,
                            k = bestK,
                            isNow = false,
                            runIdx = -3,
                        })
                    else
                        gapIdx = gapIdx + 1
                    end
                else
                    gapIdx = gapIdx + 1
                end
            end

            -- 6. Construír a lista de etiquetas finais
            local labelsList = {}
            for _, item in ipairs(filledList) do
                if item.isNow then
                    local nowTs = day0StartTs + nowIdx * 3600
                    local nowH = findHour(currentHourSec) or findHour(nowTs)
                    local curGName = (cur and cur.glyph) or (nowH and nowH.glyph) or "cloud-sun"
                    local curGColor = getTimelineGlyphColor(curGName, isDark)

                    local nowTemp = (cur and cur.temp) or (nowH and nowH.temp) or 0
                    local nowRain = (nowH and nowH.rainProb) or (weather.rainProb or 0)
                    local nowSky = (cur and cur.skyDesc) or (nowH and nowH.skyDesc) or ""
                    local nowSkyPart = (nowSky ~= "") and (" · " .. nowSky) or ""
                    local nowWday = nowH and nowH.weekday or tonumber(os.date("%w", currentHourSec)) or 0
                    local nowDayNum = nowH and nowH.day or tonumber(os.date("%d", currentHourSec)) or 0
                    local nowDayName = weekdaysFull[nowWday] or ""
                    local nowTime = nowH and nowH.time or os.date("%H:%M", currentHourSec)

                    local nowWindVal = (cur and tonumber(cur.windSpeed)) or (nowH and tonumber(nowH.windSpeed)) or 0
                    local nowWindDesc = (cur and cur.windDesc) or (nowH and nowH.windDesc) or ""
                    local nowWindArrow = getWindArrow(nowWindDesc, nowWindVal)
                    local nowWindLine = formatWindTooltip(nowWindDesc, nowWindVal, isEn)

                    local nowTooltip = string.format("%s, %d %s %s\n%d°C%s\n%s: %d%%\n%s",
                        nowDayName, nowDayNum, atWord, nowTime,
                        nowTemp, nowSkyPart,
                        rainWord, nowRain,
                        nowWindLine)

                    local nowWindLabel = (nowWindArrow == "•") and "0" or string.format("%s %d", nowWindArrow, nowWindVal)
                    local nowWindColor = getWindColor(nowWindVal, isDark)

                    labelsList[#labelsList + 1] = {
                        x = padLeft + nowIdx * hourW,
                        text = isEn and "Now" or "Agora",
                        fontSize = 9.5,
                        fontWeight = "bold",
                        color = isDark and "#38bdf8" or "#0284c7",
                        glyph = curGName,
                        glyphColor = curGColor,
                        windLabel = nowWindLabel,
                        windColor = nowWindColor,
                        tooltip = nowTooltip,
                        onClick = function()
                            noctalia.state.set("hourly_offset", 0)
                            render()
                        end,
                    }
                else
                    local sData = slotInfo[item.k]
                    local isStartOfDay = sData.isStartOfDay
                    local lblColor = (isStartOfDay and item.k > 0)
                        and (isDark and "#f8fafc" or "#0f172a")
                        or (isDark and "#cbd5e1" or "#334155")
                    local lblWeight = (isStartOfDay and item.k > 0) and "bold" or "medium"

                    local windLabel = (sData.windArrow == "•") and "0" or string.format("%s %d", sData.windArrow, sData.windSpeed)
                    local windColor = getWindColor(sData.windSpeed, isDark)

                    labelsList[#labelsList + 1] = {
                        x = padLeft + item.k * hourW,
                        text = string.format("%02dh", sData.hNum),
                        fontSize = 9.0,
                        fontWeight = lblWeight,
                        color = lblColor,
                        glyph = sData.glyph,
                        glyphColor = getTimelineGlyphColor(sData.glyph, isDark),
                        windLabel = windLabel,
                        windColor = windColor,
                        tooltip = sData.tooltip,
                        onClick = sData.onClick,
                    }
                end
            end

            table.sort(labelsList, function(a, b)
                return a.x < b.x
            end)

            local labelWidgets = {}
            local lblWidth = 26
            local currentX = 0

            for _, lbl in ipairs(labelsList) do
                local targetLeft = lbl.x - lblWidth / 2.0
                local gap = math.max(0, targetLeft - currentX)
                if gap > 0 then
                    labelWidgets[#labelWidgets + 1] = ui.box({ width = gap, height = 1, fill = "#00000000" })
                end
                labelWidgets[#labelWidgets + 1] = ui.column({
                    width = lblWidth,
                    justify = "center",
                    align = "center",
                    gap = 2,
                    tooltip = lbl.tooltip,
                    onClick = lbl.onClick,
                }, {
                    ui.glyph({
                        name = lbl.glyph or "cloud",
                        size = 16,
                        color = lbl.glyphColor or lbl.color,
                    }),
                    ui.label({
                        text = lbl.windLabel or "",
                        fontSize = 8.5,
                        fontWeight = "bold",
                        color = lbl.windColor or "on_surface_variant",
                    }),
                    ui.label({
                        text = lbl.text,
                        fontSize = lbl.fontSize,
                        fontWeight = lbl.fontWeight,
                        color = lbl.color,
                    }),
                })
                currentX = currentX + gap + lblWidth
            end

            local finalGap = s.chartWidth - currentX
            if finalGap > 0 then
                labelWidgets[#labelWidgets + 1] = ui.box({ width = finalGap, height = 1, fill = "#00000000" })
            end

            local labelsRow = ui.row({
                width = s.chartWidth,
                align = "center",
                gap = 0,
            }, labelWidgets)

            local selectorHeader = ui.row({
                paddingH = 16,
                gap = 8,
                align = "center",
            }, {
                ui.row({ gap = 5, align = "center" }, {
                    ui.box({ width = 6, height = 6, radius = 3, fill = isDark and "#38bdf8" or "#0284c7" }),
                    ui.label({
                        text = tr("ui.rain_probability", isEn and "Rain" or "Choiva"),
                        fontSize = s.sectionSub,
                        fontWeight = "bold",
                        color = "on_surface",
                    }),
                }),
                ui.label({
                    text = "·",
                    fontSize = s.sectionSub,
                    color = "outline",
                }),
                ui.row({ gap = 5, align = "center" }, {
                    ui.glyph({
                        name = "wind",
                        size = 13,
                        color = isDark and "#94a3b8" or "#475569",
                    }),
                    ui.label({
                        text = isEn and "Wind (km/h)" or "Vento (km/h)",
                        fontSize = s.sectionSub,
                        fontWeight = "bold",
                        color = "on_surface_variant",
                    }),
                }),
            })

            local timelineRow = ui.row({
                width = s.chartWidth,
                align = "center",
                gap = 0,
            }, {
                ui.box({ width = leftSpacerW, height = 1, fill = "#00000000" }),
                ui.row({
                    width = availW,
                    align = "center",
                    gap = 0,
                }, timelineSlots),
                ui.box({ width = rightSpacerW, height = 1, fill = "#00000000" }),
            })

            local timelineCard = ui.column({
                width = s.chartWidth,
                paddingV = 7,
                radius = 10,
                fill = isDark and "#141720" or (colors and colors.surfaceVariant or "#e9efef"),
                border = isDark and "#252b3b" or (colors and colors.outline or "#cbd5e1"),
                borderWidth = 1,
                gap = 4,
            }, {
                selectorHeader,
                timelineRow,
                labelsRow,
            })

            -- ── 3.2. BARRA HORIZONTAL DÍA / NOITE SINCRONIZADA ──
            local barHeight = (s == SCALES["xlarge"]) and 20 or ((s == SCALES["large"]) and 18 or 16)
            local sunGlyphSize = (s == SCALES["xlarge"]) and 12 or ((s == SCALES["large"]) and 11 or 10)
            local leafGlyphSize = (s == SCALES["xlarge"]) and 11 or ((s == SCALES["large"]) and 10 or 9)
            local moonGlyphSize = (s == SCALES["xlarge"]) and 11 or ((s == SCALES["large"]) and 10 or 9)
            local barFontSize = (s == SCALES["xlarge"]) and 9.5 or ((s == SCALES["large"]) and 9.0 or 8.5)

            local nightTrackFill = isDark and "#151b27" or "#334155"
            local nightTrackBorder = isDark and "#232b3e" or "#475569"
            local nightMoonColor = isDark and "#7dd3fc" or "#cbd5e1"
            local dayBorderLine = isDark and "#252e42" or "#475569"

            local dayFill = isDark and "#d97706" or "#fef08a"
            local dayBorder = isDark and "#f59e0b" or "#eab308"
            local dayTextColor = isDark and "#fef3c7" or "#78350f"
            local dayIconColor = isDark and "#fde047" or "#b45309"
            local daySepColor = isDark and "#fbbf24" or "#d97706"

            local colW = availW / nDays
            local trackChildren = {}

            local function parseTimeToHours(timeStr: string?): number
                if type(timeStr) ~= "string" then return 12.0 end
                local h, m = timeStr:match("(%d+):(%d+)")
                if h and m then
                    return tonumber(h) + tonumber(m) / 60.0
                end
                return 12.0
            end

            for i = 1, nDays do
                local d = dailyDays[i]
                local dayMidTs = day0StartTs + (i - 1) * 86400 + 43200
                local sRiseStr, sSetStr = shared.calcSolar(today.latitude, today.longitude, dayMidTs)
                local riseH = parseTimeToHours(sRiseStr)
                local setH = parseTimeToHours(sSetStr)

                local n1W = (riseH / 24.0) * colW
                local dayW = ((setH - riseH) / 24.0) * colW
                local n2W = colW - n1W - dayW
                if i < nDays then
                    n2W = n2W - 1
                end

                local dayDurationH = setH - riseH
                local dayDurHours = math.floor(dayDurationH)
                local dayDurMins = math.floor((dayDurationH - dayDurHours) * 60 + 0.5)

                local nightDurationH = 24.0 - dayDurationH
                local nightDurHours = math.floor(nightDurationH)
                local nightDurMins = math.floor((nightDurationH - nightDurHours) * 60 + 0.5)

                local icaShort = isEn and "Good" or "Boa"
                local icaFull = isEn and "Good (ICA 1)" or "Favorable (ICA 1)"
                if d.ica and d.ica >= 4 then
                    icaShort = isEn and "V.Poor" or "M.Mala"
                    icaFull = isEn and "Very poor (ICA 4)" or "Moi mala (ICA 4)"
                elseif d.ica and d.ica >= 3 then
                    icaShort = isEn and "Poor" or "Mala"
                    icaFull = isEn and "Poor (ICA 3)" or "Mala (ICA 3)"
                elseif d.ica and d.ica >= 2 then
                    icaShort = isEn and "Fair" or "Razoable"
                    icaFull = isEn and "Fair (ICA 2)" or "Razoable (ICA 2)"
                end

                local uvRiskStr = ""
                if d.uv and d.uv > 0 then
                    if d.uv >= 11 then
                        uvRiskStr = isEn and " (Extreme)" or " (Extremo)"
                    elseif d.uv >= 8 then
                        uvRiskStr = isEn and " (Very high)" or " (Moi alto)"
                    elseif d.uv >= 6 then
                        uvRiskStr = isEn and " (High)" or " (Alto)"
                    elseif d.uv >= 3 then
                        uvRiskStr = isEn and " (Moderate)" or " (Moderado)"
                    else
                        uvRiskStr = isEn and " (Low)" or " (Baixo)"
                    end
                end

                local dayName = weekdaysFull[d.weekday] or (d.reach == 0 and tr("ui.today", "Hoxe") or (d.reach == 1 and tr("ui.tomorrow", "Mañá") or ""))
                local monthName = monthsTable[d.month] or ""
                local dateStr = (d.day and d.day > 0) and string.format("%d %s", d.day, monthName) or ""
                local headerStr = (dateStr ~= "") and string.format("%s, %s", dayName, dateStr) or dayName

                local dayTooltip = string.format("%s\n☀️ %s: %s → %s (%dh %02dm)\n🔆 %s: %s\n🍃 %s: %s",
                    headerStr,
                    isEn and "Daylight" or "Horas de sol", sRiseStr, sSetStr, dayDurHours, dayDurMins,
                    isEn and "Max UV Index" or "Radiación UV máx", (d.uv and d.uv > 0) and (tostring(d.uv) .. uvRiskStr) or (isEn and "Not available" or "Non dispoñible"),
                    isEn and "Air Quality" or "Calidade do aire", (d.ica and d.ica > 0) and icaFull or (isEn and "Not available" or "Non dispoñible"))

                local nightTooltip = string.format("%s\n🌙 %s: %s → %s (%dh %02dm)\n🍃 %s: %s",
                    headerStr,
                    isEn and "Night hours" or "Horas de noite", sSetStr, sRiseStr, nightDurHours, nightDurMins,
                    isEn and "Air Quality" or "Calidade do aire", (d.ica and d.ica > 0) and icaFull or (isEn and "Not available" or "Non dispoñible"))

                local dayClickHandler = function()
                    local targetOffset = math.max(0, math.min((i - 1) * 12, maxOffset))
                    noctalia.state.set("hourly_offset", targetOffset)
                    render()
                end

                local n1Children = {}
                if n1W >= 30 then
                    n1Children[#n1Children + 1] = ui.glyph({ name = "moon", size = moonGlyphSize, color = nightMoonColor })
                end
                trackChildren[#trackChildren + 1] = ui.row({
                    width = n1W,
                    height = barHeight,
                    align = "center",
                    justify = "center",
                    tooltip = nightTooltip,
                }, n1Children)

                local dayChildren = {}
                dayChildren[#dayChildren + 1] = ui.glyph({ name = "sun", size = sunGlyphSize, color = dayIconColor })
                if d.uv and d.uv > 0 then
                    dayChildren[#dayChildren + 1] = ui.label({
                        text = "UV " .. tostring(d.uv),
                        fontSize = barFontSize,
                        fontWeight = "bold",
                        color = dayTextColor,
                    })
                    if d.ica and d.ica > 0 then
                        dayChildren[#dayChildren + 1] = ui.label({ text = "·", fontSize = barFontSize, color = daySepColor })
                        dayChildren[#dayChildren + 1] = ui.glyph({ name = "leaf", size = leafGlyphSize, color = dayIconColor })
                        dayChildren[#dayChildren + 1] = ui.label({
                            text = icaShort,
                            fontSize = barFontSize,
                            fontWeight = "bold",
                            color = dayTextColor,
                        })
                    end
                else
                    dayChildren[#dayChildren + 1] = ui.label({
                        text = string.format("%s → %s", sRiseStr, sSetStr),
                        fontSize = barFontSize,
                        fontWeight = "medium",
                        color = dayTextColor,
                    })
                end

                trackChildren[#trackChildren + 1] = ui.row({
                    width = dayW,
                    height = barHeight - 2,
                    radius = math.floor((barHeight - 2) / 2),
                    fill = dayFill,
                    border = dayBorder,
                    borderWidth = 1,
                    align = "center",
                    justify = "center",
                    gap = 5,
                    tooltip = dayTooltip,
                    onClick = dayClickHandler,
                }, dayChildren)

                local n2Children = {}
                if n2W >= 30 then
                    n2Children[#n2Children + 1] = ui.glyph({ name = "moon", size = moonGlyphSize, color = nightMoonColor })
                end
                trackChildren[#trackChildren + 1] = ui.row({
                    width = n2W,
                    height = barHeight,
                    align = "center",
                    justify = "center",
                    tooltip = nightTooltip,
                }, n2Children)

                if i < nDays then
                    trackChildren[#trackChildren + 1] = ui.box({
                        width = 1,
                        height = barHeight - 6,
                        fill = dayBorderLine,
                        radius = 0.5,
                    })
                end
            end

            local dayNightBar = ui.row({
                width = s.chartWidth,
                align = "center",
                gap = 0,
            }, {
                ui.box({ width = padLeft, height = 1, fill = "#00000000" }),
                ui.row({
                    width = availW,
                    height = barHeight,
                    radius = math.floor(barHeight / 2),
                    fill = nightTrackFill,
                    border = nightTrackBorder,
                    borderWidth = 1,
                    align = "center",
                    gap = 0,
                }, trackChildren),
                ui.box({ width = padRight, height = 1, fill = "#00000000" }),
            })

            rootChildren[#rootChildren + 1] = ui.column({
                width = s.chartWidth,
                gap = 6,
                align = "center",
            }, {
                chartWidget,
                timelineCard,
                dayNightBar,
            })
        else
            rootChildren[#rootChildren + 1] = chartWidget
        end
    end

    -- ── 4. COMENTARIO OFICIAL DE METEOGALICIA ─────────────────────────────────
    if today.comment and today.comment ~= "" then
        rootChildren[#rootChildren + 1] = ui.separator()
        rootChildren[#rootChildren + 1] = ui.row({ gap = 6, align = "center" }, {
            ui.glyph({ name = "message-report", size = s.sectionIcon, color = "primary" }),
            ui.label({ text = tr("ui.comment_title", "Comentario oficial de MeteoGalicia"), fontSize = s.commentTitle, fontWeight = "bold", color = "on_surface" }),
        })

        rootChildren[#rootChildren + 1] = ui.column({
            padding = s.commentPad,
            radius = 8,
            fill = commentaryBg,
            border = "outline/0.25",
            borderWidth = 1,
        }, {
            ui.label({
                text = today.comment,
                fontSize = s.commentText,
                color = "on_surface",
            }),
        })
    end

    -- ── 5. BADGES INFORMATIVOS E PE DE PÁXINA ─────────────────────────────────
    rootChildren[#rootChildren + 1] = ui.separator()

    local indicators = {}

    -- Índice UV
    if today.uv and today.uv > 0 then
        indicators[#indicators + 1] = ui.row({ gap = 4, align = "center" }, {
            ui.glyph({ name = "sun-high", size = s.footerIcon, color = "tertiary" }),
            ui.label({ text = (isEn and "Max UV index: " or "Índice UV máx: ") .. tostring(today.uv), fontSize = s.footerText, color = "on_surface_variant" }),
        })
    end

    -- Estación meteorolóxica máis próxima (para humidade real)
    if cur.stationName and cur.stationName ~= "" then
        indicators[#indicators + 1] = ui.row({ gap = 4, align = "center" }, {
            ui.glyph({ name = "map-pin", size = s.footerIcon, color = "secondary" }),
            ui.label({ text = (isEn and "Station: " or "Estación: ") .. cur.stationName, fontSize = s.footerText, color = "on_surface_variant" }),
        })
    end

    -- Hora de actualización
    if weather.updatedAt then
        indicators[#indicators + 1] = ui.row({ gap = 4, align = "center" }, {
            ui.glyph({ name = "clock", size = s.footerIcon, color = "on_surface_variant" }),
            ui.label({ text = (isEn and "Updated: " or "Actualizado: ") .. tostring(weather.updatedAt), fontSize = s.footerText, color = "on_surface_variant" }),
        })
    end

    local footerRow = ui.row({ gap = 16, align = "center" }, {
        ui.row({ gap = 14, align = "center" }, indicators),
        ui.spacer(),
        ui.button({
            text = tr("ui.open_web", "MeteoGalicia"),
            glyph = "external-link",
            variant = "outline",
            controlSize = s.btnSize,
            onClick = "onOpenWeb",
        }),
    })

    rootChildren[#rootChildren + 1] = footerRow

    panel.render(ui.column({
        gap = s.panelGap,
        padding = s.panelPadding,
        fill = rootFill,
        radius = 16,
        border = "outline/0.25",
        borderWidth = 1,
        flexGrow = 1,
    }, rootChildren))
end

-- Rexistro de estado reactivo
noctalia.state.watch("weather", function(val)
    weather = val
    weatherError = nil
    render()
end)

noctalia.state.watch("weather_error", function(val)
    weatherError = val
    render()
end)

noctalia.state.watch("weather_loading", function(val)
    isLoading = val == true
    render()
end)

noctalia.state.watch("hourly_offset", function()
    render()
end)

function onOpen()
    weather = noctalia.state.get("weather")
    weatherError = noctalia.state.get("weather_error")
    noctalia.state.set("hourly_offset", 0)
    render()
end

weather = noctalia.state.get("weather")
weatherError = noctalia.state.get("weather_error")
render()
