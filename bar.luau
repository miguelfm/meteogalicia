--!strict
-- Bar widget capsule for MeteoGalicia.
-- Shows weather glyph, temperature, rain probability (if > 0%) and municipality name.
-- Clicking opens the detailed hourly forecast panel.

local weatherData = nil
local weatherError = nil
local isLoading = false

local function tr(key: string, fallback: string): string
    if type(noctalia.tr) == "function" then
        local val = noctalia.tr(key)
        if val and val ~= "" and val ~= key then
            return val
        end
    end
    return fallback
end

local function render()
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

        -- Tooltip con información estruturada (táboa nativa de dúas columnas de Noctalia)
        local town = weatherData.officialName or weatherData.concelloName or "Fene"
        local rows = {
            { key = tr("tooltip.town", "Concello"), value = town },
            { key = tr("tooltip.condition", "Estado"), value = cur.skyDesc or "Predición" },
            { key = tr("tooltip.temperature", "Temperatura"), value = string.format("%d°C (Min: %d°C / Máx: %d°C)", cur.temp or 0, today.tempMin or 0, today.tempMax or 0) },
            { key = tr("tooltip.rain_prob", "Choiva"), value = string.format("%d%%", cur.rainProb or 0) },
            { key = tr("tooltip.wind", "Vento"), value = string.format("%s (%d km/h)", cur.windDesc ~= "" and cur.windDesc or "Calma", cur.windSpeed or 0) },
        }
        if weatherData.updatedAt then
            rows[#rows + 1] = { key = tr("tooltip.updated", "Actualizado"), value = weatherData.updatedAt }
        end

        barWidget.setTooltip(rows)
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
        barWidget.setTooltip("Erro de MeteoGalicia: " .. tostring(weatherError) .. "\nPreme co botón dereito para reintentar.")
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
        barWidget.setTooltip("Cargando predición de MeteoGalicia…")
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

weatherData = noctalia.state.get("weather")
weatherError = noctalia.state.get("weather_error")
render()
