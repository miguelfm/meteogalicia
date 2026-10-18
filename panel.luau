--!strict
-- Detailed weather panel for MeteoGalicia.
-- Shows current conditions, horizontal hourly forecast cards,
-- upcoming daily summary, official forecaster commentary, and meteorological indicators.

local shared = require("./shared.luau")

local weather = nil
local weatherError = nil
local isLoading = false
local render: () -> () = function() end

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
        panelPadding = 22,
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
        hourlyWidth = 92,
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
        chartWidth = 1214,
        chartHeight = 260,
        commentTitle = 13,
        commentText = 12,
        commentPad = 12,
        footerIcon = 14,
        footerText = 12,
        btnSize = "sm",
    },
    large = {
        panelPadding = 22,
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
        hourlyWidth = 92,
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
        chartWidth = 1214,
        chartHeight = 280,
        commentTitle = 15,
        commentText = 14,
        commentPad = 14,
        footerIcon = 16,
        footerText = 14,
        btnSize = "md",
    },
    xlarge = {
        panelPadding = 22,
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
        hourlyWidth = 92,
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
        chartWidth = 1214,
        chartHeight = 300,
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

function onKey(chord: string?, pressed: boolean)
    if not pressed then return end
    local raw = tostring(chord or "")
    local lower = raw:lower()
    local cleanKey = lower:gsub("[_%s%-]", "")

    if cleanKey == "escape" then
        if type(panel.close) == "function" then panel.close() end
    elseif cleanKey == "r" then
        onRefresh()
    elseif cleanKey == "s" or cleanKey == "c" then
        onOpenSettings()
    elseif cleanKey == "left" or cleanKey == "arrowleft" or cleanKey == "[" or cleanKey == "bracketleft" or cleanKey:find("%+left$") ~= nil then
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

    local rootChildren = {}

    -- ── 1. CABECEIRA PRINCIPAL ───────────────────────────────────────────────
    local sunrise = today.sunrise
    local sunset = today.sunset
    if not sunrise or not sunset then
        local r, s_time = shared.calcSolar(today.latitude, today.longitude, os.time())
        sunrise = sunrise or r
        sunset = sunset or s_time
    end

    local makeSolarCard = function(iconName, iconColor, labelText, timeText)
        return ui.row({
            gap = math.max(8, math.floor(s.headerSunGap * 0.6)),
            align = "center",
            paddingH = s.headerSunPadH,
            paddingV = s.headerSunPadV,
            radius = 12,
            fill = cardBgNorm,
            border = "outline/0.25",
            borderWidth = 1,
            tooltip = tr("ui.solar_tooltip", "Horarios solares: Orto (amencer) e Ocaso (solpor)"),
        }, {
            ui.glyph({
                name = iconName,
                size = s.headerSunIcon,
                color = iconColor,
            }),
            ui.column({ gap = 2 }, {
                ui.label({
                    text = labelText,
                    fontSize = s.headerSunText,
                    color = "on_surface_variant",
                }),
                ui.label({
                    text = timeText,
                    fontSize = s.headerSunTime,
                    fontWeight = "bold",
                    color = "on_surface",
                }),
            }),
        })
    end

    local solarCards = ui.row({ gap = 12, align = "center" }, {
        makeSolarCard("weather-sunrise", "tertiary", tr("ui.sunrise", "Orto"), sunrise),
        makeSolarCard("weather-sunset", "secondary", tr("ui.sunset", "Ocaso"), sunset),
    })

    local headerRow = ui.row({ gap = 16, align = "center" }, {
        ui.glyph({
            name = cur.glyph or "cloud-sun",
            size = s.headerGlyph,
            color = cur.color or "primary",
        }),
        ui.column({ gap = 3 }, {
            ui.label({
                text = weather.officialName or weather.concelloName or "Fene",
                fontSize = s.headerTown,
                fontWeight = "bold",
                color = "on_surface",
            }),
            ui.label({
                text = cur.skyDesc or "Predición diaria",
                fontSize = s.headerDesc,
                color = "on_surface_variant",
            }),
        }),
        ui.spacer(),
        solarCards,
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
    rootChildren[#rootChildren + 1] = ui.separator()

    -- ── 2. PREDICIÓN POR HORAS (ATA 48 HORAS) ────────────────────────────────
    local hourlyOffset = tonumber(noctalia.state.get("hourly_offset")) or 0
    local totalHourly = math.min(hoursLimit, #hourly)
    local numBlocks = math.max(1, math.ceil(totalHourly / 12))
    local maxOffset = math.max(0, totalHourly - 12)
    if hourlyOffset > maxOffset then
        hourlyOffset = maxOffset
    end

    local isEn = (tr("ui.today", "Hoxe") == "Today")
    local weekdaysShort = isEn and shared.WEEKDAYS_SHORT_EN or shared.WEEKDAYS_SHORT_GL
    local weekdaysFull = isEn and shared.WEEKDAYS_EN or shared.WEEKDAYS_GL
    local monthsTable = isEn and shared.MONTHS_FULL_EN or shared.MONTHS_FULL_GL

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
    local currentHourSec = math.floor(os.time() / 3600) * 3600

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

    -- Axuste da anchura de cada tarxeta para manter exactamente a grella de 1214px
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
        local cardTooltip = dayName .. ", " .. tostring(h.day) .. " ás " .. (h.time or "--:--") .. " · " .. (h.skyDesc or "") .. " · " .. tostring(h.temp or 0) .. "°C"

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
        })
    end

    rootChildren[#rootChildren + 1] = ui.row({
        gap = s.hourlyRowGap,
        align = "center",
        justify = "center",
    }, hourCards)

    -- ── 3. RESUMO DIARIO (VINDEIROS DÍAS) ────────────────────────────────────
    local showDailySummary = noctalia.getConfig("show_daily_summary")
    if showDailySummary == nil then showDailySummary = true end

    local dailyDays = weather.dailyDays or {}
    if showDailySummary and #dailyDays > 0 then
        rootChildren[#rootChildren + 1] = ui.separator()

        rootChildren[#rootChildren + 1] = ui.row({ gap = 6, align = "center" }, {
            ui.glyph({ name = "calendar", size = s.sectionIcon, color = "primary" }),
            ui.label({ text = tr("ui.daily_title", "Resumo dos vindeiros días"), fontSize = s.sectionTitle, fontWeight = "bold", color = "on_surface" }),
        })

        local chartSvg = shared.generateDailyChartSvg(dailyDays, s.chartWidth, s.chartHeight, {
            isEn = isEn,
            isXlarge = (s == SCALES["xlarge"]),
            todayLabel = tr("ui.today", "Hoxe"),
            tomorrowLabel = tr("ui.tomorrow", "Mañá"),
        })
        local chartPath = "/tmp/meteogalicia_daily_trend.svg"
        noctalia.writeFile(chartPath, chartSvg)

        rootChildren[#rootChildren + 1] = ui.image({
            path = chartPath,
            width = s.chartWidth,
            height = s.chartHeight,
        })
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

    -- Vento
    indicators[#indicators + 1] = ui.row({ gap = 4, align = "center" }, {
        ui.glyph({ name = "wind", size = s.footerIcon, color = "primary" }),
        ui.label({ text = (cur.windDesc ~= "" and cur.windDesc or "Vento") .. " (" .. tostring(cur.windSpeed) .. " km/h)", fontSize = s.footerText, color = "on_surface_variant" }),
    })

    -- Calidade do aire (ICA)
    if today.ica and today.ica > 0 then
        local icaDesc = "Favorable"
        local icaColor = "secondary"
        if today.ica >= 4 then
            icaDesc = "Moi mala"
            icaColor = "error"
        elseif today.ica >= 3 then
            icaDesc = "Mala"
            icaColor = "secondary"
        end

        indicators[#indicators + 1] = ui.row({ gap = 4, align = "center" }, {
            ui.glyph({ name = "leaf", size = s.footerIcon, color = icaColor }),
            ui.label({ text = "Calidade do aire: " .. icaDesc, fontSize = s.footerText, color = icaColor }),
        })
    end

    -- Índice UV
    if today.uv and today.uv > 0 then
        indicators[#indicators + 1] = ui.row({ gap = 4, align = "center" }, {
            ui.glyph({ name = "sun-high", size = s.footerIcon, color = "tertiary" }),
            ui.label({ text = "Índice UV máx: " .. tostring(today.uv), fontSize = s.footerText, color = "on_surface_variant" }),
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
