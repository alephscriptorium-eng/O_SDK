#!/usr/bin/env bash
# rebuild-inner.sh — corre DENTRO de la imagen oasis-deb-build.
# Entradas: /pkg/oasis.deb (v1, ro), /kit (el kit, ro), /out (dist/ del kit), /cache (tarball de Node).
# Pasos: payload v1 → SRC_DIR fiel → R0 (script upstream, sin cambios) → build con la propuesta.
set -euo pipefail
NODE_VERSION=22.20.0
TARBALL="node-v${NODE_VERSION}-linux-x64.tar.xz"
EV=/out/rebuild-evidence; mkdir -p "$EV"
log() { printf '%s\n' "$*" | tee -a "$EV/R-rebuild.txt" >&2; }
run() { printf '$ %s\n' "$*" >> "$EV/R-rebuild.txt"; "$@" >> "$EV/R-rebuild.txt" 2>&1; printf '[exit=%d]\n\n' $? >> "$EV/R-rebuild.txt"; }

log "== 1. payload del v1"
run sha256sum /pkg/oasis.deb
run dpkg-deb -x /pkg/oasis.deb /work/payload
mkdir -p /work/src
run rsync -a --exclude '/node/' /work/payload/opt/oasis/ /work/src/
run ls -la /work/src
run sh -c 'ls -l /work/src/src/server/node_modules'
export PATH="/work/payload/opt/oasis/node/bin:$PATH"
run node -v

log "== 2. Node ${NODE_VERSION} verificado contra SHASUMS256.txt de nodejs.org"
if [ ! -f "/cache/$TARBALL" ]; then
  run wget -q "https://nodejs.org/dist/v${NODE_VERSION}/${TARBALL}" -O "/cache/$TARBALL"
fi
run wget -q "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt" -O /cache/SHASUMS256.txt
(cd /cache && grep " ${TARBALL}\$" SHASUMS256.txt | sha256sum -c -) >> "$EV/R-rebuild.txt" 2>&1
cp "/cache/$TARBALL" /tmp/

log "== 3. R0 · reproducibilidad: script upstream sin cambios sobre el payload"
cp /kit/upstream/build-deb2.sh /work/src/scripts/build-deb2.sh
run bash /work/src/scripts/build-deb2.sh
R0=/tmp/oasis-deb-build/oasis_1.2.2_amd64.deb
run ls -l "$R0" /pkg/oasis.deb
dpkg-deb -c /pkg/oasis.deb | awk '{print $1, $3, $6, $7, $8}' | sort > /tmp/v1.lst
dpkg-deb -c "$R0"            | awk '{print $1, $3, $6, $7, $8}' | sort > /tmp/r0.lst
{ printf '$ diff <(dpkg-deb -c v1 | modo,tamaño,ruta) <(dpkg-deb -c R0 | ...)\n'; diff /tmp/v1.lst /tmp/r0.lst || true; printf '[entradas v1=%s R0=%s]\n\n' "$(wc -l < /tmp/v1.lst)" "$(wc -l < /tmp/r0.lst)"; } >> "$EV/R-rebuild.txt"
{ printf '$ diff control v1 / R0\n'; diff <(dpkg-deb -I /pkg/oasis.deb) <(dpkg-deb -I "$R0") || true; printf '\n'; } >> "$EV/R-rebuild.txt"
{ printf '$ diff postinst v1 / R0\n'; diff <(dpkg-deb --ctrl-tarfile /pkg/oasis.deb | tar -xO ./postinst) <(dpkg-deb --ctrl-tarfile "$R0" | tar -xO ./postinst) && echo identicos; printf '\n'; } >> "$EV/R-rebuild.txt"
R0_DIFF=$(diff /tmp/v1.lst /tmp/r0.lst | grep -c '^[<>]' || true)
log "R0 entradas_distintas=$R0_DIFF"
rm -rf /tmp/oasis-deb-build

log "== 4. build con packaging/build-deb2.sh"
cp /kit/packaging/build-deb2.sh /work/src/scripts/build-deb2.sh
run bash /work/src/scripts/build-deb2.sh
V2=$(ls /tmp/oasis-deb-build/oasis_*_amd64.deb)
run ls -l "$V2"
run dpkg-deb -I "$V2"
run sh -c "ar t '$V2'"
run sh -c "dpkg-deb --ctrl-tarfile '$V2' | tar -tv"
run sh -c "dpkg-deb --fsys-tarfile '$V2' | tar -xO ./opt/oasis/oasis-run"
run sh -c "dpkg-deb --fsys-tarfile '$V2' | tar -xO ./usr/bin/oasis ./lib/systemd/system/oasis.service"
cp "$V2" /out/
(cd /out && sha256sum "$(basename "$V2")") | tee -a "$EV/R-rebuild.txt"
log "== listo: /out/$(basename "$V2")"
