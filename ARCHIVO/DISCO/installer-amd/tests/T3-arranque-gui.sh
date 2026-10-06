#!/usr/bin/env bash
# T3 · arranque a mano como el usuario de servicio, modo gui, sin red; identidad desechable.
source "$(dirname "$0")/../bin/lib.sh"; CASE=T3-arranque-gui
oasis_start "$C_MAIN" /tmp/oasis-gui.log --host=0.0.0.0 --no-open
note 'arrancado en background: runuser -u oasis -- env HOME=/var/lib/oasis PATH=/opt/oasis/node/bin:... sh -c "cd /opt/oasis && exec sh oasis.sh --host=0.0.0.0 --no-open"'
if wait_http "$C_MAIN" http://127.0.0.1:3000/.well-known/oasis 120; then obs gui_up yes; else obs gui_up no; fi
evx "$C_MAIN" 'curl -s -m 5 http://127.0.0.1:3000/.well-known/oasis; echo; curl -s -o /dev/null -w "GET / -> %{http_code}\n" -m 10 http://127.0.0.1:3000/'
evx "$C_MAIN" 'ss -ltnp'
evx "$C_MAIN" 'ps -o pid,user,args -C node'
evx "$C_MAIN" 'tail -n 40 /tmp/oasis-gui.log'
evx "$C_MAIN" 'ls -la /var/lib/oasis/.ssb; stat -c "%a %U:%G %s %n" /var/lib/oasis/.ssb/secret; ls /var/lib/oasis/.ssb/db2 2>/dev/null | head'
obs ssb_dir "$(docker exec "$C_MAIN" sh -c 'ls /var/lib/oasis/.ssb 2>/dev/null | tr "\n" " "')"
evx "$C_MAIN" 'ls -la /opt/oasis/src/server/.update_required /var/lib/oasis/.config 2>&1 | head'
evx "$C_MAIN" 'md5sum /opt/oasis/src/configs/oasis-config.json; grep -E "\"ai(Nav)?Mod\"" /opt/oasis/src/configs/oasis-config.json'
oasis_stop "$C_MAIN"
evx "$C_MAIN" 'sleep 2; ps -C node -o pid,args; tail -n 5 /tmp/oasis-gui.log'
