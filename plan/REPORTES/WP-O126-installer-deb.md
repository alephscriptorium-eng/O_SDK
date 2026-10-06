# WP-O126 · Test del instalador `.deb` de Oasis 1.2.2 (amd64) y propuesta de arreglo

2026-10-06 · rama `test/installer-amd` · sin merge a `main` (lo decide el custodio).
**Estado: kit entregado y probado. v1 del autor medido en Docker (11 casos); v2 regenerado con la
propuesta y medido con los mismos casos. Informe para el autor en
`ARCHIVO/DISCO/installer-amd/reports/REPORTE-2026-10-06.md`.**

## 1. Por qué

Un amigo del custodio construye un `.deb` de Oasis con Node 22 embebido (`build-deb2.sh`) y pide
testers y un informe. El custodio quiso ir más allá del informe: devolverle el script corregido y un
paquete regenerado y probado, y dejar el banco como artefacto FOSS que saldrá a repo propio.

## 2. Qué se entregó

Todo en `ARCHIVO/DISCO/installer-amd/` (AGPL-3.0, autónomo: nada referencia rutas de o-sdk).

| Commit | Pieza |
|---|---|
| `0d833068` | Esqueleto del kit; `upstream/` con lo recibido tal cual; `docs/PROTOCOLO.md`, `docs/PLAN.md`, `docs/ECOIN.md`; ignores de los `.deb` en la raíz y en el kit |
| `0f794987` | `bin/run-tests.sh` + `tests/T0…T9`; evidencia del v1 en `reports/evidence/v1/` |
| `d0068dd4` | `packaging/build-deb2.sh` (propuesta), `build-deb2.diff`, `oasis-run`, `oasisrc.example`, `packaging/README.md` |
| `97b812d4` | `bin/rebuild.sh` + `docker/rebuild-inner.sh`; R0 (reproducibilidad) y v2 construido; `SHA256SUMS` |
| (cierre) | evidencia del v2, `reports/REPORTE-2026-10-06.md`, CHANGELOG |

Los `.deb` no entran en git: `dist/` ignorado, huellas en `SHA256SUMS`.

## 3. Criterios de aceptación

- **CA1 · el banco corre solo y sin red para la app.** `bin/run-tests.sh dist/<deb> <etiqueta>`
  construye las imágenes, corre los once casos con `--network none` (salvo T9, que necesita `apt`)
  y deja comando + salida por caso. Evidencia: `reports/evidence/v1/RESUMEN.txt` (11 `ok`),
  `reports/evidence/v2/RESUMEN.txt`.
- **CA2 · los hallazgos del v1 están sellados en caliente, no solo leídos.** Ver
  `reports/evidence/v1/OBSERVACIONES.txt`: `oasisrc_readers=` (vacío), `client_node_args=node backend.js`
  y `pub_node_args=node backend.js` (el servicio ignora `.oasisrc` también con PUB=yes),
  `launch_from_tmp=1`, `tty_server_config_pub="pub": false`, `conffile_drift=yes`,
  `debian_11-slim=dpkg-deb: error: … unknown compression for member 'control.tar.zst'`.
- **CA3 · el rebuild es fiel.** `reports/evidence/rebuild/R-rebuild.txt`: R0 con el script upstream
  sin cambios da 33 773 entradas, `entradas_distintas=0` en modo/tamaño/ruta y `postinst` idéntico.
  Node 22.20.0 verificado contra `SHASUMS256.txt` de nodejs.org.
- **CA4 · el v2 corrige lo que la propuesta dice corregir.** `reports/evidence/v2/OBSERVACIONES.txt`:
  `ar_members=… control.tar.xz data.tar.xz`, `oasisrc_readers=/opt/oasis/oasis-run`,
  `launch_from_tmp=124` (arranca hasta que el `timeout` lo mata), `tty_server_config_pub="pub": true`,
  `env_server_config_pub="pub": true`, `client_node_args=node backend.js --host=127.0.0.1 --port=3000 --no-open`,
  `client_listen=127.0.0.1:3000 *:8008`. El modo PUB bajo systemd: ver §4.
- **CA5 · ningún secreto en la evidencia.** El banco falla si encuentra claves privadas; la
  identidad de cada contenedor es desechable y sale solo su clave pública en los logs de arranque.

## 4. Hallazgos

- **Del instalador v1**: trece, de F1 a F13, con severidad y evidencia en el informe del autor.
  Los tres que más pesan: nadie lee `.oasisrc` (F1), zstd no instala en Debian 11 (F2), y con
  PUB=yes el sbot sigue en forma de escritorio (F13).
- **De la propia propuesta, encontrado al probar el v2**: en modo pub, `oasis.sh server` ya pasa
  `--host=0.0.0.0`; mi primer runner lo repetía y el backend recibía un array (`ERR_INVALID_ARG_TYPE`
  en `koa.listen`, servicio en `activating (auto-restart)`). Corregido antes del v2 definitivo: en
  modo server el runner solo añade `--port` y `--allow-host`. La tanda que lo destapó queda fuera de
  git (`reports/evidence/_descartado/`, ignorado) y constada aquí.
- **Del banco**: dos tandas descartadas por fallos del arnés (un `pkill` que se mataba a sí mismo;
  T9 sin `jq` antes de llegar a `dpkg`). Ninguno afectaba al paquete; se repitieron limpias.
- **Debian 11 con el v2**: `dpkg -i` desempaqueta (`install ok unpacked`, nativos cargan), pero
  `apt-get install -f` no encuentra `jq`: bullseye salió de soporte LTS el 2026-08-31 y el mirror
  devuelve 404. No es del paquete.

## 5. Lo que no se hizo

- ECOin solo como diseño (`docs/ECOIN.md` del kit): ni instalar `ecoind` en el banco ni cablear
  `wallet.*`. Es el siguiente paso natural si el autor quiere que el instalador lo contemple.
- arm64, upgrade sobre una `.ssb` existente y `oasis.sh test` (el paquete no lleva `test/`).
- Merge a `main` y extracción del kit a su propio repo: del custodio.
