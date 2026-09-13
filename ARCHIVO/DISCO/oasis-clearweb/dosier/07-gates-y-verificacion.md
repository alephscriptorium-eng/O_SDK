# 07 · Gates, medición y verificación

## 1. Gates locales (bloqueantes antes de tocar el VPS)

Entorno: `npm run pub:local:up` (perfil `.env.local`: pub local en SSB 8009, Caddy en 8088/8443; HUB en
`../volumes-dev/oasis-hub/*`).

| Gate | Qué se comprueba | Cómo | Pasa si |
|---|---|---|---|
| **G1 sintaxis** | compose, nginx, Caddy | `docker compose --env-file pub/.env.local -f pub/docker-compose.pub.yml config` · `docker run --rm -e HUB_UPSTREAM=oasis-hub:3000 -e HUB_CACHE_MAX_SIZE=2g -v "$PWD/pub/config/hub/nginx.conf.template:/etc/nginx/templates/default.conf.template:ro" nginx:alpine sh -c '/docker-entrypoint.sh nginx -t && cat /etc/nginx/conf.d/default.conf'` · `docker run --rm -v "$PWD/pub/caddy/Caddyfile:/etc/caddy/Caddyfile:ro" caddy:2-alpine caddy validate --config /etc/caddy/Caddyfile` | `oasis-hub`/`hub-cache` sin `ports` ni `build`; «syntax is ok»; en el render `$host`, `$request_uri`, `$hub_up` intactos y `max_size=2g` sustituido; Caddy «Valid configuration» |
| **G2 arranque** | sbot embebido, identidad nueva, `:ro` inocuo | pre-crear `volumes-dev/oasis-hub/ssb-data/oasis-first-contact`; `OASIS_HUB_PUBLIC=false docker compose … up -d oasis-hub`; `docker logs oasis-pub-hub` | sin «Another Oasis instance», sin `EADDRINUSE`, **sin `EROFS`**; existe `secret` nuevo y `socket`; `grep '"id"' …/ssb-data/secret` ≠ feed del pub; `docker exec oasis-pub-hub curl -fsS localhost:3000/c/inhabitant/@AAAA…=.ed25519` → 200 |
| **G3 bootstrap** | invite, follow-back, `about`, cierre de POST | script de `06 §6` contra el pub local (si `invite.create` da «no public ip», fijar `external` en `config.local`) | POST accept → 302; `conn.json`/`gossip.json` del HUB contienen `oasis-pub`; el pub publica +1 `contact`; `POST /profile/edit` → 302; a los 3 min en el HUB `grep -a -c '"private":true' flume/log.offset` = 0 y `'"type":"contact"'` = 1; tras `up -d oasis-hub` sin la variable, `POST …/invite/accept` → **403** |
| **G4 caché y cabeceras** | nginx, URI crudo, dedupe | `up -d hub-cache`; `curl -I localhost:8088/c` ×2; `curl -sI 'localhost:8088/c/inhabitant/%40AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA%3D.ed25519'`; `docker logs oasis-pub-hub-cache`; `curl -sI localhost:8088/c \| grep -ci '^x-frame-options'`; `curl -X POST localhost:8088/c`; `curl -sI localhost:8088/qr/x`; `curl -sI 'localhost:8088/c/blob/&AAAA…AAA=.sha256'` ×2 | `X-Cache-Status` MISS → HIT; 200 y la URI llega con `%40…%3D` sin decodificar; **1** `X-Frame-Options`; POST → 405; `/qr/x` y `/settings` → respuesta estática de Caddy (sin `X-Cache-Status`); blob inexistente → 404 en ≤ 35 s y HIT en la segunda |
| **G5 aislamiento** | fallos independientes | `docker stop oasis-pub-hub` → `npm run pub:local:whoami`, `pub:local:invite`; `docker start`; `docker stop` del pub → `curl -I localhost:8088/c` | pub responde con el HUB parado; `/c` sirve `STALE`/`HIT` con el pub parado; `docker stats` sin cambios en el pub |
| **G6 memoria** | línea base y límites | ver §2 | `mem_limit` y `--max-old-space-size` fijados con datos, presupuesto ≤ 3 GB |
| **G7 utilidad** | `hub-disk.sh` | `DEVOPS_HOST` de prueba apuntando a localhost o modo `--local` | `status`, `check`, `--json` renderizan sin error; `prune-blobs --dry-run` lista sin borrar |

## 2. Medición de memoria (G6 y cierre a 24 h)

1. `P` = RSS del pub en reposo (`docker stats --no-stream oasis-pub-scriptorium`).
2. Arrancar el HUB con `PUBLIC=false`, esperar `/c/inhabitant/@AAAA…` 200 y 10 min de replicación → `H0`.
3. Con `proxy_cache off` temporal en nginx (o pegando directo a `oasis-hub:3000` desde la red Docker):
   `ab -n 200 -c 4 http://…/c` → RSS pico `H1`.
