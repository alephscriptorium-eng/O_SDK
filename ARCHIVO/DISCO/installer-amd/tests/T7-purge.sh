#!/usr/bin/env bash
# T7 · remove y purge: qué queda y qué se conserva.
source "$(dirname "$0")/../bin/lib.sh"; CASE=T7-purge
evx "$C_MAIN" 'dpkg -r oasis; echo "exit=$?"'
evx "$C_MAIN" 'dpkg -s oasis | head -3; ls -la /opt/oasis 2>&1 | head; ls /opt/oasis/src/configs 2>&1'
evx "$C_MAIN" 'dpkg -P oasis; echo "exit=$?"'
evx "$C_MAIN" 'ls -ld /opt/oasis /var/lib/oasis 2>&1; ls -la /var/lib/oasis; id oasis 2>&1; stat -c "%u:%g %n" /var/lib/oasis/.ssb 2>&1'
obs after_purge_opt "$(docker exec "$C_MAIN" sh -c 'test -e /opt/oasis && echo present || echo absent')"
obs after_purge_varlib "$(docker exec "$C_MAIN" sh -c 'test -e /var/lib/oasis/.ssb && echo kept || echo gone')"
obs after_purge_user "$(docker exec "$C_MAIN" sh -c 'id -u oasis 2>/dev/null || echo deleted')"
c_rm "$C_MAIN"
