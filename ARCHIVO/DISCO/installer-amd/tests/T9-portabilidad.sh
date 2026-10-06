#!/usr/bin/env bash
# T9 · otras distribuciones. Primero `dpkg -i` a pelo (enseña si dpkg sabe leer el paquete), luego
# `apt-get install -f` para resolver jq — única parte del banco con red.
source "$(dirname "$0")/../bin/lib.sh"; CASE=T9-portabilidad
for img in debian:11-slim ubuntu:22.04 ubuntu:24.04; do
  note "imagen $img"
  docker pull -q "$img" >/dev/null 2>&1 || true
  out="$(docker run --rm -v "$DEB_HOST:/pkg/oasis.deb:ro" "$img" bash -c '
    export DEBIAN_FRONTEND=noninteractive
    . /etc/os-release; echo "$PRETTY_NAME"; dpkg --version | head -1; ldd --version | head -1
    echo "--- dpkg -i"
    dpkg -i /pkg/oasis.deb </dev/null 2>&1 | grep -vE "^(Selecting|Preparing|Unpacking|Setting up|Processing)" | tail -n 8
    echo "dpkg -i exit=${PIPESTATUS[0]}"
    echo "--- apt-get update && apt-get install -f (resuelve jq)"
    apt-get update 2>&1 | tail -n 2
    apt-get install -f -y 2>&1 | grep -vE "^(Selecting|Preparing|Unpacking|Setting up|Processing|Get:|Reading|Building|Fetched)" | tail -n 6
    echo "apt -f exit=${PIPESTATUS[0]}"
    dpkg -s oasis 2>&1 | head -2
    if [ -x /opt/oasis/node/bin/node ]; then cd /opt/oasis/src/server && /opt/oasis/node/bin/node -e "require(\"sodium-native\");require(\"leveldown\");require(\"sharp\");console.log(\"native ok\")" 2>&1 | tail -1; fi
  ' 2>&1)"
  printf '$ docker run --rm %s bash -c "dpkg -i /pkg/oasis.deb; apt-get install -f ..."\n%s\n[fin]\n\n' "$img" "$out" >> "$EV_DIR/$CASE.txt"
  st="$(printf '%s\n' "$out" | grep -E "^Status: install|unknown compression|dpkg-deb: error|package 'oasis' is not installed" | head -1)"
  obs "$(echo "$img" | tr ':.' '__')" "${st:-sin estado}"
done
