# WP-O131 · bot retro y vía caliente de plantillas — reporte (fases 1 y 2)

Rama `dev/scriptorium-exported` (desde `dev/retro-exporter` e186830e). Fechas: 2026-10-08. Custodio: el
mismo que decidió D-O29. Fase 3 (VPS) **no ejecutada**: runbook con PERMISOS en
`ARCHIVO/DISCO/scriptorium-exported/runbook-vps.md`.

## 1. Qué se entregó (commit por pieza)

| Pieza | Commit | Qué |
|---|---|---|
| Plantilla Campamento + contrato | `7e273b4a` | `pub/templates/campamento.json` derivada por script; `SCHEMA.md` con `image`, `clearnetPublic`, `responsable`, `meta.reparto` |
| Kit visual + avatar | `0ed60a9d` | `pub/tools/template-kit.py`: 40 PNG deterministas + manifest con blob id previsto; avatar 512 px del logo Scriptorium Skins |
| Guía de reparto | `86166e35` | `--reparto` (una fuente, tres salidas: dosier, wiki en Oasis, Sala 02) |
| Vía caliente | `ea466fbc` | `--hot`: `seed-plan.js` (planificador puro) + `seed-hot.js` (cooler por socket, dry-run, `--yes`, gates, ledger, evidencia, bloque `clearnet`) |
| Bot retro | `f19f3813` | servicio `oasis-retro-bot` modo `server`, `config/retro-bot`, `OASIS_RETRO_BOT_*`, `ssb-admin.js publish-about --image` |
| Devops | `75ad00c4` | cuarto nodo en `upgrade-gates`, `capacity`, `lib-node`, `deploy-status`, `host.env` |
| Docs | `9cb30a12` | TEMPLATE §4.3-§4.6, HUB §11-§12, fichas, AGENTES §5, roles/pub, nav; `docs:build` reparado |
| Plan y dosier | `bc9cc0e0` | WP-O131 🔶, D-O29, CHANGELOG, dosier con runbooks |
| Drill y correcciones | (este cierre) | runbook ejecutado, 7 correcciones a la herramienta y al protocolo, evidencia en `dry-run/` |

## 2. Criterios de aceptación y evidencia

| Criterio | Medido | Dónde |
|---|---|---|
| El bot nace con identidad propia, modo `server`, sin HTTP, y nada publica solo salvo `oasisVersion` | ✅ feed `@Oz7l6q…` ≠ pub; tras el bootstrap `contact=1 pub=1 oasisVersion=1`; un reinicio en la misma versión no publica | runbook G1-G4 |
| Bootstrap sin backend (invite por socket, conn-fix) | ✅ `accept: true`, CONNECTED en el pub, `contact +1` en el pub y nada más | G3 |
| `about` con avatar en un solo mensaje, con el blob id previsto en fase 1 | ✅ `image = &q4Mkl/fcUGNELIrsmVyMBBdZsCXxyh5LmGN/XovlHDg=.sha256` | G4 |
| Dry-run sin publicar; gate whoami | ✅ delta 0; exit 3 con la identidad del propio bot | G5 |
| Cada bloque publica exactamente lo previsto, o el seeder para | ✅ 10 de 11 bloques con delta = previsto; **1 parada** (calendars 36 ≠ 29: `calendarNote` no contado) que el seeder detuvo sola; corregido y seguido | G6-G7, `dry-run/hot-*.jsonl` |
| Reejecutar no duplica | ✅ `pending 0`, delta 0 | G6 |
| Los blobs del kit llegan al pub y al HUB | ✅ 17/17 en el `.ssb` del pub; `/c/blob/<png>` → `200 image/png` en el HUB | G6, G8 |
| Lo marcado público sale en `/c`; lo demás no | ✅ sitemap del HUB: 1 calendario, 7 eventos, 1 mapa (solo el `OPEN`), 5 wikis; salas con tribu: 0 | G8 |
| Guía de reparto con enlaces reales | ✅ 36 enlaces `/c/…`, todos 200 con contenido | G9 |
| El feed del pub no cambia por la siembra | ✅ Δ0 desde `retro2`; en todo el drill solo el `contact` del invite | G10 |
| Aislamiento | ✅ bot parado: pub y HUB intactos | G10 |

Totales: 146 mensajes publicados por el bot en la siembra (seq 5 → 151), 25 tribus (16 raíz + 9 sub), 22
invitaciones abiertas, 7 salas con centralita en el pub, 7 calendarios (36 mensajes), 7 eventos, 4 listas,
5 wikis, 2 mapas, 15 `clearnetItem`.

## 3. Hallazgos (todos medidos; corrección aplicada donde la hay)

1. **Un sbot recién nacido no tiene `db2/log.bipf`** hasta su primer mensaje: `snapshot` lo da por ilegible.
   La foto base útil es la posterior al bootstrap. (TEMPLATE §4.5)
