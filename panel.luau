--!strict
-- Detailed weather panel for MeteoGalicia.
-- Shows current conditions, horizontal hourly forecast cards,
-- official forecaster commentary, and meteorological indicators.

local shared = require("./shared.luau")

local weather = nil
local weatherError = nil
local isLoading = false

function onRefresh()
    noctalia.state.set("weather_request_refresh", true)
end

function onOpenWeb()
    local id = (weather and weather.concelloId) or 15035
    noctalia.runAsync(string.format("xdg-open 'https://www.meteogalicia.gal/web/predicion/concellos/%d/0'", id))
end

function onKey(chord: string?, pressed: boolean)
    if not pressed then return end
    local lower = tostring(chord or ""):lower()
    if lower == "escape" then
        if type(panel.close) == "function" then panel.close() end
    elseif lower == "r" then
        onRefresh()
    end
end

local function render()
    if weather == nil or weather.current == nil then
        if weatherError then
            panel.render(ui.column({ gap = 16, padding = 24, align = "center" }, {
                ui.glyph({ name = "cloud-off", size = 48, color = "error" }),
                ui.label({ text = "Non se puideron cargar os datos de MeteoGalicia", fontSize = 16, fontWeight = "bold", color = "error" }),
                ui.label({ text = tostring(weatherError), fontSize = 13, color = "on_surface_variant" }),
                ui.button({ text = "Reintentar", glyph = "refresh", variant = "primary", onClick = "onRefresh" }),
            }))
        else
            panel.render(ui.column({ gap = 16, padding = 32, align = "center" }, {
                ui.glyph({ name = "cloud-rain", size = 48, color = "primary" }),
                ui.label({ text = "Cargando predición de MeteoGalicia…", fontSize = 15, color = "on_surface_variant" }),
            }))
        end
        return
    end

    local cur = weather.current
    local today = weather.today or {}
    local hourly = weather.hourly or {}
    local hoursLimit = tonumber(noctalia.getConfig("hours_count")) or 12

    local rootChildren = {}

    -- ── 1. CABECEIRA PRINCIPAL ───────────────────────────────────────────────
    local headerRow = ui.row({ gap = 16, align = "center" }, {
        ui.glyph({
            name = cur.glyph or "cloud-sun",
            size = 46,
            color = cur.color or "primary",
        }),
        ui.column({ gap = 3 }, {
            ui.row({ gap = 8, align = "center" }, {
                ui.label({
                    text = weather.officialName or weather.concelloName or "Fene",
                    fontSize = 22,
                    fontWeight = "bold",
                    color = "on_surface",
                }),
                ui.column({
                    padding = 4,
                    radius = 4,
                    fill = "surface_variant",
                }, {
                    ui.label({ text = "MeteoGalicia", fontSize = 10, fontWeight = "bold", color = "primary" }),
                }),
            }),
            ui.label({
                text = cur.skyDesc or "Predición diaria",
                fontSize = 14,
                color = "on_surface_variant",
            }),
        }),
        ui.spacer(),
        ui.column({ gap = 2, align = "end" }, {
            ui.row({ gap = 4, align = "center" }, {
                ui.label({
                    text = tostring(cur.temp or 0),
                    fontSize = 32,
                    fontWeight = "bold",
                    color = "on_surface",
                }),
                ui.label({ text = "°C", fontSize = 18, fontWeight = "bold", color = "on_surface_variant" }),
            }),
            ui.row({ gap = 8 }, {
                ui.label({
                    text = "↓ " .. tostring(today.tempMin or 0) .. "°",
                    fontSize = 13,
                    fontWeight = "bold",
                    color = "secondary",
                }),
                ui.label({
                    text = "↑ " .. tostring(today.tempMax or 0) .. "°",
                    fontSize = 13,
                    fontWeight = "bold",
                    color = "error",
                }),
            }),
        }),
        ui.button({
            glyph = "refresh",
            variant = "ghost",
            tooltip = "Actualizar datos (R)",
            onClick = "onRefresh",
        }),
    })

    rootChildren[#rootChildren + 1] = headerRow
    rootChildren[#rootChildren + 1] = ui.separator()

    -- ── 2. PRESTRIP / TIRA HORARIA ────────────────────────────────────────────
    rootChildren[#rootChildren + 1] = ui.row({ gap = 6, align = "center" }, {
        ui.glyph({ name = "clock", size = 15, color = "primary" }),
        ui.label({ text = "Predición por horas (Hoxe)", fontSize = 14, fontWeight = "bold", color = "on_surface" }),
        ui.spacer(),
        ui.label({ text = "Próximas " .. tostring(math.min(hoursLimit, #hourly)) .. " horas", fontSize = 11, color = "on_surface_variant" }),
    })

    local hourCards = {}
    local currentHourNum = tonumber(os.date("%H")) or 0

    local count = 0
    for _, h in ipairs(hourly) do
        if h.hourNum >= currentHourNum or count > 0 or #hourly <= hoursLimit then
            count = count + 1
            if count > hoursLimit then break end

            local isCurrent = (h.hourNum == currentHourNum)
            local cardBg = isCurrent and "primary/0.14" or "surface_variant/0.5"
            local cardBorder = isCurrent and "primary/0.4" or "outline/0.15"

            hourCards[#hourCards + 1] = ui.column({
                gap = 5,
                align = "center",
                width = 56,
                padding = 6,
                radius = 8,
                fill = cardBg,
                border = cardBorder,
                borderWidth = 1,
            }, {
                ui.label({
                    text = h.time or "--:--",
                    fontSize = 11,
                    fontWeight = isCurrent and "bold" or "normal",
                    color = isCurrent and "primary" or "on_surface_variant",
                }),
                ui.glyph({
                    name = h.glyph or "cloud",
                    size = 20,
                    color = h.color or "on_surface",
                }),
                ui.label({
                    text = tostring(h.temp or 0) .. "°",
                    fontSize = 13,
                    fontWeight = "bold",
                    color = "on_surface",
                }),
                ui.row({ gap = 1, align = "center" }, {
                    ui.glyph({ name = "droplet", size = 9, color = "secondary" }),
                    ui.label({
                        text = tostring(h.rainProb or 0) .. "%",
                        fontSize = 10,
                        color = "secondary",
                    }),
                }),
            })
        end
    end

    rootChildren[#rootChildren + 1] = ui.row({ gap = 8, align = "center" }, hourCards)

    -- ── 3. COMENTARIO OFICIAL DE METEOGALICIA ─────────────────────────────────
    if today.comment and today.comment ~= "" then
        rootChildren[#rootChildren + 1] = ui.separator()
        rootChildren[#rootChildren + 1] = ui.row({ gap = 6, align = "center" }, {
            ui.glyph({ name = "message-report", size = 15, color = "primary" }),
            ui.label({ text = "Comentario oficial de MeteoGalicia", fontSize = 13, fontWeight = "bold", color = "on_surface" }),
        })

        rootChildren[#rootChildren + 1] = ui.column({
            padding = 12,
            radius = 8,
            fill = "surface_variant/0.4",
            border = "outline/0.15",
            borderWidth = 1,
        }, {
            ui.label({
                text = today.comment,
                fontSize = 12,
                color = "on_surface",
            }),
        })
    end

    -- ── 4. BADGES INFORMATIVOS E PE DE PÁXINA ─────────────────────────────────
    rootChildren[#rootChildren + 1] = ui.separator()

    local indicators = {}

    -- Vento
    indicators[#indicators + 1] = ui.row({ gap = 4, align = "center" }, {
        ui.glyph({ name = "wind", size = 14, color = "primary" }),
        ui.label({ text = (cur.windDesc ~= "" and cur.windDesc or "Vento") .. " (" .. tostring(cur.windSpeed) .. " km/h)", fontSize = 12, color = "on_surface_variant" }),
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
            ui.glyph({ name = "leaf", size = 14, color = icaColor }),
            ui.label({ text = "Calidade do aire: " .. icaDesc, fontSize = 12, color = icaColor }),
        })
    end

    -- Índice UV
    if today.uv and today.uv > 0 then
        indicators[#indicators + 1] = ui.row({ gap = 4, align = "center" }, {
            ui.glyph({ name = "sun-high", size = 14, color = "tertiary" }),
            ui.label({ text = "Índice UV máx: " .. tostring(today.uv), fontSize = 12, color = "on_surface_variant" }),
        })
    end

    local footerRow = ui.row({ gap = 16, align = "center" }, {
        ui.row({ gap = 14, align = "center" }, indicators),
        ui.spacer(),
        ui.button({
            text = "Abrir na web",
            glyph = "external-link",
            variant = "outline",
            controlSize = "sm",
            onClick = "onOpenWeb",
        }),
    })

    rootChildren[#rootChildren + 1] = footerRow

    panel.render(ui.column({ gap = 12, padding = 16 }, rootChildren))
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
