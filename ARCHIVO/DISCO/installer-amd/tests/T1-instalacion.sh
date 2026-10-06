#!/usr/bin/env bash
# T1 · instalación no interactiva (stdin cerrado, como apt/unattended) en Debian 12 sin red.
# Deja el contenedor principal instalado para T2…T7.
source "$(dirname "$0")/../bin/lib.sh"; CASE=T1-instalacion
c_plain "$C_MAIN"
evx "$C_MAIN" 'dpkg --version | head -1; ldd --version | head -1'
evx "$C_MAIN" 's=$(date +%s); dpkg -i /pkg/oasis.deb </dev/null; rc=$?; echo "exit=$rc took=$(( $(date +%s)-s ))s"; exit $rc'; rc=$?
obs dpkg_i_exit "$rc"
evx "$C_MAIN" 'dpkg -s oasis | head -8'
evx "$C_MAIN" 'id oasis; getent passwd oasis'
evx "$C_MAIN" 'ls -la /var/lib/oasis; stat -c "%a %U:%G %n" /var/lib/oasis/.oasisrc'
evx "$C_MAIN" 'cat /var/lib/oasis/.oasisrc'
obs oasisrc_pub "$(docker exec "$C_MAIN" sh -c 'grep -E "^OASIS_PUB=" /var/lib/oasis/.oasisrc')"
evx "$C_MAIN" 'ls -l /opt/oasis/src/server/node_modules; ls -ld /opt/oasis /opt/oasis/src /opt/oasis/node; stat -c "%U:%G %n" /opt/oasis/oasis.sh /opt/oasis/node/bin/node'
evx "$C_MAIN" 'du -sh /opt/oasis /opt/oasis/node /opt/oasis/src/base'
evx "$C_MAIN" 'dpkg -V oasis; echo "dpkg -V rc=$?"'
evx "$C_MAIN" 'ls /var/lib/dpkg/info/ | grep ^oasis'
obs md5sums_present "$(docker exec "$C_MAIN" sh -c 'test -f /var/lib/dpkg/info/oasis.md5sums && echo yes || echo no')"
evx "$C_MAIN" 'cat /usr/bin/oasis; cat /lib/systemd/system/oasis.service'
evx "$C_MAIN" 'grep -rl oasisrc /opt/oasis/oasis.sh /opt/oasis/src/backend /opt/oasis/src/client /opt/oasis/src/server/*.js /lib/systemd/system/oasis.service /usr/bin/oasis /opt/oasis/oasis-run; echo "ficheros que mencionan oasisrc: rc=$?"'
obs oasisrc_readers "$(docker exec "$C_MAIN" sh -c 'grep -rl oasisrc /opt/oasis/oasis.sh /opt/oasis/src/backend /opt/oasis/src/client /opt/oasis/src/server/*.js /lib/systemd/system/oasis.service /usr/bin/oasis /opt/oasis/oasis-run 2>/dev/null | tr "\n" " "')"
