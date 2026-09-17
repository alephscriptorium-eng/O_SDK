# Protocolo del cliente (nodo personal)

> **Este repo es el sitio del cliente** (`C:\S_LAB\o-sdk`,
> `https://github.com/alephscriptorium-eng/O_SDK.git`). El cliente se levanta con el compose de
> la **raíz** (`docker-compose.yml`, proyecto `o-sdk`, servicio `oasis-client`); el pub, el HUB y el
> entorno scriptorium viven en `pub/` (proyecto `oasis-pub-scriptorium`) y **no comparten** puertos,
> nombres, redes ni directorios de `volumes-dev/` con el cliente (ver §0).

> **Estado · ACTIVO 2026-09-17 13:37 UTC** (WP-O98). Oasis **1.1.2**, feed
> `@tMJzSfcZSNCsFRF3pl3rMoFDatz6VjDCjQ8/TpjYIRY=.ed25519` («Alephillo»), importado desde el
> cliente 0.8.8 de `BlockchainComPort\volumes-dev\ssb-data` (seq 44 al importar; 45 = `oasisVersion`
> del sbot puro; 46 = `karmaScore` de la GUI; `seq_pub` = 46; `Verification`: forks 0). Manifiesto
> `volumes-dev/ssb-data/.import-20260917-153020.txt`; backup `devops/backups/client/20260917-153020/`.
> Blobs del origen descartados (todos dañados por NUL): 4 propios pendientes de la red. Reporte
> `plan/REPORTES/WP-O98-cliente-fresco-identidad.md`. Instalación antigua **retirada** el mismo día (§7: contenedor, imagen, 6 volúmenes y 2 redes); el directorio físico queda como backup frío.

Checklist operativo para **dar de alta un cliente fresco, traer una identidad SSB existente sin
bifurcar su feed, sincronizarlo con el pub, subirlo de versión, verificarlo y volver atrás**.
Deriva de `UPGRADE-PROTOCOL.md` (misma imagen, tres modos) y de `RECOVERY-PROTOCOL.md` §4 (regla
de oro), y del primer alta+importación hecha en este repo (WP-O98, 2026-09-17).

> **Modelo mental.** Solo hay **una cosa irremplazable: el `secret`**. Y una cosa que conviene no
> perder: **tu propio log** (`flume/log.offset`), porque lo que el pub no tenga de tu feed no existe.
> Todo lo demás (índices flume, `ebt/`, `conn.json`, `config`, blobs) es derivable. Oasis **no tiene
> guardia contra la bifurcación del feed**: si la GUI arranca con tu `secret` y un log vacío, publica
> (en 1.1.2, el PM de bienvenida a los 3 s) un mensaje con `sequence: 1` → fork irreversible frente a
> lo que guarda el pub. Por eso importar = **ficheros con el cliente parado + sbot puro hasta
> sincronizar + GUI al final**.

## 0. Estado y convivencia con el pub local

```bash
docker compose -p o-sdk ps -a                    # cliente: oasis-client (+ ecoin-wallet con --profile ecoin)
docker compose -p oasis-pub-scriptorium ps -a    # pub+HUB local: no debe ocupar 3000/8008 (usa 8009/8088/8443/8788 con pub/.env.local)
ls volumes-dev/                                  # cliente: ssb-data ai-models logs ecoin-data · pub: oasis-pub oasis-hub teatro
docker volume inspect o-sdk_oasis-ssb-data-dev --format '{{index .Options "device"}}'   # = <repo>\volumes-dev\ssb-data (o no existe aún)
```

