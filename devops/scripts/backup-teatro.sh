#!/usr/bin/env bash
# backup-teatro.sh — el Teatro es REGENERABLE (lore + sidecar), así que no se copia la media.
#   --verify        compara el árbol remoto de la obra con el MANIFEST.sha256 local (solo lectura)
#   (sin flag)      trae lo NO regenerable: portada estampada, checksums, firmas, manifiesto; y
#                   empaqueta los stores de voces y enlaces del lore (contenido de terceros que
#                   desaparece con el tiempo). Los exports son responsabilidad del usuario.
# Uso: TEATRO_OBRA=<obra> bash devops/scripts/backup-teatro.sh [--verify]
set -euo pipefail
export MSYS_NO_PATHCONV=1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib-host.sh"
REPO_ROOT="$(cd "$DEVOPS_DIR/.." && pwd)"
OBRA="${TEATRO_OBRA:-}"
[[ "$OBRA" =~ ^[a-z0-9][a-z0-9-]*$ ]] || { echo "ERROR: define TEATRO_OBRA=<obra>"; exit 2; }
KEY_PATH="${KEY_PATH:-}"; [[ -f "$KEY_PATH" ]] || { echo "ERROR: clave SSH no encontrada: $KEY_PATH"; exit 1; }
REMOTE="$REMOTE_USER@$REMOTE_HOST"
REMOTE_OBRA="${REMOTE_TEATRO_DIR:-/srv/oasis/teatro}/$OBRA"
LOCAL_OBRA="${LOCAL_TEATRO_DIR:-$REPO_ROOT/volumes-dev/teatro}/$OBRA"
SOURCE="${TEATRO_SOURCE:-twitter_x}"
LORE="$REPO_ROOT/ARCHIVO/LORE/$SOURCE/$OBRA"
SSH_OPTS=(-i "$KEY_PATH" -o StrictHostKeyChecking=accept-new -o BatchMode=yes -o ConnectTimeout=15)

if [[ "${1:-}" == "--verify" ]]; then
  [[ -f "$LOCAL_OBRA/MANIFEST.sha256" ]] || { echo "ERROR: falta $LOCAL_OBRA/MANIFEST.sha256 (sidecar.py manifest)"; exit 1; }
  echo "[backup-teatro] verificando $REMOTE:$REMOTE_OBRA contra el manifiesto local…"
  ssh "${SSH_OPTS[@]}" "$REMOTE" "cd '$REMOTE_OBRA' && sha256sum -c --quiet - && echo OK_MANIFEST" < "$LOCAL_OBRA/MANIFEST.sha256"
  n_local="$(wc -l < "$LOCAL_OBRA/MANIFEST.sha256")"
  n_remote="$(ssh "${SSH_OPTS[@]}" "$REMOTE" "cd '$REMOTE_OBRA' && find . -type f ! -name '*.zip' ! -name '*.sha256' ! -name '*.sig' ! -name allowed_signers ! -path ./index.html | wc -l")"
  echo "[backup-teatro] ficheros: manifiesto $n_local · remoto $n_remote (sin zips, firmas ni portada)"
  ssh "${SSH_OPTS[@]}" "$REMOTE" "du -sh '$REMOTE_OBRA'; df -h /srv/oasis | tail -1; find '$REMOTE_OBRA' -perm -o+w | head -3 | wc -l | sed 's/^/world-writable: /'"
  exit 0
fi

TS="$(date -u +%Y%m%dT%H%M%SZ)"
DEST="$DEVOPS_DIR/backups/teatro/$OBRA/$TS"
mkdir -p "$DEST/remote"
echo "[backup-teatro] artefactos no regenerables de $REMOTE_OBRA → $DEST/remote"
for f in index.html "$OBRA.zip.sha256" "$OBRA.zip.sha256.sig" "$OBRA-cerebro.zip.sha256" "$OBRA-cerebro.zip.sha256.sig" MANIFEST.sha256 MANIFEST.sha256.sig allowed_signers; do
  ssh "${SSH_OPTS[@]}" "$REMOTE" "cat '$REMOTE_OBRA/$f' 2>/dev/null" > "$DEST/remote/$f" || true
  [[ -s "$DEST/remote/$f" ]] || rm -f "$DEST/remote/$f"
done
if [[ -d "$LORE/store" ]]; then
  echo "[backup-teatro] stores del lore (voces y enlaces) → $DEST/lore-store.tgz"
  tar -C "$LORE" -czf "$DEST/lore-store.tgz" store cache/links obra.json 2>/dev/null || tar -C "$LORE" -czf "$DEST/lore-store.tgz" store obra.json
fi
( cd "$DEST" && find . -type f ! -name SHA256SUMS.txt -print0 | xargs -0 sha256sum > SHA256SUMS.txt && sha256sum -c --quiet SHA256SUMS.txt )
du -sh "$DEST" | sed 's/^/[backup-teatro] /'
echo "[backup-teatro] OK. Cópialo fuera de la máquina. Los exports (ARCHIVO/LORE/.../exports) NO van aquí."
