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
| 6 | **PERMISO · invite redimida** | `invite.create 1` en el pub (`/app/OASIS_PUB/tools/ssb-admin.js`, HUB §9), host → IP del bridge; `ssb-probe.js invite-accept` en el bot; verificar por estado (`conn.json`, `contact +1` en el pub); `hub-conn-fix.js 'net:oasis-pub:8008~shs:<KEY>'`; `docker restart`; CONNECTED | el pub publica **un** `contact` (su único cambio en todo el runbook) |
| 7 | **PERMISO · `about`** | `docker cp` del avatar a `/tmp` del bot · `ssb-admin.js publish-about 'retro.escrivivir.co' '<literal de la ficha §4>' --image /tmp/avatar.png` **una vez** · borrar `/tmp/avatar.png` · `upgrade-gates.sh --remote check pre-retro --expect 'pub:contact=+1 hub:=0 bot:=0 retro:about=+1'` · reiniciar → `oasisVersion=+1` | `image` = blob previsto; ficha §4: de *propuesto* a *publicado* con fecha |
| 8 | Dry-run | `retro-seed.sh --env pub/.env.prod --pub-id <id del pub> --evidence vps-dry` | exit 0; mismos `expected` que en el drill; delta 0 |
| 9 | **PERMISO por bloque** | `--yes tribes` → `--yes subtribes` → `--yes invites` → `--yes rooms` (el pub debe **seguir** al bot: lo hace el `contact` del paso 6; relé acotado HUB §14) → `calendars` → `events` → `mailing` → `wiki` → `maps` → **`clearnet`** (hace público en `/c`: permiso aparte). Tras cada uno, `check` | `delta == expected` en cada bloque; si no, parada dura |
| 10 | Verificación pública | `curl -s https://pub.escrivivir.co/c/sitemap.xml`; `/c/blob/<png>` → `200 image/png`; `/c/wiki/<reparto>`; HUB §4 matriz; `deploy-status.sh` | los 9 objetos `clearnet`; feed del pub = `contact +1` y nada más |
| 11 | Guía al sitio (Sala 02) | copiar el ledger del bot (`docker cp …/oasis/keys/plantilla-campamento.json`) al dosier **como evidencia** (no contiene códigos); `--reparto --ledger … --html … --out pub/site/parlament/campamento/index.html`; subir con la regla de la ficha §5 (sha256 del vivo antes; `deploy-site.sh` sincroniza con `--delete`: comprobar que no borra páginas vivas) | la página enlaza a `/c/…` reales; `verificar-sitio.mjs` limpio |
| 12 | Cierre | `backup-oasis-pub.sh`-equivalente del bot: `tar` de `/srv/oasis/oasis-retro-bot/ssb-data/{secret,oasis/keys}` fuera del host (el keyring de tribus es irremplazable; **quién lo custodia: DECISIÓN del colectivo**); `deploy-log.sh … --mode server+hub+wallet+retro`; `capacity.sh`; ficha §3 con feed id y fecha; CHANGELOG; reporte | journal con el cuarto nodo |

Rollback: `$C --profile retro stop oasis-retro-bot` deja el pub y el HUB como estaban; lo publicado no se
retira (el feed del bot se puede dejar de seguir desde el pub: `contact` irreversible, PERMISO).
