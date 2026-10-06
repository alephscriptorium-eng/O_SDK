#!/usr/bin/env bash
# run-tests.sh <ruta.deb> <etiqueta> [T0 T4 ...]
# Corre los casos de tests/ contra un .deb y deja la evidencia en reports/evidence/<etiqueta>/.
set -uo pipefail
export MSYS_NO_PATHCONV=1
KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
deb="${1:?uso: run-tests.sh <ruta.deb> <etiqueta> [casos...]}"
LABEL="${2:?uso: run-tests.sh <ruta.deb> <etiqueta> [casos...]}"
shift 2
sel=("$@")

[ -f "$deb" ] || { echo "no existe $deb" >&2; exit 2; }
DEB_HOST="$(cygpath -m "$(realpath "$deb")" 2>/dev/null || realpath "$deb")"
EV_DIR="$KIT_DIR/reports/evidence/$LABEL"
if [ -e "$EV_DIR" ] && [ ${#sel[@]} -eq 0 ]; then
  echo "ya existe $EV_DIR; usa otra etiqueta o pasa casos sueltos" >&2; exit 2
fi
mkdir -p "$EV_DIR"
# rutas en formato que entiende el daemon de Docker (en Git Bash, C:/… en vez de /c/…)
KIT_DK="$(cygpath -m "$KIT_DIR" 2>/dev/null || echo "$KIT_DIR")"
export KIT_DIR DEB_HOST LABEL EV_DIR

{
  echo "kit: installer-amd"
  echo "fecha: $(date -u +%FT%TZ)"
  echo "paquete: $(basename "$deb")"
  sha256sum "$deb" | cut -d' ' -f1
  docker version --format 'docker: {{.Server.Version}} {{.Server.Os}}/{{.Server.Arch}}'
  echo "host: $(uname -srm)"
} > "$EV_DIR/ENTORNO.txt"

echo "== imágenes"
docker build -q -t oasis-deb-plain   -f "$KIT_DK/docker/Dockerfile.plain"   "$KIT_DK/docker" >/dev/null || exit 1
docker build -q -t oasis-deb-systemd -f "$KIT_DK/docker/Dockerfile.systemd" "$KIT_DK/docker" >/dev/null || exit 1

for t in "$KIT_DIR"/tests/T*.sh; do
  base="$(basename "$t" .sh)"; id="${base%%-*}"
  if [ ${#sel[@]} -gt 0 ] && ! printf '%s\n' "${sel[@]}" | grep -qx "$id"; then continue; fi
  echo "== $base"
  if bash "$t"; then echo "$base ok" >> "$EV_DIR/RESUMEN.txt"
  else echo "$base ERROR(exit $?)" >> "$EV_DIR/RESUMEN.txt"; fi
done

# limpieza: nada queda corriendo, ningún volumen
docker ps -a --filter "name=oasis-deb-${LABEL}-" -q | xargs -r docker rm -f >/dev/null 2>&1

# filtro anti-secretos: claves privadas ed25519 o JSON con "private"
if grep -rlE '"private" *:|[A-Za-z0-9+/]{80,}={0,2}\.ed25519' "$EV_DIR" >/dev/null 2>&1; then
  echo "ALTO: material de claves en la evidencia; revisar antes de versionar" >&2; exit 3
fi
echo "== evidencia en $EV_DIR"; cat "$EV_DIR/RESUMEN.txt"
