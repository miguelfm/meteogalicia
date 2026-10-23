# Internationalization

MeteoGalicia for Noctalia maintains two complete catalogs:

* `translations/en.json`: English, also Noctalia's fallback catalog.
* `translations/gl-ES.json`: Galician, using Noctalia's canonical locale name.

Noctalia's [plugin translation catalog](https://github.com/noctalia-dev/noctalia/blob/main/src/scripting/plugin_i18n.cpp)
loads English first, then overlays the shell's resolved language. A file named
`gl.json` alone does not match a shell using `gl-ES`. The
[runtime API](https://docs.noctalia.dev/noctalia/plugins/development/runtime-api/#translations-and-data-helpers)
provides `noctalia.tr`; the
[shell language setting](https://docs.noctalia.dev/noctalia/configuration/shell/#shell-settings)
is `shell.lang`.

## Language selection

The plugin's `language` setting defaults to `auto`, following Noctalia. Optional
`gl` and `en` values override the panel and bar, useful when the weather display
should have a different language from the desktop. The selection applies to
existing data and structured errors without waiting for another weather request.

`i18n.luau` uses the native translator in automatic mode. For an explicit override,
it reads the same JSON catalogs through plugin-relative `noctalia.readFile` and
caches them; there is no separately maintained copy of the strings. `meta.locale`
identifies the resolved catalog without guessing from a translated word.

Settings labels belong to Noctalia's settings UI and follow the shell language.
Changing the plugin preference does not change the desktop language. To use
Galician throughout Noctalia, set `lang = "gl-ES"` under `[shell]`.

## Content and maintenance

UI labels, tooltips, errors, dates, sky conditions, standard wind descriptions,
air-quality grades and UV risks are localized. Forecast values and timestamps
remain unchanged. Municipality and station names keep their official spelling.
The provider's free-form official outlook remains in its original Galician and
is identified as such in English. It is source content rather than an automatic
machine translation of the forecast.

Edit both catalogs when adding strings. Keep their keys and formatting
placeholders identical. Dynamic values such as HTTP status and missing dates
are stored separately from error keys, so an already displayed error changes
language immediately. Unknown sky codes use a localized unknown label in English
and may retain an informative source description in Galician.

## Verification

```sh
TZ=Europe/Madrid luau tests/forecast_test.luau
python tests/check_i18n.py
noctalia plugins lint .
```

Pass `--luau /path/to/luau` to the Python runner when the interpreter is not on
`PATH`. It validates matching catalog keys/placeholders and all declared setting
labels, then injects the real plugin modules into an isolated Luau host. Checks
exercise automatic English/Galician, both explicit overrides, municipality
search, bar tooltips, generated SVG labels, loading/errors and language changes
with existing data. The runner does not access the network or modify Noctalia.
