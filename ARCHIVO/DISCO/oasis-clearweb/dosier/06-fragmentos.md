# 06 · Fragmentos finales para el worker del WP-O46

Todo lo de aquí vive en `ALCANCE_DIFF`. Nada toca `src/`, `Dockerfile`, `docker-entrypoint.sh` ni el
servicio `oasis-pub` del compose. Los valores `[NV]` se confirman en los gates de `07`.

## 1. `pub/docker-compose.pub.yml` — servicios nuevos (añadir tras `pub-web`, antes de `pub-frontend`)

```yaml
  oasis-hub:                      # nodo de soporte: backend.js --public con sbot embebido (gui.js:12-16)
    image: oasis-pub-scriptorium:latest      # misma imagen que el pub, sin build
    container_name: oasis-pub-hub
    command: ["backend"]                     # docker-entrypoint.sh:521-524 → node backend.js --host 0.0.0.0
    restart: unless-stopped
    depends_on: [oasis-pub]
    environment:
      NODE_ENV: production
      OASIS_SKIP_AI_MODEL: "true"
      OASIS_SERVER_CONFIG_OVERRIDE: /home/oasis/.ssb/config
      HOME: /home/oasis
      SSB_PATH: /home/oasis/.ssb
      OASIS_PUBLIC: ${OASIS_HUB_PUBLIC:-true}     # false SOLO durante el bootstrap del invite
      OASIS_OPEN: "false"
      OASIS_ALLOW_HOST: ${OASIS_PUB_WEB_HOST:-pub.escrivivir.co}
      NODE_OPTIONS: ${OASIS_HUB_NODE_OPTIONS:---max-old-space-size=1024}
    volumes:
      - "${OASIS_HUB_SSB_DATA_DIR:-../volumes-dev/oasis-hub/ssb-data}:/home/oasis/.ssb"
      - "${OASIS_HUB_LOGS_DIR:-../volumes-dev/oasis-hub/logs}:/app/logs"
      - "${OASIS_HUB_SSB_CONFIG_FILE:-./config/hub/ssb-config}:/home/oasis/.ssb/config:ro"
      - "${OASIS_HUB_OASIS_CONFIG_FILE:-./config/hub/oasis-config.json}:/app/src/configs/oasis-config.json:ro"
    # sin ports: 3000 y 8008 solo en oasis_pub_net
    mem_limit: ${OASIS_HUB_MEM_LIMIT:-1536m}      # generoso el día 1; 1.5×pico tras 24 h (07 §G6)
    logging:
      driver: json-file
      options: { max-size: "20m", max-file: "5" }
    healthcheck:   # feed inexistente pero válido: una consulta backlinks, 200; NO /c (O(N·k), F11)
      test: ["CMD-SHELL", "curl -fsS -o /dev/null http://127.0.0.1:3000/c/inhabitant/@AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=.ed25519"]
      interval: 60s
      timeout: 10s
      retries: 5
      start_period: 120s
    networks: [oasis_pub_net]

  hub-cache:                      # caché HTTP en disco delante del HUB
    image: nginx:alpine
    container_name: oasis-pub-hub-cache
    restart: unless-stopped
    depends_on: [oasis-hub]
    environment:
      HUB_UPSTREAM: oasis-hub:3000
      HUB_CACHE_MAX_SIZE: ${HUB_CACHE_MAX_SIZE:-2g}
    volumes:
      - ./config/hub/nginx.conf.template:/etc/nginx/templates/default.conf.template:ro
      - "${OASIS_HUB_HTTP_CACHE_DIR:-../volumes-dev/oasis-hub/http-cache}:/var/cache/hub"
    mem_limit: 128m
    logging:
      driver: json-file
      options: { max-size: "10m", max-file: "3" }
    healthcheck:
      test: ["CMD-SHELL", "wget -qO- http://127.0.0.1/hub-cache-health >/dev/null"]
      interval: 30s
      timeout: 5s
      retries: 3
    networks: [oasis_pub_net]
```

Por qué cada cosa: `image` sin `build` (cero rebuild, `02 §3`) · `command: ["backend"]` (`03 §2`) ·
`OASIS_*` por env (`01 §2`) · `OASIS_SERVER_CONFIG_OVERRIDE` al mismo fichero que ya lee `ssb-config`
(patrón del pub; el override gana, `01 §8`) · sin `ports` (Caddy → nginx → HUB por alias de red) ·
`mem_limit` desde el día 1 porque el pub no tiene límite (F9 de `05`) · `logging` porque `/app/logs` no
tiene escritores (F17) · healthcheck barato (F11) · `curl` existe en la imagen (`Dockerfile:10`) y `wget`
en `nginx:alpine` (busybox).

