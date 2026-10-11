#!/usr/bin/env bash
# lib-retro.sh — ayudantes de la secretaría (bot retro, modo server) compartidos por drill-26s.sh y secretaria.sh.
# Se hace `source`; el que lo carga define ROOT (raíz del repo). Ninguna función imprime invites, semillas ni claves
# enteras: las direcciones se enmascaran al mostrarse. Reglas de HUB §3 (bootstrap por el socket, conn.json sin seed).
RETRO_PROBE="${ROOT:?ROOT sin definir}/pub/tools/ssb-probe.js"
export MSYS_NO_PATHCONV=1

# retro_exec <ctr> <cmd…>: docker exec como oasis con HOME (ssb_config resuelve ~/.ssb; como root hablaría como un desconocido)
retro_exec() { local c="$1"; shift; docker exec -u oasis -e HOME=/home/oasis "$c" sh -lc "cd /app/src/server && $*"; }
# retro_probe <ctr> <feed|''> <seq|peers|invite-accept> [invite]: ssb-probe.js por stdin (no viaja en la imagen)
retro_probe() { docker exec -i -u oasis -e HOME=/home/oasis -e SSB_FEED="$2" -e SSB_ACTION="$3" ${4:+-e SSB_INVITE="$4"} "$1" sh -lc 'cd /app/src/server && node -' < "$RETRO_PROBE" 2>/dev/null; }
retro_whoami() { retro_exec "$1" 'node /app/pub/tools/ssb-admin.js whoami' 2>/dev/null | grep -oE '@[A-Za-z0-9+/]+=\.ed25519' | head -1; }
retro_mask() { sed -E 's/(shs:[A-Za-z0-9+\/]{6})[A-Za-z0-9+\/=:]+/\1…/g; s/@[A-Za-z0-9+\/]{6}[A-Za-z0-9+\/=]*\.ed25519/@…/g; s/~[A-Za-z0-9+\/=]{8,}/~…/g'; }
# retro_conn_fix <ctr> 'net:<host>:<port>~shs:<KEY44>': deja esa entrada en conn.json sin seed (hub-conn-fix.js)
retro_conn_fix() {
  docker exec -i -u oasis -e HOME=/home/oasis "$1" sh -lc 'cat > /tmp/hub-conn-fix.js' < "$ROOT/pub/tools/hub-conn-fix.js"
  retro_exec "$1" "node /tmp/hub-conn-fix.js '$2'" 2>&1 | retro_mask | tail -4
}
# retro_join <ctr> <pub feed id> <invite> <addr net:…~shs:KEY44>: accept por socket → restart (un nodo server persiste
# conn.json al parar) → conn-fix → restart → espera `connected` con el pub. Devuelve 1 si no conecta en 30 s.
retro_join() {
  local ctr="$1" pk="$2" inv="$3" addr="$4"
  local acc; acc="$(retro_probe "$ctr" "$pk" invite-accept "$inv")"
  echo "accept: $(echo "$acc" | grep -o '"accept": *[a-z]*' | head -1 || echo '?')"
  docker restart "$ctr" >/dev/null; sleep 8; retro_conn_fix "$ctr" "$addr"; docker restart "$ctr" >/dev/null; sleep 10
  for i in 1 2 3 4 5 6; do
    local p; p="$(retro_probe "$ctr" "$pk" peers)"
    if echo "$p" | grep -q '"state": *"connected"'; then echo "connected al pub (seq $(echo "$p" | grep -o '"seq": *[0-9]*' | grep -o '[0-9]*$') del pub visto desde el bot) tras $((i*5)) s"; return 0; fi
    sleep 5
  done
  echo "NO conectado al pub en 30 s" >&2; return 1
}
# retro_about <ctr> <png> <desc.txt> <nombre>: avatar y descripción POR STDIN (nunca docker cp), un único publish-about
retro_about() {
  docker exec -i -u oasis "$1" sh -lc 'cat > /tmp/avatar.png' < "$2"; docker exec -i -u oasis "$1" sh -lc 'cat > /tmp/desc.txt' < "$3"
  retro_exec "$1" "node /app/pub/tools/ssb-admin.js publish-about \"$4\" \"\$(cat /tmp/desc.txt)\" --image /tmp/avatar.png" 2>&1 | grep -E '"image"|description|rror' | head -3
}
# retro_pub_seq <ctr> <pub feed id>: último sequence del pub que ESTE bot tiene (Δ0 del pub tras una siembra)
retro_pub_seq() { retro_probe "$1" "$2" seq | grep -o '"seq": *[0-9]*' | grep -o '[0-9]*$'; }
