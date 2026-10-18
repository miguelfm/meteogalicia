--!strict
-- Shared utilities, constants and MeteoGalicia mapping tables.

local shared = {}

shared.API_KEY = "eyJ4NXQiOiJObUU1TXpSbVpXSmtNREZtT1RJeFlqWTFNRE00TmpnM1pqVmlOR0k1WkdZM09HTXpPVEJsTURNelpUQmhOalJtWVdJNE9HUmpOR1ZpTldKak1qZGpZUSIsImtpZCI6ImdhdGV3YXlfY2VydGlmaWNhdGVfYWxpYXMiLCJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJhZG1pbkBjYXJib24uc3VwZXIiLCJhcHBsaWNhdGlvbiI6eyJvd25lciI6ImFkbWluIiwidGllclF1b3RhVHlwZSI6bnVsbCwidGllciI6IlVubGltaXRlZCIsIm5hbWUiOiJ3X21ldGVvMiIsImlkIjozMzAxLCJ1dWlkIjoiMmNhMDI4N2ItNWYzYy00NGMzLTg3ZGEtOWY5ODg3NWZjNjk5In0sImlzcyI6Imh0dHBzOlwvXC9wcmQtd3NvMmFwaW0tYzAxLTAwMDEueHVudGEubG9jYWw6OTQ0NFwvb2F1dGgyXC90b2tlbiIsInRpZXJJbmZvIjp7IlB1YmxpYyI6eyJ0aWVyUXVvdGFUeXBlIjoicmVxdWVzdENvdW50IiwiZ3JhcGhRTE1heENvbXBsZXhpdHkiOjAsImdyYXBoUUxNYXhEZXB0aCI6MCwic3RvcE9uUXVvdGFSZWFjaCI6dHJ1ZSwic3Bpa2VBcnJlc3RMaW1pdCI6MCwic3Bpa2VBcnJlc3RVbml0Ijoic2VjIn19LCJrZXl0eXBlIjoiUFJPRFVDVElPTiIsInBlcm1pdHRlZFJlZmVyZXIiOiIiLCJzdWJzY3JpYmVkQVBJcyI6W3sic3Vic2NyaWJlclRlbmFudERvbWFpbiI6ImNhcmJvbi5zdXBlciIsIm5hbWUiOiJNRVRFTzJfQVBJIiwiY29udGV4dCI6IlwvbWV0ZW8yYXBpXC92MSIsInB1Ymxpc2hlciI6IkFNVEVHQVwvdWUwODIwNSIsInZlcnNpb24iOiJ2MSIsInN1YnNjcmlwdGlvblRpZXIiOiJQdWJsaWMifV0sInBlcm1pdHRlZElQIjoiIiwiaWF0IjoxNjk0MDk1MzMzLCJqdGkiOiI1NzkwYmM5NC04M2Y2LTQ4YTgtODg3Yy02MmQyNDJiMTJmZDYifQ==.W9Uc6D5te5GhMcWb-ewkiuor8rpNX5S3P89LSvrewNxNffwkQ5LC47OiSIwx0NOhZ9YKSiOf0i5L2MDjA8Roezp1xkPzC1Cx6ESkuTaXtIgu0iP4mUo6pCmwywWLhDO7_fz58k6PnPAYyehQ6R8r85nEx3Wr9F9e1u-WZx2zGTFGpqvTU9jFA1d4rlcTjTK7eGuIFSbQn6goko8elKFe3GajzGy8r6NtJLMvSgxhSpftsykx-tpGyoUVVH90dTiEul927JiYvqgOsCKa4FU1tVVY3Y9t8AJByJqsOeTz64R7KIe9A8C2WB29IewjKxDkrsypFODpOQHkIbEDhZ5g8Q=="

shared.BASE_API = "https://apis-ext.xunta.gal/meteo2api/v1/api/"

export type SkyInfo = {
    glyph: string,
    desc: string,
    color: string,
}

