#!/usr/bin/env bash
# T8 · el camino real: systemd. (a) cliente (PUB=no); (b) PUB=yes por entorno y .oasisrc.
source "$(dirname "$0")/../bin/lib.sh"; CASE=T8-systemd
run_variant() {
  local c="$1" envs="$2" tag="$3"
  c_systemd "$c" || { obs "${tag}_container" failed; return 1; }
  if ! wait_systemd "$c" 60; then obs "${tag}_systemd_boot" failed; evx "$c" 'systemctl is-system-running; journalctl --no-pager -n 20'; return 1; fi
  evx "$c" 'systemctl is-system-running; systemctl --version | head -1'
  evx "$c" "$envs dpkg -i /pkg/oasis.deb </dev/null | tail -n 12"
  if [ "$tag" = pub ]; then
    note 'además se fuerza PUB=yes/DOMAIN=pub.test en .oasisrc, por si el postinst no lo hizo'
    evx "$c" 'sed -i -e "s/^OASIS_PUB=.*/OASIS_PUB=\"yes\"/" -e "s/^OASIS_DOMAIN=.*/OASIS_DOMAIN=\"pub.test\"/" /var/lib/oasis/.oasisrc; grep -E "^OASIS_(PUB|DOMAIN|HOST|PORT)=" /var/lib/oasis/.oasisrc'
  fi
  evx "$c" 'systemctl enable --now oasis; echo "exit=$?"'
  sleep 45
  evx "$c" 'systemctl status --no-pager -l oasis'
  obs "${tag}_active" "$(docker exec "$c" systemctl is-active oasis)"
  evx "$c" 'journalctl -u oasis --no-pager -n 60'
  evx "$c" 'ps -o pid,user,args -C node'
  obs "${tag}_node_args" "$(docker exec "$c" sh -c 'ps -o args= -C node | grep backend | head -1')"
  evx "$c" 'ss -ltnp'
  obs "${tag}_listen" "$(docker exec "$c" sh -c 'ss -ltn | awk "NR>1{print \$4}" | tr "\n" " "')"
  evx "$c" 'curl -s -m 5 http://127.0.0.1:3000/.well-known/oasis; echo " <- /.well-known/oasis"'
  evx "$c" 'grep -oE "\"pub\": *[a-z]+" /opt/oasis/src/configs/server-config.json; ls -la /var/lib/oasis/.ssb 2>&1 | head -5'
  evx "$c" 'journalctl --no-pager -n 30 | grep -iE "xdg|open|EACCES|error" | head'
  evx "$c" 'systemctl stop oasis; systemctl is-active oasis'
  c_rm "$c"
}
run_variant "oasis-deb-${LABEL}-t8a" "" client
run_variant "oasis-deb-${LABEL}-t8b" "OASIS_PUB=yes OASIS_DOMAIN=pub.test" pub
