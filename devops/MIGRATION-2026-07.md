# Migración de layout — refactor 2026-07

El refactor `refactor/estructura` renombra las carpetas del fork:

| Antes | Ahora |
|-------|-------|
| `OASIS_PUB/` | `pub/` |
| `GANDI_DEVOPS_FOLDER/` | `devops/` |
| `OASIS_CLIENT_dEV/` + `docker-scripts/` | `client/` |
| `ECOIN_DOCKERIZE/` | `ecoin/` |
| `HACKATON_GUIDE.md`, `SESSION-BACKLOG/`, transcripts | `archive/` |
| servicio `oasis-dev` (contenedor `oasis-server-dev`) | `oasis-client` |

Git gestiona los renombres al hacer `pull`; lo que NO gestiona son los
ficheros **sin trackear** que vivían dentro de las carpetas renombradas.

## En el VPS (instancia scriptorium)

Ventana de mantenimiento corta. El proyecto compose del pub tiene `name:`
explícito (`oasis-pub-scriptorium`), así que los contenedores y volúmenes NO
cambian de identidad; solo cambian rutas del repo y la imagen se reconstruye.

```bash
ssh scriptorium-vps            # alias en devops/.ssh/config
cd /opt/oasis-scriptorium
git fetch && git checkout main && git pull

# 1. Mover el env real (untracked) del layout viejo al nuevo
mv OASIS_PUB/.env.prod pub/ 2>/dev/null || true
mv OASIS_PUB/.env       pub/ 2>/dev/null || true
mv OASIS_PUB/data       pub/ 2>/dev/null || true

# 2. Retirar el directorio viejo si quedó vacío
rmdir OASIS_PUB 2>/dev/null || rm -ri OASIS_PUB

# 3. Redesplegar (rebuild: las rutas in-container ahora son /app/pub/...)
bash pub/scripts/env-run.sh .env.prod deploy.sh
```

Avisos:

- **No** reinicies `pub-web` (Caddy) a ciegas: sirve más vhosts. `deploy.sh`
  reconstruye lo necesario.
- Los bind mounts de estado (`/srv/oasis/oasis-pub/*`) no cambian: la
  identidad SSB (`secret`, flume, blobs) queda intacta.
- Verifica después: `npm run devops:status` desde la máquina operadora y
  `bash pub/scripts/env-run.sh .env.prod whoami.sh` en el VPS (el feed id
  debe ser el mismo).

## En local (rol cliente)

El servicio pasa de `oasis-dev` a `oasis-client` y el proyecto compose ahora
se llama `o-sdk`:

```bash
docker compose up -d --remove-orphans --build
```

Los datos no se pierden: los volúmenes son binds a `./volumes-dev/*`.
El wallet ECOin ahora es opcional (profile): `npm run ecoin:up`.

## SSH

`devops/.ssh/config` define el alias `scriptorium-vps` con la ruta nueva de
la clave (`devops/.ssh/gandi_pub_ed25519`). Los datos de instancia (IP,
usuario, cap del ciclo) están en `devops/hosts/scriptorium/host.env`.
