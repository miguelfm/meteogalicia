--!strict
-- Background poller for MeteoGalicia.
-- Fetches official daily and hourly forecast data from meteo2api (Xunta de Galicia)
-- and publishes a unified, reactive state table for the bar capsule and panel.

local shared = require("./shared.luau")

local inFlight = false

local concellosCoords: { [number]: { lat: number, lon: number } } = {
    [15035] = { lat = 43.475156, lon = -8.167317 }, -- Fene
    [15036] = { lat = 43.483212, lon = -8.236944 }, -- Ferrol
    [15030] = { lat = 43.371350, lon = -8.418800 }, -- A Coruña
    [15078] = { lat = 42.878213, lon = -8.544844 }, -- Santiago
    [36057] = { lat = 42.232820, lon = -8.722640 }, -- Vigo
    [36038] = { lat = 42.433611, lon = -8.647500 }, -- Pontevedra
    [32054] = { lat = 42.336667, lon = -7.864167 }, -- Ourense
    [27028] = { lat = 43.009923, lon = -7.556019 }, -- Lugo
}
local concellosLoaded = false

local function ensureConcellosCoords(headers: { string })
    if concellosLoaded then return end
    concellosLoaded = true
    noctalia.http({
        url = shared.BASE_API .. "concellos",
        method = "GET",
        headers = headers,
    }, function(res)
        if res and res.ok and res.status == 200 then
            local list = noctalia.json.decode(res.body or "[]")
            if type(list) == "table" then
                for _, item in ipairs(list) do
                    if item.id and item.latitude and item.longitude then
                        concellosCoords[item.id] = { lat = item.latitude, lon = item.longitude }
                    end
                end
            end
        end
    end)
