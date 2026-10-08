# Runbook · fase 3 · alta del bot retro y siembra en `pub.escrivivir.co` (WP-O131)

**Sin GO no se ejecuta nada de esto.** Precondición: fase 2 cerrada con reporte (todos los gates en verde o
con sus desviaciones corregidas en el protocolo). Patrón: ECOIN-PROTOCOL §3 con `oasis-retro-bot` en modo
`server`; reglas fijas de HUB §3 (siempre `up -d --no-deps <svc>` con `--env-file .env.prod`, nunca
`deploy.sh`, Caddy no se toca, binds in place, backups `*.bak-retro-<fecha>`). Los pasos marcados
**PERMISO** son irreversibles (`AGENTES.md` §3) y se piden al custodio en el momento, uno a uno.

| # | Paso | Cómo | Esperado |
|---|---|---|---|
| 0 | Líneas base | `bash devops/scripts/deploy-status.sh` · `bash devops/scripts/backup-oasis-pub.sh` · `bash devops/scripts/upgrade-gates.sh --remote snapshot pre-retro` · `df -h /` · `free -m` | 3 nodos Oasis healthy; `sequence` del pub anotado; ≥ 1 GB libres (el bot pide 512 MB) |
| 1 | Directorios en el volumen | `sudo mkdir -p /srv/oasis/oasis-retro-bot/{ssb-data,logs,assets}` con el uid de `oasis` de la imagen (ECOIN §3 paso 2); `chmod 700 ssb-data` | sin `oasis-first-contact` (no hay backend) |
| 2 | Kit y avatar al host | `scp -r pub/templates/assets/campamento/* <host>:/srv/oasis/oasis-retro-bot/assets/` · `scp ARCHIVO/DISCO/scriptorium-exported/assets/avatar-retro-512.png <host>:/srv/oasis/oasis-retro-bot/assets/avatar.png` · `sha256sum` en destino contra `manifest.json` | 42 ficheros + avatar; sha256 iguales |
| 3 | `.env.prod` | backup `.env.prod.bak-retro-<fecha>`; añadir el bloque `OASIS_RETRO_BOT_*` de `pub/.env.vps.example` con `OASIS_RETRO_BOT_ASSETS_DIR=/srv/oasis/oasis-retro-bot/assets` (escritura in place, `cat >>`) | `grep -c OASIS_RETRO_BOT_ .env.prod` = 6 |
| 4 | Compose y config | subir `docker-compose.pub.yml` **diffeado** contra el vivo (backup previo; solo el bloque `oasis-retro-bot`), `config/retro-bot/ssb-config`, `tools/` (seeder, probe, admin) y `templates/campamento.json`; `$C config` | los 5 servicios existentes sin cambios en `config`; el nuevo aparece solo con `--profile retro` |
| 5 | Arranque | `$C --profile retro up -d --no-deps oasis-retro-bot` → healthy; `whoami` del bot | `secret` nace en `/srv/oasis/oasis-retro-bot/ssb-data`; feed id **nuevo** → a la ficha §3 (de «se mide» a su valor) |
| 6 | **PERMISO · invite redimida** | `invite.create 1` en el pub (`/app/OASIS_PUB/tools/ssb-admin.js`, HUB §9), host → IP del bridge; `ssb-probe.js invite-accept` en el bot → `accept: true`; **`docker restart`** (el `server` escribe `conn.json` al parar); `hub-conn-fix.js 'net:oasis-pub:8008~shs:<KEY>'` (debe encontrar la entrada con seed y olvidarla); `docker restart`; CONNECTED; `check pre-retro --expect 'pub:contact=+1 hub:=0 bot:=0 retro:contact=+1,pub=+1,oasisVersion=+1'`; **foto base nueva** `retro-base` (antes del primer mensaje el log no existe) | el pub publica **un** `contact` (su único cambio en todo el runbook); el bot, los 3 del bootstrap |
| 7 | **PERMISO · `about`** | `docker cp` del avatar a `/tmp` del bot · la descripción **por stdin** (`printf '%s' "$DESC" \| docker exec -i … 'cat > /tmp/desc.txt'`; comprobar `wc -c`) · `ssb-admin.js publish-about 'retro.escrivivir.co' "$(cat /tmp/desc.txt)" --image /tmp/avatar.png` **una vez** · borrar `/tmp/*` · leer el mensaje (`description` no vacía, `image` = blob previsto) · `check retro-base --expect 'pub:=0 hub:=0 bot:=0 retro:about=+1'` · reiniciar → sin cambios (misma versión) | `image` = blob previsto; ficha §4: de *propuesto* a *publicado* con fecha |
| 8 | Dry-run | `retro-seed.sh --env pub/.env.prod --pub-id <id del pub> --evidence vps-dry` | exit 0; mismos `expected` que en el drill; delta 0 |
| 9 | **PERMISO por bloque** | `--yes tribes` → `--yes subtribes` → `--yes invites` → `--yes rooms` (el pub debe **seguir** al bot: lo hace el `contact` del paso 6; relé acotado HUB §14) → `calendars` → `events` → `mailing` → `wiki` → `maps` → **`clearnet`** (hace público en `/c`: permiso aparte). Tras cada uno, `check` | `delta == expected` en cada bloque; si no, parada dura |
| 10 | Verificación pública | primero: el HUB tiene el feed del bot (`ssb-probe.js` en el HUB con `SSB_FEED=<bot>` → `seq` = el del bot; si 0, esperar o reiniciar el HUB: en el drill hizo falta); después `hub-disk.sh prune-cache` (el sitemap de antes se sirve 7 días); `curl -s https://pub.escrivivir.co/c/sitemap.xml` → 1 calendario, 7 eventos, 1 mapa, 5 wikis; `/c/blob/<png>` → `200 image/png`; `/c/wiki/<reparto>` con portada y cuerpo; HUB §4 matriz; `deploy-status.sh` | los 14 objetos `clearnet` y las 24 tribus públicas; feed del pub = `contact +1` y nada más |
| 11 | Guía al sitio (Sala 02) | copiar el ledger del bot (`docker cp …/oasis/keys/plantilla-campamento.json`) al dosier **como evidencia** (no contiene códigos); `--reparto --ledger … --html … --out pub/site/parlament/campamento/index.html`; subir con la regla de la ficha §5 (sha256 del vivo antes; `deploy-site.sh` sincroniza con `--delete`: comprobar que no borra páginas vivas) | la página enlaza a `/c/…` reales; `verificar-sitio.mjs` limpio |
| 12 | Cierre | `backup-oasis-pub.sh`-equivalente del bot: `tar` de `/srv/oasis/oasis-retro-bot/ssb-data/{secret,oasis/keys}` fuera del host (el keyring de tribus es irremplazable; **quién lo custodia: DECISIÓN del colectivo**); `deploy-log.sh … --mode server+hub+wallet+retro`; `capacity.sh`; ficha §3 con feed id y fecha; CHANGELOG; reporte | journal con el cuarto nodo |

