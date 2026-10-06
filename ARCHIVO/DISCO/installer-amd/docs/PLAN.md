# Plan · WP-O126 — `installer-amd`: kit FOSS para testear y mejorar el `.deb` de Oasis 1.2.2 (rama `test/installer-amd`)

## Contexto

Un amigo del custodio construye un `.deb` de Oasis con Node embebido y pide testers e informe. El
custodio quiere aliviarle trabajo: devolverle el script corregido y un `.deb` v2 ya probado. Ciclo:
(a) commit inicial, (b) cambios propuestos, (c) regenerar el `.deb`, (d) instalar y testear, (e) subir
y enviarle mejoras + reporte. Todo vive en **`ARCHIVO/DISCO/installer-amd/`** (carpeta ya creada,
vacía), con **estructura de repo autónomo** que más adelante saldrá de o-sdk: nada dentro referencia
rutas de o-sdk; lo que es contabilidad del WP (BACKLOG, `plan/REPORTES`, CHANGELOG de o-sdk) queda fuera.

**Viable sin pedirle nada al amigo.** `build-deb2.sh` copia de `$SRC_DIR` justo lo que el `.deb` lleva
en `/opt/oasis` (`src/*`, `scripts/`, `docs/PUB/`, `oasis.sh`, `LICENSE`, `README.md`). Extrayendo el
payload del v1 tenemos un `SRC_DIR` fiel a su árbol, que es **más nuevo que nuestro `src/` 1.2.2** (su
`oasis.sh` arranca `server` con `backend.js --public` y tiene modo `test`). Solo `test/` no viaja, y su
script tampoco lo copia.

Entradas en `ARCHIVO/DISCO/` (sin trackear): `oasis_1.2.2_amd64.deb` (111 MB, sha256 `3619386d…89cdf`,
**no ignorado por git**), `build-deb2.txt`, `oasis.sh` (idéntico al del `.deb`), `oasisrc` (lo que
genera el postinst), `plan.md`. Docker Desktop **parado** (paso 0). WP libre: **WP-O126**. Rama pedida:
`test/installer-amd` (la convención es `wp/O<n>-…`; se respeta lo pedido).

**Licencia del kit: AGPL-3.0.** El `LICENSE` de o-sdk (AIPL, broma) no vale para un artefacto FOSS; el
script parcheado deriva de Oasis, AGPL-3.0 según `usr/share/doc/oasis/copyright` del `.deb`. Decisión
reversible: si el custodio prefiere otra para el banco de pruebas, se cambia solo `LICENSE`.

### Hallazgos sobre el v1 (leídos del `.deb` en memoria; cada uno se sella en caliente)

| # | Hallazgo | Sev. | v2 |
|---|---|---|---|
| F1 | **Nadie lee `/var/lib/oasis/.oasisrc`**: el servicio ejecuta `oasis.sh` sin args ni `EnvironmentFile`; `oasis.sh`/`backend.js` lo ignoran. Config muerta; además lleva `if/then`, ilegible por `EnvironmentFile=`. | alta | sí |
| F2 | `*.tar.zst`: no instalable en Debian 11 / Ubuntu ≤ 21.04. | alta | `-Zxz` |
| F3 | `oasis.sh` usa `$(pwd)`; `/usr/bin/oasis` no hace `cd` → falla fuera de `/opt/oasis`. | alta | lanzador |
| F4 | Servicio arranca gui en `localhost` con `open=true` (xdg-open como usuario nologin). | alta | vía F1 |
| F13 | Asistente PUB=yes **no** pone `pub:true` en `server-config.json` (viaja `docs/PUB/server-config.json.example`, nadie lo copia). El `ssb_config.js` del amigo no tiene override por env. | alta | postinst 1ª instalación |
| F5 | `oasis.sh` hace `sed -i` sobre el conffile `oasis-config.json` en cada arranque; la app escribe `src/server/.update_required` → deriva de conffile. | media | se documenta (cambio de app) |
| F6 | `postinst` lee stdin con `[ -t 0 ]`, no debconf; bajo `apt`/unattended se salta. | media | env `OASIS_PUB`/`OASIS_DOMAIN` como vía no interactiva |
| F7 | `Depends: jq` solo; faltan `libc6 (>= 2.28)`, `libstdc++6`, `libgcc-s1`, `xdg-utils` (Recommends); sin `md5sums`. | media | sí |
| F8 | `oasis.sh test` → `test/run.sh` no viaja; README → `docs/install/install.md` no viaja. | baja | se reporta |
| F9 | `chown -R oasis /opt/oasis` (33 773 ficheros): el servicio puede modificar su código; purge deja `/var/lib/oasis` con uid huérfano (consciente). | baja | root salvo `src/configs`, `src/server` |
| F10 | `node/include` (60 MB), npm, corepack prescindibles; `Version` sin revisión Debian. | baja | poda + `1.2.2-1` |
| F11 | `snh-invite-code.json` viaja como conffile con un código de invitación (no se imprime). | nota | no |
| F12 | El `.deb` **no toca ECOin** (`wallet.*` vacíos); el motor RBU del pub se enciende solo con `pub:true` y RPC vivo (`backend.js:13571`). | diseño | solo propuesta escrita |

