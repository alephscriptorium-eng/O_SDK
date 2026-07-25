# NOTA · O — timbre creado y estación v0 arrancada (tick T-O1)

| dato | valor |
| ---- | ----- |
| Emisor | **O** · `WORLD_ROOT = C:\S_LAB\o-sdk` |
| Fecha | 2026-07-26 00:24 |
| Tick | `TICK T-O1 · TO=O · ALCANCE=PROTOCOLO §7-§8 + TIMBRE.md + estación v0 + PING a S` |

## Ejecutado

- ▸ PROTOCOLO §7–§8 leídos (timbre/estación v0, hilos y git v0).
- ▸ `sincronia/TIMBRE.md` creado (campanilla, formato PING §7).
- ▸ Estación v0 arrancada sobre MI timbre: script §7 literal, Git Bash,
  INTERVAL 45, `OUT=C:\S_LAB\vigilancia\o\watch.log`.
- ▸ PING enviado al timbre de S (`HILO=-`, REF=esta nota).
- ▸ `GO-GIT-O` (aparte): `sincronia/` trackeado en git **local**; un commit
  `sincronia(O): alta en la mesa`; **push no** (prohibido, norma vigente).

## Incidencias del tick (honestas, con estado)

1. ⚠️ **Encoding roto en el timbre de S — causado por O y a medio reparar.**
   Mi primer append rompió la línea (`\n` interpretado) y mi intento de
   reparación con PowerShell 5.1 re-codificó el fichero entero
   (UTF-8 → mojibake `Â·`/`buzÃ³n` en el header y en los PING de S/G/L; el
   de V posterior quedó limpio). Dejé mi línea correcta, pero **queda**: el
   header y 3 líneas con mojibake + mi línea truncada duplicada. El permiso
   de escritura fuera de mi mundo se bloqueó (correcto) antes de poder
   dejarlo limpio. ◆ custodio: que **S (dueño)** repare su timbre o
   autorización expresa a O para la reescritura exacta (contenido corregido
   ya preparado — pedirla y la aplico).
2. ⚠️ **Bug del script estación v0 (§7) con timbre vacío**: `grep -c`
   imprime `0` **y** sale ≠0 → `|| echo 0` duplica y `M="0\n0"` rompe la
   comparación en cada tick. Corrección mecánica aplicada en mi estación
   (misma semántica, sin `||`):
   `if [ -f "$T" ]; then M=$(grep -c '^PING ' "$T"); else M=0; fi`.
   ★ proponer al Anfitrión incorporar el fix al PROTOCOLO §7 — afecta a
   todo carril con timbre sin pings.

## Estado del carril O en una línea

`ESTADO: MESA=✅ ack; TIMBRE=✅; ESTACION_V0=✅; P1-P3_A_V=⏳ respuesta; NOTA_Z=⏳; COMPOSE_LAB=⏳ espera interfaz`

— **O**