Rollback: `$C --profile retro stop oasis-retro-bot` deja el pub y el HUB como estaban; lo publicado no se
retira (el feed del bot se puede dejar de seguir desde el pub: `contact` irreversible, PERMISO).

## Ejecución · 2026-10-08 (GO del custodio; un PERMISO por irreversible)

| # | Resultado | Evidencia |
|---|---|---|
| 0 | ✅ | `deploy-status`: 3 nodos 1.2.3 healthy; `backup-oasis-pub.sh` → `devops/backups/oasis-pub/20261008T114641Z/`; `snapshot pre-retro` (pub seq 20, hub 16, bot-2 67); 2 GB de memoria disponibles, `/` 43 %, `/srv/oasis` 37 % |
| 1 | ✅ | `/srv/oasis/oasis-retro-bot/{ssb-data,logs,assets}` uid 999, `ssb-data` 700 |
| 2 | ✅ | 42 ficheros del kit + `avatar.png` en `assets/`; sha256 iguales a los locales (avatar `ab832497…`, tribu `f4facb42…`) |
| 3 | ✅ | `.env.prod.bak-retro-20261008T114927Z`; bloque `OASIS_RETRO_BOT_*` (6 variables) añadido con `cat >>` |
| 4 | ✅ | `tools/` (seeder, lib, `ssb-admin.js` con `--image`, probe, conn-fix; backups `.bak-retro-*` de los que existían), `templates/campamento.json`, `config/retro-bot/ssb-config`, `scripts/retro-seed.sh`; compose vivo = repo sin bloque retro (diff vacío) → sustituido in place con backup; `config` de los 7 servicios existentes: 0 líneas de diferencia |
| 5 | ⚠️ → ✅ | **Parada**: `read-only file system` al crear `/app/pub/templates/assets/campamento`: un bind anidado dentro de `/app/pub/templates:ro` no se puede crear si la imagen no trae `/app/pub` (la local sí lo trae). Corrección: assets en `/app/pub/assets/<plantilla>` (compose, `retro-seed.sh`, protocolo); segundo `up` → `healthy` en 50 s; feed `@fJG3E7UKNlYVh0Aoc89LKPAAQsKNfy4iMaJtdVH0I8I=.ed25519`; 43 assets visibles |
| 6 PERMISO | ✅ con corrección | `invite.create 1` (host `pub.escrivivir.co` → bridge `172.18.0.4`); probe `accept: true`; `hub-conn-fix` → `remember` + `connect` ok; CONNECTED en el pub; `check pre-retro`: pub `contact+1`, hub 0, bot-2 0. **Desviación**: el feed del bot quedó en 0 (reinicié justo tras el `accept` y sus `contact`/`pub` no se escribieron; en local sí). Dentro del PERMISO 6, `ssb-admin.js follow <pub>` → seq 1; reinicio → seq 2 (`contact`, `oasisVersion`); el pub tiene el feed (seq 2, `followsMe: true`), el bot replica al pub (seq 21). `snapshot retro-base` |
| 7 PERMISO | ✅ | descripción por stdin (416 B); `publish-about --image` → seq 3, `%lrtuvolSEp80ksfp9rwXRk4zKxuSTPAm5Yuvxz71FUo=.sha256`, `description_len 408`, `image` = blob previsto; `check retro-base`: solo `retro:about=+1` |
| 8 | ✅ | dry-run: gates `true`, 10 bloques, 160 previstos; `snapshot retro-seed0` |
| 9 PERMISO | ✅ | tribes 16 · subtribes 9 · invites 44 · rooms 7 · calendars 36 · events 7 · mailing 4 · wiki 5 · maps 3: **delta = previsto en los nueve**, seq 3 → 134; salas con `hub` = pub; 43 blobs en bot y pub; ledger 91 claves; `check retro-seed0`: pub 0, hub 0, bot-2 0 |
| 9c PERMISO | ✅ | `clearnet` 14/14, seq 134 → 148; el HUB ya tenía el feed (seq 148) sin reiniciar |
| 10 | ✅ | `hub-disk.sh prune-cache` (518935 → 0 B); sitemap público 191 URL (1 calendario, 7 eventos, 1 mapa, 27 wikis…); `/c/blob/<png>` 11863 B `image/png`; wiki de reparto con cuerpo y portada; matriz HUB §4 GATE OK; guía con el ledger del VPS: 32 enlaces `/c/…` en 200 y sin «not accessible» (24 tribus, 1 calendario, 1 mapa, 5 wikis, 1 evento) |
| 11 | ✅ | `site/parlament/index.html` vivo (CRLF, distinto del repo): **solo +1 línea** sobre el vivo, a nivel de bytes, backup `.bak-retro-*`; `campamento/index.html` nuevo; `https://pub.escrivivir.co/parlament/campamento/` 200 con 24 enlaces a `/c/tribe/` |
| 12 | ✅ | backup `secret` + `oasis/keys` + `conn.json` → `devops/backups/oasis-retro-bot/20261008T120750Z/` (fuera de git; mover a cifrado); `snapshot retro-final`; `deploy-log.sh … --mode …+retro`; `deploy-status`: 4 nodos healthy, `config/retro-bot/ssb-config` igual que HEAD; ficha §3-§4 al día |

Trampas nuevas para el protocolo: en Git Bash con `MSYS_NO_PATHCONV=1` exportado, `curl -o /tmp/x` y
`-D /tmp/x` escriben en `C:\tmp` (inexistente) y la matriz del HUB da `000`: la variable va **delante de
cada `docker exec`**, nunca exportada (ya lo decía AGENTES §4 para el gate `hub`; aquí costó dos medidas falsas).