4. `OASIS_HUB_MEM_LIMIT = ceil(1.5·H1)` (mín. 768m); `OASIS_HUB_NODE_OPTIONS=--max-old-space-size=<0.7·mem_limit>`.
5. Presupuesto del VPS (4 GB): `P + mem_limit + 128m (nginx) + ~150m (Caddy) + ~100m (panel) ≤ 3 GB`.
   Si no cabe: bajar `ssbLogStream.limit` (20000 → 5000), luego `friends.hops` a 1, **antes** que tocar el pub.
6. En el VPS: `docker stats` a los 10 min y a las 24 h → segundo `up -d --no-deps oasis-hub` con los valores finales.

## 3. Verificación end-to-end pública (tras el paso 4 del deploy)

```bash
H=https://pub.escrivivir.co; FEED='%40%2FsnvahvaTP5obvdiYva9OX9NNnTSlUQbEUBSuDRzrZA%3D.ed25519'
c() { curl -sS -o /dev/null -w "%{http_code} %{content_type}  $*\n" "$@"; }
c $H/ ; c $H/public/status ; c $H/assets/fanzine.css            # 200 html · 200 json · 200 css (estático)
c $H/hub/ ; curl -s $H/scriptorium/ | grep -c "Sala 04"          # 200 · 1
c $H/c ; c "$H/c?type=events" ; c $H/clearnet                    # 200 · 200 · 302
c "$H/c/inhabitant/$FEED" ; c $H/assets/images/snh-oasis.jpg     # 200 html · 200 image
curl -sI $H/c | grep -i x-cache-status ; curl -sI $H/c | grep -i x-cache-status   # MISS · HIT
curl -sI $H/c | grep -iE '^(x-frame-options|content-security-policy|referrer-policy)' | sort | uniq -c   # 1 de cada; script-src 'none'
c -X POST $H/c ; c -X POST $H/clearnet                            # 405 · 405 (nginx)
for p in settings profile publish update json/x qr/x; do curl -sI $H/$p | grep -ci 'x-cache-status'; done   # 0 ×6 (Caddy estático)
curl -s "$H/c/inhabitant/@nadie.ed25519" | grep -c "not accessible"   # 1 (200 por diseño upstream)
time curl -s -o /dev/null "$H/c?nocache=$RANDOM"                  # coste real de /c (MISS)
for v in scriptorium admin.scriptorium mcp.scriptorium npm.scriptorium rooms.scriptorium; do c https://$v.escrivivir.co/healthz; done   # 200 ×5
```

## 4. Comprobaciones en el VPS

| Qué | Cómo | Esperado |
|---|---|---|
| Contenedores | `docker ps --format 'table {{.Names}}\t{{.Status}}'` | `oasis-pub-scriptorium`, `oasis-pub-hub`, `oasis-pub-hub-cache` healthy; `oasis-pub-web` **sin reinicio** (`StartedAt` anterior al deploy) |
| Pub intacto | `ssb-admin.js whoami` en el pub; `grep -a -c '"type":"contact"' flume/log.offset` | mismo feed id; `contact` = BEFORE + 1 |
| HUB limpio | en el HUB `grep -a -c '"private":true' flume/log.offset`; `grep -o '"id": *"[^"]*"' secret` | 0; id anotado en el bootstrap |
| Disco de sistema | `df -h /` vs línea base | igual (sin rebuild) |
| Volumen de datos | `hub-disk.sh status`, `hub-disk.sh check` | rutas bajo `/srv/oasis/oasis-hub`; exit 0 |
| URI crudo | `docker logs oasis-pub-hub-cache \| grep '%40%2F'` | presente sin decodificar |
| Journal | `deploy-log.sh … --mode server+hub`; `hub-disk.sh --json` | línea nueva; JSON anotado en el reporte |

## 5. Rollback

| Nivel | Cuándo | Pasos | Tiempo | Efecto en el pub |
|---|---|---|---|---|
| 1 | `/c` da problemas | `cat caddy/Caddyfile.bak-hub-<fecha> > caddy/Caddyfile` → `caddy validate` → `caddy reload`; opcional `$C stop oasis-hub hub-cache` | < 2 min | ninguno |
| 2 | retirar del todo | `$C rm -sf oasis-hub hub-cache`; restaurar `docker-compose.pub.yml.bak-hub-<fecha>`; `/srv/oasis/oasis-hub` se conserva (identidad reutilizable) o se borra si se abandona la cuenta | < 5 min | ninguno; el `contact` del pub hacia el HUB queda en el log (append-only); opcional `unfollow` desde el pub |
| — | identidad del pub | su `.ssb` no está montado en ningún servicio nuevo; backup del paso 1 | — | — |

En ningún nivel se reinicia `oasis-pub` ni `pub-web`.