## Estructura del artefacto (`ARCHIVO/DISCO/installer-amd/`)

```
installer-amd/
  README.md            qué es, quickstart (3 comandos), mapa de carpetas, licencia  [ES, resumen EN]
  LICENSE              AGPL-3.0
  CHANGELOG.md         0.1.0: v1 recibido, kit, propuesta, v2
  CONTRIBUTING.md      cómo correr el banco, cómo añadir un caso, regla «comando + salida», sin secretos
  SHA256SUMS           huellas de los .deb probados/construidos (v1 recibido, v2 construido)
  .gitignore           dist/*.deb, build/, *.log
  dist/                los .deb (ignorados): aquí se mueve oasis_1.2.2_amd64.deb; aquí cae el v2
  upstream/            v1 tal cual llegó: build-deb2.sh, oasis.sh, oasisrc, README-upstream.md (origen, fecha, sha)
  packaging/           la propuesta: build-deb2.sh (parcheado), build-deb2.diff (upstream → propuesta),
                       oasis-run (wrapper), oasisrc.example, README.md (qué cambia y por qué, F→cambio)
  docker/              Dockerfile.build (debian:12 + dpkg-dev wget xz-utils ca-certificates),
                       Dockerfile.plain (debian:12-slim + jq ca-certificates curl procps),
                       Dockerfile.systemd (debian:12 + systemd; CMD /sbin/init)
  bin/                 rebuild.sh  (payload v1 → SRC_DIR → script → dist/)
                       run-tests.sh <deb> <etiqueta>  (itera tests/, escribe reports/evidence/<etiqueta>/)
                       lib.sh (docker helpers, MSYS_NO_PATHCONV, filtro anti-secretos)
  tests/               un fichero por caso: T0-integridad.sh … T9-portabilidad.sh, R0-reproducible.sh
                       (cada uno imprime el comando literal y su salida; sale ≠0 si falla lo esperado)
  docs/                PROTOCOLO.md (casos, esperado, cómo se sella), PLAN.md (este plan, desde DISCO/plan.md),
                       ECOIN.md (diseño: cómo encajaría ECOin en el instalador, qué no debe viajar)
  reports/             REPORTE-2026-10-06.md (para el amigo) + evidence/v1/ y evidence/v2/ (T*.txt)
```
Reutilizar: `ecoin/Dockerfile` (bookworm-slim, `sha256sum -c` con `tr -d '\r'`), chequeo de nativos del
`Dockerfile` raíz l.58-60, estilo de `plan/REPORTES/WP-O119-medida-db2.md`, `MSYS_NO_PATHCONV=1`.

## Pasos

### 0. Preparar
1. Arrancar Docker Desktop; esperar `docker version` (≤ 3 min). Si no responde: parada dura.
2. `git switch -c test/installer-amd` (desde `23029b66`). `.gitignore` raíz += `ARCHIVO/DISCO/*.deb` (por si queda alguno fuera de `dist/`); `.dockerignore` += `ARCHIVO/DISCO/`.

