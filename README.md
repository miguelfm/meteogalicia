# MeteoGalicia para Noctalia (v5)

> **Proxecto persoal e non oficial**, desenvolvido e mantido por `miguelfm`.
> Non está afiliado, patrocinado nin avalado por MeteoGalicia ou pola Xunta de Galicia.
> Emprega as súas APIs públicas como fonte de datos meteorolóxicos.

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
  * **Cabeceira de condicións actuais**:
    * Glifo de gran formato, concello e descrición sinóptica xeral.
    * **Buscador interactivo de concellos**: Botón de busca xunto ao nome do municipio (ou premendo <kbd>F</kbd> / <kbd>/</kbd>) que desprega un selector rápido e amplo:
      * **Caixa de busca de ancho completo**: Campo de entrada con foco automático inmediato (`focus = true`), atallo rápido <kbd>Esc</kbd> e botón de peche visible.
      * **Filtros por provincia e reconto dinámico**: Fila independente con pestanas rápidas (*Todas*, *A Coruña*, *Lugo*, *Ourense*, *Pontevedra*) e reconto en tempo real de resultados (ex: *313 concellos*).
      * **Grella a 3 columnas amplas**: Disposición espazosa a 3 columnas (ou 2 en pantallas máis estreitas) deseñada para acomodar con total folgura nomes compostos e longos (ex: *Barco de Valdeorras (O)*, *Xunqueira de Espadanedo*, *Pobra do Caramiñal (A)*), amosando nome destacado en negriña, provincia, código INE e marca de verificación (✓) no municipio activo.
      * **Desprazamento vertical fluído**: Listaxe con altura fixa calibrada (`height = 280`), filtrado insensible a maiúsculas/tiles e persistencia inmediata en `settings.toml` mediante `set_concello.py`.
    * Bloque central con 5 tarxetas métricas homoxéneas:
      * **Horarios solares**: Orto (amencer) e Ocaso (solpor) calculados astronomicamente polas coordenadas exactas do municipio.
      * **Vento actual**: Frecha vectorial de orientación real de compás (`↑`, `↗`, `→`, `↘`, `↓`, `↙`, `←`, `↖`), velocidade instantánea en km/h e descrición oficial no *tooltip*.
      * **Humidade relativa en tempo real (💧 %)**: Conexión directa coa rede de observación cada 10 minutos de MeteoGalicia (`ultimos10minEstacionsMeteo`), emparellando automaticamente coa estación meteorolóxica máis próxima ao concello (ex: CIS Ferrol para Fene).
      * **Calidade do aire (ICA)**: Avaliación cualitativa actual (*Boa*, *Razoable*, *Mala*, *Moi mala*) con indicador cromático adaptado.
    * Temperatura instantánea destacada con graos centígrados, rango diario de temperaturas mínima e máxima (`↓ mín° ↑ máx°`), e botóns de axustes e actualización inmediata.
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
  * **Timeline sincronizado de probabilidade de chuvia e vento (96 horas)**:
    * Situado ao pé do gráfico e sincronizado verticalmente ao 100% coas horas da curva horaria de temperaturas.
    * **Barras de probabilidade de precipitación**: Columnas azuis con alturas proporcionais para cada hora de predición continua.
    * **Previsión horaria do vento integrada**: Frechas Unicode de dirección e velocidade en km/h con escala cromática de intensidade en cada columna horaria de referencia.
    * **Iconas contextuais nos cambios de tempo**: As iconas do ceo colócanse dinamicamente cando o estado meteorolóxico muda (inicio ou remate de chuvascos, chuvia, despexado, nubes e claros, néboas ou caída da noite), con priorización de fenómenos adversos e resolución intelixente de conflitos para evitar calquera solapamento.
    * **Marcador dinámico *Agora* (*Now*)**: Posicionamento en tempo real aliñado co fuso horario local.
    * **Demarcación de xornadas**: Indicadores de cambio de día (`00h`) en letra grosa para unha navegación temporal intuitiva.
    * **Tooltip estruturado en 4 liñas**: Ao pasar o rato amosa data e hora, temperatura con descrición do ceo, probabilidade de choiva e vento previsto (ex: `Luns, 19 out ás 14:00 \n 18°C · Nubes e Claros \n Choiva: 25% \n Vento: Nordés feble (10 km/h)`).
    * **Barra diúrno/nocturna astronómica (`dayNightBar`)**: Situada xusto debaixo da tarxeta de choiva/vento e sincronizada ao píxel coas 96 horas, con cápsulas diúrnas douradas que presentan a radiación ultravioleta máxima (`☀️ UV`) e a calidade do aire (`🍃 ICA`), pistas nocturnas con símbolo lunar e separadores verticais a medianoite.
    * **Interacción directa**: Clic en calquera hora do timeline ou da barra solar sincroniza a predición horaria instantaneamente.
  * **Comentario oficial (*Evolución xeral* / *Outlook*)**: Análise sinóptica oficial redactada polos meteorólogos de MeteoGalicia sobre a evolución atmosférica en Galicia.
  * **Pé de páxina informativo**: Índice UV máximo previsto da xornada, estación meteorolóxica de referencia empregada para as lecturas actuais e hora da última sincronización.
  * **Acceso directo**: Botón para abrir a predición do concello na web oficial de MeteoGalicia.
