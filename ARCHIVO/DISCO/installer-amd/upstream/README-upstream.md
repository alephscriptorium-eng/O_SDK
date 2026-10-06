# upstream/ · lo que llegó, tal cual

Recibido el 2026-10-06 del autor del paquete. No se edita: la propuesta vive en `packaging/`.

| Fichero | sha256 | Qué es |
|---|---|---|
| `build-deb2.sh` | `542019c3e580c2de8c717dd72c8c8d971b1210ec5f4c2118212cd92a7bacc2ca` | Script que genera el `.deb` con Node 22.20.0 embebido. En su repo vive en `scripts/build-deb2.sh`. |
| `oasis.sh` | `27de52e9902ba8c6631504b71f4f424850f550aac1404cbd0c766b1903ac41b5` | El lanzador de la app. Byte a byte el mismo que viaja en el `.deb` como `/opt/oasis/oasis.sh`. |
| `oasisrc` | `456f67ebfaa76a05f58866cbc7355b202c20bc9b717f4413fb953306b3c3d773` | El `/var/lib/oasis/.oasisrc` que escribe el `postinst` cuando se responde «no» al asistente. |
| `../dist/oasis_1.2.2_amd64.deb` | `3619386d747695fdd5e474fd9efb3acccc9a6adf393b8135f66f1856d7089cdf` | El paquete (111 369 992 bytes). Fuera de git; ver `../SHA256SUMS`. |

Lo que el paquete declara: `Package: oasis`, `Version: 1.2.2`, `Architecture: amd64`,
`Depends: jq`, `Installed-Size: 538460`, conffiles `src/configs/{oasis-config,server-config,snh-invite-code}.json`.
Miembros del `ar`: `debian-binary`, `control.tar.zst`, `data.tar.zst`.