### (a) Commit inicial — esqueleto + v1
- Crear la estructura; mover `build-deb2.txt`→`upstream/build-deb2.sh`, `oasis.sh`, `oasisrc`→`upstream/`, `plan.md`→`docs/PLAN.md`, el `.deb`→`dist/`. `SHA256SUMS` con el v1.
- `README`, `LICENSE`, `CONTRIBUTING`, `.gitignore`, `docs/PROTOCOLO.md`.
- Commit `chore(installer-amd): esqueleto del kit y entrada del v1 tal cual` + fila WP-O126 🔶 en `plan/BACKLOG.md`.

### (d1) Banco de pruebas y test del v1
`bin/run-tests.sh dist/oasis_1.2.2_amd64.deb v1`: construye `plain`/`systemd` (contexto `docker/`), monta el `.deb` en `/pkg:ro`, corre `tests/T*.sh` vía `docker exec`, guarda `reports/evidence/v1/T<n>-<slug>.txt`. Contenedores `--rm`, sin volúmenes, app siempre `--network none`, nunca `cat` del `secret` (solo `ls -l`/`stat`).

| Caso | Dónde | Clave | Sella |
|---|---|---|---|
| T0 integridad | plain | `sha256sum`, `dpkg-deb --info/--contents`, `ar t` | F2 |
| T1 instalación no interactiva | plain | `dpkg -i </dev/null`; `dpkg -s`; `id oasis`; symlink; `.oasisrc`; `dpkg -V` | F7 |
| T2 nativos/glibc | plain | `node -v`, `ldd --version`, `node -e require(ssb-db2, sodium-native, leveldown, sharp…)` | — |
| T3 arranque gui manual | plain | `runuser -u oasis … sh oasis.sh --host=0.0.0.0 --no-open`; `curl /.well-known/oasis`=oasis ≤ 90 s; `.ssb/` creado | — |
| T3b arranque `server` | plain | `sh oasis.sh server --port=3000`; nota «desktop config (pub:false)» | F13 |
| T4 lanzador | plain | `cd / && oasis help`; `cd /tmp && oasis` (timeout 20 s) | F3 |
| T5 asistente | plain limpio | `printf 'y\npub.test\n' \| script -qc 'dpkg -i …' /dev/null`; `.oasisrc`; `server-config.json`; `grep -r oasisrc /opt /lib/systemd` | F1 F13 |
| T6 reinstalación | plain tras T3 | md5 conffile vs paquete; `dpkg -i` de nuevo | F5 |
| T7 remove/purge | plain | `dpkg -r`, `dpkg -P`; `/var/lib/oasis` conservado | F9 |
| T8 systemd | systemd `--privileged --cgroupns=host --network none` | `systemctl enable --now oasis`; `status`; `journalctl -n 60`; `ss -ltnp`; PUB=no y PUB=yes | F1 F4 |
| T9 portabilidad | debian:11-slim, ubuntu:22.04, ubuntu:24.04 | `dpkg -i` | F2 |

Si T8 no corre en Docker Desktop: parada dura en ese caso, `⏳ sin verificar`, no se improvisa.
Commit `test(installer-amd): banco de pruebas y evidencia del v1`.

### (b) Propuesta (`packaging/`)
1. `dpkg-deb -Zxz --build` (F2).
2. `.oasisrc` solo `KEY="VALUE"` (`OASIS_PUB`, `OASIS_DOMAIN`, `OASIS_HOST`, `OASIS_PORT`, `OASIS_NO_OPEN`, `OASIS_DEBUG`). Wrapper `/opt/oasis/oasis-run` (lo escribe el script): `. /var/lib/oasis/.oasisrc` → modo + args → `cd /opt/oasis && exec /bin/sh oasis.sh $MODE $ARGS`. `ExecStart=/opt/oasis/oasis-run` (F1 F4). Solo flags que `oasis.sh` ya acepta.
3. `/usr/bin/oasis`: `cd /opt/oasis && exec /bin/sh oasis.sh "$@"` (F3). `oasis.sh` no se toca.
4. `postinst`: PUB=yes y `$2` vacío → copia `docs/PUB/server-config.json.example` sobre `src/configs/server-config.json`; respuestas por env si no hay tty (F13 F6).
5. `control`: `Depends: jq, libc6 (>= 2.28), libstdc++6, libgcc-s1`, `Recommends: xdg-utils`, `Version: 1.2.2-1`; `DEBIAN/md5sums` (F7 F10).
6. `/opt/oasis` root; `chown -R oasis` solo `src/configs` y `src/server` (F9).
7. Poda de `node/`: `include/`, `share/`, `lib/node_modules/{npm,corepack}`, `bin/{npm,npx,corepack}` (F10); si T2/T3 del v2 lo echan en falta, se revierte y se anota.
8. `packaging/build-deb2.diff` = `diff -u upstream/build-deb2.sh packaging/build-deb2.sh`; `packaging/README.md` mapea F→cambio.
Commit `feat(installer-amd): propuesta build-deb2 — .oasisrc vivo, xz, lanzador, deps, md5sums`.

