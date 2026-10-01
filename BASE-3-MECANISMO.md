# BASE 3 — EL MECANISMO

> Reglas ejecutables del mundo `oasis-sdk`. Texto canónico de §B–§E en el skill
> `site-web` (`reference/metodo-mecanismo.md`). Primera pasada.

## A · Mapa

Fundación (BASE-1/2/3) manda · el código real aporta los datos/refs · salida =
superficie del portal (`docs/`) o paquete de entrega al swarm.

## B · Reglas

Aplicar las reglas del método: denotación primero, ref-o-muerte (cada
afirmación con ⟨ref⟩ a fichero/feature real), hechos no bandos, FOSS visible
en los heros, versiones leídas de `package.json` (no hardcode).

## C · Filtros

- `mundo.lexico_no` = `/(blockchain social|web3|to the moon|revoluciona|disruptiv)/i`
  — esto es SSB/P2P; nada de humo cripto-marketing.
- `mundo.ceguera` = `/(escrivivir-co\/|pub\.escrivivir\.co|@tMJzSfcZ|secret\b)/`
  — la cara pública no filtra la cuenta origen anulada, el host del pub privado
  ni material de identidad. Correr el grep de ceguera antes de publicar.
- **Ceguera por ámbito** (D-O26). D-O23 hizo pública la ficha de la demo; el filtro se aplica así:
  - **Puertas y plantilla** (`docs/roles/**`, `docs/PUB/INSTANCIA-PLANTILLA.md`): **cero** menciones
    al nombre de la demo o a su dominio. Quien monta su pub no debe leer el nuestro. Únicas
    excepciones: la URL de la forja y el enlace a la ficha de la demo como ejemplo relleno.
  - **Protocolos de método** ya publicados: trinquete. El recuento de menciones no puede subir;
    se van llevando a la ficha cuando se toca cada uno.
  - **Ficha de la demo**: ahí vive la instancia.
  Lo comprueba `npm run docs:verificar` (`devops/scripts/docs-ceguera.sh`).
- **Verdad de contenido**: `docs/.vitepress/verdad-checks.json`. La versión sale inyectada y no
  vacía, nadie la escribe a mano en la portada, y ninguna puerta «probada» o «ejercida» va sin reporte.

## D · Procedimiento

Brief → borrador de superficie → filtros C → revisión de cara interna →
(si swarm) paquete de entrega verbatim → revisión marketing.

## E · Entrega al swarm

Reemplazos verbatim + criterios de aceptación: `npm run docs:build` verde,
`verificar-sitio.mjs` verde (enlaces internos + anclas + verdad), ceguera por ámbito, piel y
contraste: todo en `npm run docs:verificar`. Diff cerrado.

## F · Cola

| Superficie | Estado | Bloqueo |
| ---------- | ------ | ------- |
| Portada | v2 publicada (puertas, «Llévatela») | pulir copy con marketing |
| Proyecto · DevOps | v1 publicada | — |
| Puertas por rol (`docs/roles/`) | v1 publicada, WP-O115 | pasar los encargos «en obras» a «probado»: WP-O116, WP-O117, WP-O118 |
| Guía de instalación | absorbida por la puerta Cliente | arranque sin GPU ni modelo: WP-O116 |
| Catálogo de features | pendiente | inventario desde `src/models` + `src/views` |

## Backtracking

1. Marketing edita la entrega (bloques canónicos = verbatim).
2. El agente extrae el patrón → regla en BASE-2/3.
3. Re-ejecuta la pipeline sobre el resto; no toca bloques canónicos.
