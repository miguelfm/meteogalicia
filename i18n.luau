--!nonstrict
-- Noctalia owns the default locale. A per-plugin override reads the same JSON
-- catalogs used by the shell, so each language has one maintained source.
local i18n = {}
local catalogs = {}
local language = "en"
local automatic = true

local function catalog(lang)
    if catalogs[lang] then return catalogs[lang] end
    local values = {}
    if noctalia and noctalia.readFile and noctalia.json then
        local path = lang == "gl" and "translations/gl-ES.json" or "translations/en.json"
        local ok, raw = pcall(noctalia.readFile, path)
        if ok and type(raw) == "string" then
            local decodedOk, decoded = pcall(noctalia.json.decode, raw)
            if decodedOk and type(decoded) == "table" then values = decoded end
        end
    end
    catalogs[lang] = values
    return values
end

function i18n.refresh()
    local choice = noctalia and noctalia.getConfig and noctalia.getConfig("language") or "auto"
    automatic = choice ~= "gl" and choice ~= "en"
    if automatic then
        local resolved = noctalia and noctalia.tr and noctalia.tr("meta.locale") or "en"
        language = (resolved == "gl" or resolved == "gl-ES") and "gl" or "en"
    else
        language = choice
    end
end

function i18n.locale()
    return language
end

function i18n.tr(key, fallback)
    if automatic and noctalia and noctalia.tr then
        local translated = noctalia.tr(key)
        if type(translated) == "string" and translated ~= "" and translated ~= key then return translated end
    end
    return catalog(language)[key] or catalog("en")[key] or fallback or key
end

function i18n.format(key, ...)
    return string.format(i18n.tr(key), ...)
end

function i18n.error(value)
    if type(value) ~= "table" then return tostring(value or "") end
    local message = i18n.tr(value.key or "ui.error_load")
    if value.status ~= nil then return string.format(message, tostring(value.status)) end
    if value.network then return string.format(message, i18n.tr("error.network")) end
    if value.date then return string.format(message, value.date) end
    return message
end

function i18n.sky(code, fallback)
    local key = "sky." .. tostring(code or "unknown")
    if catalog(language)[key] or catalog("en")[key] then return i18n.tr(key) end
    if language == "gl" and type(fallback) == "string" and fallback ~= "" then return fallback end
    return i18n.tr("sky.unknown")
end

local windWords = {
    vento = "wind", ventos = "winds", calma = "calm", calmo = "calm",
    norte = "north", sur = "south", leste = "east", este = "east", oeste = "west",
    ["nordés"] = "northeast", nordeste = "northeast", noroeste = "northwest",
    sueste = "southeast", sureste = "southeast", sudoeste = "southwest", suroeste = "southwest",
    feble = "light", febles = "light", frouxo = "light", frouxos = "light",
    moderado = "moderate", moderados = "moderate", forte = "strong", fortes = "strong",
    moi = "very", variable = "variable", variables = "variable",
    con = "with", refachos = "gusts", refacho = "gust", rachas = "gusts",
    de = "from", ["do"] = "from", da = "from", ["compoñente"] = "component",
    a = "to", e = "and", predominio = "predominantly", ocasionalmente = "occasionally",
}

function i18n.wind(description)
    local text = tostring(description or "")
    if language == "gl" then return text end
    local direction, strength = text:lower():match("^(%S+)%s+(.+)$")
    local directionKey = direction and windWords[direction]
    local strengthKey = ({ feble = "light", frouxo = "light", moderado = "moderate",
        forte = "strong", ["moi forte"] = "very_strong" })[strength or ""]
    if directionKey and strengthKey then
        return i18n.format("wind.summary", i18n.tr("wind." .. strengthKey), i18n.tr("wind." .. directionKey))
    end
    return (text:gsub("[A-Za-z\128-\255]+", function(word)
        local key = windWords[word:lower()]
        return key and i18n.tr("wind." .. key) or word
    end))
end

function i18n.weekdays(short)
    local values = {}
    for day = 0, 6 do
        values[day] = i18n.tr("calendar.weekdays_" .. (short and "short." or "full.") .. tostring(day))
    end
    return values
end

function i18n.months(short)
    local values = {}
    for month = 1, 12 do
        values[month] = i18n.tr("calendar.months_" .. (short and "short." or "full.") .. tostring(month))
    end
    return values
end

i18n.refresh()
return i18n
