#!/usr/bin/env bash
# T3b · modo `server` (lo que un PUB debería ejecutar) con la config que trae el paquete.
source "$(dirname "$0")/../bin/lib.sh"; CASE=T3b-arranque-server
oasis_start "$C_MAIN" /tmp/oasis-server.log server --port=3000
if wait_http "$C_MAIN" http://127.0.0.1:3000/.well-known/oasis 120; then obs server_up yes; else obs server_up no; fi
evx "$C_MAIN" 'head -n 12 /tmp/oasis-server.log'
obs desktop_config_note "$(docker exec "$C_MAIN" sh -c 'grep -c "desktop config" /tmp/oasis-server.log')"
evx "$C_MAIN" 'ps -o pid,user,args -C node'
evx "$C_MAIN" 'grep -E "\"(pub|hops)\"" /opt/oasis/src/configs/server-config.json'
evx "$C_MAIN" 'curl -s -o /dev/null -w "GET / -> %{http_code}\n" -m 10 http://127.0.0.1:3000/; curl -s -o /dev/null -w "POST /publish -> %{http_code}\n" -m 10 -X POST http://127.0.0.1:3000/publish'
oasis_stop "$C_MAIN"
evx "$C_MAIN" 'sleep 2; ps -C node -o pid,args; echo "nodos vivos: $(pgrep -c node)"'
