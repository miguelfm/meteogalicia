# Changelog

## 1.3.0 — 2026-10-31

- Engadir vista detallada interactiva da calidade do aire premendo na tarxeta da cabeceira ou cos atallos de teclado `A` / `Q` (e `Esc` para pechar):
  - Dashboard comparativo das 3 estacións de medición máis próximas á capitalidade municipal ordenadas por distancia xeodésica real.
  - Para cada estación: distancia estimada (~km), hora da lectura, índice ICA continuo e estado descritivo con código de cor estándar, contaminante determinante coa súa concentración exacta ($\mu\text{g}/\text{m}^3$) e consello de saúde.
  - Ligazón directa ao portal oficial de calidade do aire de MeteoGalicia.
  - Transición limpa que substitúe a predición meteorolóxica mentres estea activa a vista detallada, garantindo un axuste vertical perfecto sen barras de desprazamento.

## 1.2.0 — 2026-10-31

- Integrar a rede de estacións de calidade do aire de MeteoGalicia en tempo real (`jsonICAActual.action`).
- Abrir un tooltip flotante detallado ao pousar o rato sobre a tarxeta de calidade do aire con:
  - Estación de referencia máis próxima e distancia comarcal estimada en quilómetros (cálculo xeodésico dende a capitalidade municipal).
  - Contaminante determinante crítico ($\text{PM}_{2.5}$, $\text{PM}_{10}$, $\text{NO}_2$, $\text{O}_3$, $\text{SO}_2$) e a súa concentración exacta en $\mu\text{g}/\text{m}^3$.
  - Índice cuantitativo continuo (ICA) e hora da última medición validada.
  - Recomendación sanitaria e de actividade exterior segundo o nivel oficial de calidade do aire.
  - Fallback automático á predición xeral do modelo municipal para zonas sen estación próxima ou incidencias no servizo.
- Actualizar os catálogos de tradución (`gl-ES` e `en`) con paridade estrita de claves e parámetros.

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
