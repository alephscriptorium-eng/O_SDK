# 02 · VPS y volúmenes

## 1. Inventario del VPS **[VPS]** (`pub/BACKLOG.md`)

| Dato | Valor | Ref |
|---|---|---|
| Proveedor / talla | GandiCloud VPS **V-R4**: 2 vCPU · 4 GB RAM · Debian 13 | `pub/BACKLOG.md:29-38` |
| Motivo | «deja margen para pub SSB, Caddy, panel API, frontend, segunda landing y mantenimiento» | `:40` |
| Datacenter / hostname | `FR-SD6` (Paris) · `escrivivirco-scriptorium-pub-oasis` | `:89-90` |
| IP | `92.243.24.163` · IPv6 `2001:4b98:dc0:43:f816:3eff:feb7:a5b5` | `:86-87` |
| Kernel | `6.12.38+deb13-amd64` | `:95` |
| Docker | Engine `26.1.5+dfsg1` · Compose `2.26.1-4` | `:104` |
| UFW | 22, 80, 443, 8008 (IPv4+IPv6) | `:105` |
| Verificador post-reboot | 26 pass, 1 warning (`PermitRootLogin without-password`), 0 fail | `:115` |

## 2. Los dos volúmenes **[VPS]**

| Volumen | Nombre Gandi | Tamaño | Dispositivo / FS | Montaje | Ref |
|---|---|---|---|---|---|
| Sistema (boot) | `vps-boot` (ID `55f0e620-…`), origen `Debian 13 TrixieBoot` | **25 GB** | raíz | `/` | `pub/BACKLOG.md:98` |
| Datos | `scriptorium-oasis-pub-volumen` (ID `5e4ef192-48a3-4b1b-afeb-2c00985859a3`) | **40 GB** | `/dev/xvdb`, ext4, label `scriptorium-oasi`, UUID `87fb15ef-4806-4928-813e-a2646d2e8082` | `/srv/oasis` por UUID en `/etc/fstab` | `:99-101` |

Layout aplicado: código en `/opt/oasis-scriptorium`, estado del pub en `/srv/oasis/oasis-pub` (`:102`).

Automatización (`devops/scripts/bootstrap-debian13-base.sh`): `MOUNT_POINT=/srv/oasis` (`:8`),
`detect_volume_device` elige el único disco ≠ sistema o exige `--device` (`:209-235`), `mkfs.ext4 -L
scriptorium-oasis-pub` solo si no hay FS (`:274-294`), fstab por `UUID=`. La doc dice `/dev/vdb`
(`devops/README.md:89`), la evidencia real `/dev/xvdb`.

Verificación (`devops/scripts/verify-debian13-base.sh`): `findmnt /srv/oasis` (`:152-157`), entrada
`UUID=` en fstab (`:165-168`), exige `/srv/oasis/oasis-pub/{ssb-data,logs,caddy-data,caddy-config,backups}`
(`:176-181`) y propietario (`:202-208`). **El plan añade `/srv/oasis/oasis-hub/{ssb-data,logs,http-cache}`.**

## 3. Dónde está Docker y por qué importa

- **No hay `daemon.json` ni `data-root`** en el repo (grep `daemon\.json|data-root|/var/lib/docker` → solo
  flags CLI de scripts propios). Según la evidencia disponible **Docker vive en el disco de sistema de 25 GB**.
- `docs/PUB/UPGRADE-PROTOCOL.md:115-117`: «la raíz del VPS es pequeña y cada rebuild deja una imagen
  `<none>` de ~3 GB. Antes del build: `docker image prune -f && docker builder prune -f` (en 09/2026
  había **9,5 GB reclamables**). Comprueba `df -h /` y `docker system df`.»
- Rollback de `src/` en tarball dentro del volumen grande: `tar … -czf /srv/oasis/src-<ver>.tgz src` (`:119`).
- **Consecuencia para la v2**: al reutilizar la imagen `oasis-pub-scriptorium:latest` **no hay rebuild** →
  cero presión nueva en `/`. Solo `docker pull nginx:alpine` (~20 MB). Cambiar `docker-entrypoint.sh`
  (v1) habría invalidado la capa `npm install` y forzado un rebuild de ~3 GB.

## 4. Mediciones que existen y que faltan

| Dato | Estado |
|---|---|
| `df -h` real capturado | **no existe** en ningún fichero versionado |
| `docker system df` capturado | **no existe**; solo instrucción en UPGRADE-PROTOCOL §4 y `deploy-teatro.sh:60` (`df -h /srv/oasis`) |
| Memoria del pub | «Pub hoy: 91 MiB, 2,9 GB libres» (`v1.md:79`, sin punto de montaje ni fecha exacta) |
| Tamaño del `ssb-data` del pub | tarball del backup 2026-09-12: `ssb-data-20260912T164504Z.tar.gz` = **294.791.733 bytes (~281 MiB)** comprimidos (`devops/backups/oasis-pub/20260912T164504Z/`) |
| `pub/BACKLOG.md:214` | `[ ] Métricas de disco/volumen SSB.` pendiente |
| `pub/BACKLOG.md:66` | `[ ] Configurar snapshots automáticos/manuales en Gandi` pendiente |
| Journal `devops/logs/deploy-history.jsonl` | **una** línea; campos `ts,target,host,gitSha,oasisVersion,capsShs,cycle,feedId,mode,actor`; **sin** memoria ni disco |