| | Cliente | Pub + HUB (local) |
|---|---|---|
| Compose / proyecto | `docker-compose.yml` · `o-sdk` | `pub/docker-compose.pub.yml` · `oasis-pub-scriptorium` |
| Contenedores | `oasis-client`, `ecoin-wallet` | `oasis-pub-scriptorium`, `oasis-pub-hub`, `oasis-pub-hub-cache`, `oasis-pub-web`, `oasis-pub-panel-api` |
| Puertos host | 3000, 8008 (7474/12000 ecoin) | con `pub/.env.local`: 8009, 8088, 8443, 8788, 3001 (maint-ui) |
| `volumes-dev/` | `ssb-data`, `ai-models`, `logs`, `ecoin-data` | `oasis-pub/*`, `oasis-hub/*`, `teatro` |
| Red | `o-sdk_oasis-network` | `oasis-pub-scriptorium_oasis_pub_net` |
| Imagen | `o-sdk-oasis-client` (mismo `Dockerfile`) | `oasis-pub-scriptorium:latest` |

**Regla**: el pub local siempre con `npm run pub:local:*` (`--env-file .env.local`). Sin `--env-file`
el compose del pub toma los defaults del VPS (8008/80/443) y choca con el cliente y con Windows.

## 1. Alta fresca (identidad nueva)

```bash
npm run build                    # imagen o-sdk-oasis-client (10-20 min la primera vez)
npm run setup                    # volumes-dev/{ssb-data,ai-models,logs,ecoin-data}; sin esto el bind falla
# Modelo IA (4,08 GB): tres opciones
#   a) copiar uno existente a volumes-dev/ai-models/oasis-42-1-chat.Q4_K_M.gguf (head -c4 = GGUF; sha256 igual)
#   b) dejar que el entrypoint lo descargue (3,8 GB, solarnethub.com) en el primer arranque
#   c) sin IA: OASIS_SKIP_AI_MODEL=true en un docker-compose.override.yml no versionado
docker compose up -d oasis-client
docker compose logs -f oasis-client   # parches 3/3 ✓ · [Version: X.Y.Z] · secret creado si no existía
```

Qué hace el primer arranque: el entrypoint (root) crea y chowna `.ssb`, `models`, `logs`; escribe
`~/.ssb/config` si falta (cap aleatorio que `src/configs/server-config.json` pisa: el cap de red es
el del repo); aplica 3 parches a `node_modules`; `backend.js` levanta el sbot embebido, que **crea
`secret` si no existe**, la GUI en :3000 y (bajo demanda) la IA en :4001. La GUI publica el PM de
bienvenida y crea `oasis-first-contact`.

Healthcheck del alta: §5. El primer día: `npm run client:backup-keys` y guarda la copia **fuera**
de la máquina. **`npm run up` = `setup` + `up -d`: no lo uses durante una importación (§2).**

## 2. Importar una identidad existente

Con el cliente **parado** (`docker compose stop oasis-client`) y `volumes-dev/ssb-data` vacío
(o `--force`, que lo aparta a `ssb-data.pre-import-<ts>` sin borrar nada):

```bash
npm run client:import-identity -- --from "C:/ruta/al/.ssb/viejo" --with-blobs --dry-run   # verifica sin copiar
npm run client:import-identity -- --from "C:/ruta/al/.ssb/viejo" --with-blobs [--force]
```

| Se copia (lista blanca) | Por qué |
|---|---|
| `secret` | la identidad |
| `flume/log.offset` | tu feed completo (y el de tus pares): elimina la ventana de fork por construcción |
| `gossip.json` | direcciones/claves de pubs conocidos: el cliente vuelve a encontrar al pub solo |
| `keys/` | claves de tribus (no derivables) |
| `blobs/` (opcional) | avatares/adjuntos; content-addressed, re-descargables |

| **No** se copia | Por qué |
|---|---|
| `flume/*` (índices), `ebt/`, `blobs_push/` | vistas derivadas; las de otra versión hacen que el arranque muera con «Another Oasis instance is already running» (`isLockError` trata cualquier `OpenError` de leveldb como lock) o `isCorruptStoreError` |
| `conn.json` | se regenera desde `gossip.json`; corrupto bloquea conexiones |
| `config` | lo escribe el entrypoint; `server-config.json` manda (caps, connections, hops) |
| `socket`, `manifest.json`, `node_modules`, `*.nul-damaged-bak` | residuos |

