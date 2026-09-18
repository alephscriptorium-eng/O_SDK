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

> **ECOin en el cliente · implementado en rama, drill pendiente** (WP-O103, 2026-09-18): dirección o
> cartera propia, independiente del VPS. Procedimiento y avisos en §8.

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
docker compose -p o-sdk ps -a                    # cliente: oasis-client (+ ecoin-wallet con el perfil ecoin, §8)
docker compose -p oasis-pub-scriptorium ps -a    # pub+HUB local: no debe ocupar 3000/8008 (usa 8009/8088/8443/8788 con pub/.env.local)
ls volumes-dev/                                  # cliente: ssb-data ai-models logs client-state · pub: oasis-pub oasis-hub teatro
docker volume inspect o-sdk_oasis-ssb-data-dev --format '{{index .Options "device"}}'   # = <repo>\volumes-dev\ssb-data (o no existe aún)
docker volume ls --filter label=o-sdk.role=client-wallet   # o-sdk-client-ecoin-data: la wallet.dat del cliente (§8), si se creó
```

| | Cliente | Pub + HUB (local) |
|---|---|---|
| Compose / proyecto | `docker-compose.yml` · `o-sdk` | `pub/docker-compose.pub.yml` · `oasis-pub-scriptorium` |
| Contenedores | `oasis-client`, `ecoin-wallet` | `oasis-pub-scriptorium`, `oasis-pub-hub`, `oasis-pub-hub-cache`, `oasis-pub-web`, `oasis-pub-panel-api` |
| Puertos host | 3000, 8008 (`ecoin-wallet` **no publica ninguno**: RPC 7474 y P2P 7408 solo en la red del compose, §8) | con `pub/.env.local`: 8009, 8088, 8443, 8788, 3001 (maint-ui) |
| `volumes-dev/` | `ssb-data`, `ai-models`, `logs`, `client-state` (la `wallet.dat` **no** vive aquí: volumen externo `o-sdk-client-ecoin-data`, §8) | `oasis-pub/*`, `oasis-hub/*`, `teatro` |
| Red | `o-sdk_oasis-network` | `oasis-pub-scriptorium_oasis_pub_net` |
| Imagen | `o-sdk-oasis-client` (mismo `Dockerfile`) | `oasis-pub-scriptorium:latest` |

**Regla**: el pub local siempre con `npm run pub:local:*` (`--env-file .env.local`). Sin `--env-file`
el compose del pub toma los defaults del VPS (8008/80/443) y choca con el cliente y con Windows.

## 1. Alta fresca (identidad nueva)

```bash
npm run build                    # imagen o-sdk-oasis-client (10-20 min la primera vez)
npm run setup                    # volumes-dev/{ssb-data,ai-models,logs,client-state/banking}; sin esto el bind falla
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
npm run build && docker compose up -d oasis-client               # .ssb, ai-models y client-state son binds: se preservan
```

- Con el log intacto la GUI arranca directa: su `oasisVersion` cae en seq N+1.
- Si el upgrade obligó a apartar `flume/` (índices corruptos): `Settings › Rebuild database`
  (`POST /settings/rebuild`, no toca `log.offset`). Si se apartó el **log entero**, entonces §3 antes de la GUI.
- La config de la GUI y el estado bancario viven en `volumes-dev/client-state` (§8.4): sobreviven al
  rebuild, y las claves nuevas que traiga upstream en `oasis-config.json` entran por el default de la imagen.
- Healthcheck: §5 (y `npm run client:ecoin:verify` si usas ECOin, §8). Journal: no aplica (el journal es del pub).

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

## 8. ECOin en el cliente

> **Estado · implementado en la rama `wp/O103-cliente-ecoin` (WP-O103, 2026-09-18); drill con
> identidad desechable pendiente (§8.9).** Nada de esta sección se ha ejecutado aún sobre la identidad
> real: la publicación de la dirección en el feed del custodio es una **puerta con confirmación
> expresa**. Doc hermana (el lado del banco): `PUB/ECOIN-PROTOCOL.md`. Asiento: D-O19.

> **Modelo mental.** Oasis 1.1.2 lee la cartera **solo** de `src/configs/oasis-config.json`
> (`wallet.{url,user,pass,fee}` y `walletPub.pubId`); las variables `ECOIN_RPC_*` no las lee nadie
> salvo el entrypoint, que las escribe ahí. Un mensaje SSB `wallet` con tu dirección es **permanente**
> y solo sirve si conservas la `wallet.dat` que tiene su clave: **una dirección publicada sin copia de
> su cartera queda huérfana para siempre**. Por eso el orden es siempre *cartera → backup → publicar*,
> y publicar se hace **una vez**.

El cliente tiene ECOin **independiente del VPS**, en dos niveles. El valor por defecto es el primero
sin nada cableado: `wallet.url = ""`, ningún RPC saliente, `/banking` sin latencia.

| | (i) Solo dirección | (ii) Cartera propia |
|---|---|---|
| Sirve para | aparecer, recibir y reclamar RBU | además saldo, envíos e historial (`/wallet/*` usa RPC) |
| `ecoind` propio | solo el rato de generar la dirección | corriendo siempre (perfil `ecoin`) |
| `.env` raíz | `COMPOSE_PROFILES=` · `ECOIN_RPC_URL=` | `COMPOSE_PROFILES=ecoin` · `ECOIN_RPC_URL=http://ecoin-wallet:7474` |
| Quién paga la RBU | el `ecoind` del banco (bot-2), nunca el tuyo | ídem |
| Coste | ninguno en reposo | ~50 MB de cadena, ~13 min de sync inicial (medido en el VPS), hasta 512 MB de memoria |

En los dos niveles la dirección sale de **una `wallet.dat` tuya**. Nunca publiques una dirección
cuya cartera no controlas ni tienes respaldada.

### 8.1 Nivel (i): solo dirección

Se arranca `ecoind` **sin cablear Oasis** (`ECOIN_RPC_URL` vacía), se saca una dirección, se respalda
la cartera, se para, y se da de alta la dirección a mano **una vez**.

```bash
npm run ecoin:build                                  # antepone ecoin:fetch-deb (sha256 del .deb verificado; imagen de WP-O102)
npm run client:ecoin:init -- --mode address          # .env raíz con credenciales generadas + volumen externo o-sdk-client-ecoin-data
npm run ecoin:up                                     # ecoin-init.sh --ensure + up -d --wait ecoin-wallet (healthy)
npm run ecoin:address                                # getnewaddress → APÚNTALA. Cada llamada genera OTRA: llámalo una vez
npm run client:wallet:backup                         # devops/backups/client-wallet/<TS>/ con sha256 y manifiesto (§8.6)
npm run ecoin:stop                                   # la wallet.dat queda en el volumen; no hace falta que siga corriendo
```

Después, con la GUI arriba, **una sola vez**: `http://localhost:3000/banking?filter=addresses` →
añadir tu feed y la dirección apuntada. Ese formulario (`POST /banking/addresses`) publica el mensaje
`wallet` **sin RPC** y **no es idempotente**: cada envío publica otro mensaje permanente. Comprueba
después con `npm run client:ecoin:verify` que hay **exactamente 1** mensaje `wallet` en tu feed.

Copia el backup **fuera de la máquina** antes de publicar. Para pasar más adelante al nivel (ii)
basta `client:ecoin:init -- --mode own`: la cartera es la misma y la dirección publicada sigue valiendo.

### 8.2 Nivel (ii): cartera propia

```bash
npm run ecoin:build
npm run client:ecoin:init -- --mode own              # COMPOSE_PROFILES=ecoin · ECOIN_RPC_URL=http://ecoin-wallet:7474
npm run ecoin:up                                     # healthy (hasta ~70 s); sincroniza la cadena en segundo plano
npm run client:wallet:backup                         # ANTES de abrir la GUI
docker compose up -d oasis-client                    # recrea el cliente: el entrypoint cablea wallet.url/user/pass (§8.3)
npm run client:ecoin:verify                          # RPC por DNS de servicio, config cableada, symlinks, nº de mensajes wallet
```

> **Aviso: abrir `/` llama a `getnewaddress`.** Con `wallet.url` respondiendo RPC, `GET /`
> (→ `/activity`) y `GET /banking` ejecutan `ensureSelfAddressPublished()`: pide una dirección nueva
> al `ecoind` y la guarda en el mapa `wallet-addresses.json`. En 1.1.2 la publicación automática
> **falla en silencio** (un `ReferenceError` en `banking_model.js`), pero una 1.1.3 puede arreglarla y
> **publicar de verdad** al abrir la GUI. Consecuencias: el backup va **antes** de abrir la GUI; tras
> abrirla, otro `npm run client:wallet:backup`; y antes de un upgrade de Oasis con el nivel (ii)
> activo, releer `PUB/ECOIN-PROTOCOL.md` (preflight de upgrades).

Publicar la dirección sigue siendo un acto manual y único: la que muestra `/wallet`, dada de alta en
`/banking?filter=addresses` **una vez** (misma advertencia de no idempotencia que en §8.1). Si ya
publicaste una dirección en el nivel (i) con esta misma cartera, **no publiques otra**.

### 8.3 Qué hace el entrypoint con cada variable

`docker-entrypoint.sh` (raíz; `src/` sigue con exactamente 4 guards) solo actúa si
`OASIS_CLIENT_STATE_DIR` está definido y el modo no es `server`. El pub, el HUB y bot-2 no lo
definen: para ellos nada cambia. Orden: `persist_client_state` → `wire_wallet_config` →
`setup_oasis_config`.

| Variable | Qué hace el entrypoint | Clave de `oasis-config.json` |
|---|---|---|
| `OASIS_CLIENT_STATE_DIR` (`/app/state`) | activa todo lo de esta tabla; crea y chowna el directorio; fusiona el default de la imagen con el `oasis-config.json` persistido (gana lo persistido) y deja `src/configs/oasis-config.json` como symlink al resultado | el fichero entero |
| `OASIS_BANKING_DIR` (`/app/state/banking`) | crea y chowna el directorio; siembra `wallet-addresses.json` con `{}` y enlaza `src/configs/wallet-addresses.json` a él (los dos mapas de Oasis pasan a ser uno) | — (lo lee `banking_model.js`) |
| `ECOIN_RPC_URL` | si está **definida, aunque vacía**, se asigna tal cual; pasa antes por la guarda anti-remoto | `wallet.url` |
| `ECOIN_RPC_USER` | se asigna junto a la URL; nunca se imprime | `wallet.user` |
| `ECOIN_RPC_PASS` | se asigna junto a la URL; nunca se imprime | `wallet.pass` |
| `OASIS_WALLET_FEE` | opcional; si viene, se asigna | `wallet.fee` |
| `OASIS_WALLET_PUB_ID` | si casa con el formato de feed ed25519 se asigna; vacía → no toca; inválida → aviso en el log y no toca | `walletPub.pubId` |
| `ECOIN_RPC_ALLOW_REMOTE` | solo el valor `i-know` desactiva la guarda anti-remoto | — |
| `OASIS_WALLET_WIRING` | `manual` → el entrypoint no toca `wallet.*` ni `walletPub.*` | — |
| `ECOIN_MEM_LIMIT` | no la lee el entrypoint: es el `mem_limit` de `ecoin-wallet` en el compose (512m por defecto) | — |
| `COMPOSE_PROFILES` | no la lee el entrypoint: `ecoin` hace que `docker compose up -d` levante también `ecoin-wallet` | — |

- **Guarda anti-remoto.** El host de `ECOIN_RPC_URL` debe ser `ecoin-wallet`, `localhost`,
  `127.0.0.1` o `host.docker.internal`. Cualquier otro → error en el log y `wallet.url = ""`.
- **Env manda.** Lo que teclees en `/settings/wallet` se **pisa en el siguiente arranque** con lo que
  diga el entorno. Es deliberado: la GUI no sabe vaciar `wallet.url` (solo el entrypoint puede poner
  `""`) y así las credenciales viven en un único sitio, el `.env` raíz (ignorado por git).
  Escape: `OASIS_WALLET_WIRING=manual` y gestionas la cartera desde la GUI bajo tu responsabilidad.
- El resto de la config de la GUI (tema, idioma, módulos) **no** se pisa: se persiste (§8.4).

### 8.4 Estado persistente: `volumes-dev/client-state`

Bind `./volumes-dev/client-state` → `/app/state`. Contiene `oasis-config.json` y `banking/`
(`wallet-addresses.json`, `banking-*.json`). Por qué existe:

- Sin `OASIS_BANKING_DIR`, el estado bancario vive en la capa efímera de la imagen: **cada recreate
  generaría otra dirección** (y, con una 1.1.3, otro mensaje `wallet`).
- Oasis mantiene **dos mapas** de direcciones (uno en `banking_model.js`, otro fijo en
  `src/configs/` para las rutas `/wallet*`); el symlink los unifica.
- La GUI reescribe `oasis-config.json` entero desde 11 rutas (tema, idioma, módulos…): un bind de
  solo lectura rompería la GUI, y `src/configs/` contiene código y guards, así que no se puede
  persistir el directorio. Se persiste **solo el fichero**, por symlink, y `setup_oasis_config` se
  reescribió en node porque `sed -i` rompe los symlinks.

`npm run setup` crea `client-state/banking`. `client:import-identity -- --force` aparta
`client-state/banking/wallet-addresses.json` (el mapa va por feed) y **no toca la cartera**.
`oasis-config.json` persistido lleva las credenciales RPC: `volumes-dev/` está ignorado por git; no lo compartas.

### 8.5 La `wallet.dat`: volumen nombrado externo

`wallet.dat` y la cadena viven en el volumen Docker **`o-sdk-client-ecoin-data`** (etiqueta
`o-sdk.role=client-wallet`), declarado `external` en el compose. Ya no existe `volumes-dev/ecoin-data`.

- **Por qué no un bind**: Berkeley DB sobre un bind de Windows (virtiofs) es frágil y lento; una
  `wallet.dat` corrupta es dinero perdido.
- **Por qué `external`**: `docker compose down -v` **no borra** volúmenes externos. Lo crea
  `client:ecoin:init`, no el compose; el cliente arranca igual sin el perfil y sin que el volumen exista.
- **Contrapartida**: un volumen nombrado vive dentro de la VM de Docker Desktop (WSL2) y **se pierde
  con un factory reset**. El backup al host (§8.6) es obligatorio, no opcional.
- `ecoin-wallet` **no publica puertos**: el RPC (7474) y el P2P (7408, solo saliente) quedan en
  `o-sdk_oasis-network`. El 12000 desaparece. Quien quiera P2P entrante añade `7408:7408` en un
  `docker-compose.override.yml` no versionado. **El RPC no se publica nunca.**
- Credenciales: generadas por `client:ecoin:init` (usuario `oasis-` + 8 hex, contraseña de 48 hex) en el
  `.env` raíz; la imagen arranca *fail-closed* (`ECOIN_REQUIRE_CREDS=1` rechaza vacío y `ecoinrpc`).
  `ecoin:info`, `ecoin:balance` y `ecoin:address` no llevan credenciales en la línea de comandos
  (`ecoind` las lee de su conf) y `ecoin:system` no vuelca `rpcpassword`.

### 8.6 Backup y restore de la cartera

```bash
npm run client:wallet:backup                                              # en caliente: backupwallet → docker cp → sha256 contenedor = host
npm run client:wallet:backup -- --cold                                    # con ecoind parado
npm run client:wallet:restore -- devops/backups/client-wallet/<TS>        # aparta la actual a wallet.dat.pre-restore-<TS>; nunca sobrescribe
```

Cada backup deja en `devops/backups/client-wallet/<TS>/` la cartera (`wallet-<TS>.dat`),
`SHA256SUMS.txt`, `MANIFEST.json` (`getinfo.blocks`, direcciones, imagen, volumen) y `RESTORE.txt`;
`npm run client:wallet:backup -- --verify` seguido del directorio recomprueba los sha256 sin tocar
Docker. El restore exige que el contenedor exista (`npm run ecoin:up` al menos una vez). Tras un restore: `validateaddress` de la dirección publicada debe dar
`ismine: true`.

- La copia **no está cifrada** y es **material de claves**: fuera de git (ya ignorado), fuera de
  cualquier imagen y con una copia fuera de la máquina.
- **Keypool**: una copia antigua solo conoce las claves pregeneradas hasta ese momento. Haz backup
  después de cada tanda de direcciones nuevas (y tras abrir la GUI por primera vez en el nivel ii).
- Cuándo: antes de publicar la dirección, antes de un upgrade, antes de cualquier `down`.
- `npm run client:backup-keys` respalda la identidad **SSB**, no la cartera (avisa si el volumen existe).

### 8.7 El banco del cliente: bot-2

La RBU de esta red la paga **`azofaifo-scriptorium-wallet-bot-2`**, feed
`@NYAqUzX7OACl+Fs866J8aVeKcqPxbbXccV/phcKx9UU=.ed25519` (`PUB/ECOIN-PROTOCOL.md`). Se fija con:

```bash
npm run client:ecoin:init -- --pub-id '@NYAqUzX7OACl+Fs866J8aVeKcqPxbbXccV/phcKx9UU=.ed25519'
docker compose up -d oasis-client          # OASIS_WALLET_PUB_ID → walletPub.pubId; aparece el botón de claim
```

- **Cada claim es un mensaje `ubiClaim`: irreversible**, como todo en SSB. Pulsar el botón publica.
- **Hoy el banco tiene el motor APAGADO**: bot-2 está desplegado con el motor de RBU armado y sin
  encender hasta la dote. Un claim hecho ahora **no se paga**; solo deja el mensaje. Espera al aviso
  de encendido (`PUB/ECOIN-PROTOCOL.md` §9).
- Quien paga es el `ecoind` del banco hacia tu dirección publicada: para cobrar basta el nivel (i).

### 8.8 Avisos

- **Nunca apuntes `ECOIN_RPC_URL` al `ecoind` del VPS.** Su RPC es HTTP plano y es un monedero único
  sin cuentas: tus credenciales viajarían en claro y quien las tenga maneja los fondos del banco. La guarda anti-remoto lo rechaza;
  `ECOIN_RPC_ALLOW_REMOTE=i-know` existe para laboratorio, no para esto.
- **Prohibido `docker system prune --volumes`** (y `docker volume prune`): es lo único que borra el
  volumen externo con tu `wallet.dat` si `ecoin-wallet` está parado. `npm run downDELETEVOLS` y
  `npm run cleanDELETEVOLS` pasan antes por `client/scripts/guard-destroy.sh`: lista qué sobrevive,
  exige escribir `BORRAR` y se niega si hay `wallet.dat` sin backup de menos de 24 h.
- **Los mensajes SSB son permanentes**: `wallet` (tu dirección) y `ubiClaim` no se borran ni se
  editan. Una dirección equivocada o duplicada se queda en tu feed y en el pub.
- **Abrir la GUI con el nivel (ii) activo llama a `getnewaddress`** (§8.2): backup antes.
- `.env` raíz: lo comparte todo el compose de la raíz. El pub usa su propio `--env-file` y no lo lee.

### 8.9 Drill con identidad desechable

Todo lo anterior se ensaya **antes** con una identidad que no es la tuya, en un proyecto compose
aparte que no comparte nada con el cliente real: proyecto `o-sdk-drill`, contenedores
`oasis-client-drill` y `ecoin-wallet-drill`, puertos `3100:3000` y `8108:8008`, binds en
`volumes-dev/drill/*`, volumen externo `o-sdk-drill-ecoin-data`, env-file `client/.env.drill` (no
versionado), sin GPU y con `OASIS_SKIP_AI_MODEL=true`. La identidad se crea vacía, con `gossip.json`
vacío y sin invite: **no replica con nadie y no ensucia la red**.

```bash
# SIEMPRE desde la raíz del repo, con los DOS -f (el drill es un override del compose raíz) y el --env-file
export MSYS_NO_PATHCONV=1
D="docker compose -p o-sdk-drill -f docker-compose.yml -f client/docker-compose.drill.yml --env-file client/.env.drill"
mkdir -p volumes-dev/drill/{ssb-data,ai-models,logs,client-state/banking}
[ -f volumes-dev/drill/ssb-data/gossip.json ] || echo "[]" > volumes-dev/drill/ssb-data/gossip.json
ECOIN_ENV_FILE=client/.env.drill ECOIN_VOLUME=o-sdk-drill-ecoin-data ECOIN_STATE_DIR=volumes-dev/drill/client-state \
  npm run client:ecoin:init -- --mode own          # credenciales y volumen del drill, no los reales
$D up -d --build
CLIENT_CONTAINER=oasis-client-drill ECOIN_CONTAINER=ecoin-wallet-drill HOST_GUI_PORT=3100 npm run client:ecoin:verify
ECOIN_CONTAINER=ecoin-wallet-drill npm run client:wallet:backup
ECOIN_VOLUME=o-sdk-drill-ecoin-data ECOIN_CONTAINER=ecoin-wallet-drill GUARD_DATA_DIR=volumes-dev/drill \
  bash client/scripts/guard-destroy.sh && $D down -v   # el volumen externo sobrevive
```

| # | Qué se comprueba en el drill |
|---|---|
| D1 | `ecoin:fetch-deb` y build |
| D2 | `docker port ecoin-wallet-drill` vacío; el host no alcanza 7474/7408/12000; RPC 200 por DNS de servicio desde `oasis-client-drill`; `ecoinrpc` → 401 |
| D3 | config cableada y symlinks (`client:ecoin:verify`) |
| D4 | `/wallet` con saldo 0 y dirección; publicar **una vez**; exactamente 1 mensaje `wallet` |
| D5 | `--force-recreate` y rebuild: sobreviven tema, config de cartera y mapa; sigue habiendo 1 mensaje |
| D6 | `down -v` con guard: `wallet.dat` intacta |
| D7 | backup → volumen nuevo (otra dirección) → restore → `ismine: true` |
| D8 | sin perfil: arranca, `/banking` sin latencia, cableado omitido |
| D9 | guarda anti-remoto: URL remota → `wallet.url = ""` |

**Puerta**: solo con D1-D9 en verde y **confirmación expresa del custodio** se pasa a la identidad
real, en este orden: `client:backup-keys` → `client:ecoin:init` → `ecoin:up` → **backup de cartera
antes de publicar** → publicar una vez → 1 mensaje `wallet` en el feed y replicado al pub → después,
`--pub-id` de bot-2. El primer claim real es otra confirmación aparte.

## 9. Piezas

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
| ECOin: credenciales, volumen y modo | `client/scripts/ecoin-init.sh` (`npm run client:ecoin:init`; `--mode address` o `--mode own`, `--pub-id`, `--ensure`) |
| ECOin: backup y restore de la cartera | `client/scripts/backup-wallet.sh` (`npm run client:wallet:backup`, `npm run client:wallet:restore`) |
| ECOin: verificación de los CA | `client/scripts/ecoin-verify.sh` (`npm run client:ecoin:verify`) |
| ECOin: guarda de borrado | `client/scripts/guard-destroy.sh` (antes de `downDELETEVOLS` y `cleanDELETEVOLS`) |
| ECOin: cableado de la config | `docker-entrypoint.sh` (`persist_client_state`, `wire_wallet_config`, `setup_oasis_config`) |
| ECOin: plantilla de entorno | `.env.example` (raíz) → `.env` (ignorado) |
| ECOin: drill | `client/docker-compose.drill.yml` + `client/.env.drill` (no versionado) |
| ECOin: imagen de `ecoind` | `ecoin/` (endurecida en WP-O102; se reutiliza tal cual) |
| Identidad GPG del usuario | `client/identity/init-gpg-key.sh` |
