# Contribuir

## Correr el banco

```sh
sha256sum -c SHA256SUMS
bin/run-tests.sh dist/<paquete>.deb <etiqueta>
```

La etiqueta nombra la carpeta `reports/evidence/<etiqueta>/`. Usa `v1`, `v2`… para versiones del
paquete, o `local-<fecha>` para pruebas sueltas. Nunca sobrescribas una evidencia ya versionada:
si repites, usa otra etiqueta.

## Añadir un caso

1. Crea `tests/T<n>-<slug>.sh`. Mira `tests/T4-lanzador.sh` como ejemplo mínimo.
2. Usa `ev <nombre> <comando...>` de `bin/lib.sh`: escribe el comando literal y su salida en el
   fichero de evidencia y devuelve el código de salida. No uses `echo` para «resumir» lo que viste.
3. Termina con una o más líneas `obs <clave> <valor>`: son los hechos que el informe cita. Un
   caso **observa**, no juzga; lo esperado para cada versión del paquete está en `docs/PROTOCOLO.md`.
4. Documenta el caso en `docs/PROTOCOLO.md`: qué mide, qué hallazgo sella.

## Qué no entra

- Contenido de `secret`, `wallet.dat`, credenciales RPC, códigos de invitación. Si un test
  necesita demostrar que existe un fichero así, `ls -l` o `stat` bastan.
- Los `.deb`: van por `SHA256SUMS`.
- Cambios en `upstream/`: es la entrada tal cual llegó. Si llega una versión nueva, se añade
  como `upstream/<fecha>/` y se actualiza `upstream/README-upstream.md`.

## Estilo

- Shell POSIX donde se pueda, `bash` cuando haga falta (`bin/` y `tests/` son bash).
- Un commit por paso con prefijo `chore|feat|fix|test|docs`.
- Español en docs e informes; inglés en los mensajes que ve el usuario del paquete.
