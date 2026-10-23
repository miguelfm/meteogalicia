# Changelog

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
