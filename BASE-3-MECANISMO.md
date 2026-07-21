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

## D · Procedimiento

Brief → borrador de superficie → filtros C → revisión de cara interna →
(si swarm) paquete de entrega verbatim → revisión marketing.

## E · Entrega al swarm

Reemplazos verbatim + criterios de aceptación: `npm run docs:build` verde,
`verificar-sitio.mjs` verde (enlaces internos + anclas), grep de ceguera = 0,
diff cerrado.

## F · Cola

| Superficie | Estado | Bloqueo |
| ---------- | ------ | ------- |
| Portada | v1 publicada | pulir copy con marketing |
| Proyecto · DevOps | v1 publicada | — |
| Guía de instalación | pendiente | integrar `docs/install` sin romper links |
| Catálogo de features | pendiente | inventario desde `src/models` + `src/views` |

## Backtracking

1. Marketing edita la entrega (bloques canónicos = verbatim).
2. El agente extrae el patrón → regla en BASE-2/3.
3. Re-ejecuta la pipeline sobre el resto; no toca bloques canónicos.
