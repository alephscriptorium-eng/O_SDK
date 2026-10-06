#!/usr/bin/env bash
# T4 · el lanzador /usr/bin/oasis desde fuera de /opt/oasis.
source "$(dirname "$0")/../bin/lib.sh"; CASE=T4-lanzador
evx "$C_MAIN" 'cd / && oasis help | head -n 8'; obs help_from_root_exit "$?"
evx "$C_MAIN" 'cd /tmp && timeout 20 runuser -u oasis -- env HOME=/var/lib/oasis oasis --no-open --host=127.0.0.1 --port=3999; echo "exit=$?"'
obs launch_from_tmp "$(docker exec "$C_MAIN" sh -c 'cd /tmp && timeout 20 runuser -u oasis -- env HOME=/var/lib/oasis oasis --no-open --host=127.0.0.1 --port=3999 >/dev/null 2>&1; echo $?')"
oasis_stop "$C_MAIN"