2. **`invite.accept` por socket publica `contact` y `pub`** en el feed del bot y el reinicio `oasisVersion`:
   el bot no queda en 0 tras el bootstrap. (HUB §11)
3. **El `server` persiste `conn.json` al parar**: `hub-conn-fix.js` justo tras el accept ve `{}`. Orden:
   accept → restart → conn-fix → restart. (HUB §3 para nodos `server`)
4. **`docker cp` de `/tmp/desc.txt` falla en Windows** (`C:\tmp`): el primer `about` del drill salió sin
   descripción. La descripción entra por stdin; y se comprueba `description_len` antes de dar el `about` por
   bueno. En el VPS no hay segunda oportunidad. (HUB §12)
5. **`calendarNote`**: una nota en la primera fecha es un mensaje más (`calendars_model.js:452-467`).
   (`seed-plan.js`)
6. **Los eventos necesitan `clearnetItem`** (`backend.js:1019`): su `clearnetPublic` no basta. Uno por
   repetición. (`seed-plan.js`, TEMPLATE §4.4)
7. **Un objeto suelto que el modelo cifra para sí** (mapa `SINGLE`/`CLOSED`, calendario `CLOSED`, sala
   `INVITE-ONLY`) no lo lee el HUB aunque lleve `clearnetItem`. Validación nueva. (`template-seed.js`, SCHEMA)
8. **El cuerpo largo de una wiki va a un `bodyBlob` sin `push`**: la página sale vacía en el HUB. El seeder lo
   empuja. (`seed-hot.js`)
9. **El HUB no replica solo un feed a 2 saltos recién seguido por el pub**: hizo falta reiniciarlo (20 s).
   En el VPS: reconectar o esperar; medir con `ssb-probe.js` antes de dar `/c` por verificado. (TEMPLATE §5)
10. **La caché nginx del HUB sirve 7 días el sitemap de antes de la siembra**. En el VPS,
    `hub-disk.sh prune-cache`; en local la caché es un volumen nombrado que `--local prune-cache` no vacía.
    (TEMPLATE §5, HUB §6)
11. `hub-disk.sh --local prune-cache` mide `0 → 0 bytes` porque mira el bind, no el volumen nombrado de
    Windows: no corregido (fuera de alcance; anotado en HUB §6 como trampa local).
12. El cliente local (`o-sdk-oasis-client`, 5 GB, GPU) murió por memoria a los 4 min: no se midió la vista
    de cliente. No se publicó nada desde él.

## 4. Seguimiento

- Fase 3 (VPS): `runbook-vps.md`, con los hallazgos 2-4 y 9-10 ya incorporados; cada PERMISO al custodio.
- WP-O130 (`--cold`): sigue en el backlog.
- Capturas para la presentación: con el drill vivo, `http://localhost:8088/c` (tras vaciar caché) y, si el
  cliente aguanta, `http://127.0.0.1:3000/tribes`.
- `hub-disk.sh --local prune-cache` sobre volumen nombrado: pendiente (hallazgo 11).

## 5. Fase 3 · VPS (2026-10-08, GO del custodio, un PERMISO por irreversible)

Ejecutada entera: `ARCHIVO/DISCO/scriptorium-exported/runbook-vps.md`, tabla «Ejecución». Resultado: bot nº 3
`retro.escrivivir.co` = `@fJG3E7UKNlYVh0Aoc89LKPAAQsKNfy4iMaJtdVH0I8I=.ed25519` en `/srv/oasis/oasis-retro-bot`,
modo `server`, `about` con el avatar previsto (seq 3); Campamento sembrada en `pub.escrivivir.co` con delta
exacto en los 10 bloques (feed del bot en 148); el pub publicó **solo** su `contact`; HUB y bot-2 a 0; el HUB
replicó el feed sin reiniciar; sitemap público con 191 URL; 32 enlaces de la guía en 200; Sala 02 con la guía
generada (`/parlament/campamento/`, +1 línea sobre la página viva). Backup del `secret` y los keyrings fuera
del host. Journal con `+retro`.

Hallazgos nuevos (13 y 14), corregidos: un bind anidado dentro de otro `:ro` no se puede crear si la imagen
del host no trae `/app/pub` (assets en `/app/pub/assets/<plantilla>`); reiniciar el bot justo tras
`invite.accept` pierde sus `contact`/`pub` (esperar `seq ≥ 2`; el `contact` se publicó con `ssb-admin.js follow`
dentro del PERMISO 6). Y una trampa de medida: `MSYS_NO_PATHCONV=1` exportado rompe `curl -o /tmp/…` y la
matriz del HUB da `000` (dos lecturas falsas del sitemap antes de verlo).

Estado del WP: **✅ ejercido en la demo**. Pendiente: prueba en frío; WP-O130 (`--cold`); vista del cliente local.
