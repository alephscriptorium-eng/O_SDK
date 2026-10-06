# Protocolo de prueba del instalador `.deb`

Cada caso es un script en `tests/` que **observa** y deja evidencia literal (comando + salida) en
`reports/evidence/<etiqueta>/<caso>.txt`, más una o varias líneas `clave=valor` en
`OBSERVACIONES.txt`. Lo **esperado** para cada versión del paquete está aquí, no en el script: así el
mismo banco sirve para el v1 del autor y para cualquier v2.

Reglas: la app corre siempre sin red (`--network none`) y con una identidad SSB desechable; ningún
test lee `secret`, `wallet.dat`, credenciales ni códigos de invitación; si algo no sale como se
esperaba, el caso lo anota y el banco sigue con el siguiente.

## Entornos

| Imagen | Para qué |
|---|---|
| `oasis-deb-plain` (Debian 12 slim + jq curl procps iproute2 binutils) | instalar con `dpkg -i`, arrancar a mano como el usuario de servicio, purgar |
| `oasis-deb-systemd` (Debian 12 + systemd, `--privileged --cgroupns=host`) | el camino real: `systemctl enable --now oasis` |
| `debian:11-slim`, `ubuntu:22.04`, `ubuntu:24.04` | portabilidad, con `apt` (única parte con red) |
| `oasis-deb-build` (Debian 12 + dpkg-dev) | `bin/rebuild.sh`: regenerar el paquete |

## Casos

| Caso | Qué mide | Observaciones clave | Esperado v1 | Esperado v2 (propuesta) | Sella |
|---|---|---|---|---|---|
| T0 integridad | sha256, miembros `ar`, `control`, conffiles, scripts de mantenimiento, forma del payload | `ar_members`, `entries` | `control.tar.zst data.tar.zst` | `control.tar.xz data.tar.xz` | F2 |
| T1 instalación | `dpkg -i` sin tty ni red en Debian 12; usuario, symlink, `.oasisrc`, `dpkg -V`, quién lee `.oasisrc` | `dpkg_i_exit`, `oasisrc_pub`, `md5sums_present`, `oasisrc_readers` | instala; `PUB="no"`; nadie lee `.oasisrc` | instala; `/opt/oasis/oasis-run` lo lee | F1 F7 F9 |
| T2 nativos | Node embebido y módulos nativos (`sodium-native`, `leveldown`, `sharp`…) con la glibc del sistema | `native_require_exit` | 0 | 0 (tras la poda de `node/`) | F7 F10 |
| T3 arranque gui | `oasis.sh --host=0.0.0.0 --no-open` como `oasis`; `/.well-known/oasis`; `~/.ssb` creado; deriva del conffile | `gui_up`, `ssb_dir` | arriba; `secret` 600; `oasis-config.json` reescrito por `sed -i` | igual (cambio de app, no de paquete) | F5 |
| T3b arranque server | `oasis.sh server` con la config que trae el paquete | `server_up`, `desktop_config_note` | arriba, con la nota «desktop config (pub: false)» | igual: solo cambia si el asistente dijo PUB=yes (T5/T8) | F13 |
| T4 lanzador | `/usr/bin/oasis` desde `/` y desde `/tmp` | `help_from_root_exit`, `launch_from_tmp` | `help` funciona; arrancar desde `/tmp` falla (`cd src/backend`) | ambos funcionan | F3 |
| T5 asistente | (a) tty simulado, respuestas `y`, `pub.test`; (b) sin tty con `OASIS_PUB=yes OASIS_DOMAIN=pub.test` | `tty_oasisrc`, `tty_server_config_pub`, `env_oasisrc`, `env_server_config_pub` | (a) `.oasisrc` PUB=yes pero `pub: false`; (b) entorno ignorado | (a) y (b): PUB=yes y `pub: true` | F1 F6 F13 |
| T6 reinstalación | md5 del conffile tras T3 vs paquete; `dpkg -i` encima; `.oasisrc` preservado | `conffile_drift` | deriva `yes`; dpkg conserva el local | igual (cambio de app) | F5 |
| T7 purge | `dpkg -r`, `dpkg -P`: qué queda | `after_purge_opt`, `after_purge_varlib`, `after_purge_user` | `/opt/oasis` fuera, `/var/lib/oasis/.ssb` conservado, usuario borrado | igual | F9 |
| T8 systemd | (a) cliente; (b) PUB=yes por entorno **y** forzado en `.oasisrc`. Estado, journal, args de `node`, puertos | `client_active`, `client_node_args`, `client_listen`, `pub_*` | (a) gui en `localhost:3000`, intenta abrir navegador; (b) idéntico a (a): `.oasisrc` no cuenta | (a) gui en `127.0.0.1:3000` sin `xdg-open`; (b) `server --allow-host=pub.test` en `0.0.0.0:3000` | F1 F4 F13 |
| T9 portabilidad | `apt-get install ./oasis.deb` en Debian 11, Ubuntu 22.04 y 24.04 | `debian_11-slim`, `ubuntu_22_04`, `ubuntu_24_04` | Debian 11: «unknown compression»; Ubuntu: instala | los tres instalan | F2 |
| R0 reproducible (`bin/rebuild.sh`) | construir con el script upstream sin cambios a partir del payload del v1 y comparar contenidos | `R0 entradas_distintas` | — | 0 (salvo el propio `scripts/build-deb2.sh`) | fidelidad del rebuild |

## Cómo se sella un hallazgo

Un hallazgo pasa de «leído en el script» a «observado» cuando el informe cita el fichero de evidencia
y la observación. Si un caso no pudo ejecutarse (por ejemplo, el contenedor systemd no arranca en un
Docker concreto), el informe lo marca `⏳ sin verificar` y el hallazgo queda como estático.
