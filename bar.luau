--!strict
-- Bar widget capsule for MeteoGalicia.
-- Shows weather glyph, temperature, rain probability (if > 0%) and municipality name.
-- Clicking opens the detailed hourly forecast panel.

local i18n = require("./i18n.luau")

local weatherData = nil
local weatherError = nil
local isLoading = false

local tr = i18n.tr

local function render()
    i18n.refresh()
    local showTown = noctalia.getConfig("show_town_name") == true
    local showRain = noctalia.getConfig("show_rain_prob") ~= false

    local children = {}

    if weatherData and weatherData.current then
        local cur = weatherData.current
        local today = weatherData.today or {}

        -- Glifo do estado do ceo
        children[#children + 1] = ui.glyph({
            name = cur.glyph or "cloud-sun",
            size = 15,
            color = cur.color or "primary",
        })

        -- Temperatura actual
        children[#children + 1] = ui.label({
            text = tostring(cur.temp) .. "°C",
            fontSize = 13,
            color = "on_surface",
        })

        -- Probabilidade de choiva / humidade (se está activada e é > 0)
        if showRain and cur.rainProb and cur.rainProb > 0 then
            children[#children + 1] = ui.row({ gap = 2, align = "center" }, {
                ui.glyph({ name = "droplet", size = 13, color = "secondary" }),
                ui.label({
                    text = tostring(cur.rainProb) .. "%",
                    fontSize = 13,
                    color = "secondary",
                }),
            })
        end

        -- Nome do concello (desactivado por defecto na barra)
        if showTown then
            children[#children + 1] = ui.label({
                text = weatherData.concelloName or "Fene",
                fontSize = 13,
                color = "on_surface_variant",
            })
        end

        -- Tooltip con información completa e lexible sen truncado de texto
        local town = weatherData.officialName or weatherData.concelloName or "Fene"
        local tempStr = string.format("%d°C", cur.temp or 0)
        if today.tempMin and today.tempMax then
            tempStr = string.format(
                "%d°C (%s: %d°C / %s: %d°C)",
                cur.temp or 0,
                tr("ui.min", "Mín"),
                today.tempMin,
                tr("ui.max", "Máx"),
                today.tempMax
            )
        end

        local skyDesc = i18n.sky(cur.skyCode or cur.skyId, cur.skyDesc)
        local condStr = skyDesc .. ", " .. tempStr

        local windStr
        if cur.windDesc and cur.windDesc ~= "" then
            windStr = string.format("%s: %s (%d km/h)", tr("tooltip.wind", "Vento"), i18n.wind(cur.windDesc), cur.windSpeed or 0)
        elseif cur.windSpeed and cur.windSpeed > 0 then
            windStr = string.format("%s: %d km/h", tr("tooltip.wind", "Vento"), cur.windSpeed)
        else
            windStr = string.format("%s: %s", tr("tooltip.wind", "Vento"), tr("ui.calm", "Calma"))
        end

        local lines = {
            string.format("%s — MeteoGalicia", town),
            condStr,
            string.format("%s: %d%%", tr("tooltip.rain_prob", "Choiva"), cur.rainProb or 0),
            windStr,
        }

        if today.sunrise and today.sunset and today.sunrise ~= "" and today.sunset ~= "" then
            lines[#lines + 1] = string.format("%s: %s · %s: %s", tr("ui.sunrise", "Orto"), today.sunrise, tr("ui.sunset", "Ocaso"), today.sunset)
        end

        if weatherData.updatedAt then
            lines[#lines + 1] = string.format("%s: %s", tr("tooltip.updated", "Actualizado"), weatherData.updatedAt)
        end

        lines[#lines + 1] = tr("tooltip.click_hint", "Preme para ver a predición detallada")

        barWidget.setTooltip(table.concat(lines, "\n"))
    elseif weatherError then
        children[#children + 1] = ui.glyph({
            name = "cloud-off",
            size = 14,
            color = "error",
        })
        children[#children + 1] = ui.label({
            text = "Meteo",
            fontSize = 12,
            color = "error",
        })
        barWidget.setTooltip(i18n.format("error.bar", i18n.error(weatherError)) .. "\n" .. tr("error.retry_hint"))
    else
        children[#children + 1] = ui.glyph({
            name = "cloud-rain",
            size = 14,
            color = "on_surface_variant",
        })
        children[#children + 1] = ui.label({
            text = "…",
            fontSize = 12,
            color = "on_surface_variant",
        })
        barWidget.setTooltip(tr("ui.loading"))
    end

    barWidget.render(ui.row({ gap = 6, align = "center" }, children))
end

-- Rexistro de estado reactivo
noctalia.state.watch("weather", function(val)
    weatherData = val
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

function onClick()
    noctalia.togglePanel("miguelfm/meteogalicia:panel")
end

function onScroll(_axis: string?, steps: number?, _startsGesture: boolean?)
    local s = steps or 0
    local curOffset = tonumber(noctalia.state.get("hourly_offset")) or 0
    local totalHourly = (weatherData and weatherData.hourly and #weatherData.hourly) or 48
    local maxOffset = math.max(0, totalHourly - 12)
    if s > 0 and curOffset < maxOffset then
        noctalia.state.set("hourly_offset", curOffset + 1)
    elseif s < 0 and curOffset > 0 then
        noctalia.state.set("hourly_offset", curOffset - 1)
    end
end

weatherData = noctalia.state.get("weather")
weatherError = noctalia.state.get("weather_error")
render()

function onConfigChanged()
    render()
end
