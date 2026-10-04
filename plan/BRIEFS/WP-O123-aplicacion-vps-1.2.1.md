# BRIEF · WP-O123 · Aplicación en el VPS del upgrade a Oasis 1.2.1

Dep: WP-O119, WP-O120, WP-O121, WP-O122 (rama `upgrade/oasis-1.2.1`). Asiento D-O27.
Protocolo: `docs/PUB/UPGRADE-PROTOCOL.md` §4 y §0.5. **Cada paso marcado pide GO expreso. Desde que
un nodo arranca en 1.2.1 no hay rollback.**

## Paso 0 · medido el 2026-10-04 (solo lectura)

`upgrade-gates.sh --remote snapshot pre-o123` (medida nueva; las tres fuentes cuadran):

```
  pub  running healthy  v1.1.10  server   log=flume seq=16 registros=16 → cuadra · sbot=16
       tipos: (cifrado)=1 about=3 contact=5 karmaScore=1 oasisVersion=5 pub=1
  hub  running healthy  v1.1.10  backend  log=flume seq=12 registros=12 → cuadra · sbot=12
       tipos: (cifrado)=4 about=2 contact=1 oasisVersion=4 pub=1
  bot  running healthy  v1.1.10  backend  log=flume seq=55 registros=55 → cuadra · sbot=55
       tipos: (cifrado)=1 about=2 contact=1 karmaScore=2 oasisVersion=3 pub=1 pubAvailability=28 ubiAllocation=16 wallet=1
       dirección=EYdruXgDVQGhBpSsns83VA1BmDfAKBP4Lc épocas=2026-09,2026-10 motor:pub=true
```

| Dato | Valor |
|---|---|
| Log por nodo (`flume/log.offset`) | pub 4,25 MB · HUB 3,58 MB · bot 4,04 MB |
| Blobs | pub 580 MB · HUB 449 MB · bot 72 MB |
| Disco | `/` 12 G de 25 G (52 %) · `/srv/oasis` 8,4 G de 40 G (23 %) |
| Memoria | 3,9 GB; pub 140 MiB (**sin límite**), HUB 305 de 768 MiB, bot 136 de 768 MiB, edge 285 MiB |
| Log de Docker del pub | **sin rotación** |
| Crontab del usuario | vacío |
| Restos | `src-1.1.4.tgz`, `src.old-1.1.4`, imagen `:1.1.4`; cuatro `*.bak-o106/o114-*.tgz` en `/srv/oasis` |

**Deriva de los ficheros de build** (traídos y diferenciados):

| Fichero del host | Qué es | Qué se hace |
|---|---|---|
| `Dockerfile` | el del repo anterior, sin comentarios: `node:20`, `chown -R /app`, **`npm install` en `src/server`** | se sustituye por el del repo. Con el viejo la imagen no usaría `src/base` |
| `docker-entrypoint.sh` | versión de mayo (544 líneas; 317 de diferencia con `main`): lleva `install_runtime_deps` con `npm install` | se sustituye por el del repo, que es el que han ejercido todos los gates locales. **Revisar el diff antes del GO-1** |
| `.dockerignore` | propio del layout del host (`OASIS_PUB/…`) | **no** se sustituye: se le añaden `src/AI/node_modules`, `src/AI/embeddings`, `src/AI/.cache`, `src/server/node_modules.full` |
| `OASIS_PUB/docker-compose.pub.yml` | igual que `main` salvo comentarios | se le aplican los cambios de la rama: `OASIS_SNAPSHOT=off` (HUB, bot), `mem_limit` y `logging` del pub, `logging` de panel-api y web |

El layout del host no es el canónico: la carpeta del compose es `OASIS_PUB/` y las herramientas
quedan en la imagen en `/app/OASIS_PUB/tools/`. `pub-snapshot.sh cron` ya lo deduce de `host.env`.
El `HUB` tiene en el host `mem_limit` 768 MiB (el repo propone 1536 por defecto): no se cambia aquí.

## Pasos

| # | Paso | Puerta |
|---|---|---|
| 1 | `backup-oasis-pub.sh` · `backup-ecoin.sh` · `*.bak-o123-<fecha>` de `Dockerfile`, entrypoint, `.dockerignore`, compose, configs de HUB y bot, `site/hub/index.html` · converger esos ficheros in place | **GO-1** |
| 2 | Disco: retirar `src.old-1.1.4`, `src-1.1.4.tgz`, imagen `:1.1.4` y los `*.bak-o106-*.tgz` · `docker image prune -f` · `docker builder prune -f` | (con GO-1) |
| 3 | `docker tag …:latest …:1.1.10` · `tar -czf /srv/oasis/src-1.1.10.tgz src` | |
| 4 | Subir `src/` con `git -c core.autocrlf=false -c core.eol=lf archive` · comprobaciones (versión, sin CRLF, enlace real, `src/base` presente, guard del dominio) · `mv src src.old-1.1.10` | |
| 5 | Subir `OASIS_PUB/tools/` (snapshot-build, log-bipf, sonda) | |
| 6 | Build · humo (`server` y `backend`, sin red) · **ensayo de migración** sobre copia de los tres logs, sin `secret` y sin red · `df` | |
| 7 | **Pub**: `stop` · tgz en frío de `ssb-data` · `up -d --no-deps oasis-pub` · esperar · `check pre-o123 --expect 'pub:oasisVersion=+1'` · invite · `/public/status` | **GO-2 · sin retorno** |
| 8 | **HUB**: config in place · `stop` · tgz · `up` · `check` · `prune-cache` · `hub --strict` · Sala 04 | **GO-3 · sin retorno** |
| 9 | **Bot**: `hub-wallet.sh pause` · `check` (misma dirección, un `wallet`) · `on --yes` · `check` · `backup-ecoin.sh` | **GO-4a · sin retorno** / **GO-4b** |
| 9b | Snapshot del pub: `pub-snapshot.sh build` · `status` · `check` (sin publicaciones) · línea de `cron` en el crontab del host | **GO-5** |
| 10 | `check` a los 5 min · `snapshot post-o123` · `capacity.sh` · `deploy-log.sh` · ficha de instancia · reporte | |

Delta declarado: `pub:oasisVersion=+1 hub:oasisVersion=+1 bot:oasisVersion=+1,pubAvailability=+0..1`.
Con los logs medidos (unos 4 MB) la migración es cuestión de segundos más el coste fijo; el ensayo
del paso 6 da la cifra real.

## Fuera de alcance

El cliente (pide antes su drill y `client:test-ai`, y GO aparte si la identidad es real). La
migración del host al layout canónico. El `mem_limit` del HUB.