## 2. `pub/config/hub/ssb-config`

```json
{
  "logging": { "level": "notice" },
  "caps": { "shs": "H5EC+V5BU9s0lWxCkt4z8a095Sj8a6TgiLKPYi1JD7s=" },
  "pub": false,
  "local": false,
  "friends": { "dunbar": 150, "hops": 2 },
  "gossip": { "connections": 5, "local": false, "friends": true, "seed": true, "global": false },
  "seeds": ["net:oasis-pub:8008~shs:/snvahvaTP5obvdiYva9OX9NNnTSlUQbEUBSuDRzrZA="],
  "replicationScheduler": { "autostart": true, "partialReplication": null },
  "autofollow": { "enabled": false, "feeds": [] },
  "connections": {
    "incoming": {
      "net":  [ { "scope": "device", "transform": "shs", "port": 8008, "host": "127.0.0.1" } ],
      "unix": [ { "scope": ["device"], "transform": "noauth" } ]
    },
    "outgoing": { "net": [ { "transform": "shs" } ], "tunnel": [], "onion": [], "ws": [] }
  }
}
```

- Mismo `caps.shs` (ciclo 6; si el ciclo rota, este fichero entra en el lockstep de UPGRADE-PROTOCOL §5).
- `pub:false` → `ssb-invite-client` (tiene `invite.accept`, no `invite.create`); sin `external` (no se anuncia).
- `hops 2` = pub (1) + todo lo que el pub sigue (2). `dunbar 150` y `connections 5` conservadores: el HUB
  solo necesita hablar con el pub.
- `autofollow.enabled:false` → el plugin no se carga (`SSB_server.js:88-98`); el follow lo pone el invite.
- `seeds` es cinturón **[NV]** (clave `/snvahva…=` = feed id sin `@` ni `.ed25519`); la persistencia real
  la deja `invite.accept` en `conn.json`/`gossip.json`.
- `connections.incoming.net` **completo** porque `mergeDeep` reemplaza arrays (F16).
- El `secret` lo genera `ssb-keys` en el primer arranque en el bind → identidad nueva.

## 3. `pub/config/hub/oasis-config.json`

Copia de `src/configs/oasis-config.json` (84 líneas) con estas diferencias:

```json
"modules": { "…igual…", "aiMod": "off", "aiNavMod": "off" },
"walletPub": { "pubId": "" },
"ssbLogStream": { "limit": 20000 },
"lanBroadcasting": false,
"themes": { "current": "Dark-SNH" }
```

- `ssbLogStream.limit` se lee **una vez** al cargar `inhabitants_model.js` → cambiarlo exige reiniciar el HUB.
- Montado `:ro`; regla del bind de fichero: **sobrescribir in place** (`cat > fichero`), nunca `mv` encima.
- El fichero del pub (`src/configs/oasis-config.json` dentro de su imagen) no se toca.

## 4. `pub/config/hub/nginx.conf.template`

```nginx
proxy_cache_path /var/cache/hub levels=1:2 keys_zone=hub:10m
                 max_size=${HUB_CACHE_MAX_SIZE} inactive=7d use_temp_path=off;
limit_req_zone $http_x_forwarded_for zone=hub_req:10m rate=10r/s;   # todo llega desde la IP de Caddy (F13)
map $upstream_cache_status $hub_cache_status { default $upstream_cache_status; "" "BYPASS"; }

server {
  listen 80;
  server_name _;
  resolver 127.0.0.11 valid=30s ipv6=off;       # DNS interno de Docker
  set $hub_up http://${HUB_UPSTREAM};
  if ($request_method !~ ^(GET|HEAD)$) { return 405; }        # 2ª barrera; el backend ya 403ea (F20)

  location = /hub-cache-health { access_log off; return 200 "ok\n"; }

  proxy_hide_header X-Frame-Options;          # las fija Caddy (header global del vhost) (F8)
  proxy_hide_header X-Content-Type-Options;
  proxy_hide_header Referrer-Policy;
  proxy_hide_header Permissions-Policy;
  proxy_hide_header Set-Cookie;
  proxy_ignore_headers Set-Cookie;

  proxy_http_version 1.1;
  proxy_set_header Host $host;                # Caddy conserva el Host del cliente
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto https;
  proxy_set_header Connection "";
  proxy_connect_timeout 5s;
  proxy_read_timeout 40s;

  proxy_cache hub;
  proxy_cache_key "$scheme$host$request_uri";
  proxy_cache_lock on;
  proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
  proxy_cache_background_update on;
  proxy_cache_valid 200 301 302 60s;
  proxy_cache_valid 404 30s;                  # caché negativa con caducidad (WP-O53)
  proxy_cache_valid 500 502 503 504 5s;
  add_header X-Cache-Status $hub_cache_status always;

  location ^~ /c/blob/ {                      # immutable del backend; ausente = hasta 30 s de want (F9)
    limit_req zone=hub_req burst=40 nodelay;
    proxy_cache_lock_timeout 35s;
    proxy_cache_lock_age 35s;
    proxy_cache_valid 200 30d;
    proxy_cache_valid 404 30s;
    proxy_pass $hub_up;                       # SIN URI: pasa $request_uri crudo (%2F intacto)
  }
  location ~ ^/(c|clearnet)(/|$|\?) {
    limit_req zone=hub_req burst=20 nodelay;
    proxy_pass $hub_up;
  }
  location ~ ^/assets/(styles|themes|images)/ {
    proxy_cache_valid 200 1d;
    proxy_pass $hub_up;
  }
  location / { return 404; }                  # nada más del backend sale por aquí (F20)
}
```