El script además: verifica el origen (`secret` con `id` = `@public`, sin bytes NUL; `log.offset`
por **frames** con `client/scripts/lib/inspect-log-offset.js` → `tailOk`, `badFrames: 0`, `mySeq`),
guarda un **backup verificado** en `devops/backups/client/<ts>/` (sha256), copia, **crea
`oasis-first-contact`** = `<feed>\n<ISO>\nwelcome=done\n` (formato `onboarding_model.adopt`; apaga el
PM de bienvenida y el banner), verifica sha256 y frames tras la copia (y una muestra de blobs por
hash) y deja el manifiesto `volumes-dev/ssb-data/.import-<ts>.txt`.

Después **no arranques la GUI**: §3.

> Solo `secret` (sin log): válido si no tienes el log (`RECOVERY-PROTOCOL.md` modelo mental: el pub
> guarda tu feed). El script exige `log.offset`; para ese caso copia el `secret` a mano, crea el flag
> igual y ve a §3: el sbot puro traerá tu feed del pub. Lo que el pub no tenga se pierde.

## 3. Sincronizar con el pub antes de la GUI (sbot puro)

```bash
npm run client:sync-only -- start              # modo `server` del entrypoint: solo sbot, nada publica
docker logs -f oasis-sync-only                 # CONNECTED net:pub.escrivivir.co:8008 · sin "Another Oasis"/"corrupt"
npm run client:sync-only -- status --pub --watch   # cada 30 s hasta SYNC-OK
npm run client:sync-only -- stop               # exige log.offset estable 60 s; verifica el frame final
docker compose up -d oasis-client              # ahora sí. (El propio sbot puro ya publicó `oasisVersion` en seq N+1 a los 7 s:
                                               #  SSB_server.js solo lo hace si el log NO está vacío; el pub lo acepta como continuación)
```

`start` tiene un **gate**: si el sbot no se identifica como el feed del `secret` (`ID-MISMATCH`), se
para solo (habría creado otra identidad sobre un montaje equivocado). `status` compara el seq propio
según el fichero, según el sbot y según el pub (`devops/scripts/pub-feed-seq.sh`, solo lectura):

| Veredicto | Significa | Qué hacer |
|---|---|---|
| **SYNC-OK** | seq local = seq pub, `log.offset` estable ≥ 5 min, pub visto conectado | `stop` y arrancar la GUI |
| AHEAD | local > pub (publicaste offline) | normal: el sbot empuja al pub (EBT es bidireccional); repetir |
| BEHIND | local < pub | **no arrancar la GUI**; esperar; si no avanza en 10 min `docker restart oasis-sync-only` |
| PUB-UNKNOWN | el pub no tiene el feed ni lo sigue | `npm run devops:invite -- 1` y `SSB_INVITE='…' npm run client:sync-only -- invite` (redime desde el sbot puro; publica un `contact`, legítimo porque local ≥ pub). Nunca `join-prod-client.sh` (necesita GUI) |
| ID-MISMATCH | el sbot no es tu feed | parar; revisar `docker volume inspect o-sdk_oasis-ssb-data-dev` |

La parada acaba en SIGKILL (PID 1 del contenedor es `su`): por eso `stop` exige estabilidad y
comprueba el último frame con `inspect-log-offset.js`. `log.offset` es append-only: un kill sin
escritura en curso es inocuo.

## 4. Upgrade del cliente

Misma imagen y mismo ciclo que el pub: `UPGRADE-PROTOCOL.md` §1-§3 (rama `upgrade/oasis-X.Y.Z`,
overlay, guards). Para el cliente:

```bash
docker tag o-sdk-oasis-client o-sdk-oasis-client:<ver-vieja>     # rollback preparado
npm run build && docker compose up -d oasis-client               # .ssb y ai-models son binds: se preservan
```

- Con el log intacto la GUI arranca directa: su `oasisVersion` cae en seq N+1.
- Si el upgrade obligó a apartar `flume/` (índices corruptos): `Settings › Rebuild database`
  (`POST /settings/rebuild`, no toca `log.offset`). Si se apartó el **log entero**, entonces §3 antes de la GUI.