### (c) Regenerar (`bin/rebuild.sh` en `Dockerfile.build`)
1. `dpkg-deb -x dist/v1.deb /work/payload`; `SRC_DIR=/work/src` = `payload/opt/oasis` sin `node/`; `PATH` con `payload/opt/oasis/node/bin` (el script hace `node -p`).
2. Node: descargar `node-v22.20.0-linux-x64.tar.xz` de nodejs.org y verificar con `SHASUMS256.txt` (única etapa con red).
3. **R0 reproducibilidad**: construir con `upstream/build-deb2.sh` sin cambios y comparar `dpkg-deb -c` (rutas/tamaños) con el v1. Si difiere más allá de timestamps: parada, el `SRC_DIR` no es fiel.
4. Construir con `packaging/build-deb2.sh` → `dist/oasis_1.2.2-1_amd64.deb`; añadir a `SHA256SUMS`.

### (d2) Test del v2
`bin/run-tests.sh dist/oasis_1.2.2-1_amd64.deb v2` → `reports/evidence/v2/`. Criterio: `ar t` sin `.zst`; T4 funciona desde `/tmp`; T5 PUB=yes deja `pub:true`; T8 PUB=yes arranca `server --allow-host=pub.test`, PUB=no arranca gui en `0.0.0.0:3000` sin xdg-open; T9 Debian 11 instala; `dpkg -V` limpio.
Commit `test(installer-amd): v2 construido y evidencia`.

### (e) Entrega
- `reports/REPORTE-2026-10-06.md`: entorno; tabla v1/v2 por caso con enlace a evidencia; F1…F13 con su cambio; cómo aplicar `packaging/build-deb2.diff` en su `scripts/build-deb2.sh`; pendientes (arm64, upgrade sobre `.ssb` existente, `test/`).
- `docs/ECOIN.md` (F12, diseño sin ensayo): el `.deb` no debe llevar `wallet.dat` ni credenciales (ley 4); `ecoin` como `.deb` aparte con servicio (`ecoin_0.0.4-1_amd64.deb` upstream, sha256 conocido); el postinst de Oasis o un `oasis ecoin-init` genera en destino `rpcuser`/`rpcpassword` (`openssl rand -hex`), los escribe a 600 en `ecoin.conf` y en `wallet.*`; **no** abre la GUI ni enciende el motor del pub (publicar `wallet`/`pubAvailability` es irreversible); orden cartera → backup → publicar.
- `CHANGELOG.md` del kit (0.1.0); `plan/REPORTES/WP-O126-installer-deb.md` corto en o-sdk; CHANGELOG y BACKLOG de o-sdk.
- `git push -u origin test/installer-amd`. Sin merge a main. Opcional: publicar el reporte como Artifact privado para pasarle un enlace.

## Lo que NO se toca
`src/` (5 guards), host vivo, `volumes-dev/`, identidades reales. Ningún `secret`, invite ni credencial en evidencia ni reporte. ECOin no se ensaya en Docker en este WP.

## Verificación
- `git status` sin `.deb`; `git check-ignore -v` sobre `dist/*.deb`.
- `reports/evidence/v1` y `v2` completos (T0…T9, R0), comando + salida literal; `docker ps -a | grep oasis-deb` vacío.
- `sha256sum -c SHA256SUMS` en `installer-amd/` pasa; `dpkg-deb -I` del v2 muestra `Version: 1.2.2-1` y los `Depends` nuevos; `ar t` sin `.zst`.
- `grep -rn secret reports/evidence/` solo `ls`/`stat`.
- El kit se puede clonar solo: `bin/run-tests.sh dist/<deb> x` funciona sin nada de o-sdk.
