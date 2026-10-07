#!/usr/bin/env bash
# lib-node.sh — lo común para MEDIR los nodos de Oasis de una instancia (pub, HUB, bots),
# en el host por SSH o en el stack local. Requiere lib-host.sh ya cargado.
#
# Un nodo es un contenedor de la imagen de Oasis con su carpeta `.ssb` propia. De cada uno
# interesa lo mismo: qué versión corre, quién es (feed id) y qué ha publicado con su identidad.
#
# Lado operador (este fichero, al hacer `source`):
#   node_run_setup <0|1>   0 = host por SSH · 1 = stack local (pub/.env.local, volumes-dev/)
#                          define: run (ejecuta en destino el script que recibe por stdin),
#                          run_cmd "<comando>" (ejecuta un comando y deja pasar stdin),
#                          NODE_SUDO, NODE_COMPOSE_DIR, NODE_ENV_FILE, NODE_DATA, NODE_LOCAL
#   node_remote_lib        imprime las funciones de shell del LADO DESTINO (abajo). Se anteponen
#                          al script que se envía a `run`:
#                              { node_remote_preamble; node_remote_lib; cat <<'EOS' … EOS; } | run
#   node_remote_preamble   imprime las variables que esas funciones esperan
#   node_probe_seq <contenedor> <feed>   2ª fuente del `sequence`: pregunta al sbot vivo con
#                          pub/tools/ssb-probe.js por stdin (no depende de lo que traiga la imagen)
#
# Lado destino (funciones que imprime node_remote_lib):
#   node_ssb_dir <contenedor>         carpeta del host montada como /home/oasis/.ssb
#   node_feed <ssb-dir>               feed id (campo público `id` del secret; no se lee nada más)
#   node_log_format <ssb-dir>         flume (Oasis <= 1.1.x) · db2 (>= 1.2) · migrando · ninguno
#   node_own_scan <ssb-dir> <feed> [<contenedor>] [<tipo>]
#                                     una pasada por el log: `F <formato>`, `S <sequence propio>`,
#                                     `R <tipo>` por mensaje PROPIO (su `type`, `(cifrado)`,
#                                     `(sin-type-inicial)` o `(cadena)`), `L <último contenido de <tipo>>`.
#                                     Si el log no se puede leer: `S ?`, nunca `S 0`.
#   node_own_seq / node_own_records / node_own_types   lo mismo, por partes (mismos argumentos)
#   node_state / node_version / node_image <contenedor>
#
# Por qué así:
#  - Contar POR AUTOR. A hops > 0 el log trae los mensajes de media red (AGENTES §4).
#  - Los mensajes cifrados se guardan como `"content":"….box"`, no como objeto: un contador por
#    `"type"` no los ve y `grep '"private":true'` da 0 siempre. Aquí cuentan como `(cifrado)`.
#  - La invariante es `sequence` propio == nº de registros propios. Si no cuadra, la medida no
#    vale y quien la use debe decir «no medible», no «sin cambios».
#  - `grep -a -o … | wc -l`, nunca `grep -c`, sobre un fichero binario (AGENTES §4).
#  - Dos formatos de log. flume/log.offset es JSON y se lee con grep. db2/log.bipf es binario y lo
#    lee node dentro del contenedor (pub/tools/log-bipf.js): por eso db2 pide el contenedor en marcha.
#    Tras migrar, flume/log.offset es un fichero-guarda de texto: un grep sobre él da 0 sin error.
#    Lo que no se puede leer es `?`, y `?` es «no medible».

