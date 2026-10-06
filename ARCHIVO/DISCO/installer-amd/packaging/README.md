# packaging/ · la propuesta

`build-deb2.sh` es el script del autor con los cambios mínimos para que el paquete haga lo que su
asistente promete. `build-deb2.diff` es ese cambio en formato parche, listo para aplicar sobre
`scripts/build-deb2.sh` de su repo:

```sh
cd <repo-de-oasis>
patch -p1 scripts/build-deb2.sh < build-deb2.diff     # o: git apply --directory=scripts
DEB_REVISION=1 bash scripts/build-deb2.sh
```

`oasis.sh` **no se toca**: todo lo que necesitaba el servicio se resuelve desde el paquete.

| Hallazgo | Cambio | Dónde |
|---|---|---|
| F1 `.oasisrc` no lo lee nadie; lleva lógica de shell | `.oasisrc` pasa a ser solo `KEY="VALUE"` (ver `oasisrc.example`). Nuevo `/opt/oasis/oasis-run` (ver `oasis-run`) lo lee, decide `gui`/`server` y pasa a `oasis.sh` solo flags que ya acepta: `--host --port --allow-host --no-open --debug`. | `SERVICE RUNNER`, `postinst` |
| F4 el servicio arrancaba gui en localhost con `open=true` | `ExecStart=/opt/oasis/oasis-run` en la unidad | `SYSTEMD SERVICE` |
| F2 zstd | `dpkg-deb -Zxz` | `BUILD` |
| F3 `oasis.sh` usa `$(pwd)` | `/usr/bin/oasis` hace `cd /opt/oasis` | `CLI LAUNCHER` |
| F13 PUB=yes dejaba `pub: false` | En la primera instalación con PUB=yes se copia `docs/PUB/server-config.json.example` (que el paquete ya lleva) sobre `src/configs/server-config.json` | `postinst` |
| F6 asistente solo con tty | Si hay `OASIS_PUB`/`OASIS_DOMAIN` en el entorno no pregunta; solo pregunta en la primera instalación (si existe `.oasisrc`, lo respeta y no molesta en upgrades) | `postinst` |
| F7 dependencias | `Depends: jq, libc6 (>= 2.28), libstdc++6, libgcc-s1`, `Recommends: xdg-utils`; `DEBIAN/md5sums` explícito | `control`, `md5sums` |
| F9 `chown -R oasis /opt/oasis` | `/opt/oasis` es de root; `oasis` solo escribe en `src/configs` (lo edita `oasis.sh`) y `src/server` (`.update_required`). `/var/lib/oasis` a 750 | `postinst` |
| F10 tamaño y versión | Se podan `node/include`, `node/share`, npm y corepack (la app no los usa en producción); `Version: 1.2.2-1` con `DEB_REVISION` | `NODE.JS EMBEBIDO`, `control` |
| seguridad | Un cliente escucha en `127.0.0.1` (la GUI no tiene autenticación); un PUB en `0.0.0.0` | `postinst` |

Lo que la propuesta **no** cambia porque es cosa de la aplicación, no del paquete: F5 (`oasis.sh`
edita `src/configs/oasis-config.json` en cada arranque, un conffile), F8 (`oasis.sh test` apunta a
`test/run.sh`, que el paquete no lleva), F11 (`snh-invite-code.json` viaja como conffile).
