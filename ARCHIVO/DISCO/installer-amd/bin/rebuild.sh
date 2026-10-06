#!/usr/bin/env bash
# rebuild.sh <v1.deb>
# Regenera el .deb a partir del payload del v1 con packaging/build-deb2.sh, dentro de la imagen de build.
# Antes construye con el script upstream sin tocar (R0) y compara el contenido, para demostrar que el
# payload extraído es un SRC_DIR fiel. Evidencia en reports/evidence/rebuild/.
set -euo pipefail
export MSYS_NO_PATHCONV=1
KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
deb="${1:?uso: rebuild.sh <v1.deb>}"
[ -f "$deb" ] || { echo "no existe $deb" >&2; exit 2; }
DEB_HOST="$(cygpath -m "$(realpath "$deb")" 2>/dev/null || realpath "$deb")"
KIT_DK="$(cygpath -m "$KIT_DIR" 2>/dev/null || echo "$KIT_DIR")"
docker build -q -t oasis-deb-build -f "$KIT_DK/docker/Dockerfile.build" "$KIT_DK/docker" >/dev/null
rm -rf "$KIT_DIR/dist/rebuild-evidence"
docker run --rm --name oasis-deb-rebuild \
  -v "$DEB_HOST:/pkg/oasis.deb:ro" \
  -v "$KIT_DK:/kit:ro" \
  -v "$KIT_DK/dist:/out" \
  -v oasis-deb-node-cache:/cache \
  oasis-deb-build bash /kit/docker/rebuild-inner.sh
mkdir -p "$KIT_DIR/reports/evidence/rebuild"
mv "$KIT_DIR/dist/rebuild-evidence/"* "$KIT_DIR/reports/evidence/rebuild/"
rmdir "$KIT_DIR/dist/rebuild-evidence"
echo "== evidencia en reports/evidence/rebuild/; paquete en dist/"
ls -l "$KIT_DIR/dist/"
