#!/usr/bin/env bash
# =============================================================================
# pub-snapshot.sh — el snapshot que el PUB ofrece a los clientes nuevos (Oasis >= 1.2, D-O27).
#
# Un cliente que acepta un invite le pide al pub un fichero con el historial empaquetado
# (`<.ssb>/oasis/content/snapshot.oasissn`) y lo ingiere de golpe. Upstream lo construye con el
# backend público del pub; nuestro pub es solo sbot, así que lo construye pub/tools/snapshot-build.js
# dentro de su contenedor: lee el log por el socket, no publica y solo escribe registros de mensaje.
#
# QUIÉN LO RECONSTRUYE: el propio contenedor del pub. Su entrypoint, en modo server, lanza un proceso
# de fondo que lo rehace cada OASIS_PUB_SNAPSHOT_HOURS horas (6 en el compose; 0 = no ofrecerlo).
# No hay nada que instalar en el host. Este script es para MIRAR, forzar una construcción o retirarlo.
#
# Uso:
#   bash devops/scripts/pub-snapshot.sh [--local] status       fichero, tamaño, edad y mensajes · solo lectura
#   bash devops/scripts/pub-snapshot.sh [--local] build        lo (re)construye ahora. ESCRIBE en el .ssb del pub
#   bash devops/scripts/pub-snapshot.sh [--local] off --yes    borra el fichero: el pub dice «not available»
#                                                              hasta la siguiente reconstrucción. Para dejar
#                                                              de ofrecerlo: OASIS_PUB_SNAPSHOT_HOURS=0 en el
#                                                              env del pub y recrearlo; después, off.
#
#   --local   stack local (pub/.env.local, volumes-dev/); sin él, el host de la instancia por SSH
#
# Entorno: SNAPSHOT_MAX_MB (techo; por defecto 1024: por encima no se publica) · PUB_CONTAINER
#          SNAPSHOT_MAX_AGE_H (status avisa si es más viejo; por defecto 24)
# Códigos: 0 ok · 1 fallo · 2 sin snapshot o viejo (status) · 3 techo superado · 64 uso
#
# El pub solo lo sirve a quien SIGUE (lo hace al aceptarle un invite). No sale por HTTP.
# =============================================================================
set -uo pipefail
export MSYS_NO_PATHCONV=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib-host.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib-node.sh"
REPO_ROOT="$(cd "$DEVOPS_DIR/.." && pwd)"

usage() { sed -n '2,25p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

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
    [ "$YES" = 1 ] || { echo "off borra el snapshot del pub; si OASIS_PUB_SNAPSHOT_HOURS > 0 volverá en la siguiente reconstrucción. Repite con --yes." >&2; exit 64; }
    run_cmd "docker exec -u oasis '$PUBC' sh -c 'rm -f $FILE $FILE.tmp && echo retirado'" ;;
  status)
    hours="$(run_cmd "docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' '$PUBC'" 2>/dev/null | sed -n 's/^OASIS_PUB_SNAPSHOT_HOURS=//p' | tr -d '')"
    case "${hours:-}" in ''|0) echo "reconstrucción automática: DESACTIVADA en este contenedor (OASIS_PUB_SNAPSHOT_HOURS=${hours:-sin definir})" ;; *) echo "reconstrucción automática: cada $hours h, dentro del contenedor del pub" ;; esac
    run_cmd "docker exec -u oasis -e F='$FILE' -e MAXH='${SNAPSHOT_MAX_AGE_H:-24}' '$PUBC' sh -c '
      if [ ! -f \"\$F\" ]; then echo \"snapshot: no hay (el pub responde not available)\"; exit 2; fi
      size=\$(stat -c %s \"\$F\"); age=\$(( ( \$(date +%s) - \$(stat -c %Y \"\$F\") ) / 3600 ))
      meta=\$(tail -c +9 \"\$F\" | gunzip 2>/dev/null | head -c 600 | grep -a -o \"{\\\"version\\\":[^}]*}\" | head -1)
      echo \"snapshot: \$size bytes · hace \$age h · \$meta\"
      [ -f \"\$F.tmp\" ] && echo \"AVISO: hay un .tmp (construcción en curso o interrumpida)\"
      [ \"\$age\" -le \"\$MAXH\" ] || { echo \"AVISO: más viejo que \$MAXH h (¿corre el temporizador?)\"; exit 2; }
    '" ;;
esac