- Healthcheck: §5. Journal: no aplica (el journal es del pub).

## 5. Healthcheck

```bash
docker ps --filter name=oasis-client --format '{{.Status}}'                       # healthy
curl -s http://localhost:3000/settings | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1   # versión
grep -o '"id": *"[^"]*"' volumes-dev/ssb-data/secret                             # = tu feed
npm run client:inspect-log -- '<tu-feed>'                                         # tailOk, mySeq
npm run devops:pub-feed-seq -- '<tu-feed>'                                        # seq_pub ≤ seq local (+ oasisVersion)
curl -s -X POST -H 'Referer: http://localhost:3000/settings' http://localhost:3000/settings/verify -o /dev/null && \
  curl -s http://localhost:3000/settings | grep -i -A3 'verification'             # sin gaps / broken links / forks (mine)
docker compose logs oasis-client | grep -c 'welcome-pm'                           # 0 tras una importación
npm run client:test-ai                                                            # POST /ai dentro del contenedor
```

Perfil sin nombre/avatar tras importar **no** es pérdida de identidad: los `about` son mensajes del
log; llegan con la replicación.

## 6. Rollback

- **Upgrade fallido**: `docker compose stop oasis-client` → `docker tag o-sdk-oasis-client:<ver-vieja> o-sdk-oasis-client` →
  `docker compose up -d --no-build oasis-client`. `.ssb` intacto (binds).
- **Importación fallida** (log corrupto al arrancar, `ID-MISMATCH`): `sync-only stop --now`; volver a
  `volumes-dev/ssb-data.pre-import-<ts>` (si lo había) o re-importar desde el backup
  `devops/backups/client/<ts>/`; en último caso solo `secret` + flag + §3.
- **Nunca** truncar `log.offset` ni tocar `secret`. Ningún camino de este protocolo cambia el `secret`.

## 7. Retirar instalaciones antiguas

Solo tras §5 en verde unos días y con backup verificado fuera de la máquina:

```bash
docker rm oasis-server-dev                                   # contenedor del cliente antiguo (otro repo)
docker rmi alephscript-clean-oasis-dev                       # su imagen (4,36 GB)
docker volume rm alephscript-clean_oasis-ssb-data-dev alephscript-clean_oasis-ai-models-dev alephscript-clean_oasis-logs-dev \
                 blockchaincomport_oasis-ssb-data-dev blockchaincomport_oasis-ai-models-dev blockchaincomport_oasis-logs-dev
docker network rm alephscript-clean_oasis-network blockchaincomport_oasis-network
```

Los volúmenes con nombre son **punteros** a directorios bind: borrarlos no borra los datos. El
directorio físico de origen se conserva como backup frío (solo lectura) hasta decisión del custodio;
sus `*.nul-damaged-bak` (5,7 GB) son los primeros candidatos a borrar.

## 8. Piezas

| Pieza | Fichero |
|---|---|
| Compose del cliente | `docker-compose.yml` (raíz) |
| Directorios de volúmenes | `client/scripts/setup.sh` (`npm run setup`) |
| Importar identidad | `client/scripts/import-identity.sh` (`npm run client:import-identity`) |
| Integridad y seq del log | `client/scripts/lib/inspect-log-offset.js` (`npm run client:inspect-log`) |
| Sbot puro / sincronización | `client/scripts/sync-only.sh` (`npm run client:sync-only`) |
| Sonda dentro del contenedor | `pub/tools/ssb-probe.js` (por stdin; pub, HUB o cliente; siempre `docker exec -u oasis -e HOME=/home/oasis`) |
| Seq de un feed en el pub | `devops/scripts/pub-feed-seq.sh` (`npm run devops:pub-feed-seq`) |
| Backup de identidad | `client/scripts/backup-keys.sh` (`npm run client:backup-keys`) |
| Prueba de IA | `client/scripts/test-ai-service.sh` (`npm run client:test-ai`) |
| Identidad GPG del usuario | `client/identity/init-gpg-key.sh` |
