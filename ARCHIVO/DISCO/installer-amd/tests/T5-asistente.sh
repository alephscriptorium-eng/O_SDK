#!/usr/bin/env bash
# T5 · el asistente del postinst: (a) interactivo con tty respondiendo PUB=yes; (b) no interactivo por entorno.
source "$(dirname "$0")/../bin/lib.sh"; CASE=T5-asistente
a="oasis-deb-${LABEL}-t5a"; c_plain "$a"
note '(a) tty simulado con script(1); respuestas: y, pub.test'
evx "$a" 'printf "y\npub.test\n" | script -qec "dpkg -i /pkg/oasis.deb" /dev/null | tail -n 25'
evx "$a" 'cat /var/lib/oasis/.oasisrc'
obs tty_oasisrc "$(docker exec "$a" sh -c 'grep -E "^OASIS_(PUB|DOMAIN)=" /var/lib/oasis/.oasisrc | tr "\n" " "')"
evx "$a" 'grep -E "\"(pub|hops)\"" /opt/oasis/src/configs/server-config.json'
obs tty_server_config_pub "$(docker exec "$a" sh -c 'grep -oE "\"pub\": *[a-z]+" /opt/oasis/src/configs/server-config.json')"
c_rm "$a"
b="oasis-deb-${LABEL}-t5b"; c_plain "$b"
note '(b) sin tty, con OASIS_PUB=yes OASIS_DOMAIN=pub.test en el entorno'
evx "$b" 'OASIS_PUB=yes OASIS_DOMAIN=pub.test dpkg -i /pkg/oasis.deb </dev/null | tail -n 12'
evx "$b" 'grep -E "^OASIS_(PUB|DOMAIN)=" /var/lib/oasis/.oasisrc; grep -oE "\"pub\": *[a-z]+" /opt/oasis/src/configs/server-config.json'
obs env_oasisrc "$(docker exec "$b" sh -c 'grep -E "^OASIS_(PUB|DOMAIN)=" /var/lib/oasis/.oasisrc | tr "\n" " "')"
obs env_server_config_pub "$(docker exec "$b" sh -c 'grep -oE "\"pub\": *[a-z]+" /opt/oasis/src/configs/server-config.json')"
c_rm "$b"