end

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
    ensureConcellosCoords(headers)

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

        -- 2. Obter predición por horas para hoxe, mañá, pasado mañá e seguinte (48+ horas continuas)
        local nowSec = os.time()
        local todayParam = os.date("!%Y-%m-%dT00%%3A00%%3A00.000Z", nowSec)
        local tomorrowParam = os.date("!%Y-%m-%dT00%%3A00%%3A00.000Z", nowSec + 86400)
        local dayAfterParam = os.date("!%Y-%m-%dT00%%3A00%%3A00.000Z", nowSec + 172800)
        local day3Param = os.date("!%Y-%m-%dT00%%3A00%%3A00.000Z", nowSec + 259200)

        local hourlyTodayUrl = shared.BASE_API .. "concellos/predicion-horaria?idConcello=" .. tostring(concelloId) .. "&data=" .. todayParam .. "&idioma=gl"
        local hourlyTomorrowUrl = shared.BASE_API .. "concellos/predicion-horaria?idConcello=" .. tostring(concelloId) .. "&data=" .. tomorrowParam .. "&idioma=gl"
        local hourlyDayAfterUrl = shared.BASE_API .. "concellos/predicion-horaria?idConcello=" .. tostring(concelloId) .. "&data=" .. dayAfterParam .. "&idioma=gl"
        local hourlyDay3Url = shared.BASE_API .. "concellos/predicion-horaria?idConcello=" .. tostring(concelloId) .. "&data=" .. day3Param .. "&idioma=gl"
        local mediumTermUrl = shared.BASE_API .. "concellos/predicion-medio-prazo?idConcello=" .. tostring(concelloId) .. "&idioma=gl"

        noctalia.http({
            url = hourlyTodayUrl,
            method = "GET",
            headers = headers,
        }, function(hourlyRes)
            if not hourlyRes or not hourlyRes.ok or hourlyRes.status ~= 200 then
                inFlight = false
                noctalia.state.set("weather_loading", false)
                noctalia.state.set("weather_error", "Erro ao obter predición horaria (" .. tostring(hourlyRes and hourlyRes.status or "rede") .. ")")
                return
            end

            local hourlyDataToday = noctalia.json.decode(hourlyRes.body or "{}")
            if not hourlyDataToday or type(hourlyDataToday) ~= "table" then
                inFlight = false
                noctalia.state.set("weather_loading", false)
                noctalia.state.set("weather_error", "Formato de predición horaria non válido")
                return
            end

            -- Obter horas de mañá
            noctalia.http({
                url = hourlyTomorrowUrl,
                method = "GET",
                headers = headers,
            }, function(hourlyTomorrowRes)
                local hourlyDataTomorrow = nil
                if hourlyTomorrowRes and hourlyTomorrowRes.ok and hourlyTomorrowRes.status == 200 then
                    hourlyDataTomorrow = noctalia.json.decode(hourlyTomorrowRes.body or "{}")
                end

                -- Obter horas de pasado mañá
                noctalia.http({
                    url = hourlyDayAfterUrl,
                    method = "GET",
                    headers = headers,
                }, function(hourlyDayAfterRes)
                    local hourlyDataDayAfter = nil
                    if hourlyDayAfterRes and hourlyDayAfterRes.ok and hourlyDayAfterRes.status == 200 then
                        hourlyDataDayAfter = noctalia.json.decode(hourlyDayAfterRes.body or "{}")
                    end

                    -- Obter horas do cuarto día para garantir 48 horas completas a calquera hora do día
                    noctalia.http({
                        url = hourlyDay3Url,
                        method = "GET",
                        headers = headers,
                    }, function(hourlyDay3Res)
                        local hourlyDataDay3 = nil
                        if hourlyDay3Res and hourlyDay3Res.ok and hourlyDay3Res.status == 200 then
                            hourlyDataDay3 = noctalia.json.decode(hourlyDay3Res.body or "{}")
                        end

                        -- Obter predición a medio prazo (para o 4º día)
                        noctalia.http({
                            url = mediumTermUrl,
                            method = "GET",
                            headers = headers,
                        }, function(mediumTermRes)
                            inFlight = false
                            noctalia.state.set("weather_loading", false)

                            local mediumTermData = nil
                            if mediumTermRes and mediumTermRes.ok and mediumTermRes.status == 200 then
                                mediumTermData = noctalia.json.decode(mediumTermRes.body or "{}")
                            end

                -- Procesar datos diarios
                local shortTermList = dailyData.forecastDataShortTerm or {}
                local todayShort = shortTermList[1] or {}
                local cleanComment = shared.cleanHtml(dailyData.comment or "")

                local coords = concellosCoords[concelloId]
                local lat = (coords and coords.lat) or (dailyData.townHall and dailyData.townHall.latitude) or shared.DEFAULT_LAT
                local lon = (coords and coords.lon) or (dailyData.townHall and dailyData.townHall.longitude) or shared.DEFAULT_LON
                local sunrise, sunset = shared.calcSolar(lat, lon, nowSec)

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
                    sunrise = sunrise,
                    sunset = sunset,
                    latitude = lat,
                    longitude = lon,
                }

                local dailyDays = {}
                local seenDateKeys: { [string]: boolean } = {}

                for idx, dEntry in ipairs(shortTermList) do
                    local reach = dEntry.reach or (idx - 1)
                    local sky = shared.getSky(dEntry.forecastSkyId)

                    local dateStr = dEntry.dateForecast or ""
                    local yStr, mStr, dStr = dateStr:match("(%d+)-(%d+)-(%d+)")
                    local y = tonumber(yStr) or 0
                    local m = tonumber(mStr) or 0
                    local d = tonumber(dStr) or 0
                    local wday = 0
                    local dayTs = nowSec + (reach * 86400)
                    if y > 0 and m > 0 and d > 0 then
                        local t = os.time({ year = y, month = m, day = d, hour = 12 })
                        wday = tonumber(os.date("%w", t)) or 0
                        dayTs = t
                        seenDateKeys[string.format("%04d-%02d-%02d", y, m, d)] = true
                    end
                    local dayRise, daySet = shared.calcSolar(lat, lon, dayTs)

                    dailyDays[#dailyDays + 1] = {
                        reach = reach,
                        day = d,
                        month = m,
                        year = y,
                        weekday = wday,
                        tempMin = dEntry.temperatureMin or 0,
                        tempMax = dEntry.temperatureMax or 0,
                        skyId = dEntry.forecastSkyId or 101,
                        skyDesc = dEntry.forecastSkyDescription or sky.desc,
                        glyph = sky.glyph,
                        color = sky.color,
                        rainProb = dEntry.probabilityRain or 0,
                        windDesc = dEntry.forecastWindDescription or "",
                        warningLevel = dEntry.warningLevel or 0,
                        uv = dEntry.uvMax or 0,
                        ica = dEntry.ica or 0,
                        sunrise = dayRise,
                        sunset = daySet,
                    }
                end

                -- Integrar o 4º día (ata completar 4 días en total) dende a predición a medio prazo de MeteoGalicia
                local mediumList = (mediumTermData and mediumTermData.forecastDataMediumTerm) or {}
                for _, mEntry in ipairs(mediumList) do
                    if #dailyDays >= 4 then
                        break
                    end
                    local ms = tonumber(mEntry.date) or 0
                    if ms > 0 then
                        local sec = math.floor(ms / 1000)
                        -- Engadir 12 horas para situarnos no mediodía local e evitar calquera desfasamento horario
                        local middaySec = sec + 43200
                        local dateInfo = os.date("*t", middaySec)
                        local dateKey = string.format("%04d-%02d-%02d", dateInfo.year, dateInfo.month, dateInfo.day)

                        if not seenDateKeys[dateKey] then
                            seenDateKeys[dateKey] = true
                            local reach = #dailyDays
                            local sky, skyId, rainProb = shared.getSkyFromProbabilities(mEntry.forecastSkyProbability)
                            local windDesc = shared.getWindTrend(mEntry.idWindForceTrend)
                            local dayRise, daySet = shared.calcSolar(lat, lon, middaySec)

                            dailyDays[#dailyDays + 1] = {
                                reach = reach,
                                day = dateInfo.day,
                                month = dateInfo.month,
                                year = dateInfo.year,
                                weekday = tonumber(os.date("%w", middaySec)) or 0,
                                tempMin = mEntry.minTemperature or 0,
                                tempMax = mEntry.maxTemperature or 0,
                                skyId = skyId,
                                skyDesc = sky.desc,
                                glyph = sky.glyph,
                                color = sky.color,
                                rainProb = rainProb,
                                windDesc = windDesc,
                                warningLevel = 0,
                                uv = 0,
                                ica = 0,
                                sunrise = dayRise,
                                sunset = daySet,
                            }
                        end
                    end
                end

                -- Combinar horas de hoxe, mañá, pasado mañá e cuarto día
                local rawToday = (hourlyDataToday and hourlyDataToday.forecastDataTime) or {}
                local rawTomorrow = (hourlyDataTomorrow and hourlyDataTomorrow.forecastDataTime) or {}
                local rawDayAfter = (hourlyDataDayAfter and hourlyDataDayAfter.forecastDataTime) or {}
                local rawDay3 = (hourlyDataDay3 and hourlyDataDay3.forecastDataTime) or {}
                local combinedHours = {}
                for _, h in ipairs(rawToday) do
                    combinedHours[#combinedHours + 1] = h
                end
                for _, h in ipairs(rawTomorrow) do
                    combinedHours[#combinedHours + 1] = h
                end
                for _, h in ipairs(rawDayAfter) do
                    combinedHours[#combinedHours + 1] = h
                end
                for _, h in ipairs(rawDay3) do
                    combinedHours[#combinedHours + 1] = h
                end

                local currentHourSec = math.floor(nowSec / 3600) * 3600
                local todayDateStr = os.date("%Y-%m-%d", nowSec)
                local tomorrowDateStr = os.date("%Y-%m-%d", nowSec + 86400)
                local currentEntry = nil
                local processedHours = {}
                local hourlyCurve = {}
                local seenCurveTs: { [number]: boolean } = {}

                -- Inicio do día de hoxe (00:00:00) para aliñar a liña no gráfico
                local todayStartSec = 0
                if #dailyDays > 0 and dailyDays[1].year > 0 then
                    todayStartSec = os.time({ year = dailyDays[1].year, month = dailyDays[1].month, day = dailyDays[1].day, hour = 0, min = 0, sec = 0 })
                else
                    local tParts = os.date("*t", nowSec)
                    todayStartSec = os.time({ year = tParts.year, month = tParts.month, day = tParts.day, hour = 0, min = 0, sec = 0 })
                end

                for _, h in ipairs(combinedHours) do
                    local ms = tonumber(h.date) or 0
                    local sec = math.floor(ms / 1000)
                    local hNum = tonumber(os.date("%H", sec)) or 0
                    local hTime = string.format("%02d:00", hNum)
                    local wday = tonumber(os.date("%w", sec)) or 0
                    local dayNum = tonumber(os.date("%d", sec)) or 0
                    local monthNum = tonumber(os.date("%m", sec)) or 0
                    local sky = shared.getSky(h.idSkyTrend)
                    local itemDateStr = os.date("%Y-%m-%d", sec)
                    local isTomorrow = (itemDateStr == tomorrowDateStr)

                    local item = {
                        time = hTime,
                        hourNum = hNum,
                        timestamp = sec,
                        weekday = wday,
                        day = dayNum,
                        month = monthNum,
                        dateStr = itemDateStr,
                        isTomorrow = isTomorrow,
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

                    if sec == currentHourSec then
                        currentEntry = item
                    end

                    -- Engadir horas dende a hora actual en adiante para a tira do panel (ata 48 horas)
                    if sec >= currentHourSec and #processedHours < 48 then
                        processedHours[#processedHours + 1] = item
                    end

                    -- Engadir á curva horaria continua dende o comezo de hoxe para o gráfico diario
                    if sec >= todayStartSec and not seenCurveTs[sec] then
                        seenCurveTs[sec] = true
                        hourlyCurve[#hourlyCurve + 1] = {
                            timestamp = sec,
                            temp = h.averageTemperature or 0,
                        }
                    end
                end

                -- Se non atopamos a hora exacta actual, usamos a primeira dispoñible
                if not currentEntry and #processedHours > 0 then
                    currentEntry = processedHours[1]
                end

                local currentSky = shared.getSky(currentEntry and currentEntry.skyCode or todayInfo.skyId)

                -- Recuperar ou calcular temperaturas do día anterior (Onte) para ancorar o gráfico
                local history = noctalia.state.get("weather_daily_history")
                if type(history) ~= "table" then history = {} end
                local concelloHistory = history[tostring(concelloId)] or {}
                local yesterdayDateStr = os.date("%Y-%m-%d", nowSec - 86400)
                local yesterdayInfo = concelloHistory[yesterdayDateStr]

                if not yesterdayInfo then
                    -- Se non temos onte no historial, calculamos a continuidade térmica
                    -- baseada na mínima da madrugada de hoxe (00h-06h) e na máxima prevista
                    local earlyMin = 999
                    for _, h in ipairs(rawToday) do
                        local ms = tonumber(h.date) or 0
                        local sec = math.floor(ms / 1000)
                        local hNum = tonumber(os.date("%H", sec)) or 0
                        local temp = tonumber(h.averageTemperature)
                        if hNum <= 6 and temp then
                            if temp < earlyMin then
                                earlyMin = temp
                            end
                        end
                    end
                    if earlyMin == 999 then earlyMin = todayInfo.tempMin end
                    yesterdayInfo = {
                        tempMin = earlyMin,
                        tempMax = todayInfo.tempMax,
                    }
                end

                -- Gardar o día de hoxe no historial para o día de mañá
                concelloHistory[todayDateStr] = {
                    tempMin = todayInfo.tempMin,
                    tempMax = todayInfo.tempMax,
                }
                history[tostring(concelloId)] = concelloHistory
                noctalia.state.set("weather_daily_history", history)

                -- Obter datos do seguinte día (Día 5) a partir do medio prazo para ancorar o extremo dereito
                local nextDayInfo = nil
                local lastDay = dailyDays[#dailyDays] or todayInfo
                for _, mEntry in ipairs(mediumList) do
                    local ms = tonumber(mEntry.date) or 0
                    if ms > 0 then
                        local sec = math.floor(ms / 1000) + 43200
                        local dInfo = os.date("*t", sec)
                        local dKey = string.format("%04d-%02d-%02d", dInfo.year, dInfo.month, dInfo.day)
                        if not seenDateKeys[dKey] and mEntry.maxTemperature and mEntry.minTemperature then
                            nextDayInfo = {
                                tempMin = mEntry.minTemperature,
                                tempMax = mEntry.maxTemperature,
                            }
                            break
                        end
                    end
                end
                if not nextDayInfo then
                    nextDayInfo = {
                        tempMin = lastDay.tempMin,
                        tempMax = lastDay.tempMax,
                    }
                end

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
                        time = currentEntry and currentEntry.time or string.format("%02d:00", tonumber(os.date("%H", nowSec)) or 12),
                    },
                    today = todayInfo,
                    yesterday = yesterdayInfo,
                    nextDay = nextDayInfo,
                    dailyDays = dailyDays,
                    hourly = processedHours,
                    hourlyCurve = hourlyCurve,
                    updatedAt = os.date("%H:%M"),
                }

                noctalia.state.set("weather_error", nil)
                noctalia.state.set("weather", payload)
            end)
        end)
    end)
end)
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