Notas: `^~ /c/blob/` tiene prioridad sobre la regex de `/c` · `nginx:alpine` renderiza
`/etc/nginx/templates/*.template` con envsubst solo sobre las variables **definidas** en el entorno del
contenedor (`$host`, `$request_uri`, `$hub_up` quedan intactos) **[NV-doc → G1]** · los HTML de `/c` no
traen `Cache-Control` → mandan los `proxy_cache_valid`; si se quiere que el navegador cachee, añadir
`add_header Cache-Control "public, max-age=60"` en la location HTML · `/qr/*` no se enruta (F14).

## 5. `pub/caddy/Caddyfile` — vhost del pub, sustituye las l.10-19

```caddyfile
  @public path /public/*
  handle @public { reverse_proxy pub-panel-api:8787 }

  # HUB clearnet: nodo de soporte oasis-hub detrás de la caché hub-cache (WP-O46).
  # /assets/* NO entero: /assets/fanzine.css es de la landing. /qr/* no se expone (localhost:3000 en el QR).
  @hub path /c /c/* /clearnet /assets/styles/* /assets/themes/* /assets/images/*
  handle @hub {
    reverse_proxy hub-cache:80 {
      transport http { dial_timeout 5s  response_header_timeout 45s }
    }
  }

  handle { root * /srv/site  try_files {path} {path}/index.html /index.html  file_server }
```

El bloque `header {}` (l.4-8) **no cambia**. Los 5 vhosts ajenos (l.22-107) **no se tocan**. Aplicar con
`caddy validate` + `caddy reload`; Caddy resuelve `hub-cache` por petición → si cae, 502 solo en `@hub`.

## 6. Bootstrap del nodo de soporte (una vez, en el VPS)

