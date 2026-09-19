#!/usr/bin/env bash
# =============================================================================
# teatro-p2p.sh — sacar una obra del Teatro a la escena P2P (WP-O110, fase 0).
#
# Oasis anuncia torrents pero no los siembra. El HTTPS del Teatro ya sirve con Range: un
# .torrent con SEMILLA WEB (BEP 19) convierte esa URL en fuente permanente sin ningún
# demonio. Para que eso valga, los bytes detrás de la URL no pueden cambiar: por eso
# primero se CONGELA la obra. Doc viva: docs/PUB/TEATRO-P2P-PROTOCOL.md.
#
# Uso:
#   TEATRO_OBRA=<obra> bash devops/scripts/teatro-p2p.sh <subcomando>
#
# Subcomandos:
#   status     marca de congelación, zips, artefactos p2p/.   [read-only]
#   congelar   escribe <obra>/CONGELADO.json (ficheros, tamaños, sha256, fecha, motivo) tras
#              comprobar cada zip contra su .sha256 publicado. Desde ese momento
#              deploy-teatro.sh NO regenera esos zips: una edición nueva sale con sufijo
#              (TEATRO_ZIP_SUFIJO). Idempotente; nunca re-congela con otros hashes.
#   publicar   exige la marca. Construye la imagen teatro-p2p-tools en el host, genera
#              <obra>/p2p/{*.torrent,*.meta4,p2p.json,index.html} en un contenedor efímero
#              y sin red, firma p2p.json en local (la clave no viaja) y verifica desde fuera.
#
# Variables: TEATRO_OBRA (obligatoria) · TEATRO_TITULO · TEATRO_MOTIVO (para congelar)
#   TEATRO_P2P_TRACKERS  lista separada por comas (por defecto tres abiertos; "-" = solo DHT/PEX)
#   REMOTE_TEATRO_DIR (/srv/oasis/teatro) · PUB_HOST · instancia por lib-host.sh
# Nada de esto es irreversible: son ficheros. Lo irreversible es ANUNCIARLO en Oasis.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib-host.sh"
REPO_ROOT="$(cd "$DEVOPS_DIR/.." && pwd)"
TOOLS="$REPO_ROOT/pub/teatro-seed/tools"

CMD="${1:-status}"
OBRA="${TEATRO_OBRA:-}"
[[ "$OBRA" =~ ^[a-z0-9][a-z0-9-]*$ ]] || { echo "ERROR: define TEATRO_OBRA=<obra> ([a-z0-9-])"; exit 2; }
PUB_HOST="${PUB_HOST:-pub.escrivivir.co}"
REMOTE_TEATRO_DIR="${REMOTE_TEATRO_DIR:-/srv/oasis/teatro}"
REMOTE_OBRA="$REMOTE_TEATRO_DIR/$OBRA"
BASE_URL="https://$PUB_HOST/teatro/$OBRA"
TITULO="${TEATRO_TITULO:-$OBRA}"
TRACKERS="${TEATRO_P2P_TRACKERS:-udp://tracker.opentrackr.org:1337/announce,udp://open.stealth.si:80/announce,udp://tracker.torrent.eu.org:451/announce}"
[ "$TRACKERS" = "-" ] && TRACKERS=""
FILES="$OBRA.zip,$OBRA-cerebro.zip"

KEY_PATH="${KEY_PATH:-}"
[[ -f "$KEY_PATH" ]] || { echo "ERROR: clave SSH no encontrada: $KEY_PATH"; exit 1; }
TMP_WORK="$(mktemp -d)"; trap 'rm -rf "$TMP_WORK"' EXIT
PUB_KEY_PATH="${PUB_KEY_PATH:-$KEY_PATH.pub}"
key_mode="$(stat -c '%a' "$KEY_PATH" 2>/dev/null || echo 600)"
if [[ "$key_mode" != "600" && "$key_mode" != "400" ]]; then
  cat "$KEY_PATH" > "$TMP_WORK/key"; chmod 600 "$TMP_WORK/key"; KEY_PATH="$TMP_WORK/key"
fi
SSH_OPTS="-i $KEY_PATH -o StrictHostKeyChecking=accept-new -o BatchMode=yes -o ServerAliveInterval=30"
REMOTE="${REMOTE_USER:?}@${REMOTE_HOST:?}"
rssh() { ssh $SSH_OPTS "$REMOTE" "$@"; }   # shellcheck disable=SC2029

