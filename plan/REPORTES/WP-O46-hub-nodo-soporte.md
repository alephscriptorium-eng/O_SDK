# Reporte · WP-O46 · Sala 04 · HUB clearnet como nodo de soporte

- **Fecha**: 2026-09-13 · **Rama**: `wp/O46-hub-nodo-soporte` (10 commits sobre `9684bc2`) · **Método**: ultracode (workflows de agentes con parada dura), prioridad tiempo sobre validación estricta (decisión del custodio).
- **Resultado**: **desplegado**. `https://pub.escrivivir.co/c` activo desde las 19:55 UTC; Sala 04 en `/hub/`; journal `--mode server+hub` 20:02 UTC.
- **Doc viva**: `docs/PUB/HUB-PROTOCOL.md` (estado en cabecera). **Plan**: `ARCHIVO/DISCO/oasis-clearweb/v2.md`. **Asientos**: D-O13, D-O14.

## Qué se entregó

| Pieza | Commit |
|---|---|
| Plan v2 integrado: protocolo del HUB, upgrade, gobierno | `3c275db` |
| Compose (`oasis-hub`, `hub-cache`), `OASIS_HUB_*`, rutas del volumen | `7098c53` |
| Configs del nodo de soporte (`ssb-config`, `oasis-config.json`, nginx) | `1457f6d` |
| Bloque `@hub` en Caddy | `0715e1f` |
| `hub-conn-fix.js` (normaliza `conn.json` tras el invite) | `d7b6f60` |
| `hub-disk.sh` + línea de `check` en `deploy-status.sh` | `5d12927` |
| Sala 04 (`pub/site/hub/`, vestíbulo, Accesos) | `a7bed15` |
| Changelog | `d972ffb` |
| `seeds` retirado del `ssb-config` (hallazgo del deploy) | `68b12e5` |
| `hub-conn-fix.js`: olvidar la entrada con seed sea cual sea el host | `7ed4641` |

## Criterios de aceptación (BRIEF) · evidencia

| CA | Resultado |
|---|---|
| `/c`, `/c/inhabitant/%40%2F…`, `/assets/images/snh-oasis.jpg` → 200, CSP `script-src 'none'`, **una** `X-Frame-Options`, `X-Cache-Status` | ✅ paso 4: 200/200/200; cabeceras `sort \| uniq -c` = 1 de cada; MISS→HIT |
| Segunda petición a `/c` = HIT | ✅ |
| Landing, `/assets/fanzine.css`, `/public/status` y los 5 vhosts intactos tras `caddy reload` | ✅ códigos idénticos antes/después (pub 200 · scriptorium 404 · admin 404 · mcp 502 **preexistente** · npm 200 · rooms 200) |
| El feed del pub solo crece por el `contact` del follow-back (+1) | ✅ `grep -a -o '"type":"contact"' \| wc -l` 360→361; `"contact":"@KM+ZBip…"` = 1 |
| El pub sigue healthy y no se reinicia en ningún paso | ✅ `StartedAt` 2026-09-12T17:02:23Z antes y después |
| Todo el estado nuevo bajo `/srv/oasis/oasis-hub`; `df /` igual | ✅ `/` 49 % antes y después; `/srv/oasis` 15 % |
| Feed del HUB = solo `contact`, `pub`, `about`, `oasisVersion`; cero `private` | ✅ 4 mensajes propios, `private:true` = 0 (criterio ampliado de 2 a 4 tipos en G3) |
| `hub-disk.sh check` → 0 | ✅ |
| Rollback ensayado (< 5 min) | ⏳ **no ensayado** (quita `/c` ~1 min; decisión del custodio). Receta lista en HUB-PROTOCOL §8 con `Caddyfile.bak-hub-2026-09-13` |
| Journal | ✅ 20:02:48 UTC, gitSha `7ed4641` |

