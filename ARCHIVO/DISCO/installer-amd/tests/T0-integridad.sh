#!/usr/bin/env bash
# T0 · integridad del paquete: huella, cabecera ar, control, scripts de mantenimiento, forma del payload.
source "$(dirname "$0")/../bin/lib.sh"; CASE=T0-integridad
c="oasis-deb-${LABEL}-t0"; c_plain "$c"
evx "$c" 'sha256sum /pkg/oasis.deb'
evx "$c" 'ar t /pkg/oasis.deb'
obs ar_members "$(docker exec "$c" ar t /pkg/oasis.deb | tr '\n' ' ')"
evx "$c" 'dpkg-deb --info /pkg/oasis.deb'
evx "$c" 'dpkg-deb --ctrl-tarfile /pkg/oasis.deb | tar -tv'
evx "$c" 'dpkg-deb --ctrl-tarfile /pkg/oasis.deb | tar -xO ./conffiles'
evx "$c" 'dpkg-deb --ctrl-tarfile /pkg/oasis.deb | tar -xO ./postinst'
evx "$c" 'dpkg-deb --ctrl-tarfile /pkg/oasis.deb | tar -xO ./prerm ./postrm'
evx "$c" 'dpkg-deb --contents /pkg/oasis.deb | wc -l'
obs entries "$(docker exec "$c" sh -c 'dpkg-deb --contents /pkg/oasis.deb | wc -l')"
evx "$c" 'dpkg-deb --contents /pkg/oasis.deb | awk "{print \$6}" | grep -v node_modules | cut -d/ -f1-4 | sort -u'
evx "$c" 'dpkg-deb --contents /pkg/oasis.deb | grep -E " -> "'
evx "$c" 'dpkg-deb --contents /pkg/oasis.deb | grep -E "/(lib/systemd|usr/bin|usr/share)" | grep -v "/$"'
evx "$c" 'dpkg-deb --fsys-tarfile /pkg/oasis.deb | tar -xO ./lib/systemd/system/oasis.service'
evx "$c" 'dpkg-deb --fsys-tarfile /pkg/oasis.deb | tar -xO ./usr/bin/oasis'
evx "$c" 'dpkg-deb --fsys-tarfile /pkg/oasis.deb | tar -xO ./opt/oasis/src/configs/server-config.json | grep -E "\"(pub|local|hops)\""'
note 'snh-invite-code.json es conffile y lleva un código de invitación: se lista, no se imprime'
evx "$c" 'dpkg-deb --contents /pkg/oasis.deb | grep snh-invite-code'
c_rm "$c"
