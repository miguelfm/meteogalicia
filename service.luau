--!strict
-- Background poller for MeteoGalicia.
-- Fetches official daily and hourly forecast data from meteo2api (Xunta de Galicia)
-- and publishes a unified, reactive state table for the bar capsule and panel.

local shared = require("./shared.luau")

local inFlight = false

local function getConfig()
    local concelloId = tonumber(noctalia.getConfig("concello_id")) or 15035
    local concelloName = tostring(noctalia.getConfig("concello_name") or "Fene")
    local refreshMinutes = tonumber(noctalia.getConfig("refresh_minutes")) or 30
    if refreshMinutes < 5 then refreshMinutes = 5 end
    return concelloId, concelloName, refreshMinutes
end

local function poll()
    if inFlight then return end
    inFlight = true
    noctalia.state.set("weather_loading", true)

    local concelloId, concelloName, refreshMinutes = getConfig()
    noctalia.setUpdateInterval(refreshMinutes * 60 * 1000)

    local headers = {
        "apikey: " .. shared.API_KEY,
        "Accept: application/json",
        "Accept-Language: gl",
    }

    local dailyUrl = shared.BASE_API .. "concellos/predicion/diaria?idConcello=" .. tostring(concelloId) .. "&idioma=gl"

    -- 1. Obter predición diaria (resumo, mínimas, máximas, aviso e comentario oficial)
    noctalia.http({
        url = dailyUrl,
        method = "GET",
        headers = headers,
    }, function(dailyRes)
        if not dailyRes or not dailyRes.ok or dailyRes.status ~= 200 then
            inFlight = false
            noctalia.state.set("weather_loading", false)
            noctalia.state.set("weather_error", "Erro ao obter predición diaria (" .. tostring(dailyRes and dailyRes.status or "rede") .. ")")
            return
        end

        local dailyData = noctalia.json.decode(dailyRes.body or "{}")
        if not dailyData or type(dailyData) ~= "table" then
            inFlight = false
            noctalia.state.set("weather_loading", false)
            noctalia.state.set("weather_error", "Formato de predición diaria non válido")
            return
        end

        -- 2. Obter predición por horas para a data de hoxe
        local dateParam = os.date("!%Y-%m-%dT00%%3A00%%3A00.000Z")
        local hourlyUrl = shared.BASE_API .. "concellos/predicion-horaria?idConcello=" .. tostring(concelloId) .. "&data=" .. dateParam .. "&idioma=gl"

        noctalia.http({
            url = hourlyUrl,
            method = "GET",
            headers = headers,
        }, function(hourlyRes)
            inFlight = false
            noctalia.state.set("weather_loading", false)

            if not hourlyRes or not hourlyRes.ok or hourlyRes.status ~= 200 then
                noctalia.state.set("weather_error", "Erro ao obter predición horaria (" .. tostring(hourlyRes and hourlyRes.status or "rede") .. ")")
                return
            end

            local hourlyData = noctalia.json.decode(hourlyRes.body or "{}")
            if not hourlyData or type(hourlyData) ~= "table" then
                noctalia.state.set("weather_error", "Formato de predición horaria non válido")
                return
            end

            -- Procesar datos diarios
            local shortTermList = dailyData.forecastDataShortTerm or {}
            local todayShort = shortTermList[1] or {}
            local cleanComment = shared.cleanHtml(dailyData.comment or "")

            local todayInfo = {
                tempMin = todayShort.temperatureMin or 0,
                tempMax = todayShort.temperatureMax or 0,
                skyId = todayShort.forecastSkyId or 101,
                skyDesc = todayShort.forecastSkyDescription or "",
                rainProb = todayShort.probabilityRain or 0,
                windDesc = todayShort.forecastWindDescription or "",
                uv = todayShort.uvMax or 0,
                ica = todayShort.ica or 0,
                comment = cleanComment,
                warningLevel = todayShort.warningLevel or 0,
            }

            -- Procesar horas
            local hoursRaw = hourlyData.forecastDataTime or {}
            local nowLocalHour = tonumber(os.date("%H")) or 12
            local currentEntry = nil
            local processedHours = {}

            for _, h in ipairs(hoursRaw) do
                local ms = tonumber(h.date) or 0
                local sec = math.floor(ms / 1000)
                local hNum = tonumber(os.date("%H", sec)) or 0
                local hTime = string.format("%02d:00", hNum)
                local sky = shared.getSky(h.idSkyTrend)

                local item = {
                    time = hTime,
                    hourNum = hNum,
                    temp = h.averageTemperature or 0,
                    rainProb = h.probabilityRain or 0,
                    windSpeed = h.windSpeed or 0,
                    windDesc = h.windTrendDescription or "",
                    skyCode = h.idSkyTrend or 101,
                    skyDesc = h.skyTrendDescription or sky.desc,
                    glyph = sky.glyph,
                    color = sky.color,
                    ica = h.ica,
                }

                processedHours[#processedHours + 1] = item

                -- Seleccionar a hora actual
                if hNum == nowLocalHour then
                    currentEntry = item
                end
            end

            -- Se non atopamos a hora exacta, usamos a primeira dispoñible
            if not currentEntry and #processedHours > 0 then
                currentEntry = processedHours[1]
            end

            local currentSky = shared.getSky(currentEntry and currentEntry.skyCode or todayInfo.skyId)

            local payload = {
                concelloId = concelloId,
                concelloName = concelloName,
                officialName = (dailyData.townHall and dailyData.townHall.name) or concelloName,
                current = {
                    temp = currentEntry and currentEntry.temp or todayInfo.tempMax,
                    rainProb = currentEntry and currentEntry.rainProb or todayInfo.rainProb,
                    windSpeed = currentEntry and currentEntry.windSpeed or 0,
                    windDesc = currentEntry and currentEntry.windDesc or todayInfo.windDesc,
                    skyCode = currentEntry and currentEntry.skyCode or todayInfo.skyId,
                    skyDesc = currentEntry and currentEntry.skyDesc or todayInfo.skyDesc,
                    glyph = currentSky.glyph,
                    color = currentSky.color,
                    time = currentEntry and currentEntry.time or string.format("%02d:00", nowLocalHour),
                },
                today = todayInfo,
                hourly = processedHours,
                updatedAt = os.date("%H:%M"),
            }

            noctalia.state.set("weather_error", nil)
            noctalia.state.set("weather", payload)
        end)
    end)
end

-- Escoitar mensaxes (ex: `noctalia msg plugin miguelfm/meteogalicia:poller refresh`)
function onMessage(action: string, _payload: any)
    if action == "refresh" then
        poll()
    end
end

-- Rexistrar petición manual de refresco desde o panel ou widget
noctalia.state.watch("weather_request_refresh", function(value)
    if value == true then
        noctalia.state.set("weather_request_refresh", false)
        poll()
    end
end)

-- Primeira chamada inmediata
poll()
