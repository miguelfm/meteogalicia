# Integración con Noctalia 5.4

Revisado o 27/10/2026: versión 1.1.2, plugin_api = 43, Noctalia instalado 5.4.0.
Miguel confirmou o redimensionamento corrixido polo axente anterior. Nesta revisión
non se cambiaron a xeometría, o deseño, os axustes nin o código de execución.

## Contrato do panel

| Campo | Valor |
| --- | --- |
| width | 1400 |
| height | "content" |
| max_height | 980 |
| placement / position | attached / auto |
| open_near_click | true |

height = "content" permite que Noctalia mida o contido e adapte a altura; o
máximo declarado limita o crecemento. Non converte o ancho fixo nun ancho
adaptable. As medidas son lóxicas: o resultado físico depende da escala e do
espazo dispoñible. A confirmación visual corresponde ao equipo de Miguel;
non se probou nesta revisión outra resolución ou sesión niri.

O máximo de 980 acompaña os axustes de espazos e gráfico do preset xlarge.
O panel raíz conserva a columna natural: non engadir un scroll global para
axustar a altura, pois pode interceptar a roda usada para avanzar polas horas.
O buscador conserva a súa lista interna de 280. Non restaurar automaticamente
os 1400×1000 fixos anteriores nin as dimensións da primeira adaptación.

## Cores e compatibilidade

O código usa surface_container e outline_variant. on_surface_variant segue
sendo un rol válido. variant = "outline" é o estilo dun botón: non renomealo.
As chamadas a getColor e os campos pasados aos gráficos usan os nomes novos.
A revisión non atopou usos de surface_variant nin de outline como rol de cor.

As capacidades novas de capas, idle watches, calendario, drag and drop e
pixel streams non son dependencias destes paneis. O OSD do escritorio úsase
nos scripts compartidos; non substitúe os avisos persistentes ou erros do plugin.
Non é preciso adoptar cada API nova para ser compatible coa versión 5.4.

## Verificación e fontes

noctalia plugins lint e noctalia config validate pasaron. A shell lista esta
versión como plugin local activado e as ligazóns apuntan aos repositorios
propios; non se copian os plugins dentro dos dotfiles compartidos.

As probas illadas con Luau 0.742 pasaron: 220 comprobacións de predición e
8653 de idiomas/renderizado; 239 claves coinciden entre os catálogos. O host
simulado comproba árbores de UI e gráficos, pero non mide píxeles de Wayland.
A proba visual do tamaño é a confirmada por Miguel.

Referencias oficiais:

- [Notas de Noctalia 5.4.0](https://github.com/noctalia-dev/noctalia/releases/tag/v5.4.0).
- [Manifesto e API mínima](https://docs.noctalia.dev/noctalia/plugins/development/manifest/).
- [API de execución](https://docs.noctalia.dev/noctalia/plugins/development/runtime-api/).

O 27/10/2026 a única release publicada da serie 5.4.x é 5.4.0. Revisar as notas
e validar de novo ante futuras versións; esta revisión non certifica cambios
aínda non publicados.
