#!/usr/bin/env bash
# T6 · reinstalar sobre una instalación ya arrancada: conffiles y .oasisrc.
source "$(dirname "$0")/../bin/lib.sh"; CASE=T6-reinstalacion
evx "$C_MAIN" 'md5sum /opt/oasis/src/configs/oasis-config.json; dpkg-deb --fsys-tarfile /pkg/oasis.deb | tar -xO ./opt/oasis/src/configs/oasis-config.json | md5sum; dpkg-query -W -f="\${Conffiles}\n" oasis'
obs conffile_drift "$(docker exec "$C_MAIN" sh -c 'a=$(md5sum < /opt/oasis/src/configs/oasis-config.json | cut -c1-32); b=$(dpkg-deb --fsys-tarfile /pkg/oasis.deb | tar -xO ./opt/oasis/src/configs/oasis-config.json | md5sum | cut -c1-32); [ "$a" = "$b" ] && echo no || echo yes')"
evx "$C_MAIN" 'dpkg -i /pkg/oasis.deb </dev/null; echo "exit=$?"'
evx "$C_MAIN" 'grep -c . /var/lib/oasis/.oasisrc; ls -la /opt/oasis/src/configs/'
evx "$C_MAIN" 'dpkg -V oasis; echo "dpkg -V rc=$?"'