* **Cero dependencias externas**: Desenvolvido 100% en Luau nativo usando as APIs asíncronas de Noctalia (`noctalia.http`, `noctalia.state`, `noctalia.ui`).

---

## Navegación e Atallos de Teclado

Cando o panel estea aberto, pódense empregar os seguintes controis e atallos directos:

| Tecla / Xesto | Acción |
| :--- | :--- |
| <kbd>F</kbd> ou <kbd>/</kbd> | Abrir / pechar o **buscador interactivo de concellos** (313 municipios) |
| <kbd>←</kbd> (Frecha Esquerda) ou <kbd>[</kbd> | Desprazar a predición horaria **1 hora cara atrás** |
| <kbd>→</kbd> (Frecha Dereita) ou <kbd>]</kbd> | Desprazar a predición horaria **1 hora cara adiante** |
| <kbd>Re Páx</kbd> (Page Up) | Retroceder **12 horas** (bloque anterior) |
| <kbd>Av Páx</kbd> (Page Down) | Avanzar **12 horas** (bloque seguinte) |
| <kbd>Inicio</kbd> (Home) | Saltar ao inicio (**primeiras 12 horas**) |
| <kbd>Fin</kbd> (End) | Saltar ao remate (**último bloque de 12 horas**) |
| **Roda do rato** | Desprazar hora a hora (tanto sobre o panel como sobre a cápsula da barra) |
| <kbd>R</kbd> | Forzar a actualización inmediata dos datos dende a API |
| <kbd>S</kbd> / <kbd>C</kbd> | Abrir a xanela de axustes do plugin en Noctalia |
| <kbd>Esc</kbd> | Pechar a busca de concellos / Pechar o panel emerxente |

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

Se o plugin xa está instalado mediante esta ligazón, os cambios no repositorio
aplícanse á instalación local. Tras actualizalo, podes recargar a configuración
e solicitar unha consulta inmediata:

```bash
noctalia msg config-reload
noctalia msg plugin miguelfm/meteogalicia:poller all refresh
```

---

## Configuración (`plugin.toml`)

O plugin pódese configurar dende o centro de control de Noctalia ou editando as súas opcións:

| Clave | Tipo | Valor por defecto | Descrición |
| :--- | :--- | :--- | :--- |
| `concello_id` | `int` | `15035` | Código INE do concello (campo numérico sen selector deslizante). Tamén seleccionable de xeito inmediato no panel emerxente con <kbd>F</kbd>. |
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
├── plugin.toml            # Manifesto do plugin, axustes e definición de compoñentes
├── bar.luau               # Widget da barra (cápsula, tooltip, eventos de clic e scroll)
├── panel.luau             # Panel emerxente interactivo (UI reactiva, navegación, buscador de concellos)
├── service.luau           # Servizo en segundo plano (peticións HTTP a meteo2api e observacións en tempo real)
├── concellos.luau         # Catálogo oficial dos 313 concellos de Galicia con coordenadas e códigos INE
├── stations.luau          # Catálogo oficial de estacións meteorolóxicas e coordenadas para humidade en tempo real
├── shared.luau            # Mapeo de códigos MeteoGalicia, xerador de gráfico SVG e utilidades
├── forecast.luau          # Datas locais e validación protexida das respostas de predición
├── scripts/
│   └── set_concello.py    # Script auxiliar para persistir a selección de concello en settings.toml
├── translations/          # Internacionalización (gl.json en galego, en.json en inglés)
├── tests/forecast_test.luau # Probas de regresión de datas e respostas da API
└── LICENSE                # Licenza MIT
```

---

## API de MeteoGalicia

Este proxecto emprega os servizos e APIs públicas oficiais de **MeteoGalicia** (Consellería de Medio Ambiente e Cambio Climático - Xunta de Galicia):
* **Base REST**: `https://apis-ext.xunta.gal/meteo2api/v1/api/`.
* **Predición horaria**: `concellos/predicion-horaria?idConcello=…&data=AAAA-MM-DDT00%3A00%3A00.000Z&idioma=gl` (lista `forecastDataTime`).
* **Predición diaria**: `concellos/predicion/diaria?idConcello=…&idioma=gl` (lista `forecastDataShortTerm`, avisos e comentario oficial).
* **Medio prazo**: `concellos/predicion-medio-prazo?idConcello=…&idioma=gl` (lista `forecastDataMediumTerm`).
* **Rede de Observación en Tempo Real**: `ultimos10minEstacionsMeteo` (datos de estacións meteorolóxicas cada 10 minutos para humidade relativa real).
* **Información Xeral**: [MeteoGalicia](https://www.meteogalicia.gal/).

### Corrección 1.0.1: predición horaria despois da medianoite

O erro «Formato de predición horaria non válido» producíase porque o servizo
construía a data de hoxe en UTC. Entre as 00:00 e as 02:00 en horario de verán
(ata a 01:00 en inverno), esa data corresponde aínda a onte en Galicia. A API
pode responder a esa consulta caducada con **HTTP 200 e corpo baleiro**.

Reproducido o 22/10/2026 ás 00:10 locais para Fene (`15035`): a consulta do
21/10 devolvía 200 sen corpo; a do 22/10 devolvía un obxecto JSON con
`forecastDataTime`. O sufixo `T00:00:00.000Z` mantense no parámetro que acepta
a API, pero a súa parte de data constrúese co calendario local do sistema
(en Galicia, `Europe/Madrid`).

As datas de hoxe e dos tres días seguintes, así como as referencias a mañá e
onte, calcúlanse dende o mediodía para evitar saltos nos cambios de horario.
A lectura JSON está protexida con `pcall` e valida a lista esperada: unha resposta
baleira indica «Sen predición … dispoñible», mentres que un JSON incorrecto
indica formato non válido. Os erros liberan a consulta en curso para permitir
reintentos e conservan os últimos datos. Se fallan días futuros ou o medio prazo,
séguense amosando os datos válidos dispoñibles.

### Verificación

Co intérprete [Luau](https://luau.org/getting-started/) dispoñible:

```bash
TZ=Europe/Madrid luau tests/forecast_test.luau
noctalia plugins lint .
```

As probas cobren medianoite local fronte a UTC, os cambios de horario de marzo
e outubro, cambios de mes e ano, ano bisesto, corpos baleiros e respostas JSON
malformadas ou cunha estrutura inesperada.

---

## Licenza

Distribuído baixo licenza [MIT](LICENSE). Desenvolvido por [miguelfm](https://github.com/miguelfm).