```bash
set -euo pipefail
cd /opt/oasis-scriptorium/OASIS_PUB
C="docker compose --env-file .env.prod -f docker-compose.pub.yml"
D=/srv/oasis/oasis-hub
UIDO=$(stat -c %u /srv/oasis/oasis-pub/ssb-data)                    # uid del usuario oasis de la imagen
sudo mkdir -p $D/ssb-data $D/logs $D/http-cache
sudo chown -R "$UIDO:$UIDO" $D/ssb-data $D/logs
printf 'welcome=dismissed\n' | sudo tee $D/ssb-data/oasis-first-contact >/dev/null   # F4
sudo chown "$UIDO:$UIDO" $D/ssb-data/oasis-first-contact
BEFORE=$(docker exec oasis-pub-scriptorium grep -a -c '"type":"contact"' /home/oasis/.ssb/flume/log.offset)

OASIS_HUB_PUBLIC=false $C up -d --no-deps oasis-hub                  # fase 1: no público, no expuesto
until docker exec oasis-pub-hub curl -fsS -o /dev/null \
  http://127.0.0.1:3000/c/inhabitant/@AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=.ed25519; do sleep 5; done
docker exec oasis-pub-hub grep -o '"id": *"[^"]*"' /home/oasis/.ssb/secret     # feed id del HUB → anotar

INV=$(docker exec oasis-pub-scriptorium sh -lc 'cd /app/src/server && node /app/pub/tools/ssb-admin.js invite.create 1' \
      | grep -oE '[^[:space:]"]+:[0-9]+:@[A-Za-z0-9+/]+=\.ed25519~[A-Za-z0-9+/]+=?')
INV_BRIDGE="oasis-pub:${INV#*:}"                                     # host → alias de red (F15)
docker exec oasis-pub-hub curl -sS -o /dev/null -w '%{http_code}\n' -X POST \
  -H 'Referer: http://localhost:3000/invites' --data-urlencode "invite=$INV_BRIDGE" \
  http://localhost:3000/settings/invite/accept                        # 302 SIEMPRE (F2) → verificar estado:
sleep 10
docker exec oasis-pub-hub sh -lc 'grep -l oasis-pub /home/oasis/.ssb/conn.json /home/oasis/.ssb/gossip.json'   # ≥1
AFTER=$(docker exec oasis-pub-scriptorium grep -a -c '"type":"contact"' /home/oasis/.ssb/flume/log.offset)
[ "$AFTER" -gt "$BEFORE" ] || { echo "sin follow-back"; exit 1; }

docker exec oasis-pub-hub curl -sS -o /dev/null -w '%{http_code}\n' -X POST \
  -H 'Referer: http://localhost:3000/profile/edit' \
  -F 'name=HUB clearnet · Scriptorium' \
  -F 'description=Cuenta de soporte de pub.escrivivir.co: espejo de solo lectura. No publica por nadie; replica y muestra lo marcado como clearnet.' \
  http://localhost:3000/profile/edit                                  # 302; sin vis_* → no se lista en /c (F3)

$C up -d --no-deps oasis-hub                                          # fase 2: PUBLIC=true (default)
docker exec oasis-pub-hub curl -s -o /dev/null -w '%{http_code}\n' -X POST \
  -H 'Referer: http://localhost:3000/invites' http://localhost:3000/settings/invite/accept   # 403 → gate
$C up -d --no-deps hub-cache
docker exec oasis-pub-web wget -qO- --server-response http://hub-cache/c 2>&1 | grep -E 'HTTP/|X-Cache'   # 200 MISS → HIT
# Caddyfile ya subido in place (cat > caddy/Caddyfile):
docker exec oasis-pub-web caddy validate --config /etc/caddy/Caddyfile && \
docker exec oasis-pub-web caddy reload --config /etc/caddy/Caddyfile
```

Si `invite.create` falla con «no public ip address» (caso local), fijar `external` en la config del pub
local (`join-client.sh:15-17`).

## 7. `devops/scripts/hub-disk.sh` (esbozo)

```bash
#!/usr/bin/env bash
# hub-disk.sh — status | check | prune-blobs [--older-than N] [--dry-run] | prune-cache | --json
# Umbrales: HUB_DISK_SOFT_PCT (75) / HUB_DISK_HARD_PCT (90) sobre /srv/oasis y /. Salida: 0 ok · 1 soft · 2 hard.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; source "$SCRIPT_DIR/lib-host.sh"
: "${REMOTE_USER:?}" "${REMOTE_HOST:?}" "${KEY_PATH:?}"
HUB_DATA="${HUB_DATA:-/srv/oasis/oasis-hub}"; SOFT="${HUB_DISK_SOFT_PCT:-75}"; HARD="${HUB_DISK_HARD_PCT:-90}"
ssh_h(){ ssh -i "$KEY_PATH" -o StrictHostKeyChecking=accept-new -o BatchMode=yes -o ConnectTimeout=15 "$REMOTE_USER@$REMOTE_HOST" "$1"; }
pct(){ ssh_h "df --output=pcent $1 | tail -1 | tr -dc 0-9"; }
case "${1:-status}" in
  status)
    ssh_h "df -h / /srv/oasis | sed 1d; echo; findmnt -no OPTIONS /srv/oasis; echo;
           sudo du -sh $HUB_DATA/ssb-data/flume $HUB_DATA/ssb-data/blobs $HUB_DATA/http-cache $HUB_DATA/logs /srv/oasis/oasis-pub/ssb-data 2>/dev/null;
           echo; sudo find $HUB_DATA/ssb-data/blobs -type f | wc -l | sed 's/^/blobs=/';
           docker stats --no-stream --format 'table {{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}' oasis-pub-hub oasis-pub-hub-cache oasis-pub-scriptorium oasis-pub-web;
           docker system df" ;;
  check)
    p=$(pct /srv/oasis); r=$(pct /); m=$(( p > r ? p : r )); echo "uso: /srv/oasis=$p% /=$r%"
    [ "$m" -ge "$HARD" ] && exit 2; [ "$m" -ge "$SOFT" ] && exit 1; exit 0 ;;
  prune-blobs)
    N=30; DRY=""; shift
    while [ $# -gt 0 ]; do case "$1" in --older-than) N="$2"; shift 2;; --dry-run) DRY=1; shift;; *) shift;; esac; done
    ACT="-delete"; [ -n "$DRY" ] && ACT=""
    # -atime solo es fiable si el mount NO es noatime; con noatime se cae a -mtime (fecha de descarga)
    ssh_h "opts=\$(findmnt -no OPTIONS /srv/oasis); case \$opts in *noatime*) F=-mtime;; *) F=-atime;; esac;
           echo criterio=\$F +$N; sudo find $HUB_DATA/ssb-data/blobs/sha256 -type f \$F +$N -print $ACT | wc -l | sed 's/^/afectados=/'" ;;
  prune-cache)
    ssh_h "sudo find $HUB_DATA/http-cache -mindepth 1 -delete; docker exec oasis-pub-hub-cache nginx -s reload" ;;
  --json)
    ssh_h "printf '{\"ts\":\"%s\",\"srvOasisPct\":%s,\"rootPct\":%s,\"hubFlumeBytes\":%s,\"hubBlobsBytes\":%s,\"hubCacheBytes\":%s}\n' \
      \"\$(date -u +%FT%TZ)\" \"\$(df --output=pcent /srv/oasis | tail -1 | tr -dc 0-9)\" \"\$(df --output=pcent / | tail -1 | tr -dc 0-9)\" \
      \"\$(sudo du -sb $HUB_DATA/ssb-data/flume | cut -f1)\" \"\$(sudo du -sb $HUB_DATA/ssb-data/blobs | cut -f1)\" \"\$(sudo du -sb $HUB_DATA/http-cache | cut -f1)\"" ;;
  *) echo "uso: hub-disk.sh status|check|prune-blobs [--older-than N] [--dry-run]|prune-cache|--json"; exit 2 ;;
esac
```

