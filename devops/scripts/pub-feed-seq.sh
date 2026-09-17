#!/usr/bin/env bash
# =============================================================================
# pub-feed-seq.sh — pregunta al pub REMOTO (instancia activa de devops/hosts/) qué tiene de un feed:
# último `sequence`, si el pub lo sigue y si el feed sigue al pub. Solo lectura sobre el pub.
#
# Uso: bash devops/scripts/pub-feed-seq.sh <@feed=.ed25519> [--raw]
# Datos de instancia → devops/hosts/<DEVOPS_HOST>/host.env (REMOTE_USER/HOST, KEY_FILE, PUB_CONTAINER)
#
# Mecanismo: ssh -T … "docker exec -i <pub> node -" < pub/tools/ssb-probe.js   (sin rebuild de imagen)
# Lo usa client/scripts/sync-only.sh status --pub (docs/CLIENT-PROTOCOL.md §3).
# =============================================================================
set -euo pipefail
export MSYS_NO_PATHCONV=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib-host.sh"

FEED="${1:-}"; RAW="${2:-}"
[ -n "$FEED" ] || { echo "uso: pub-feed-seq.sh <@feed=.ed25519> [--raw]" >&2; exit 2; }
[[ "$FEED" =~ ^@[A-Za-z0-9+/]{43}=\.ed25519$ ]] || { echo "feed id inválido: $FEED" >&2; exit 2; }
KEY_PATH="${KEY_PATH:-}"
[ -f "$KEY_PATH" ] || { echo "ERROR: clave SSH no encontrada: '$KEY_PATH' (¿DEVOPS_HOST / host.env?)" >&2; exit 1; }
[ -n "${REMOTE_HOST:-}" ] && [ -n "${REMOTE_USER:-}" ] || { echo "ERROR: REMOTE_HOST/REMOTE_USER vacíos" >&2; exit 1; }
PUB_CONTAINER="${PUB_CONTAINER:-oasis-pub-scriptorium}"
PROBE="$REPO_ROOT/pub/tools/ssb-probe.js"
[ -f "$PROBE" ] || { echo "ERROR: falta $PROBE" >&2; exit 1; }

json="$(ssh -T -i "$KEY_PATH" -o StrictHostKeyChecking=accept-new -o BatchMode=yes -o ConnectTimeout=15 \
  "$REMOTE_USER@$REMOTE_HOST" \
  "docker exec -i -u oasis -e HOME=/home/oasis -e SSB_FEED='$FEED' -e SSB_ACTION=seq '$PUB_CONTAINER' sh -lc 'cd /app/src/server && node -'" \
  < "$PROBE")"

if [ "$RAW" = "--raw" ]; then printf '%s\n' "$json"; exit 0; fi
node -e '
const o = JSON.parse(process.argv[1]);
console.log(`pub=${o.me}\nfeed=${o.feed}\nseq_pub=${o.seq}\nlast=${o.lastTs || "-"}\npub_follows_feed=${o.iFollow}\nfeed_follows_pub=${o.followsMe}\npeers=${(o.peers||[]).filter(p=>p.state==="connected").length} connected`);
' "$json"
