#!/usr/bin/env bash
# teatro-wsl.sh — lanza los scripts del Teatro que necesitan rsync/python3 dentro de WSL (Windows)
# o directamente (Linux/macOS).  Uso:  TEATRO_OBRA=<obra> bash devops/scripts/teatro-wsl.sh deploy
# Pasa a WSL las variables TEATRO_* y DEVOPS_HOST. La distro por defecto de WSL suele ser
# docker-desktop (sin bash): por eso se nombra siempre (WSL_DISTRO, default Ubuntu).
set -euo pipefail
export MSYS_NO_PATHCONV=1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
case "${1:-}" in
  deploy) TARGET="deploy-teatro.sh" ;;
  *) echo "uso: teatro-wsl.sh deploy   (con TEATRO_OBRA=<obra>)"; exit 2 ;;
esac
shift
if command -v rsync >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
  exec bash "$SCRIPT_DIR/$TARGET" "$@"
fi
command -v wsl.exe >/dev/null 2>&1 || { echo "ERROR: ni rsync local ni WSL. Instala rsync o WSL (Ubuntu)."; exit 1; }
DISTRO="${WSL_DISTRO:-Ubuntu}"
WIN_DIR="$(cygpath -m "$SCRIPT_DIR")"                       # C:/S_LAB/o-sdk/devops/scripts
WSL_DIR="/mnt/$(echo "${WIN_DIR:0:1}" | tr 'A-Z' 'a-z')${WIN_DIR:2}"
VARS=""
for v in TEATRO_OBRA TEATRO_DRY_RUN TEATRO_DELETE TEATRO_SKIP_ZIP TEATRO_SKIP_VERIFY REMOTE_TEATRO_DIR DEVOPS_HOST; do
  [ -n "${!v:-}" ] && VARS+="$v='${!v}' "
done
echo "[teatro-wsl] $DISTRO → $WSL_DIR/$TARGET  ${VARS}"
exec wsl.exe -d "$DISTRO" -- bash -lc "${VARS}bash '$WSL_DIR/$TARGET' $*"