case "$CMD" in
  status)
    rssh "cd '$REMOTE_OBRA' || exit 1
      if [ -f CONGELADO.json ]; then echo '== CONGELADA:'; cat CONGELADO.json; else echo '== no congelada: deploy-teatro.sh regenera los zips en cada deploy'; fi
      echo '== zips:'; ls -l *.zip 2>/dev/null | cut -c1-120
      echo '== p2p/:'; ls -l p2p 2>/dev/null | cut -c1-120 || true"
    ;;
  congelar)
    MOTIVO="${TEATRO_MOTIVO:-edición cerrada}"
    rssh "command -v python3 >/dev/null" || { echo "ERROR: python3 no disponible en el host"; exit 1; }
    rssh "cd '$REMOTE_OBRA' && python3 - '$OBRA' '$FILES' '$MOTIVO'" < "$TOOLS/congelar.py"
    ;;
  publicar)
    rssh "[ -f '$REMOTE_OBRA/CONGELADO.json' ]" || { echo "ERROR: $OBRA no está congelada: sus zips cambiarían en el próximo deploy y el torrent quedaría roto. Primero: congelar."; exit 3; }
    CONG="$(rssh "grep -o '\"congelado\": *\"[^\"]*\"' '$REMOTE_OBRA/CONGELADO.json' | cut -d'\"' -f4")"
    echo "[teatro-p2p] imagen de herramientas en el host…"
    tar -C "$TOOLS" -cf - Dockerfile gen_p2p.py | rssh "rm -rf /tmp/teatro-p2p-tools && mkdir -p /tmp/teatro-p2p-tools && tar -C /tmp/teatro-p2p-tools -xf - && docker build -q -t teatro-p2p-tools /tmp/teatro-p2p-tools && rm -rf /tmp/teatro-p2p-tools"
    echo "[teatro-p2p] generando artefactos (hash de los zips: puede tardar unos minutos)…"
    rssh "mkdir -p '$REMOTE_OBRA/p2p' && docker run --rm --network none --user \$(id -u):\$(id -g) -v '$REMOTE_OBRA':/obra -e P2P_OBRA='$OBRA' -e P2P_BASE_URL='$BASE_URL' -e P2P_FILES='$FILES' -e P2P_TRACKERS='$TRACKERS' -e P2P_TITULO='$TITULO' -e P2P_CONGELADO='$CONG' teatro-p2p-tools && chmod 644 '$REMOTE_OBRA'/p2p/*"
    if [[ -f "$PUB_KEY_PATH" ]]; then
      echo "[teatro-p2p] firmando p2p.json en local…"
      rssh "cat '$REMOTE_OBRA/p2p/p2p.json'" > "$TMP_WORK/p2p.json"
      ssh-keygen -Y sign -f "$KEY_PATH" -n file -q "$TMP_WORK/p2p.json"
      scp $SSH_OPTS -q "$TMP_WORK/p2p.json.sig" "$REMOTE:$REMOTE_OBRA/p2p/p2p.json.sig"
      rssh "chmod 644 '$REMOTE_OBRA/p2p/p2p.json.sig'"
    else
      echo "[teatro-p2p] AVISO: sin $PUB_KEY_PATH; p2p.json se publica sin firma."
    fi
    echo "[teatro-p2p] verificación desde fuera…"
    fail=0
    expect() { local code; code="$(curl -s -o /dev/null -w '%{http_code}' ${3:-} "$2")"; if [ "$code" = "$1" ]; then echo "  ok  $1 $2"; else echo "  FALLA $code (esperado $1) $2"; fail=1; fi; }
    expect 200 "$BASE_URL/p2p/"
    expect 200 "$BASE_URL/p2p/p2p.json"
    for f in ${FILES//,/ }; do
      expect 200 "$BASE_URL/p2p/$f.torrent"
      expect 200 "$BASE_URL/p2p/$f.meta4"
      expect 206 "$BASE_URL/$f" "-r 0-1023"
    done
    if [ "$fail" = 0 ]; then echo "[teatro-p2p] Done · $BASE_URL/p2p/"; else echo "[teatro-p2p] verificación con fallos"; exit 1; fi
    ;;
  *) sed -n '10,26p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 64 ;;
esac
