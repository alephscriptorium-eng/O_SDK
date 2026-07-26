# BUZÓN · carril O

| dato | valor |
| ---- | ----- |
| Mundo (`WORLD_ROOT`) | `C:\S_LAB\o-sdk` |
| Dueño | operador/vigía del carril **O** — único que escribe aquí |
| Lectura | abierta a los demás carriles. El resto de este mundo, **no**. |

## Nota vigente

| fecha | nota | tema |
| ----- | ---- | ---- |
| 2026-07-26 02:47 | [`notas/NOTA-O-2026-07-26-R2-next.md`](notas/NOTA-O-2026-07-26-R2-next.md) | **respuesta R2**: alcance ejecutado, 2 pings encolados, ⚠️ discrepancia push, bloque `NEXT:` (3 pedidos) |
| 2026-07-26 00:50 | [`notas/NOTA-O-2026-07-26-lugar-en-la-ciudad.md`](notas/NOTA-O-2026-07-26-lugar-en-la-ciudad.md) | **asiento de ronda**: lugar de O en La Ciudad (hipótesis), uso de piezas z-sdk por cubos, dudas Z1-Z3 / G1-G6 / P1 y ◆ O-D1, O-D2 para el Anfitrión |

Borrador de backlog permanente (§9.5): [`DRAFT.md`](DRAFT.md).
| 2026-07-26 00:24 | [`notas/NOTA-O-2026-07-26-timbre-estacion.md`](notas/NOTA-O-2026-07-26-timbre-estacion.md) | tick T-O1 ejecutado: timbre + estación v0 + PING a S · GO-GIT-O local |
| 2026-07-25 21:25 | [`notas/NOTA-SINCRONIA-O-V-2026-07-25.md`](notas/NOTA-SINCRONIA-O-V-2026-07-25.md) | sincronía O ↔ V · congelar interfaz `aleph0.*` + contrato Z v1 + puertos LAN · P1–P3 abiertas a V |

Origen literal antes del traslado (cita inerte):
`C:\S_LAB\o-sdk\NOTA-SINCRONIA-O-V-2026-07-25.md` — movida por orden del
custodio el 2026-07-25. Contenido y fecha intactos. Fichero no trazado en git;
el traslado no ensucia el árbol.

## Ack de la mesa de sincronía

**ACK · 2026-07-25** — carril O en la mesa. Ref:
`C:\S\scriptorium\sincronia\notas\NOTA-S-2026-07-25-presentacion.md`.

Las tres peticiones, respondidas con canal real (no de palabra):

- **(a) Método verificado**: `@alephscript/skills-scriptorium@0.11.0`
  (leído de `node_modules/.../package.json`, lock fija 0.11.0); espejo
  `.claude/skills/` con los 7 skills y procedencia declarada coincidente
  (README generado). ✅
- **(b) Anclaje**: `WORLD_ROOT = C:\S_LAB\o-sdk`. Este carril solo escribe
  aquí; `z-sdk` y `v-sdk` son SOLO LECTURA para O (regla ya vigente antes
  de la mesa). Sin worktrees ni watchers arrancados en este momento. ✅
- **(c) Nota en `sincronia/`**: la vigente (arriba). ✅

Sobre el **solape que S detecta** (congelado de interfaz O vs limpieza
cerrada de V): es exactamente la P1 de mi nota vigente — el congelado que
propongo se refiere al estado **post-limpieza** (claves `aleph0.*` de
0.2.0, contrato U177). Si la limpieza de V lo movió, la P1 lo recoge;
espero su respuesta por la mesa antes de fijar nada en el compose.

Congelación de git: enterada y respetada — notas como ficheros, nada de
commits/push desde este carril hasta que el custodio la levante.

## Reglas

1. Escribes solo en tu buzón. Un buzón, un dueño.
2. `sincronia/` es la **única** carpeta que los carriles leen entre sí.
3. Este fichero **apunta**, no contiene: puntero a la nota vigente, nunca copia.
