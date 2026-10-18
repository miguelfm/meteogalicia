--!strict
-- Detailed weather panel for MeteoGalicia.
-- Shows current conditions, horizontal hourly forecast cards,
-- upcoming daily summary, official forecaster commentary, and meteorological indicators.

local shared = require("./shared.luau")

local weather = nil
local weatherError = nil
local isLoading = false

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
        panelPadding = 16,
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
        hourlyWidth = 58,
        hourlyPad = 6,
        hourlyGap = 5,
        hourlyTime = 11,
        hourlyGlyph = 20,
        hourlyTemp = 13,
        hourlyRainIcon = 9,
        hourlyRainText = 10,
        hourlyRowGap = 6,
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
        chartWidth = 720,
        chartHeight = 310,
        commentTitle = 13,
        commentText = 12,
        commentPad = 12,
        footerIcon = 14,
        footerText = 12,
        btnSize = "sm",
    },
    large = {
        panelPadding = 20,
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
        hourlyWidth = 72,
        hourlyPad = 8,
        hourlyGap = 6,
        hourlyTime = 13,
        hourlyGlyph = 28,
        hourlyTemp = 16,
        hourlyRainIcon = 11,
        hourlyRainText = 12,
        hourlyRowGap = 8,
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
        chartWidth = 940,
        chartHeight = 330,
        commentTitle = 15,
        commentText = 14,
        commentPad = 14,
        footerIcon = 16,
        footerText = 14,
        btnSize = "md",
    },
    xlarge = {
        panelPadding = 24,
        panelGap = 16,
        headerGlyph = 76,
        headerTown = 38,
        headerBadge = 14,
        headerDesc = 20,
        headerTemp = 60,
        headerDeg = 30,
        headerMinMax = 20,
        headerBtnGap = 8,
        headerSunIcon = 44,
        headerSunText = 17,
        headerSunTime = 26,
        headerSunPadH = 22,
        headerSunPadV = 12,
        headerSunGap = 18,
        headerSunDividerHeight = 42,
        sectionIcon = 24,
        sectionTitle = 22,
        sectionSub = 16,
        hourlyWidth = 88,
        hourlyPad = 10,
        hourlyGap = 8,
        hourlyTime = 16,
        hourlyGlyph = 42,
        hourlyTemp = 22,
        hourlyRainIcon = 15,
        hourlyRainText = 16,
        hourlyRowGap = 8,
        dailyPad = 14,
        dailyGap = 8,
        dailyTitle = 20,
        dailyDate = 15,
        dailyGlyph = 48,
        dailyDesc = 16,
        dailyTemp = 20,
        dailyRainIcon = 16,
        dailyRainText = 16,
        dailyWindText = 14,
        chartWidth = 1260,
        chartHeight = 350,
        commentTitle = 20,
        commentText = 17,
        commentPad = 16,
        footerIcon = 20,
        footerText = 16,
        btnSize = "lg",
    },
}

function onRefresh()
    noctalia.state.set("weather_request_refresh", true)
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
    local lower = tostring(chord or ""):lower()
    if lower == "escape" then
        if type(panel.close) == "function" then panel.close() end
    elseif lower == "r" then
        onRefresh()
    elseif lower == "s" or lower == "c" then
        onOpenSettings()
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

local function render()
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
    local hoursLimit = tonumber(noctalia.getConfig("hours_count")) or 24

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

    -- ── 2. PRESTRIP / TIRA HORARIA ────────────────────────────────────────────
    rootChildren[#rootChildren + 1] = ui.row({ gap = 6, align = "center" }, {
        ui.glyph({ name = "clock", size = s.sectionIcon, color = "primary" }),
        ui.label({ text = tr("ui.hourly_title", "Predición por horas"), fontSize = s.sectionTitle, fontWeight = "bold", color = "on_surface" }),
        ui.spacer(),
        ui.label({ text = string.format(tr("ui.upcoming_hours_scroll", "Próximas %d horas (desprazable)"), math.min(hoursLimit, #hourly)), fontSize = s.sectionSub, color = "on_surface_variant" }),
    })

    local hourCards = {}
    local currentHourSec = math.floor(os.time() / 3600) * 3600

    for idx, h in ipairs(hourly) do
        if idx > hoursLimit then break end

        local isCurrent = (h.timestamp == currentHourSec) or (idx == 1 and not h.isTomorrow)
        local cardBg = isCurrent and cardBgActive or cardBgNorm
        local cardBorder = isCurrent and "primary/0.60" or "outline/0.25"

        local timeColor = "on_surface_variant"
        if isCurrent then
            timeColor = "primary"
        elseif h.isTomorrow then
            timeColor = "secondary"
        end

        local dayHint = h.isTomorrow and tr("ui.tomorrow", "Mañá") or tr("ui.today", "Hoxe")
        local cardTooltip = dayHint .. " ás " .. (h.time or "--:--")

        hourCards[#hourCards + 1] = ui.column({
            width = s.hourlyWidth,
            minWidth = s.hourlyWidth,
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
                fontWeight = (isCurrent or h.isTomorrow) and "bold" or "normal",
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

    rootChildren[#rootChildren + 1] = ui.scroll({
        width = s.chartWidth,
        paddingV = 2,
    }, {
        ui.row({ gap = s.hourlyRowGap, align = "center" }, hourCards)
    })

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

        local isEn = (tr("ui.today", "Hoxe") == "Today")
        local chartSvg = shared.generateDailyChartSvg(dailyDays, s.chartWidth, s.chartHeight, {
            isEn = isEn,
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

function onOpen()
    weather = noctalia.state.get("weather")
    weatherError = noctalia.state.get("weather_error")
    render()
end

weather = noctalia.state.get("weather")
weatherError = noctalia.state.get("weather_error")
render()
