#!/usr/bin/env bash
# =============================================================================
# pub-snapshot.sh — el snapshot que el PUB ofrece a los clientes nuevos (Oasis >= 1.2, D-O27).
#
# Un cliente que acepta un invite le pide al pub un fichero con el historial empaquetado
# (`<.ssb>/oasis/content/snapshot.oasissn`) y lo ingiere de golpe. Upstream lo construye con el
# backend público del pub; nuestro pub es solo sbot, así que lo construye pub/tools/snapshot-build.js
# dentro de su contenedor: lee el log por el socket, no publica y solo escribe registros de mensaje.
#
# Uso:
#   bash devops/scripts/pub-snapshot.sh [--local] status       fichero, tamaño, edad y mensajes · solo lectura
#   bash devops/scripts/pub-snapshot.sh [--local] build        lo (re)construye ahora. ESCRIBE en el .ssb del pub
#   bash devops/scripts/pub-snapshot.sh [--local] off --yes    lo retira: el pub vuelve a decir «not available»
#   bash devops/scripts/pub-snapshot.sh timer                  imprime las dos unidades de systemd para el host
#   bash devops/scripts/pub-snapshot.sh cron                   lo mismo como línea de crontab (host con cron)
#
#   --local   stack local (pub/.env.local, volumes-dev/); sin él, el host de la instancia por SSH
#
# Entorno: SNAPSHOT_MAX_MB (techo; por defecto 1024: por encima no se publica) · PUB_CONTAINER
#          SNAPSHOT_MAX_AGE_H (status avisa si es más viejo; por defecto 24)
# Códigos: 0 ok · 1 fallo · 2 sin snapshot o viejo (status) · 3 techo superado · 64 uso
#
# El pub solo lo sirve a quien SIGUE (lo hace al aceptarle un invite). No sale por HTTP.
# Activarlo en un host es escribir en el .ssb del pub y ofrecer un servicio nuevo: pide GO.
# =============================================================================
set -uo pipefail
export MSYS_NO_PATHCONV=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib-host.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib-node.sh"
REPO_ROOT="$(cd "$DEVOPS_DIR/.." && pwd)"

usage() { sed -n '2,23p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

LOCAL=0; YES=0; CMD=""
while [ $# -gt 0 ]; do
  case "$1" in
    --local) LOCAL=1 ;;
    --yes) YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) [ -z "$CMD" ] && CMD="$1" ;;
  esac
  shift
done
CMD="${CMD:-status}"
PUBC="${PUB_CONTAINER:-oasis-pub-scriptorium}"
MAX_MB="${SNAPSHOT_MAX_MB:-1024}"
FILE=/home/oasis/.ssb/oasis/content/snapshot.oasissn

# La orden que corre el temporizador llama al script que viaja DENTRO de la imagen: en el host no
# hay checkout del repo. Su ruta depende del layout del host: la carpeta del compose puede no
# llamarse `pub` (HUB-PROTOCOL §9). Se deduce de REMOTE_REPO_DIR (host.env) o se da con PUB_TOOLS_DIR.
TOOLS="${PUB_TOOLS_DIR:-/app/$(basename "${REMOTE_REPO_DIR:-pub}")/tools}"
BUILD_CMD="exec -u oasis -e HOME=/home/oasis -e SNAPSHOT_MAX_MB=$MAX_MB $PUBC node $TOOLS/snapshot-build.js"

if [ "$CMD" = timer ]; then
  # Dos unidades de systemd. Un servicio `oneshot` no se solapa consigo mismo: no hace falta cerrojo.
  # La salida (una línea JSON por construcción) queda en el journal: journalctl -u oasis-pub-snapshot.
  cat <<EOF
# --- /etc/systemd/system/oasis-pub-snapshot.service
[Unit]
Description=Snapshot del pub de Oasis para clientes nuevos (pub-snapshot.sh, D-O27)
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
ExecStart=${DOCKER_BIN:-/usr/bin/docker} $BUILD_CMD
TimeoutStartSec=900

# --- /etc/systemd/system/oasis-pub-snapshot.timer
[Unit]
Description=Reconstruye el snapshot del pub de Oasis cada 6 h

[Timer]
OnCalendar=*-*-* 00/6:17:00
RandomizedDelaySec=300
Persistent=true

[Install]
WantedBy=timers.target
EOF
  exit 0
fi
if [ "$CMD" = cron ]; then
  echo "# snapshot del pub cada 6 h (pub-snapshot.sh; D-O27). flock evita dos construcciones a la vez."
  echo "17 */6 * * * flock -n /tmp/pub-snapshot.lock docker $BUILD_CMD >> \$HOME/pub-snapshot.log 2>&1"
  exit 0
fi
case "$CMD" in status|build|off) ;; *) usage; exit 64 ;; esac

trap node_run_cleanup EXIT
node_run_setup "$LOCAL" || exit 3

case "$CMD" in
  build)
    BUILD="$REPO_ROOT/pub/tools/snapshot-build.js"
    [ -f "$BUILD" ] || { echo "ERROR: falta $BUILD" >&2; exit 1; }
    # Por stdin: vale también con una imagen que aún no lleve el script.
    out="$(run_cmd "docker exec -i -u oasis -e HOME=/home/oasis -e SNAPSHOT_MAX_MB='$MAX_MB' '$PUBC' sh -lc 'cd /app/src/server && node -'" < "$BUILD" 2>&1)"; rc=$?
    echo "$out" | tail -1
    exit $rc ;;
  off)
    [ "$YES" = 1 ] || { echo "off retira el snapshot del pub (los clientes nuevos replicarán sin él). Repite con --yes." >&2; exit 64; }
    run_cmd "docker exec -u oasis '$PUBC' sh -c 'rm -f $FILE $FILE.tmp && echo retirado'" ;;
  status)
    run_cmd "docker exec -u oasis -e F='$FILE' -e MAXH='${SNAPSHOT_MAX_AGE_H:-24}' '$PUBC' sh -c '
      if [ ! -f \"\$F\" ]; then echo \"snapshot: no hay (el pub responde not available)\"; exit 2; fi
      size=\$(stat -c %s \"\$F\"); age=\$(( ( \$(date +%s) - \$(stat -c %Y \"\$F\") ) / 3600 ))
      meta=\$(tail -c +9 \"\$F\" | gunzip 2>/dev/null | head -c 600 | grep -a -o \"{\\\"version\\\":[^}]*}\" | head -1)
      echo \"snapshot: \$size bytes · hace \$age h · \$meta\"
      [ -f \"\$F.tmp\" ] && echo \"AVISO: hay un .tmp (construcción en curso o interrumpida)\"
      [ \"\$age\" -le \"\$MAXH\" ] || { echo \"AVISO: más viejo que \$MAXH h (¿corre el temporizador?)\"; exit 2; }
    '" ;;
esac
