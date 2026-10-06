# Nota para el autor del `.deb` · 2026-10-06

Base: `https://github.com/alephscriptorium-eng/O_SDK/tree/test/installer-amd/ARCHIVO/DISCO/installer-amd`
(en adelante, **el kit**). Todo lo que se cita abajo es una ruta dentro de esa carpeta.

## 1. Lo que nos diste, dónde está y qué le hicimos

| Tuyo | En el kit | Qué le hicimos |
|---|---|---|
| `build-deb2.sh` | [`upstream/build-deb2.sh`](https://github.com/alephscriptorium-eng/O_SDK/blob/test/installer-amd/ARCHIVO/DISCO/installer-amd/upstream/build-deb2.sh) | Nada. Es tu copia, con su sha256 en [`upstream/README-upstream.md`](https://github.com/alephscriptorium-eng/O_SDK/blob/test/installer-amd/ARCHIVO/DISCO/installer-amd/upstream/README-upstream.md). |
| `oasis.sh` | [`upstream/oasis.sh`](https://github.com/alephscriptorium-eng/O_SDK/blob/test/installer-amd/ARCHIVO/DISCO/installer-amd/upstream/oasis.sh) | Nada. Comprobamos que es byte a byte el que viaja en el `.deb`. **No lo tocamos en ningún momento**: todo lo que proponemos se resuelve desde el paquete. |
| `.oasisrc` (el que escribe tu `postinst`) | [`upstream/oasisrc`](https://github.com/alephscriptorium-eng/O_SDK/blob/test/installer-amd/ARCHIVO/DISCO/installer-amd/upstream/oasisrc) | Nada. Sirvió para confirmar que nadie lo lee (abajo). |
| `oasis_1.2.2_amd64.deb` | fuera de git; huella en [`SHA256SUMS`](https://github.com/alephscriptorium-eng/O_SDK/blob/test/installer-amd/ARCHIVO/DISCO/installer-amd/SHA256SUMS) | Lo instalamos, lo arrancamos, lo purgamos, y lo **desmontamos para usar su `/opt/oasis` como árbol fuente**: es justo lo que tu script copia, así que pudimos regenerar el paquete sin pedirte el repo. Antes de cambiar nada reconstruimos con tu script tal cual y salió idéntico (33 773 entradas, cero diferencias): [`reports/evidence/rebuild/R-rebuild.txt`](https://github.com/alephscriptorium-eng/O_SDK/blob/test/installer-amd/ARCHIVO/DISCO/installer-amd/reports/evidence/rebuild/R-rebuild.txt). |

## 2. Lo que encontramos

Lo corto: instala y Oasis arranca bien, pero **el asistente escribe una configuración que nadie
lee**, así que el servicio arranca siempre como cliente en `localhost` aunque hayas dicho PUB; con
PUB=yes el sbot además sigue en `pub: false`; y el `.deb` va en zstd, que Debian 11 no abre.
Trece hallazgos, con severidad y el fichero de evidencia de cada uno, en
[`reports/REPORTE-2026-10-06.md`](https://github.com/alephscriptorium-eng/O_SDK/blob/test/installer-amd/ARCHIVO/DISCO/installer-amd/reports/REPORTE-2026-10-06.md) §3.

## 3. Lo que cambiamos y por qué

Solo `build-deb2.sh`. Nueve cambios, cada uno marcado `[Fn]` con el hallazgo que arregla:
[`packaging/build-deb2.sh`](https://github.com/alephscriptorium-eng/O_SDK/blob/test/installer-amd/ARCHIVO/DISCO/installer-amd/packaging/build-deb2.sh).
La tabla hallazgo → cambio está en
[`packaging/README.md`](https://github.com/alephscriptorium-eng/O_SDK/blob/test/installer-amd/ARCHIVO/DISCO/installer-amd/packaging/README.md),
y el parche para tu `scripts/build-deb2.sh` es
[`packaging/build-deb2.diff`](https://github.com/alephscriptorium-eng/O_SDK/blob/test/installer-amd/ARCHIVO/DISCO/installer-amd/packaging/build-deb2.diff):

```sh
patch scripts/build-deb2.sh < build-deb2.diff
DEB_REVISION=1 bash scripts/build-deb2.sh      # sale oasis_1.2.2-1_amd64.deb
```

La pieza nueva es [`packaging/oasis-run`](https://github.com/alephscriptorium-eng/O_SDK/blob/test/installer-amd/ARCHIVO/DISCO/installer-amd/packaging/oasis-run):
un `sh` de veinte líneas que lee el `.oasisrc` (ahora solo `KEY="VALUE"`, ver
[`packaging/oasisrc.example`](https://github.com/alephscriptorium-eng/O_SDK/blob/test/installer-amd/ARCHIVO/DISCO/installer-amd/packaging/oasisrc.example))
y lanza tu `oasis.sh` en `gui` o `server` con las flags que ya acepta. Es lo que ejecuta la unidad.

El paquete regenerado con esto, `oasis_1.2.2-1_amd64.deb`
(sha256 `e1e0496940bfb91db0d13c44c7c65c1efb9fb1b29d62c19f54d5a884f5043ac0`, 89 MB menos instalado),
pasa los mismos once casos que el tuyo. Te lo paso aparte si lo quieres; o lo generas tú con el parche.

Dos cosas que son de la app y no del paquete, por si te interesan: `oasis.sh` reescribe
`oasis-config.json` en cada arranque (es conffile: cada upgrade preguntará), y el modo `test` apunta
a un `test/` que no viaja. Y una sobre ECOin, que preguntaste:
[`docs/ECOIN.md`](https://github.com/alephscriptorium-eng/O_SDK/blob/test/installer-amd/ARCHIVO/DISCO/installer-amd/docs/ECOIN.md).

## 4. Cómo lo probamos

Herramienta: Docker, con contenedores desechables de Debian 12 (sin init y con systemd real),
Debian 11, Ubuntu 22.04 y 24.04. No te hace falta para nada de lo anterior: el protocolo de casos
está escrito en prosa, sin herramienta, en
[`docs/PROTOCOLO.md`](https://github.com/alephscriptorium-eng/O_SDK/blob/test/installer-amd/ARCHIVO/DISCO/installer-amd/docs/PROTOCOLO.md),
y cada caso dejó su comando literal y su salida en
[`reports/evidence/v1/`](https://github.com/alephscriptorium-eng/O_SDK/tree/test/installer-amd/ARCHIVO/DISCO/installer-amd/reports/evidence/v1)
(tu paquete) y
[`reports/evidence/v2/`](https://github.com/alephscriptorium-eng/O_SDK/tree/test/installer-amd/ARCHIVO/DISCO/installer-amd/reports/evidence/v2)
(el regenerado). Si quieres ver una sola cosa, mira `T8-systemd.txt` en los dos: es el servicio
arrancando con `systemctl enable --now oasis`, en cliente y en PUB.

## 5. La propuesta

Que ese kit sea la base de pruebas del instalador, y que siga contigo. Es un repo autónomo
(AGPL-3.0, como Oasis) con una regla: nada entra en un informe sin su comando y su salida. El trato
que te proponemos:

- tú sigues construyendo el `.deb` como hasta ahora; nos pasas el fichero (o su sha256 y de dónde bajarlo);
- nosotros lo pasamos por los once casos y te devolvemos la evidencia, igual que esta vez;
- si un caso nuevo te interesa (arm64, instalar encima de una `.ssb` existente, upgrade entre versiones), se añade al protocolo y vale para todos los paquetes que vengan.

Si lo ves, el siguiente paso es sacar la carpeta a su propio repo y darte permisos. Cómo se añade un
caso o se corre el banco está en
[`CONTRIBUTING.md`](https://github.com/alephscriptorium-eng/O_SDK/blob/test/installer-amd/ARCHIVO/DISCO/installer-amd/CONTRIBUTING.md).