El plan cubre el hueco con `hub-disk.sh status --json` (línea base en el paso 1 y en el cierre).

## 5. Ficheros `.env*`

- Tracked: `pub/.env.example`, `pub/.env.local.example`, `pub/.env.vps.example`. Untracked presente:
  `pub/.env.local` (idéntico al example). **`pub/.env.prod` no existe en el repo** (solo en el VPS;
  `devops/hosts/scriptorium/host.env:17` `REMOTE_ENV_FILE=.env.prod`).
- `pub/.env.vps.example`: `OASIS_PUB_WEB_HOST=pub.escrivivir.co` (sin esquema), SSB 8008,
  `OASIS_PUB_SSB_DATA_DIR=/srv/oasis/oasis-pub/ssb-data`, `…LOGS_DIR`, `…CADDY_DATA_DIR`,
  `…CADDY_CONFIG_DIR`, `OASIS_PUB_TEATRO_DIR=/srv/oasis/teatro`, 80/443, panel 8787, `PUB_PANEL_TOKEN`.
- `pub/.env.local.example`: **`OASIS_PUB_WEB_HOST=http://localhost`** (trae esquema; sanear si se usa
  como `--allow-host`), SSB 8009, web 8088/8443, panel 8788, maint-UI 3001, rutas `../volumes-dev/oasis-pub/*`.
- Variables nuevas del plan (ver `06-fragmentos.md` §8).

## 6. Divergencia repo ↔ VPS (leer antes de tocar)

- Layout **vivo**: `/opt/oasis-scriptorium/OASIS_PUB` (pre-refactor, **sin git**), no `…/pub`
  (`docs/PUB/TEATRO-PROTOCOL.md:129-131`; `UPGRADE-PROTOCOL.md:126`; `BACKUP_METADATA.json:
  remoteConfigFile=/opt/oasis-scriptorium/OASIS_PUB/config/ssb/config`). `devops/hosts/scriptorium/host.env:15`
  dice `REMOTE_REPO_DIR=/opt/oasis-scriptorium/pub` → **desajustado**; `pub/scripts/common.sh:36-38`
  `is_canonical_vps_layout()` no se dispara en el VPS. Migración `OASIS_PUB/ → pub/` pendiente
  (`devops/MIGRATION-2026-07.md:23-38`).
- Compose vivo ≠ repo solo en comentarios; el mount del Teatro se añadió a mano con backup
  `docker-compose.pub.yml.bak-teatro`; `OASIS_PUB_TEATRO_DIR` añadida a `.env` y `.env.prod` (TEATRO §6 `:132-135`).
- `site/scriptorium/index.html` vivo tiene el token de PUBLIC_ROOM y una etiqueta de diagrama: al desplegar
  el vestíbulo **fusionar**, no pisar (TEATRO §6 `:136-141`).
- Recrear solo el edge: `docker compose --env-file .env.prod -f docker-compose.pub.yml up -d pub-web`; el
  project name `oasis-pub-scriptorium` coincide → el día de la migración Docker adopta los contenedores (`:142-145`).
- `devops/SERVER.md` está referenciado (`pub/BACKLOG.md:85`) pero **no existe** (excluido por
  `devops/.gitignore` deny-by-default).
- Alias SSH: `scriptorium-vps` (`devops/.ssh/config`, no versionado), user `debian`, clave
  `devops/.ssh/gandi_pub_ed25519`.

## 7. Contrato de rutas que fija la v2

```
/srv/oasis/                       volumen de datos (40 GB)
├── oasis-pub/                    estado del pub (intacto)
│   ├── ssb-data/  logs/  caddy-data/  caddy-config/  backups/
├── teatro/                       obras estáticas (deploy-teatro.sh)
└── oasis-hub/                    NUEVO · estado del nodo de soporte
    ├── ssb-data/                 secret propio, flume/, blobs/, conn.json, gossip.json, oasis-first-contact
    ├── logs/                     bind de /app/logs (sin escritores conocidos; simetría con el pub)
    └── http-cache/               proxy_cache de nginx (max_size, inactive 7d)
/opt/oasis-scriptorium/OASIS_PUB/ código y configs (disco de sistema)
    ├── docker-compose.pub.yml    + servicios oasis-hub, hub-cache
    ├── caddy/Caddyfile           + bloque @hub
    └── config/hub/               NUEVO · ssb-config, oasis-config.json, nginx.conf.template
```

Qué crece dónde:

| Ruta | Crece con | Podable | Quién acota |
|---|---|---|---|
| `oasis-hub/ssb-data/flume/log.offset` | replicación (hops 2) | **no** | `friends.hops` |
| `oasis-hub/ssb-data/flume/*` índices, `ebt/` | log | sí (rebuild) | — |
| `oasis-hub/ssb-data/blobs/` | `GET /c/blob/*` ausentes + replicación de blobs | **sí** (content-addressed) | `hub-disk.sh prune-blobs`, `blobs.max` 50 MB |
| `oasis-hub/http-cache/` | tráfico web | sí | nginx `max_size` + `inactive=7d`; `prune-cache` |
| stdout de los contenedores (en `/var/lib/docker`, disco de sistema) | tráfico y replicación | sí | `logging.max-size/max-file` |
| Imágenes Docker (`/`) | rebuilds | sí | `docker image/builder prune` (no aplica: sin rebuild) |