Notas: `prune-blobs` nunca toca `flume/`, `secret`, `conn.json`, `gossip*.json`; borrar ficheros de
`blobs/sha256` con el sbot vivo es seguro por content-addressing **[NV ssb-blobs]** (`want` repone; la
caché nginx conserva la copia HTTP 7 días). `prune-cache` solo hace falta tras un rebuild de índices
(F12). Script npm: `"devops:hub-disk": "bash ./devops/scripts/hub-disk.sh"`. `deploy-status.sh` imprime
la línea de `check`.

## 8. `pub/scripts/common.sh` y `.env*`

`common.sh` (`:75-95`): añadir `OASIS_HUB_SSB_DATA_DIR`, `OASIS_HUB_LOGS_DIR`, `OASIS_HUB_HTTP_CACHE_DIR` a
`validate_vps_persistent_paths` (deben ser absolutas bajo `/srv/oasis/` en layout canónico) y a
`ensure_runtime_dirs`.

`pub/.env.vps.example` (y `.env.prod` del VPS, con backup previo):

```dotenv
# HUB clearnet · nodo de soporte (WP-O46). Estado en el volumen de datos.
OASIS_HUB_SSB_DATA_DIR=/srv/oasis/oasis-hub/ssb-data
OASIS_HUB_LOGS_DIR=/srv/oasis/oasis-hub/logs
OASIS_HUB_HTTP_CACHE_DIR=/srv/oasis/oasis-hub/http-cache
OASIS_HUB_SSB_CONFIG_FILE=./config/hub/ssb-config
OASIS_HUB_OASIS_CONFIG_FILE=./config/hub/oasis-config.json
HUB_CACHE_MAX_SIZE=2g
OASIS_HUB_MEM_LIMIT=1536m
OASIS_HUB_NODE_OPTIONS=--max-old-space-size=1024
# OASIS_HUB_PUBLIC=false   ← SOLO durante el bootstrap del invite; nunca con @hub activo en Caddy
```

`pub/.env.local.example` / `pub/.env.example`: mismas claves con `../volumes-dev/oasis-hub/*` y
`HUB_CACHE_MAX_SIZE=256m`.

## 9. Sala 04 (`pub/site/hub/`) — cambios de texto respecto a v1 §4

- Diagrama: `habitante → replicación → pub → (invite/follow-back) → nodo de soporte → nginx caché → Caddy /c`.
- Tarjeta nueva «Quién sirve esto»: «Este HUB lo sirve una **cuenta de soporte** del pub (feed
  `<id del HUB>`), de solo lectura. No publica por nadie ni escribe en el pub; replica lo que el pub
  replica y muestra solo lo que cada habitante marcó como Clearnet.»
- Se retira el aviso del QR (`/qr` no se expone). El resto (stats, «Cómo entrar», «Cómo aparecer», «Qué
  no verás», tabla de los 12 tipos, `door-link` a `/c`, footer) igual que v1.
- `README.md` de la sala: dependencia operativa pasa a `oasis-hub` + `hub-cache` + `@hub`.
