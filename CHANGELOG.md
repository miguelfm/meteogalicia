# Changelog

## 1.1.2 — 2026-10-27

- Adapt to Noctalia 5.4 (`plugin_api = 43`) and Material 3 palette tokens (`surface_container`, `outline_variant`).
- Calibrate panel dimensions for `height = "content"` with `max_height = 980`, fitting the `xlarge` 4K preset without overflow or excess empty space.
- Fine-tune `xlarge` vertical rhythm (chart height, padding and gaps) so the full forecast view fits within the panel geometry.
- Preserve direct hourly mouse-wheel stepping by avoiding unwanted root scroll interception.

## 1.1.1 — 2026-10-23

- Align hourly curves, rain/wind timelines and the current-time marker with local
  calendar dates, including daylight-saving transitions and missing forecast days.
- Keep gaps where hourly forecasts are unavailable instead of repeating daily
  summaries or drawing interpolated hourly curves across missing data.
- Display missing or invalid rain probabilities, including the provider's `-9999`
  marker, as unavailable rather than 0%; use hollow timeline marks for missing rain.
- Correct calendar timestamps for Luau's UTC interpretation of `os.time` fields.
- Extend forecast regressions to cover missing rain, partial coverage and spring
  and autumn clock changes.

## 1.1.0 — 2026-10-23

- Complete Galician and English UI catalogs, including tooltips, calendar dates,
  charts, sky conditions, standard wind descriptions, air quality and UV risks.
- Add a plugin language setting: Automatic (Noctalia), Galego or English.
  Automatic remains the default; native settings labels follow the shell language.
- Use Noctalia's `gl-ES` locale filename so Galician loads in automatic mode.
- Translate structured errors and existing weather data immediately when the
  language changes, without another request to the weather provider.
- Keep official municipality/station names and the provider's Galician outlook;
  identify the outlook's original language in the English interface.
- Add catalog and mocked-host regression checks for both automatic languages,
  explicit overrides, bar/panel rendering, SVG labels and cached errors.

See [Internationalization](docs/internationalization.md) for configuration,
implementation details and verification commands.
