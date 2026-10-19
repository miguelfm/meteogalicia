# MeteoGalicia para Noctalia (v5)

Plugin nativo para o shell de escritorio **Noctalia** (en Wayland / Hyprland) que amosa a predición meteorolóxica oficial de Galicia por concellos, conectándose directamente á API REST de **MeteoGalicia** (`meteo2api` da Xunta de Galicia).

![Noctalia Plugin](https://img.shields.io/badge/Noctalia-v5_Plugin-7c3aed?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)
![Data Source](https://img.shields.io/badge/Data-MeteoGalicia_REST_API-0284c7?style=flat-square)

---

## Características

* **Predición Oficial Galega**: Conexión directa cos modelos numéricos e sinópticos de alta resolución de MeteoGalicia (non modelos globais xenéricos).
* **Cápsula na Barra (`bar`)**:
  * Glifo do estado do ceo dinámico con variación diúrna e nocturna (máis de 25 estados: despexado, nubes e claros, orballo, treboada, néboas, sarabia, etc.).
  * Temperatura actual e probabilidade de precipitación en tempo real.
  * Nome do concello configurábel.
  * *Tooltip* con rango diario de temperaturas mín/máx, vento, horarios solares (amencer e solpor) e hora da última actualización.
  * **Interacción co rato**:
    * Clic esquerdo para abrir ou pechar o panel detallado.
    * Clic dereito para forzar unha actualización inmediata dos datos.
    * Roda do rato para desprazar a predición horaria hora a hora dende a propia barra.
* **Panel Emerxente Completo (`panel`)**:
  * **Cabeceira de condicións actuais**: Glifo de gran formato, descrición sinóptica, temperatura instantánea, temperaturas máxima/mínima da xornada e horarios de amencer e solpor con separadores visuais elegantes.
  * **Predición horaria interactiva (ata 48 horas, opcional)**:
    * Carrusel con tarxetas horarias mostrando a hora, glifo, temperatura prevista e probabilidade de choiva (💧 %).
    * Navegación fluída por bloques de 12 horas (`0h-12h`, `12h-24h`, `24h-36h`, `36h-48h`) con frechas na cabeceira.
    * Separadores visuais discretos e data centrada no cambio de día para identificar comodamente a transición entre xornadas.
    * Desprazamento hora a hora ou por bloques mediante teclado e roda do rato.
    * Oculto por defecto mediante a opción `show_hourly_cards`, xa que o novo timeline integrado permite prescindir deste bloque mantendo unha interface máis limpa e compacta.
  * **Gráfico interactivo dos vindeiros días**:
    * Gráfico continuo xerado en SVG nativo coas curvas de temperatura máxima e mínima para 4 días completos (combinando a predición a curto e medio prazo oficial de MeteoGalicia).
    * **Liña continua de evolución horaria (48h/72h/96h)**: Trazo suave en ton predominantemente gris con leve matiz verde (`#8f9690` en tema escuro, `#58605a` en tema claro), calibrado para destacar con elegancia sen saturar a interface fronte ao azul da precipitación e ás curvas térmicas diúrnas.
    * **Indicador de vento compacto**: Integración na terceira liña da cabeceira de cada día (frecha con orientación real de compás e descrición de intensidade), cun espazado vertical optimizado (22-24px) que aproveita ao máximo o layout.
    * **Adaptación dinámica ao tema (claro e escuro)**: Detección automática do modo activo e da paleta do sistema (`isDarkMode`, `getColor`), con fondos de tarxeta, tipografía, aneis térmicos e iconas optimizados para un contraste e integración visual impecables tanto en tema escuro coma en tema claro.
    * Cabeceira integrada de cada día co nome do día e data (`Hoxe, 19 out`, `Mañá, 20 out`, etc.) combinando tipografía destacada e atenuada.
  * **Timeline sincronizado de probabilidade de chuvia e cambios meteorolóxicos**:
    * Situado discretamente ao pé do gráfico e sincronizado verticalmente ao 100% coas horas da curva horaria de temperaturas.
    * **Barras de probabilidade de precipitación**: Columnas azuis con alturas proporcionais para cada hora das 96 horas de predición continua.
    * **Iconas contextuais nos cambios de tempo**: As iconas do ceo colócanse dinamicamente cando o estado meteorolóxico muda (inicio ou remate de chuvascos, chuvia, despexado, nubes e claros, néboas ou caída da noite), con priorización de fenómenos adversos e resolución intelixente de conflitos para evitar calquera solapamento.
    * **Marcador dinámico *Agora* (*Now*)**: Posicionamento en tempo real aliñado co fuso horario local.
    * **Demarcación de xornadas**: Indicadores de cambio de día (`00h`) en letra grosa para unha navegación temporal intuitiva.
    * **Tooltip estruturado en 3 liñas**: Ao pasar o rato amosa o día e hora exacta, a temperatura con descrición do ceo, e a probabilidade de choiva (ex: `Luns, 19 ás 14:00 \n 18°C · Despexado \n Choiva: 25%`).
    * **Interacción directa**: Clic en calquera hora do timeline sincroniza a predición horaria instantaneamente.
  * **Comentario oficial**: Análise sinóptica redactada polos meteorólogos de MeteoGalicia sobre a evolución atmosférica en Galicia.
  * **Indicadores ambientais**: Índice de Calidade do Aire (ICA) e Índice de Radiación Ultravioleta máximo (UV).
  * **Acceso directo**: Botón para abrir a predición do concello na web oficial de MeteoGalicia.
* **Cero dependencias externas**: Desenvolvido 100% en Luau nativo usando as APIs asíncronas de Noctalia (`noctalia.http`, `noctalia.state`, `noctalia.ui`).

---

## Navegación e Atallos de Teclado

Cando o panel estea aberto, pódense empregar os seguintes controis e atallos directos:

| Tecla / Xesto | Acción |
| :--- | :--- |
| <kbd>←</kbd> (Frecha Esquerda) ou <kbd>[</kbd> | Desprazar a predición horaria **1 hora cara atrás** |
| <kbd>→</kbd> (Frecha Dereita) ou <kbd>]</kbd> | Desprazar a predición horaria **1 hora cara adiante** |
| <kbd>Re Páx</kbd> (Page Up) | Retroceder **12 horas** (bloque anterior) |
| <kbd>Av Páx</kbd> (Page Down) | Avanzar **12 horas** (bloque seguinte) |
| <kbd>Inicio</kbd> (Home) | Saltar ao inicio (**primeiras 12 horas**) |
| <kbd>Fin</kbd> (End) | Saltar ao remate (**último bloque de 12 horas**) |
| **Roda do rato** | Desprazar hora a hora (tanto sobre o panel como sobre a cápsula da barra) |
| <kbd>R</kbd> | Forzar a actualización inmediata dos datos dende a API |
| <kbd>S</kbd> / <kbd>C</kbd> | Abrir a xanela de axustes do plugin en Noctalia |
| <kbd>Esc</kbd> | Pechar o panel emerxente |

---

## Instalación

Podes ligar o cartafol directamente á ruta de plugins locais de Noctalia:

```bash
ln -s ~/Projects/meteogalicia ~/.config/noctalia/plugins/meteogalicia
```

Logo recarga a configuración de Noctalia:

```bash
noctalia msg config-reload
```

E engade o widget `miguelfm/meteogalicia:bar` á túa barra no ficheiro `settings.toml` ou mediante o editor visual de Noctalia.

---

## Configuración (`plugin.toml`)

O plugin pódese configurar dende o centro de control de Noctalia ou editando as súas opcións:

| Clave | Tipo | Valor por defecto | Descrición |
| :--- | :--- | :--- | :--- |
| `concello_id` | `int` | `15035` | Código INE do concello (ex: `15035` Fene, `15036` Ferrol, `15030` A Coruña, `15078` Santiago, `36057` Vigo, `32054` Ourense, `27028` Lugo, `36038` Pontevedra). |
| `concello_name` | `string` | `Fene` | Nome amosado na barra e na cabeceira do panel. |
| `refresh_minutes`| `int` | `30` | Frecuencia de actualización en minutos (mínimo 5, máximo 180). |
| `show_town_name` | `bool` | `false` | Amosa o nome do concello xunto ao glifo na barra. |
| `show_rain_prob` | `bool` | `true` | Amosa a probabilidade de choiva na barra se é superior ao 0%. |
| `show_hourly_cards` | `bool` | `false` | Amosa o carrusel de tarxetas horarias no panel (oculto por defecto ao integrarse o timeline no gráfico). |
| `hours_count` | `int` | `48` | Número de horas solicitadas á API e dispoñibles para navegar (12, 24, 36 ou 48). |
| `show_daily_summary` | `bool` | `true` | Amosa o gráfico de predición e temperaturas dos vindeiros días. |
| `show_daily_hourly_curve` | `bool` | `true` | Amosa a liña continua de temperaturas horarias dentro do gráfico diario. |
| `ui_scale` | `select` | `large` | Escala xeral da interface, tipografía e iconas (`normal`, `large`, `xlarge`) optimizada para pantallas estándar e HiDPI/4K. |
| `panel_opacity` | `select` | `opaque` | Estilo e opacidade do fondo do panel (`opaque`, `subtle`, `glass`). |

---

## Estrutura do Proxecto

```text
meteogalicia/
├── plugin.toml       # Manifesto do plugin, axustes e definición de compoñentes
├── bar.luau          # Widget da barra (cápsula, tooltip, eventos de clic e scroll)
├── panel.luau        # Panel emerxente interactivo (UI reactiva, navegación, atallos de teclado)
├── service.luau      # Servizo en segundo plano (peticións HTTP a meteo2api, caché e estado)
├── shared.luau       # Mapeo de códigos MeteoGalicia, xerador de gráfico SVG e utilidades
├── translations/     # Internacionalización (gl.json en galego, en.json en inglés)
└── LICENSE           # Licenza MIT
```

---

## API de MeteoGalicia

Este proxecto emprega a API REST pública oficial da **Consellería de Medio Ambiente e Cambio Climático - Xunta de Galicia**:
* **Servizo Numérico**: `getNumericForecastInfo` (predición horaria e datos modelizados).
* **Servizo Sinóptico**: `getDailyForecastInfo` (predición xeral por concellos e comentarios dos predictores).
* **Información Xeral**: [MeteoGalicia](https://www.meteogalicia.gal/).

---

## Licenza

Distribuído baixo licenza [MIT](LICENSE). Desenvolvido por [miguelfm](https://github.com/miguelfm).
