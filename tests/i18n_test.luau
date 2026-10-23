-- Executed with the real plugin sources/catalogs injected by check_i18n.py.
local checks = 0
local function equal(actual, expected)
    checks += 1
    assert(actual == expected, "expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function host(choice, shellLanguage, entry, withWeather)
    local config = { language = choice, show_hourly_cards = true, show_daily_summary = true }
    local values, watchers, requests, files, cache = {}, {}, {}, {}, {}
    local tree, tooltip
    local nativeCatalog = CATALOGS[shellLanguage] or CATALOGS.en
    local env
    local function loadModule(name)
        name = name:gsub("^%./", ""):gsub("%.luau$", "")
        if cache[name] then return cache[name] end
        local chunk = assert(loadstring(assert(SOURCES[name], name), name))
        setfenv(chunk, env)
        local result = chunk()
        cache[name] = result
        return result
    end
    local ui = setmetatable({}, { __index = function(_, kind)
        return function(props, children) return { kind = kind, props = props or {}, children = children or {} } end
    end })
    local noctalia = {
        getConfig = function(key) return config[key] end,
        tr = function(key)
            equal(CATALOGS.en[key] ~= nil, true)
            equal(CATALOGS["gl-ES"][key] ~= nil, true)
            return nativeCatalog[key] or CATALOGS.en[key] or key
        end,
        readFile = function(path) return path end,
        writeFile = function(path, text) files[path] = text return true end,
        json = { decode = function(text)
            if text == "daily" then return { forecastDataShortTerm = { { temperatureMin = 10, temperatureMax = 20 } } } end
            return CATALOGS[text:match("translations/(.-)%.json")]
        end },
        isDarkMode = function() return true end,
        setUpdateInterval = function() end,
        http = function(request, callback) requests[#requests + 1] = { request = request, callback = callback } return true end,
        runAsync = function() error("UI rendering must not run commands") end,
        state = {
            get = function(key) return values[key] end,
            set = function(key, value)
                values[key] = value
                for _, callback in ipairs(watchers[key] or {}) do callback(value) end
            end,
            watch = function(key, callback)
                watchers[key] = watchers[key] or {}
                table.insert(watchers[key], callback)
            end,
        },
    }
    env = setmetatable({ noctalia = noctalia, ui = ui, require = loadModule,
        panel = { render = function(node) tree = node end, close = function() end },
        barWidget = { render = function(node) tree = node end, setTooltip = function(text) tooltip = text end },
    }, { __index = getfenv() })
    if withWeather then
        local days, hours = {}, {}
        for i = 0, 3 do
            local t = os.date("*t", os.time() + i * 86400)
            days[i + 1] = { year = t.year, month = t.month, day = t.day,
                weekday = t.wday - 1, reach = i, tempMin = 10 + i, tempMax = 20 + i,
                skyId = 111, skyDesc = "Chuvia", rainProb = 70, windDesc = "Nordés feble",
                glyph = "cloud-rain", uv = 8, ica = 1 }
        end
        for slot = 0, 95 do
            local d = days[math.floor(slot / 24) + 1]
            local target = os.time({ year = d.year, month = d.month, day = d.day,
                hour = slot % 24, min = 0, sec = 0 })
            local timestamp = target
            for _ = 1, 2 do
                timestamp += target - os.time(os.date("*t", timestamp))
            end
            local t = os.date("*t", timestamp)
            hours[#hours + 1] = { timestamp = timestamp, year = t.year, month = t.month,
                day = t.day, weekday = t.wday - 1, hourNum = t.hour, time = os.date("%H:%M", timestamp),
                skyCode = 111, skyDesc = "Chuvia", temp = 15, rainProb = 70,
                windDesc = "Nordés feble", windSpeed = 10, glyph = "cloud-rain" }
        end
        values.weather = { concelloId = 15035, concelloName = "Fene", officialName = "Fene",
            current = { temp = 15, skyCode = 111, skyDesc = "Chuvia", rainProb = 70,
                windDesc = "Nordés feble", windSpeed = 10, humidity = 60, stationName = "CIS Ferrol", ica = 1 },
            today = { tempMin = 10, tempMax = 20, uv = 8, ica = 1, sunrise = "08:00", sunset = "20:00",
                latitude = 43.4, longitude = -8.2, comment = "Comentario da fonte oficial." },
            dailyDays = days, hourly = hours, hourlyCurve = hours, updatedAt = "12:00" }
    end
    local chunk = assert(loadstring(assert(SOURCES[entry]), entry))
    setfenv(chunk, env)
    chunk()
    return { config = config, values = values, requests = requests, env = env, i18n = loadModule("i18n"),
        publish = noctalia.state.set, tree = function() return tree end, tooltip = function() return tooltip end,
        files = files }
end

local function texts(node, found)
    found = found or {}
    if type(node) ~= "table" then return found end
    for _, key in ipairs({ "text", "tooltip", "placeholder" }) do
        if type(node.props[key]) == "string" then found[#found + 1] = node.props[key] end
    end
    for _, child in ipairs(node.children or {}) do texts(child, found) end
    return found
end

for _, mode in ipairs({ { "auto", "en", "en" }, { "auto", "gl-ES", "gl" },
    { "gl", "en", "gl" }, { "en", "gl-ES", "en" } }) do
    for _, entry in ipairs({ "panel", "bar" }) do
        local h = host(mode[1], mode[2], entry, true)
        local lang = mode[3]
        equal(h.i18n.locale(), lang)
        equal(h.i18n.tr("ui.today"), lang == "gl" and "Hoxe" or "Today")
        equal(h.i18n.wind("Nordés feble"), lang == "gl" and "Nordés feble" or "Light northeast wind")
        equal(h.i18n.sky(111, "Chuvia"), lang == "gl" and "Chuvia" or "Rain")
        equal(h.i18n.sky(999, "Outro estado"), lang == "gl" and "Outro estado" or "Unknown")
        equal(h.i18n.weekdays(false)[1], lang == "gl" and "Luns" or "Monday")
        equal(h.i18n.months(true)[10], lang == "gl" and "out" or "Oct")
        local joined = table.concat(texts(h.tree()), "\n") .. "\n" .. (h.tooltip() or "")
        equal(joined:find(lang == "gl" and "Vento" or "Wind", 1, true) ~= nil, true)
        equal(joined:find(lang == "gl" and "Light northeast wind" or "Nordés feble", 1, true), nil)
        if entry == "panel" then
            equal(joined:find(lang == "gl" and "Vindeiros días" or "Forecast", 1, true) ~= nil, true)
            local svg = h.files["/tmp/meteogalicia_daily_trend.svg"]
            equal(svg:find(lang == "gl" and "Hoxe" or "Today", 1, true) ~= nil, true)
            equal(svg:find(lang == "gl" and "Chuvia" or "Rain", 1, true) ~= nil, true)
            h.env.onToggleSearchConcello()
            joined = table.concat(texts(h.tree()), "\n")
            equal(joined:find(lang == "gl" and "Buscar concello" or "Search municipality", 1, true) ~= nil, true)
        end
        -- Switching the plugin setting changes cached data and UI immediately.
        h.config.language = lang == "gl" and "en" or "gl"
        h.env.onConfigChanged()
        equal(h.i18n.locale(), lang == "gl" and "en" or "gl")
    end
end

for _, lang in ipairs({ "gl", "en" }) do
    for _, entry in ipairs({ "panel", "bar" }) do
        local h = host(lang, "en", entry, false)
        local errorValue = { key = "error.hourly_empty", date = "2026-10-23" }
        h.publish("weather_error", errorValue)
        local joined = table.concat(texts(h.tree()), "\n") .. "\n" .. (h.tooltip() or "")
        equal(joined:find(lang == "gl" and "Sen predición horaria" or "Hourly forecast unavailable", 1, true) ~= nil, true)
        h.config.language = lang == "gl" and "en" or "gl"
        h.env.onConfigChanged()
        equal(h.i18n.error(errorValue):find(lang == "gl" and "Hourly forecast unavailable" or "Sen predición horaria", 1, true) ~= nil, true)
    end
end

local service = host("en", "en", "service", false)
service.requests[1].callback({ ok = false, status = 503 })
equal(service.values.weather_error.key, "error.daily_http")
equal(service.i18n.error(service.values.weather_error), "Could not fetch the daily forecast (503)")
service.config.language = "gl"
service.i18n.refresh()
equal(service.i18n.error(service.values.weather_error), "Non se puido obter a predición diaria (503)")
print("i18n: " .. checks .. " checks passed (automatic/forced locales, panel, bar, SVG, errors and live switching)")