local SKY_TABLE: { [number]: SkyInfo } = {
    -- Diúrno (101 - 126)
    [101] = { glyph = "sun", desc = "Despexado", color = "tertiary" },
    [102] = { glyph = "cloud-sun", desc = "Nubes altas", color = "tertiary" },
    [103] = { glyph = "cloud-sun", desc = "Nubes e claros", color = "primary" },
    [104] = { glyph = "cloud", desc = "Nubrado", color = "on_surface_variant" },
    [105] = { glyph = "cloud", desc = "Moi nubrado", color = "on_surface_variant" },
    [106] = { glyph = "cloud-fog", desc = "Néboas", color = "on_surface_variant" },
    [107] = { glyph = "cloud-rain", desc = "Chuvasco", color = "secondary" },
    [108] = { glyph = "cloud-rain", desc = "Nubrado con chuvascos", color = "secondary" },
    [109] = { glyph = "cloud-snow", desc = "Chuvasco de neve", color = "secondary" },
    [110] = { glyph = "cloud-rain", desc = "Orballo", color = "secondary" },
    [111] = { glyph = "cloud-rain", desc = "Chuvia", color = "secondary" },
    [112] = { glyph = "snowflake", desc = "Neve", color = "secondary" },
    [113] = { glyph = "cloud-storm", desc = "Treboada", color = "error" },
    [114] = { glyph = "cloud-fog", desc = "Brétema", color = "on_surface_variant" },
    [115] = { glyph = "cloud-fog", desc = "Bancos de néboa", color = "on_surface_variant" },
    [116] = { glyph = "clouds", desc = "Cuberto", color = "on_surface_variant" },
    [117] = { glyph = "cloud-rain", desc = "Chuvia débil", color = "secondary" },
    [118] = { glyph = "cloud-rain", desc = "Chuvascos débiles", color = "secondary" },
    [119] = { glyph = "cloud-storm", desc = "Treboada con claros", color = "error" },
    [120] = { glyph = "cloud-snow", desc = "Chuvasco auganeve", color = "secondary" },
    [121] = { glyph = "cloud-rain", desc = "Sarabia", color = "secondary" },
    [122] = { glyph = "cloud-rain", desc = "Chuvia ocasional", color = "secondary" },
    [123] = { glyph = "cloud-snow", desc = "Nubrado con neve", color = "secondary" },
    [124] = { glyph = "sun", desc = "Calixe seca", color = "tertiary" },
    [125] = { glyph = "clouds", desc = "Cuberto", color = "on_surface_variant" },
    [126] = { glyph = "cloud-storm", desc = "Chuvia intensa", color = "secondary" },

    -- Nocturno (201 - 226)
    [201] = { glyph = "moon", desc = "Despexado", color = "primary" },
    [202] = { glyph = "moon-stars", desc = "Nubes altas", color = "primary" },
    [203] = { glyph = "moon-stars", desc = "Nubes e claros", color = "primary" },
    [204] = { glyph = "cloud", desc = "Nubrado", color = "on_surface_variant" },
    [205] = { glyph = "cloud", desc = "Moi nubrado", color = "on_surface_variant" },
    [206] = { glyph = "cloud-fog", desc = "Néboas", color = "on_surface_variant" },
    [207] = { glyph = "cloud-rain", desc = "Chuvasco", color = "secondary" },
    [208] = { glyph = "cloud-rain", desc = "Nubrado con chuvascos", color = "secondary" },
    [209] = { glyph = "cloud-snow", desc = "Chuvasco de neve", color = "secondary" },
    [210] = { glyph = "cloud-rain", desc = "Orballo", color = "secondary" },
    [211] = { glyph = "cloud-rain", desc = "Chuvia", color = "secondary" },
    [212] = { glyph = "snowflake", desc = "Neve", color = "secondary" },
    [213] = { glyph = "cloud-storm", desc = "Treboada", color = "error" },
    [214] = { glyph = "cloud-fog", desc = "Brétemas", color = "on_surface_variant" },
    [215] = { glyph = "cloud-fog", desc = "Bancos de néboa", color = "on_surface_variant" },
    [217] = { glyph = "cloud-rain", desc = "Chuvia débil", color = "secondary" },
    [218] = { glyph = "cloud-rain", desc = "Chuvia ocasional", color = "secondary" },
    [219] = { glyph = "cloud-storm", desc = "Treboada", color = "error" },
    [220] = { glyph = "cloud-snow", desc = "Auganeve", color = "secondary" },
    [221] = { glyph = "cloud-rain", desc = "Sarabia", color = "secondary" },
    [222] = { glyph = "cloud-rain", desc = "Chuvia ocasional", color = "secondary" },
    [223] = { glyph = "cloud-snow", desc = "Nubrado con neve", color = "secondary" },
    [224] = { glyph = "moon-stars", desc = "Calixe seca", color = "primary" },
    [225] = { glyph = "clouds", desc = "Cuberto", color = "on_surface_variant" },
    [226] = { glyph = "cloud-storm", desc = "Chuvia intensa", color = "secondary" },
}

function shared.getSky(code: number?): SkyInfo
    if code ~= nil and SKY_TABLE[code] ~= nil then
        return SKY_TABLE[code]
    end
    return { glyph = "cloud", desc = "Descoñecido", color = "on_surface_variant" }
end

function shared.cleanHtml(text: string?): string
    if type(text) ~= "string" then return "" end
    local clean = text:gsub("<br%s*/?>", "\n"):gsub("&lt;br%s*/?&gt;", "\n")
    clean = clean:gsub("&amp;", "&"):gsub("&quot;", '"'):gsub("&#39;", "'")
    clean = clean:gsub("<[^>]+>", "")
    return (clean:gsub("^%s+", ""):gsub("%s+$", ""))
end

shared.WEEKDAYS_GL = {
    [0] = "Domingo",
    [1] = "Luns",
    [2] = "Martes",
    [3] = "Mércores",
    [4] = "Xoves",
    [5] = "Venres",
    [6] = "Sábado",
}

shared.WEEKDAYS_EN = {
    [0] = "Sunday",
    [1] = "Monday",
    [2] = "Tuesday",
    [3] = "Wednesday",
    [4] = "Thursday",
    [5] = "Friday",
    [6] = "Saturday",
}

shared.MONTHS_GL = {
    [1] = "xan", [2] = "feb", [3] = "mar", [4] = "abr",
    [5] = "mai", [6] = "xuñ", [7] = "xul", [8] = "ago",
    [9] = "set", [10] = "out", [11] = "nov", [12] = "dec",
}

shared.MONTHS_EN = {
    [1] = "Jan", [2] = "Feb", [3] = "Mar", [4] = "Apr",
    [5] = "May", [6] = "Jun", [7] = "Jul", [8] = "Aug",
    [9] = "Sep", [10] = "Oct", [11] = "Nov", [12] = "Dec",
}

return shared