# shellcheck disable=SC2034
node_run_setup() {
  NODE_LOCAL="${1:-0}"
  local repo_root; repo_root="$(cd "$DEVOPS_DIR/.." && pwd)"
  if [ "$NODE_LOCAL" = 1 ]; then
    NODE_COMPOSE_DIR="$repo_root/pub"; NODE_ENV_FILE=".env.local"; NODE_DATA="$repo_root/volumes-dev"; NODE_SUDO=""
    run() { MSYS_NO_PATHCONV=1 bash -s; }
    run_cmd() { MSYS_NO_PATHCONV=1 bash -c "$1"; }
  else
    NODE_COMPOSE_DIR="${REMOTE_REPO_DIR:?REMOTE_REPO_DIR vacío (host.env)}"; NODE_ENV_FILE="${REMOTE_ENV_FILE:-.env.prod}"
    # Raíz de datos de TODOS los nodos (ecoin/, oasis-hub/, src-*.tgz…). host.env lleva la del pub
    # (REMOTE_DATA_ROOT=<raíz>/oasis-pub): si no hay WALLET_DATA_ROOT, es su carpeta padre.
    NODE_DATA="${WALLET_DATA_ROOT:-${REMOTE_DATA_ROOT:+$(dirname "$REMOTE_DATA_ROOT")}}"; NODE_DATA="${NODE_DATA:-/srv/oasis}"; NODE_SUDO="sudo -n"
    [ -n "${REMOTE_USER:-}" ] && [ -n "${REMOTE_HOST:-}" ] || { echo "ERROR: REMOTE_USER/REMOTE_HOST vacíos" >&2; return 3; }
    [ -f "${KEY_PATH:-}" ] || { echo "ERROR: clave SSH no encontrada: ${KEY_PATH:-} (vive en devops/.ssh/, fuera de git)" >&2; return 3; }
    # En Windows la clave suele quedar con permisos abiertos y ssh la rechaza: copia temporal a 600.
    local key_mode; key_mode="$(stat -c '%a' "$KEY_PATH" 2>/dev/null || echo 600)"
    if [ "$key_mode" != "600" ] && [ "$key_mode" != "400" ]; then
      NODE_TMP_KEY_DIR="$(mktemp -d)"; cat "$KEY_PATH" > "$NODE_TMP_KEY_DIR/key"; chmod 600 "$NODE_TMP_KEY_DIR/key"; KEY_PATH="$NODE_TMP_KEY_DIR/key"
    fi
    run() { ssh -i "$KEY_PATH" -o BatchMode=yes -o ServerAliveInterval=30 "$REMOTE_USER@$REMOTE_HOST" bash -s; }
    run_cmd() { ssh -T -i "$KEY_PATH" -o BatchMode=yes -o ConnectTimeout=15 "$REMOTE_USER@$REMOTE_HOST" "$1"; }
  fi
}
node_run_cleanup() { [ -n "${NODE_TMP_KEY_DIR:-}" ] && rm -rf "$NODE_TMP_KEY_DIR"; return 0; }

node_remote_preamble() {
  printf 'SUDO=%q; NODE_LOCAL=%q; NODE_DATA=%q\n' "$NODE_SUDO" "$NODE_LOCAL" "$NODE_DATA"
}

node_probe_seq() { # node_probe_seq <contenedor> <feed>  → sequence según el sbot vivo, o vacío
  local probe; probe="$(cd "$DEVOPS_DIR/.." && pwd)/pub/tools/ssb-probe.js"
  [ -f "$probe" ] || return 0
  run_cmd "docker exec -i -u oasis -e HOME=/home/oasis -e SSB_FEED='$2' -e SSB_ACTION=seq '$1' sh -lc 'cd /app/src/server && node -'" \
    < "$probe" 2>/dev/null | grep -o '"seq": *[0-9]*' | head -1 | grep -o '[0-9]*$'
}

