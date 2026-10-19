--!strict
-- Detailed weather panel for MeteoGalicia.
-- Shows current conditions, interactive 48h hourly forecast with keyboard/scroll navigation,
-- upcoming days forecast with continuous SVG temperature & rain chart, official commentary, and indicators.

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
        hourlyWidth = 104,
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
        chartWidth = 1358,
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
        hourlyWidth = 104,
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
        chartWidth = 1358,
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
        hourlyWidth = 104,
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
        chartWidth = 1358,
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

    -- Variables comúns para a predición horaria e diaria
    local currentHourSec = math.floor(os.time() / 3600) * 3600
    local isEn = (tr("ui.today", "Hoxe") == "Today")
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
        local cardTooltip = string.format("%s, %d %s %s\n%d°C%s\n%s: %d%%",
            dayName, h.day or 0, atWord, h.time or "--:--",
            tonumber(h.temp) or 0, skyPart,
            rainWord, tonumber(h.rainProb) or 0)

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
            ui.label({ text = tr("ui.daily_title", "Resumo dos vindeiros días"), fontSize = s.sectionTitle, fontWeight = "bold", color = "on_surface" }),
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

        local grayGreen = isDark and "#829f90" or "#4a6b63"

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
            if dailyDays[1] and dailyDays[1].year and dailyDays[1].year > 0 then
                day0StartTs = os.time({
                    year = dailyDays[1].year,
                    month = dailyDays[1].month,
                    day = dailyDays[1].day,
                    hour = 0,
                    min = 0,
                    sec = 0,
                })
            else
                local firstTs = tonumber(curveHours[1].timestamp) or os.time()
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

                -- Tooltip estruturado en 3 liñas
                local tTip = string.format("%s, %d %s %s\n%d°C%s\n%s: %d%%",
                    dayName, dayNum, atWord, hTime,
                    tempVal, skyPart,
                    rainWord, rainProbVal)

                -- Altura e deseño proporcional da barra de choiva
                local maxBarH = 20
                local barH = 2
                local barW = 3
                local barRadius = 1
                local barColor = isDark and "#2a3244" or "#cbd5e1"

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
                    barColor = isDark and "#3b455c" or "#94a3b8"
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
            local labelsList = {}
            local nowIdx = nil
            if currentHourSec >= day0StartTs then
                local diffH = math.floor((currentHourSec - day0StartTs) / 3600)
                if diffH >= 0 and diffH < totalSlots then
                    nowIdx = diffH
                end
            end

            for k = 0, totalSlots - 1, 6 do
                local isSuppressedByNow = (nowIdx ~= nil and math.abs(k - nowIdx) <= 2)
                if not isSuppressedByNow then
                    local hNum = k % 24
                    local isStartOfDay = (hNum == 0)
                    local lblColor = (isStartOfDay and k > 0)
                        and (isDark and "#cbd5e1" or "#334155")
                        or (isDark and "#94a3b8" or "#64748b")
                    local lblWeight = (isStartOfDay and k > 0) and "bold" or "medium"

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

                    local tTip = string.format("%s, %d %s %s\n%d°C%s\n%s: %d%%",
                        dayName, dayNum, atWord, hTime,
                        tempVal, skyPart,
                        rainWord, rainProbVal)

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

                    labelsList[#labelsList + 1] = {
                        x = padLeft + k * hourW,
                        text = string.format("%02dh", hNum),
                        fontSize = 8.5,
                        fontWeight = lblWeight,
                        color = lblColor,
                        glyph = gName,
                        glyphColor = gColor,
                        tooltip = tTip,
                        onClick = lblClickHandler,
                    }
                end
            end

            if nowIdx ~= nil then
                local nowTs = day0StartTs + nowIdx * 3600
                local nowH = findHour(currentHourSec) or findHour(nowTs)
                local curGName = (cur and cur.glyph) or (nowH and nowH.glyph) or "cloud-sun"
                local curGColor = (cur and cur.color) or (nowH and nowH.color) or grayGreen

                local nowTemp = (cur and cur.temp) or (nowH and nowH.temp) or 0
                local nowRain = (nowH and nowH.rainProb) or (weather.rainProb or 0)
                local nowSky = (cur and cur.skyDesc) or (nowH and nowH.skyDesc) or ""
                local nowSkyPart = (nowSky ~= "") and (" · " .. nowSky) or ""
                local nowWday = nowH and nowH.weekday or tonumber(os.date("%w", currentHourSec)) or 0
                local nowDayNum = nowH and nowH.day or tonumber(os.date("%d", currentHourSec)) or 0
                local nowDayName = weekdaysFull[nowWday] or ""
                local nowTime = nowH and nowH.time or os.date("%H:%M", currentHourSec)

                local nowTooltip = string.format("%s, %d %s %s\n%d°C%s\n%s: %d%%",
                    nowDayName, nowDayNum, atWord, nowTime,
                    nowTemp, nowSkyPart,
                    rainWord, nowRain)

                labelsList[#labelsList + 1] = {
                    x = padLeft + nowIdx * hourW,
                    text = isEn and "Now" or "Agora",
                    fontSize = 8.5,
                    fontWeight = "bold",
                    color = grayGreen,
                    glyph = curGName,
                    glyphColor = curGColor,
                    tooltip = nowTooltip,
                    onClick = function()
                        noctalia.state.set("hourly_offset", 0)
                        render()
                    end,
                }
            end

            table.sort(labelsList, function(a, b)
                return a.x < b.x
            end)

            local labelWidgets = {}
            local lblWidth = 34
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
                        size = 13,
                        color = lbl.glyphColor or lbl.color,
                    }),
                    ui.label({
                        text = lbl.text,
                        fontSize = lbl.fontSize,
                        fontWeight = lbl.fontWeight,
                        color = lbl.color,
                    }),
                })
                currentX = targetLeft + lblWidth
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
                gap = 6,
                align = "center",
            }, {
                ui.box({ width = 6, height = 6, radius = 3, fill = grayGreen }),
                ui.label({
                    text = tr("ui.rain_probability", isEn and "Rain probability" or "Probabilidade de chuvia"),
                    fontSize = s.sectionSub,
                    fontWeight = "bold",
                    color = "on_surface",
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

            rootChildren[#rootChildren + 1] = ui.column({
                width = s.chartWidth,
                gap = 6,
                align = "center",
            }, {
                chartWidget,
                timelineCard,
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
