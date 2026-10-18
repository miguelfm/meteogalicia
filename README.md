# MeteoGalicia para Noctalia (v5)

Plugin nativo para o shell de escritorio **Noctalia** (en Wayland / Hyprland) que amosa a predición meteorolóxica oficial de Galicia por concellos, conectándose directamente á API REST de **MeteoGalicia** (`meteo2api` da Xunta de Galicia).

![MeteoGalicia Plugin Icon](https://img.shields.io/badge/Noctalia-v5_Plugin-7c3aed?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)
![API](https://img.shields.io/badge/Data-MeteoGalicia_REST_API-0284c7?style=flat-square)

---

## Características

* **Predición Oficial Galega**: Datos directos dos modelos de alta resolución de MeteoGalicia (non modelos xenéricos globais).
* **Cápsula na Barra (`bar`)**:
  * Glifo do estado do ceo dinámico (día e noite).
  * Temperatura actual.
  * Probabilidade de precipitación en tempo real.
  * Nome do concello configurábel.
  * *Tooltip* detallado con rango de temperaturas, vento e hora de actualización.
* **Panel Emerxente Completo (`panel`)**:
  * **Tira horaria**: Predición detallada hora a hora para o día en curso con icona, temperatura, probabilidade de choiva e vento.
  * **Comentario oficial**: Texto descritivo e análise sinóptica redactada polos meteorólogos de MeteoGalicia.
  * **Indicadores ambientais**: Calidade do aire (ICA), índice ultravioleta máximo (UV) e dirección/velocidade do vento.
  * **Botón directo** para abrir o concello na webapp oficial de MeteoGalicia.
* **Cero dependencias pesadas**: Execución 100% en Luau nativo utilizando o cliente asíncrono `noctalia.http` integrado.

---

## Instalación

Podes ligar o cartafol directamente aos plugins locais de Noctalia:

```bash
ln -s ~/Projects/meteogalicia ~/.config/noctalia/plugins/meteogalicia
```

Logo recarga Noctalia dende a terminal ou co menú de axustes:

```bash
noctalia msg config-reload
```

E engade o widget `miguelfm/meteogalicia:bar` á túa barra en `settings.toml` ou no editor visual de Noctalia.

---

## Configuración (`plugin.toml`)

O plugin permite configurar os seguintes parámetros no panel de configuración de Noctalia:

| Clave | Tipo | Valor por defecto | Descrición |
| :--- | :--- | :--- | :--- |
| `concello_id` | `int` | `15035` | Código INE do concello (ex: `15035` para Fene, `15036` para Ferrol, `15030` para A Coruña, `15078` para Santiago, `36057` para Vigo). |
| `concello_name` | `string` | `Fene` | Nome amosado na barra e na cabeceira do panel. |
| `refresh_minutes`| `int` | `30` | Frecuencia de actualización en minutos (mínimo 5). |
| `show_town_name` | `bool` | `true` | Amosa o nome do concello na cápsula da barra. |
| `show_rain_prob` | `bool` | `true` | Amosa a probabilidade de choiva se é maior do 0%. |
| `hours_count` | `int` | `12` | Número de tarxetas horarias a amosar no panel (de 6 a 24). |

---

## Atallos no panel

* <kbd>R</kbd>: Forzar actualización inmediata dos datos.
* <kbd>Esc</kbd>: Pechar o panel.

---

## Licenza

Distribuído baixo licenza [MIT](LICENSE). Desenvolvido por [miguelfm](https://github.com/miguelfm).