**Hostil-omite**: sin opt-in → «not accessible» (200) ✅ · `POST /c` → 405 nginx ✅ (backend: 400 sin Referer, 302 `?error=public mode` con Referer) · `/settings`, `/profile`, `/publish`, `/update`, `/json/x`, `/qr/x` → landing, sin `X-Cache-Status` ✅ · parar `oasis-hub` no afecta al pub / parar el pub deja `/c` en STALE ✅ (G5 local; en el VPS no se paró nada) · `OASIS_HUB_PUBLIC=false` nunca con `@hub` activo ✅ (bootstrap antes del reload) · `conn.json` del HUB apunta a `oasis-pub`, no a la IP ✅.

## Desviaciones del plan (todas asentadas en `v2.md` «Hallazgos» y en el protocolo)

1. **Ruta de `ssb-admin.js`** en la imagen viva: `/app/OASIS_PUB/tools/` (layout pre-refactor). Parada 1.
2. **`seeds` bloqueaba el invite**: metía la clave del pub en `gossip.json` antes del accept y `backend.js:10736` respondía `alreadyFederated`. Retirado (`68b12e5`); bootstrap repetido con la misma identidad limpiando `gossip.json`/`conn.json`. Parada 2.
3. **`hub-conn-fix.js`** filtraba la entrada con seed por host; el invite la escribe con la IP del bridge. Corregido (`7ed4641`). Parada 3.
4. **Contador de `contact`** con `grep -c` sobre un log binario: artefacto; se usa `grep -a -o | wc -l` y prueba por contenido.
5. **Invite «reutilizado»** del intento 1 venía truncado en la transcripción → inválido; se creó uno nuevo. El del intento 1 queda sin consumir en memoria del pub hasta su próximo reinicio (1 uso; el seed solo consta en transcripciones locales).
6. **Site** subido fichero a fichero con merge a tres bandas (`git merge-file`) en vez de `deploy-site.sh` (`--delete` sin exclusiones).
7. El «403» de `PUBLIC=true` no es observable por HTTP (302 con error / 400); criterio reescrito.

## Contraevidencia para el revisor

- Feed del HUB: `sudo grep -a -o '"private":true' /srv/oasis/oasis-hub/ssb-data/flume/log.offset | wc -l` → 0; mensajes con `author` = HUB → 4 tipos.
- Feed del pub: `"contact":"@KM+ZBipR18VSyjNTFjAOnsmz6EiobGYHb3ZCZ4ZxQYI=.ed25519"` → 1; ningún otro mensaje nuevo del pub.
- `docker inspect -f '{{.State.StartedAt}}' oasis-pub-scriptorium` → `2026-09-12T17:02:23Z`.
- Mounts de `oasis-pub-hub` y `oasis-pub-hub-cache`: nada bajo `/srv/oasis/oasis-pub`.
- `curl -sI https://pub.escrivivir.co/c | grep -ciE '^x-frame-options'` → 1.

## Pendientes y seguimiento

- **24 h** (≈2026-09-14 20:00 UTC): `docker stats --no-stream oasis-pub-hub` → `OASIS_HUB_MEM_LIMIT = ceil(1,5·pico)` (mín. 768m) y `NODE_OPTIONS` ≈ 0,7·límite en `.env.prod` (backup) + `up -d --no-deps oasis-hub`; `hub-disk.sh --json`.
- **7 días** (≈2026-09-20): `hub-disk.sh status --json` → ajustar `HUB_CACHE_MAX_SIZE` / hops; después semanal.
- Rollback nivel 1: ensayar cuando el custodio lo decida.
- Revisión adversarial (revisor distinto del worker) con `dosier/05` · push · merge a `main`.
- WP-O47: tope duro de disco y `mem_limit` del pub, con 30 días de `hub-disk.jsonl`.
- Heredados: `robots.txt` para `/c/blob/`, `Cache-Control` en HTML de `/c`, indexing gate 60 s tras rebuild, `mcp.scriptorium` 502 (ajeno).
