#!/usr/bin/env bash
# lib.sh — helpers del banco de pruebas. Se carga con `source`; espera KIT_DIR, DEB_HOST, LABEL, EV_DIR y CASE.
export MSYS_NO_PATHCONV=1

_evfile() { printf '%s/%s.txt' "$EV_DIR" "${CASE:?CASE sin definir}"; }

# ev <comando...> — ejecuta en el host; graba «$ comando», la salida y el código de salida.
ev() {
  local f; f="$(_evfile)"
  printf '$ %s\n' "$*" >> "$f"
  "$@" >> "$f" 2>&1
  local rc=$?
  printf '[exit=%d]\n\n' "$rc" >> "$f"
  return $rc
}

# evx <contenedor> <orden sh> — lo mismo, pero dentro del contenedor vía `sh -c`.
evx() {
  local c="$1" cmd="$2" f; f="$(_evfile)"
  printf '$ docker exec %s sh -c %s\n' "$c" "$(printf '%q' "$cmd")" >> "$f"
  docker exec "$c" sh -c "$cmd" >> "$f" 2>&1
  local rc=$?
  printf '[exit=%d]\n\n' "$rc" >> "$f"
  return $rc
}

# note <texto> — una línea de contexto en la evidencia (no es salida de comando).
note() { printf '# %s\n' "$*" >> "$(_evfile)"; }

# obs <clave> <valor> — hecho observado; el informe cita estas líneas.
obs() { printf '%s %s=%s\n' "$CASE" "$1" "$2" | tee -a "$EV_DIR/OBSERVACIONES.txt" >&2; }

# Contenedores. Todos montan el .deb en /pkg/oasis.deb (solo lectura) y van sin red.
c_plain() {
  local name="$1"; shift
  docker rm -f "$name" >/dev/null 2>&1 || true
  docker run -d --name "$name" --network none -v "$DEB_HOST:/pkg/oasis.deb:ro" "$@" oasis-deb-plain >/dev/null
}
c_systemd() {
  local name="$1"; shift
  docker rm -f "$name" >/dev/null 2>&1 || true
  docker run -d --name "$name" --privileged --cgroupns=host --network none \
    -v "$DEB_HOST:/pkg/oasis.deb:ro" "$@" oasis-deb-systemd >/dev/null
}
c_rm() { local n; for n in "$@"; do docker rm -f "$n" >/dev/null 2>&1 || true; done; }

# wait_http <contenedor> <url> <segundos> — espera a que curl responda 2xx.
wait_http() {
  local c="$1" url="$2" t="$3" i=0
  while [ "$i" -lt "$t" ]; do
    if docker exec "$c" curl -fsS -m 2 "$url" >/dev/null 2>&1; then return 0; fi
    sleep 1; i=$((i+1))
  done
  return 1
}
# wait_systemd <contenedor> <segundos>
wait_systemd() {
  local c="$1" t="$2" i=0
  while [ "$i" -lt "$t" ]; do
    if docker exec "$c" systemctl is-system-running 2>/dev/null | grep -qE 'running|degraded'; then return 0; fi
    sleep 1; i=$((i+1))
  done
  return 1
}

# Arranque de Oasis como el usuario de servicio, sin systemd, igual que haría la unidad.
# oasis_start <contenedor> <log> <args de oasis.sh...>
oasis_start() {
  local c="$1" log="$2"; shift 2
  docker exec -d "$c" runuser -u oasis -- env HOME=/var/lib/oasis \
    PATH=/opt/oasis/node/bin:/usr/local/bin:/usr/bin:/bin NODE_ENV=production \
    sh -c "cd /opt/oasis && exec sh oasis.sh $* > $log 2>&1"
}
# El patrón [b]ackend no se encuentra a sí mismo en la línea de órdenes del sh -c que lo lanza.
oasis_stop() { docker exec "$1" sh -c 'pkill -f "[b]ackend\.js"; sleep 3; pkill -9 -f "[b]ackend\.js"; true' >/dev/null 2>&1; return 0; }

# El usuario de servicio se llama oasis; el .deb lo crea en el postinst.
C_MAIN="oasis-deb-${LABEL}-main"