node_remote_lib() {
  cat <<'NODE_LIB'
node_ssb_dir() { # en local Docker Desktop devuelve rutas de Windows: allí manda el layout de volumes-dev/
  if [ "${NODE_LOCAL:-0}" = 1 ]; then
    case "$1" in
      *wallet-bot*) echo "$NODE_DATA/oasis-wallet-bot/ssb-data" ;;
      *hub*)        echo "$NODE_DATA/oasis-hub/ssb-data" ;;
      *)            echo "$NODE_DATA/oasis-pub/ssb-data" ;;
    esac
  else
    docker inspect -f '{{range .Mounts}}{{if eq .Destination "/home/oasis/.ssb"}}{{.Source}}{{end}}{{end}}' "$1" 2>/dev/null
  fi
}
node_feed() {
  $SUDO grep -o '"id": *"@[A-Za-z0-9+/]\{43\}=\.ed25519"' "$1/secret" 2>/dev/null | head -1 | grep -o '@[^"]*'
}
node_log_format() { # flume | db2 | migrando | ninguno
  local old="$1/flume/log.offset" new="$1/db2/log.bipf" guard=0
  $SUDO head -c 64 "$old" 2>/dev/null | grep -a -q '^OASIS: this log was migrated' && guard=1
  if $SUDO test -f "$new"; then
    if [ "$guard" = 1 ] || ! $SUDO test -e "$old"; then echo db2; else echo migrando; fi
  elif [ "$guard" = 0 ] && $SUDO test -f "$old"; then echo flume
  else echo ninguno; fi
}
node_own_seq_flume() {
  { $SUDO grep -a -o "\"sequence\":[0-9]*,\"author\":\"$2\"" "$1/flume/log.offset" 2>/dev/null | sed 's/"sequence":\([0-9]*\).*/\1/'
    $SUDO grep -a -o "\"author\":\"$2\",\"sequence\":[0-9]*" "$1/flume/log.offset" 2>/dev/null | sed 's/.*"sequence"://'
    echo 0; } | sort -n | tail -1
}
node_own_records_flume() { # ancla en el sobre del mensaje (author…hash…content), en sus dos órdenes históricos
  $SUDO grep -a -o "\"author\":\"$2\",\(\"sequence\":[0-9]*,\)\{0,1\}\"timestamp\":[0-9.]*,\"hash\":\"sha256\",\"content\":\({\"type\":\"[^\"]*\"\|{\|\"[^\"]*\"\)" "$1/flume/log.offset" 2>/dev/null \
    | sed -e 's/.*"content":{"type":"\([^"]*\)"$/\1/' \
          -e 's/.*"content":{$/(sin-type-inicial)/' \
          -e 's/.*"content":"[^"]*\.box[0-9]*"$/(cifrado)/' \
          -e 's/.*"content":".*/(cadena)/'
}
node_own_scan() { # node_own_scan <ssb-dir> <feed> [<contenedor>] [<tipo para L>]  → líneas F/S/R/L/T/D/A
  local fmt out; fmt="$(node_log_format "$1")"; echo "F $fmt"
  case "$fmt" in
    flume)
      echo "S $(node_own_seq_flume "$1" "$2")"
      node_own_records_flume "$1" "$2" | sed 's/^/R /'
      if [ -n "${4:-}" ]; then
        $SUDO grep -a -o "\"author\":\"$2[^{]*{\"type\":\"$4\"[^}]*" "$1/flume/log.offset" 2>/dev/null | tail -1 | sed 's/.*"content":/L /' | cut -c1-402
      fi ;;
    db2) # binario BIPF: lo lee node dentro del contenedor (pub/tools/log-bipf.js por stdin)
      out="$(node_bipf_js | docker exec -i -u oasis -e HOME=/home/oasis -e SSB_FEED="$2" -e SSB_LAST_TYPE="${4:-}" "${3:-}" sh -lc 'cd /app/src/server && node -' 2>/dev/null)"
      if printf '%s\n' "$out" | grep -q '^S [0-9]'; then printf '%s\n' "$out" | grep '^[SRLTDA] '; else echo "S ?"; fi ;;
    *) echo "S ?" ;;
  esac
}
node_own_seq()     { node_own_scan "$@" | sed -n 's/^S //p'; }
node_own_records() { node_own_scan "$@" | sed -n 's/^R //p'; }
node_own_types()   { node_own_records "$@" | sort | uniq -c | sed 's/^ *//'; }
node_state()   { local s; s="$(docker inspect -f '{{.State.Status}}{{if .State.Health}} {{.State.Health.Status}}{{end}}' "$1" 2>/dev/null)"; echo "${s:-ausente}"; }
node_version() { docker exec "$1" sh -c 'grep -m1 "\"version\"" /app/src/server/package.json' 2>/dev/null | sed 's/.*: *"\([^"]*\)".*/\1/'; }
node_image()   { docker inspect -f '{{.Config.Image}} {{.Image}}' "$1" 2>/dev/null | sed 's/sha256:\(............\).*/\1/'; }
NODE_LIB
  # El lector del log db2 viaja dentro de la librería: en destino no hay checkout del repo.
  printf "node_bipf_js() { cat <<'NODE_BIPF_JS'\n"
  tr -d '\r' < "$(cd "$DEVOPS_DIR/.." && pwd)/pub/tools/log-bipf.js"
  printf '\nNODE_BIPF_JS\n}\n'
}
