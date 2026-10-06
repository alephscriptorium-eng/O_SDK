# installer-amd

Kit libre para **probar, diagnosticar y mejorar** el instalador `.deb` de
[Oasis](https://github.com/epsylon/oasis) (red social P2P sobre SSB) para `amd64`. Nació
para devolverle a quien construye el paquete algo más útil que una lista de quejas: evidencia
reproducible de cada fallo, el script de construcción corregido y un `.deb` regenerado y
probado con esas correcciones.

*English summary: a FOSS test bench for the Oasis `.deb` installer. It installs a given
package inside disposable Debian/Ubuntu containers (plain and systemd), records literal
command + output evidence per case, ships a patched build script and rebuilds the package
from the original payload. Everything runs offline except image pulls and the Node tarball.*

## Qué hay

| Carpeta | Contenido |
|---|---|
| `upstream/` | Lo que llegó del autor del paquete, tal cual: `build-deb2.sh`, `oasis.sh`, `oasisrc`. |
| `packaging/` | La propuesta: `build-deb2.sh` corregido, el diff contra upstream, el wrapper `oasis-run`, `oasisrc.example` y un README que mapea cada hallazgo con su cambio. |
| `docker/` | Tres imágenes: `build` (reconstruir el `.deb`), `plain` (Debian 12 sin init) y `systemd` (Debian 12 con init real). |
| `bin/` | `run-tests.sh` (banco de pruebas), `rebuild.sh` (regenera el `.deb`), `lib.sh`. |
| `tests/` | Un fichero por caso, `T0…T9`. Cada uno imprime el comando literal y su salida. |
| `docs/` | `PROTOCOLO.md` (los casos y qué sella cada uno), `PLAN.md`, `ECOIN.md` (cómo encajaría ECOin en el instalador). |
| `reports/` | El informe para el autor y la evidencia por versión (`evidence/v1`, `evidence/v2`). |
| `dist/` | Los `.deb` (ignorados por git; se verifican con `SHA256SUMS`). |

## Quickstart

Requisitos: Docker (Desktop o Engine), `bash`, `sha256sum`. En Windows, Git Bash.

```sh
# 1. deja el paquete a probar en dist/ y comprueba su huella
sha256sum -c SHA256SUMS

# 2. corre el banco contra ese paquete; la evidencia cae en reports/evidence/<etiqueta>/
bin/run-tests.sh dist/oasis_1.2.2_amd64.deb v1

# 3. regenera el paquete con la propuesta y vuelve a probarlo
bin/rebuild.sh dist/oasis_1.2.2_amd64.deb
bin/run-tests.sh dist/oasis_1.2.2-1_amd64.deb v2
```

`run-tests.sh` no necesita red para la aplicación: los contenedores donde arranca Oasis van con
`--network none` y la identidad SSB que se crea es desechable. Solo tiran de red la descarga de
imágenes base, el caso de portabilidad (instala `jq` con `apt`) y la descarga del tarball de Node
en `rebuild.sh`, que se verifica contra `SHASUMS256.txt` de nodejs.org.

## Reglas del kit

1. **Evidencia = comando + salida.** Nada entra en un informe sin su fichero en `reports/evidence/`.
2. **Ningún secreto sale del contenedor.** Los tests no leen `~/.ssb/secret` ni códigos de
   invitación; solo `ls -l` y `stat`. `run-tests.sh` falla si encuentra material de claves en la evidencia.
3. **Lo que llega de upstream no se edita.** `upstream/` es de solo lectura; la propuesta vive en `packaging/`.
4. **Parada dura.** Si un paso no da lo esperado, el test lo anota y sigue con el siguiente caso; nadie improvisa un arreglo dentro del contenedor.

## Licencia

AGPL-3.0, la misma que Oasis: `packaging/build-deb2.sh` deriva del script de upstream.
Ver `LICENSE`.
