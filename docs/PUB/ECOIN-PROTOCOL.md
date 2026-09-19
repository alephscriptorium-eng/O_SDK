# Protocolo de ECOin (hub-wallet del pub)

> **Este repo es el sitio del hub-wallet** (`C:\S_LAB\o-sdk`,
> `https://github.com/alephscriptorium-eng/O_SDK.git`). El hub-wallet **no tiene puerta web**:
> vive dentro de la red Docker del pub y solo se ve por lo que su bot publica en SSB.

> **Estado · ACTIVADO 2026-09-18 18:06 UTC** en el VPS de `pub.escrivivir.co` (WP-O102, rama
> `wp/O102-hub-wallet`). `azofaifo-scriptorium-wallet-bot-2` =
> `@NYAqUzX7OACl+Fs866J8aVeKcqPxbbXccV/phcKx9UU=.ed25519` · dirección ECOin de la cartera del pub
> `EYdruXgDVQGhBpSsns83VA1BmDfAKBP4Lc` (publicada en su feed, saldo 0) · `ecoind` sincronizado.
> **Motor de RBU**: se gobierna con `devops/scripts/hub-wallet.sh` (§9, reescrito para Oasis 1.1.4);
> su estado vigente está en §13 y se mide con `hub-wallet.sh status`. Registro en §13, hallazgos en §14, reporte
> `plan/REPORTES/WP-O102-hub-wallet.md`. Decisiones: `plan/DECISIONES.md` **D-O19**. Siguiente
> pieza: WP-O103 (ECOin en la app cliente; procedimiento en `../CLIENT-PROTOCOL.md` §8 «ECOin en el cliente»).

Checklist operativo para **activar, operar, respaldar y llevar a través de los upgrades** el
proveedor de ECOin del pub: un `ecoind` 0.0.4 en contenedor propio y una cuenta SSB de soporte
(`azofaifo-scriptorium-wallet-bot-2`) que es la única que le habla. Es el hermano de
`HUB-PROTOCOL.md` y reutiliza su método: contenedor propio, estado en el volumen de datos, el pub
no se toca.

> **Modelo mental.** Oasis 1.1.2 trae Wallet, Banking y RBU, pero el motor de la RBU **solo vive en
> `backend.js`** y el pub corre **solo el sbot**: el pub no puede ejecutarlo. Lo ejecuta **otra
> cuenta SSB**, el *hub-wallet*, en su contenedor `oasis-pub-wallet-bot`: **misma imagen** que el
> pub y que el HUB, `command: ["backend"]`, `.ssb` propio en `/srv/oasis/oasis-wallet-bot`. A su
> lado, `oasis-pub-ecoin` corre `ecoind` con la cadena y la `wallet.dat` en `/srv/oasis/ecoin`. El
> bot habla con `ecoind` por RPC (`http://ecoin:7474`) **dentro de `oasis_pub_net`**; nada se
> publica al host ni pasa por Caddy. Para la red SSB el bot es un habitante más: redime un invite
> del pub, recibe follow-back, replica a hops 3 y, cuando el motor esté encendido, firma la RBU
> con **su** feed. El motor nace **armado y apagado**: un solo valor de `.env.prod` lo enciende.

## 0. Cómo hemos llegado aquí (evolución)

| Cuándo | Hito | Dónde queda |
|---|---|---|
| Abril 2026 | Imagen `ecoin/` (Dockerfile, entrypoint, conf) verificada para el cliente; el `.deb` fuera de git y sin checksum, credenciales `ecoinrpc` en git, sin límites ni backup | `ecoin/` |
| 2026-09-17 | Oasis 1.1.2 en `src/` (WP-O97): Wallet, Banking y RBU disponibles | `plan/REPORTES/WP-O97-upgrade-oasis-1.1.2.md` |
| 2026-09-18 | Nota de upstream a los operadores de pub · tres exploraciones · decisiones del custodio | D-O19 |
| 2026-09-18 | WP-O102 implementado en rama (imagen endurecida, dos servicios con perfil `wallet`, herramientas) | este doc |
| ⏳ | Deploy en el VPS (§3) · dote · encendido del motor (§9) · WP-O103 (cliente) | §13 |

**La nota de upstream.** El autor de Oasis pide a los operadores de pub tener un `ecoind` 0.0.4
corriendo junto al pub, y anuncia que la **1.1.3** lo autodetectará. La 1.1.3 **no tiene fuente
publicada todavía**: el mecanismo de esa autodetección es desconocido. Por eso el cableado se hace
**genérico sobre 1.1.2** (lo único que existe y se puede leer) y la 1.1.3 se analiza al salir con
la tabla de contingencia de §5.3.

**Las tres exploraciones** (lectura del árbol 1.1.2, sin ejecutar nada en el VPS):

1. *Cómo se conecta Oasis a ecoind.* **Solo** por `oasis-config.json`: `wallet.url`, `wallet.user`,
   `wallet.pass`, `wallet.fee` y `walletPub.pubId` (`src/configs/oasis-config.json:65-73`). No hay
   variables de entorno ni autodetección en 1.1.2: las `ECOIN_RPC_*` de `docker-compose.yml:47-49`
   (raíz, cliente) están muertas.
2. *Dónde vive el motor.* `runPubEngineTick` está en `src/backend/backend.js:11738-11747` (tick a
   los 15 s del arranque y cada 30 min) y exige `isPubNode()`, es decir `walletPub.pubId` igual al
   feed del proceso (`src/models/banking_model.js:214-218`). El estado bancario se escribe en
   `OASIS_BANKING_DIR` o, si falta, **dentro de la imagen** (`banking_model.js:23`, capa efímera).
   Abrir la GUI publica la dirección sola: `GET /activity` y `GET /banking` llaman a
   `ensureSelfAddressPublished` (`backend.js:4455`, `backend.js:7267`) en cuanto `wallet.url` responde.
3. *Qué le faltaba a `ecoin/`.* `.deb` sin checksum, credenciales por defecto en git, puerto P2P
   real 7408 (no 12000), sin límites de memoria/CPU, sin cierre limpio de BDB y sin backup de
   `wallet.dat`.

**Decisiones del custodio (D-O19, 2026-09-18)**: 1) `ecoind` en contenedor propio · 2) bot nuevo
`azofaifo-scriptorium-wallet-bot-2` = hub-wallet, sin ruta pública · 3) los bots Azofaifo **son**
la representación oficial de `pub.escrivivir.co`: que la RBU la firme el feed del bot es lo querido
· 4) cableado genérico ya sobre 1.1.2; la 1.1.3 se analiza al salir · 5) motor **armado y
apagado** hasta la dote · 6) bot a **hops 3** · 7) orden: imagen compartida + VPS (WP-O102),
después cliente (WP-O103).

## 1. Invariantes (lo que todo cambio futuro debe conservar)

- **El pub no se toca.** Ningún servicio nuevo monta nada de `/srv/oasis/oasis-pub`; el servicio
  `oasis-pub`, su imagen y su entrypoint no cambian; el pub **no se reinicia** en ningún paso
  (deploy, encendido del motor, backup, rollback). Tampoco cambian `oasis-hub`, `hub-cache`,
  `pub/config/hub/*` ni el Caddyfile.
- **`ecoind` en contenedor propio** (`oasis-pub-ecoin`), con límites propios (`mem_limit`, `cpus`,
  `-maxconnections`): ni el pub ni el HUB pagan su sincronización ni su memoria.
- **El RPC nunca sale de la red Docker.** El servicio `ecoin` **no tiene `ports`**; el RPC (7474)
  solo es alcanzable por nombre de servicio desde `oasis_pub_net`; el P2P (7408) es solo saliente
  en fase 1. Credenciales RPC hexadecimales generadas **en el VPS** (`openssl rand -hex 32`),
  solo en `.env.prod` y en la config renderizada fuera de git. El default `ecoinrpc` se rechaza
  (`ECOIN_REQUIRE_CREDS=1` → exit 1).
- **bot-2 sin ruta pública.** `oasis-wallet-bot` no tiene `ports` ni bloque en Caddy. Su GUI solo
  se usa desde el loopback del contenedor (`docker exec`) durante el bootstrap; en régimen corre
  con `OASIS_PUBLIC=true` (todo no-GET → 403).
- **Los bots Azofaifo son la representación oficial del pub**, y **la RBU la firma el bot**: los
  `ubiAllocation`, `ubiClaimResult`, `bankClaim` y `transfer` de la RBU salen del feed de bot-2, no
  del feed del pub. Desde 1.1.3 los clientes **descubren solos** el banco por los `pubAvailability` replicados.
- **El motor se enciende y se pausa, nunca por accidente.** El interruptor es el ssb-config montado
  (`pub: false` = `isPubNode()` falso = ni tick ni pagos ni `pubAvailability`). Se enciende solo con
  confirmación expresa del custodio y `hub-wallet.sh on --yes` (§9).
- **Hops 3, política asumida.** Con el motor encendido el bot paga **cualquier** `ubiClaim` que vea
  en su log (§9, §12). La defensa no es un filtro, es el tamaño de la cartera.
- **Cartera caliente, sin cifrar, saldo pequeño.** Sin `encryptwallet` (el motor no sabe
  desbloquear). `wallet.dat` a 600, datadir a 700, uid 1000. El saldo es el que se acepta perder.
- **`wallet.dat` nunca se borra.** Ningún script hace `rm` sobre ella; restaurar es **apartar** a
  `wallet.dat.bak-<fecha>`. El `secret` del bot tampoco se borra: ambos sobreviven a cualquier rollback.
- **Tipos permitidos en el feed de bot-2.** Motor **apagado**: `contact`, `pub`, `about`,
  `oasisVersion`, `wallet`, `karmaScore`. Motor **encendido**, además: `pubAvailability`,
  `ubiAllocation`, `ubiClaimResult`, `bankClaim`, `transfer` (con tag `UBI`). **Nunca** `private`
  ni `post`. Contraevidencia: mensajes filtrados por `author` = feed de bot-2 sin otro `type`.
- **Identidad propia y nombre de serie** (D-O14): `secret` nacido en
  `/srv/oasis/oasis-wallet-bot/ssb-data`; fila 2 del registro de `HUB-PROTOCOL.md` §11.
- **Delta del fork en `src/`: cero.** Todo vive en la zona *wholesale* (`ecoin/**`, `pub/**`,
  `devops/**`). Los 4 guards de `UPGRADE-PROTOCOL.md` §2 siguen siendo los únicos.

## 2. Piezas (fuente única)

| Pieza | Fichero | Qué fija | Estado |
|---|---|---|---|
| Binario verificado | `ecoin/ecoin_0.0.4-1_amd64.deb.sha256` · `ecoin/fetch-deb.sh` · `ecoin/ecoin_0.0.4-1_amd64.deb.txt` (URL) | sha256 `ccc6b3bc09194ddf3d2872495f44df8a594dd735d0d438a94865daab1a14ede1` (2 835 896 B); el `.deb` está gitignored; `fetch-deb.sh` descarga con `curl -fL`, comprueba y **borra si no casa** | ✅ rama |
| Imagen `ecoin` | `ecoin/Dockerfile` | `sha256sum -c` tras el `COPY` (el build falla con otro binario); conf completa también en `/usr/share/ecoin/ecoin.conf.default` (un bind del datadir no la tapa); `EXPOSE 7474 7408`; healthcheck sin credenciales por defecto | ✅ rama |
| Arranque de `ecoind` | `ecoin/docker-entrypoint.sh` · `ecoin/ecoin.conf` | siembra la conf **completa** si falta; `umask 077`, conf a 600; fail-closed con `ECOIN_REQUIRE_CREDS=1`; `port=7408` explícito; `rpcallowip=172.16.*`…`172.31.*` con comodines (este ecoind no entiende CIDR: con `172.16.0.0/12` daba 403 a toda la red Docker); marcadores en vez de credenciales | ✅ rama |
| Servicio `ecoin` (`oasis-pub-ecoin`) | `pub/docker-compose.pub.yml` | `profiles: ["wallet"]`, `build: ../ecoin`, **sin `ports`**, bind `OASIS_ECOIN_DATA_DIR` → `/home/ecoin/.ecoin`, `mem_limit 512m`, `cpus 0.75`, `-maxconnections=16`, `stop_grace_period 60s`, `logging 10m×3`, healthcheck `getinfo` con `start_period 600s` | ✅ rama |
| Servicio `oasis-wallet-bot` (`oasis-pub-wallet-bot`) | `pub/docker-compose.pub.yml` | copia del patrón `oasis-hub`: misma imagen, `command: ["backend"]`, `profiles: ["wallet"]`, sin `ports`, `OASIS_ALLOW_HOST=localhost`, `OASIS_BANKING_DIR=/app/banking`, `mem_limit 768m`, `cpus 1.0`, `NODE_OPTIONS=--max-old-space-size=512` | ✅ rama |
| Identidad y replicación | `pub/config/wallet-bot/ssb-config` (bind `:ro`) | copia del del HUB: `friends.hops: 3`, `host 0.0.0.0`, **sin `seeds`**, mismo `caps.shs` (lockstep de rotación, `HUB-PROTOCOL.md` §5.2) | ✅ rama |
| Config del bot (plantilla) | `pub/config/wallet-bot/oasis-config.json.tpl` | copia de `src/configs/oasis-config.json` con `aiMod/aiNavMod off`, `lanBroadcasting false`, `ssbLogStream.limit 20000`, `bankingMod/walletMod on`, `wallet.url "http://ecoin:7474"` y tres marcadores: `__ECOIN_RPC_USER__`, `__ECOIN_RPC_PASS__`, `__WALLET_BOT_PUB_ID__` | ✅ rama |
| Render de la config | `pub/scripts/render-wallet-bot-config.sh` (npm `pub:wallet-bot:render`) | rellena la plantilla desde el env-file, valida hex y la regex del feed, escribe **in place** y a 400 en `OASIS_WALLET_BOT_OASIS_CONFIG_FILE` (fuera de git), aborta si el destino es un directorio. Se monta `:ro` en `/app/src/configs/oasis-config.json` | ✅ rama |
| Normalizar `conn.json` tras el invite | `pub/tools/hub-conn-fix.js` | **sin cambios**: el del HUB | ✅ |
| Variables | `pub/.env.vps.example`, `.env.local.example`, `.env.example`; `.env.prod` del VPS | `OASIS_ECOIN_{DATA_DIR,RPC_USER,RPC_PASS,MEM_LIMIT,CPUS,MAXCONNECTIONS}` · `OASIS_WALLET_BOT_{SSB_DATA,LOGS,BANKING}_DIR` · `OASIS_WALLET_BOT_{SSB_CONFIG,OASIS_CONFIG}_FILE` · `OASIS_WALLET_BOT_PUB_ID` (**interruptor**) · `OASIS_WALLET_BOT_{MEM_LIMIT,NODE_OPTIONS}` · `OASIS_WALLET_BOT_PUBLIC` (comentada) | ✅ rama |
| Validación de rutas | `pub/scripts/common.sh` · `devops/scripts/verify-debian13-base.sh` (`check_layout`) | rutas nuevas absolutas bajo `/srv/oasis` (solo si están definidas); `wallet.dat` 600 / uid 1000 (solo si existe) | ✅ rama |
| Backup de la cartera | `devops/scripts/backup-ecoin.sh` (npm `devops:backup:ecoin`) | RPC `backupwallet` → `devops/backups/ecoin/<TS>/` con sha256 remoto = local, `RESTORE.txt`, metadatos; `--cold`, `--verify` (§8) | ✅ rama |
| Control de disco | `devops/scripts/ecoin-disk.sh` (npm `devops:ecoin-disk`) | cadena, `wallet.dat`, `getinfo`, memoria; `--local`, `--json` → `devops/logs/ecoin-disk.jsonl` (§6) | ✅ rama |
| Gobierno | `plan/BACKLOG.md` WP-O102 / WP-O103 · `plan/DECISIONES.md` D-O19 · `CHANGELOG.md` · `HUB-PROTOCOL.md` §11 fila 2 | | ✅ 2026-09-18 |

```
/srv/oasis/                       volumen de datos (40 GB, ext4 por UUID en fstab)
├── oasis-pub/                    estado del pub (INTACTO)
├── oasis-hub/                    estado del HUB (INTACTO)
├── teatro/                       obras estáticas (TEATRO-PROTOCOL)
├── ecoin/                        datadir de ecoind · uid 1000 · 700
│   ├── wallet.dat                LA CARTERA · 600 · nunca se borra · backup §8
│   ├── ecoin.conf                sembrada por el entrypoint · 600 · lleva las credenciales RPC
│   └── blk*.dat · txleveldb/ · peers.dat · debug.log     cadena: re-derivable de la red
└── oasis-wallet-bot/             estado de azofaifo-scriptorium-wallet-bot-2
    ├── ssb-data/                 secret · flume/ · blobs/ · conn.json · gossip.json · oasis-first-contact
    ├── logs/                     bind de /app/logs
    ├── banking/                  OASIS_BANKING_DIR: wallet-addresses.json, épocas, transferencias (uid de oasis)
    └── config/oasis-config.json  RENDERIZADO fuera de git · 400 · lleva las credenciales RPC
/opt/oasis-scriptorium/OASIS_PUB/ código y configs (layout vivo pre-refactor)
    ├── docker-compose.pub.yml    + ecoin, oasis-wallet-bot (perfil wallet)
    ├── config/wallet-bot/        ssb-config · oasis-config.json.tpl
    └── ../ecoin/                 contexto de build de la imagen (build: ../ecoin)
```

Regla de los binds **de fichero** (`ssb-config`, `oasis-config.json` renderizado): sobrescribir
**in place**, nunca reemplazar el inode (`HUB-PROTOCOL.md` §2). El perfil `wallet` hace que
`pub:local:up` y el `deploy.sh` no arrastren estos servicios ni exijan el `.deb`: todo comando
sobre ellos lleva `--profile wallet`.

## 3. Activación (resumen; parada dura ante cualquier desviación)

```
G0  gates locales (Docker Desktop, MSYS_NO_PATHCONV=1) — bloqueantes:
    G1 sintaxis + build con hash bueno y build QUE FALLA con hash alterado; pub:local:up sin perfil intacto
    G2 ecoind healthy · RPC 200 desde la red · nada publicado al host · ecoinrpc → 401 · sin credenciales → exit 1
    G3 bootstrap del bot · motor apagado (cero pubAvailability) · dirección publicada UNA vez ·
       up --force-recreate conserva banking/ y no genera otra dirección · ensayo del interruptor
    G4 aislamiento (stop ecoin / stop bot → pub y HUB intactos) · G5 backup y restore de wallet.dat
       (misma dirección, ismine:true) · G6 CPU/memoria durante el sync con cpus 0.75
1   líneas base: deploy-status · df · free -m (≥ 2 GB disponibles) · StartedAt del pub · uid 1000 libre
    para ecoin y uid de oasis en la imagen
2   mkdir /srv/oasis/ecoin (uid 1000, 700) y /srv/oasis/oasis-wallet-bot/{ssb-data,logs,banking,config}
    (uid de oasis; el entrypoint NO hace chown de banking/) · PRE-CREAR ssb-data/oasis-first-contact
3   .env.prod: backup .bak-wallet-<fecha> · bloques OASIS_ECOIN_* y OASIS_WALLET_BOT_* · credenciales
    generadas EN EL VPS (openssl rand -hex 32) · OASIS_WALLET_BOT_PUB_ID vacío
4   subir compose DIFFEADO contra el vivo (backup previo) + config/wallet-bot/* + ecoin/ + render ·
    $C config: los 5 servicios existentes sin cambios
5   fetch-deb.sh (sha256) + $C --profile wallet build ecoin · PARAR si / > 70 %
6   $C --profile wallet up -d --no-deps ecoin → healthy y getinfo connections ≥ 1
7   bootstrap del bot (abajo) + dirección publicada + BACKUP de wallet.dat
8   OASIS_WALLET_BOT_PUBLIC=true · gate 302-error/400 · motor APAGADO verificado
9   invariantes: pub sin reiniciar · +1 contact en el pub · HUB, Caddy y los 6 vhosts intactos
10  memoria del HUB 1536m → 768m (§7)
11  ecoin-disk.sh status --json (línea base) · deploy-log.sh … --mode server+hub+wallet
```

Reglas fijas (las del HUB): **siempre**
`docker compose --env-file .env.prod -f docker-compose.pub.yml --profile wallet up -d --no-deps <svc>`;
**nunca** el `deploy.sh` del VPS; **Caddy no se toca**; backups `*.bak-wallet-<fecha>` de todo
fichero pisado; binds de fichero in place.

**Bootstrap del bot = el del HUB tal cual** (`HUB-PROTOCOL.md` §3 paso 3, `pub/tools/hub-conn-fix.js`
sin cambios), con `oasis-wallet-bot` donde dice `oasis-hub`:

1. Flag `ssb-data/oasis-first-contact` pre-creado (evita el PM de bienvenida).
2. `OASIS_WALLET_BOT_PUBLIC=false` y `up -d --no-deps oasis-wallet-bot`.
3. Invite en el pub con `/app/OASIS_PUB/tools/ssb-admin.js`; host reescrito a la **IP del bridge**
   del pub; `POST /settings/invite/accept` con Referer desde el loopback del bot.
4. Verificar **por estado** (`conn.json` del bot y `contact` +1 en el pub con `grep -a -o | wc -l`,
   nunca `grep -c` sobre el log binario).
5. `hub-conn-fix.js 'net:oasis-pub:8008~shs:<KEY del pub>'` → `docker restart oasis-pub-wallet-bot`
   → CONNECTED en el log del pub.
6. `about`: `name` = `azofaifo-scriptorium-wallet-bot-2`; descripción: cartera ECOin del pub,
   custodia la dote, reparte la RBU, no escribe en el pub; serie de bots. Sin `vis_*`.
7. Con `ecoind` healthy y **sincronizado** (`blocks` ≥ altura que anuncian los pares, que sale de las
   líneas `receive version message … blocks=N` de `docker logs oasis-pub-ecoin`; **no** de `height=`,
   que es la altura propia y da un falso «sincronizado»; `healthy` solo
   dice que el RPC responde): `GET /banking` **desde el loopback** (`Host: localhost:3000`) guarda la
   dirección en `banking/wallet-addresses.json`. **No la publica**: el camino automático falla en
   silencio por el `ReferenceError` de §12.4 (comprobado en G3). Ese primer GET crea dos direcciones
   en la cartera; la válida es la que queda en `wallet-addresses.json`.
8. Publicarla: `POST /banking/addresses` (solo loopback, Referer y Host con el **mismo** host:puerto)
   **EXACTAMENTE UNA VEZ**. No es idempotente: responde «exists» y aun así publica otro `wallet`.
   Comprobar: un mensaje `wallet` con `author` = bot y `validateaddress` → `ismine: true`.
9. **Backup de `wallet.dat` DESPUÉS de generar la dirección y ANTES de comunicarla a nadie** (§8).
   Un backup anterior al paso 7 no contiene esa clave. Una dirección publicada sin copia de su clave
   es una dote que se puede perder.
10. `OASIS_WALLET_BOT_PUBLIC=true` + `up -d --no-deps`; gate con `Host: localhost:3000` y
    `Referer: http://localhost:3000/invites`: 302 con `?error=` de modo público. Si el host del
    Referer no coincide exactamente con `Host` devuelve 403 con el mismo texto; sin Referer, 400.
    Cualquier 200 = no seguir.
11. **No ensayar el interruptor en el VPS antes de la dote.** Encenderlo con saldo 0 deja fijado el
    epoch del mes con pool 0 y una `ubiAllocation` de 1 ECO del bot a sí mismo (visto en G3).

**Hito posterior, con confirmación expresa del custodio**: dote de Irkä a la dirección publicada
→ encender el motor (§9) → ensayo E2E con el cliente (WP-O103).

## 4. Verificación

```bash
C="docker compose --env-file .env.prod -f docker-compose.pub.yml --profile wallet"
docker ps --format '{{.Names}} {{.Status}}'             # los 7 de siempre + oasis-pub-ecoin + oasis-pub-wallet-bot, healthy
docker port oasis-pub-ecoin ; docker port oasis-pub-wallet-bot   # vacío · vacío
curl -sS -m 3 http://127.0.0.1:7474/ ; echo "rc=$?"     # desde el HOST: rechazado (rc 7)
docker exec oasis-pub-ecoin sh -c 'ecoind -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" getinfo' \
  | grep -E '"(blocks|connections|balance)"'             # connections ≥ 1
docker exec oasis-pub-wallet-bot node -e 'const c=require("/app/src/configs/oasis-config.json");console.log(JSON.stringify(c.walletPub),c.wallet.url)'
                                                        # {"pubId":""} http://ecoin:7474  ← motor apagado
docker inspect -f '{{.State.StartedAt}}' oasis-pub-scriptorium   # = línea base: el pub no se reinició
bash devops/scripts/ecoin-disk.sh check                 # 0
ls devops/backups/ecoin/                                # al menos un <TS>/ con wallet.dat + SHA256SUMS.txt + RESTORE.txt
```

Feed de bot-2 (desde el contenedor, con `ssb-admin.js` o leyendo el log): solo los tipos del
invariante de §1 y **cero `pubAvailability`** mientras el motor esté apagado. Fuera:
`https://pub.escrivivir.co/c` y los 6 vhosts igual que antes. Aislamiento: `docker stop oasis-pub-ecoin`
o `docker stop oasis-pub-wallet-bot` no afectan a `whoami`/`invite` del pub ni a `/c`.

## 5. Upgrades de Oasis con el hub-wallet activo (leer junto a `UPGRADE-PROTOCOL.md` y `HUB-PROTOCOL.md` §5)

El hub-wallet **no añade guards** a `src/`, pero depende de comportamientos de upstream que no son
API estable. La imagen es compartida: aplica también todo `HUB-PROTOCOL.md` §5.1 (modo `backend`,
sbot embebido, `OASIS_*`).

**5.1 Antes del merge (preflight del hub-wallet).** Sobre el árbol nuevo, cada línea debe dar ≥ 1
(verificadas sobre 1.1.2 el 2026-09-18 y rehechas para **1.1.4** el 2026-09-19, §5.4):

```bash
grep -c 'async function runPubEngineTick' src/backend/backend.js          # el motor sigue en backend.js…
grep -c 'bankingModel.isPubNode()' src/backend/backend.js                 # …y sigue condicionado a isPubNode
grep -c 'function isPubNode' src/models/banking_model.js                  # el interruptor sigue siendo isPubNode()…
grep -c 'config?.pub === true' src/models/banking_model.js                # …y desde 1.1.3 es pub:true del ssb-config + wallet.url (antes walletPub.pubId)
grep -c 'migrateAll' src/backend/backend.js                               # desde 1.1.3 el estado se muda a ~/.ssb/oasis/** al arrancar
grep -c '"url": "http://localhost:7474"' src/configs/oasis-config.json    # wallet.url sigue siendo config (la plantilla lo pisa)
grep -c 'process.env.OASIS_BANKING_DIR' src/models/banking_model.js       # estado bancario fuera de la capa efímera
grep -c 'messagesByType({ type: "ubiClaim"' src/models/banking_model.js   # cómo ve el motor los reclamos (todo el log)
grep -c 'const isLoopbackRequest' src/backend/backend.js                  # escrituras de banking solo desde loopback
grep -c '.post("/banking/addresses"' src/backend/backend.js               # ruta que fija/publica la dirección
grep -c 'ensureSelfAddressPublished' src/backend/backend.js               # autopublicación de la dirección al abrir la GUI
grep -c 'oasis-first-contact' src/models/onboarding_model.js              # flag anti-PM de bienvenida
grep -c 'exec node backend.js' docker-entrypoint.sh                       # modo backend del entrypoint (nuestro)
```

Si alguna cae a 0, la pieza afectada de §2 se adapta **en la misma rama del upgrade** y se repite
el gate G3 en local (bootstrap + motor apagado + ensayo del interruptor).

**5.2 Ficheros derivados de upstream que se regeneran en cada upgrade.**

- `pub/config/wallet-bot/oasis-config.json.tpl` **es una copia** de `src/configs/oasis-config.json`
  con las claves fijadas de §2. Tras el overlay: copiar el nuevo, re-aplicar las claves y los tres
  marcadores, **re-renderizar** y comprobar que el diff contra el original son solo esas claves.
- `pub/config/wallet-bot/ssb-config`: mismas reglas que el del HUB (arrays enteros; `caps.shs` en el
  lockstep de rotación, `HUB-PROTOCOL.md` §5.2).
- Orden de deploy: pub → HUB → **bot al final**
  (`$C up -d --no-deps oasis-wallet-bot`); `ecoin` no depende de la imagen de Oasis y **no se recrea**
  en un upgrade de Oasis. Tras recrear el bot: mismo feed id, `banking/` intacto, **cero** mensajes
  `wallet` nuevos.

**5.3 Tabla de contingencia 1.1.3** (escrita antes de que hubiera fuente; **resuelta el 2026-09-19**: se
cumplió la primera fila —no hay autodetección, `wallet.*` sigue siendo config— y apareció un caso que la
tabla no previó, la última fila):

| Si la 1.1.3… | Qué hacemos | Coste |
|---|---|---|
| sigue leyendo `wallet.*` de `oasis-config.json` | **nada**: es el cableado actual | 0 |
| sondea `localhost:7474` | `network_mode: "service:ecoin"` en `oasis-wallet-bot` (comparten pila de red; `ecoin` sigue sin `ports`) | compose, 1 recreate del bot; revisar `rpcallowip` |
| lee un `ecoin.conf` local para sacar credenciales | bind `:ro` de `/srv/oasis/ecoin/ecoin.conf` en la ruta que espere | compose, 1 recreate del bot |
| lanza (`spawn`) su propio `ecoind` | **no soportado**: rompe «ecoind en contenedor propio»; se desactiva por config o se reporta a upstream antes de subir | decisión del custodio |
| **(lo que pasó)** cambia el interruptor: desaparece `walletPub`; el motor corre si `pub: true` en el ssb-config y `wallet.url` no está vacía | con `pub: false` el motor queda **apagado**; `walletPub` sobrante se ignora. Interruptor nuevo y gestión de admin: §9 (WP-O107, D-O21) | 0 para seguir apagado |

En todos los casos: el motor se **apaga** antes del upgrade del bot si hay dudas (§9) y se
re-enciende tras verificar; la cartera no se mueve.

**5.4 Lo que cambió en 1.1.3-1.1.4 y cómo se sube** (WP-O105).

- **Estado bancario**: pasa a `~/.ssb/oasis/banking/` (`src/configs/state-manager.js`; migra solo desde
  `~/.ssb/` y `src/configs/`, **no** desde `$OASIS_BANKING_DIR`). `backend.js` ignora esa variable y
  `banking_model.js` no: con ella habría dos mapas de direcciones, y un mapa vacío hace que el primer
  `GET /banking` pida otra dirección a `ecoind`. Por eso el compose **ya no define `OASIS_BANKING_DIR`**
  ni monta `/app/banking`. **Antes del primer arranque en 1.1.4**, con el bot parado:

  ```bash
  D=<datos>/oasis-wallet-bot                      # /srv/oasis/oasis-wallet-bot en la casa
  sudo mkdir -p $D/ssb-data/oasis/banking
  sudo cp -a $D/banking/. $D/ssb-data/oasis/banking/
  sudo chown -R --reference=$D/ssb-data/secret $D/ssb-data/oasis
  ```

  La carpeta vieja se conserva como backup. Verificar tras arrancar: la dirección de
  `ssb-data/oasis/banking/wallet-addresses.json` es la misma, `ismine: true`, y el feed sigue con
  **un** mensaje `wallet`.
- **Interruptor**: §9, reescrito para 1.1.4.
- **Anuncios**: `pubAvailability` ya solo se publica al cambiar de estado o cada 12 h, y no en `GET /banking`.
- **Sin arreglar en 1.1.4**: §12 (paga cualquier `ubiClaim` visible, suelo de 1 ECO sin fondos,
  `ReferenceError` de la autopublicación, alta no idempotente).

## 6. Disco

| Ruta | Crece con | Podable | Quién acota |
|---|---|---|---|
| `/srv/oasis/ecoin/` cadena (`blk*.dat`, `txleveldb/`) | la cadena de ECOin | **no** en caliente; re-derivable entera con `ecoind` parado **conservando `wallet.dat` y `ecoin.conf`** | tamaño de la cadena (no verificado: medir en G2 y en el paso 6) |
| `/srv/oasis/ecoin/wallet.dat` | casi nada | **NUNCA** | §8 |
| `/srv/oasis/ecoin/debug.log` | actividad de `ecoind` | sí (truncar in place) | — |
| `/srv/oasis/oasis-wallet-bot/ssb-data/flume/` | replicación a hops 3 | no | `friends.hops` en `pub/config/wallet-bot/ssb-config` |
| `/srv/oasis/oasis-wallet-bot/ssb-data/blobs/` | blobs replicados | sí | `blobs.max` (guard del fork) |
| `/srv/oasis/oasis-wallet-bot/banking/` | épocas y transferencias | **no** (es el libro del banco) | — |
| stdout de los contenedores (`/`, disco de sistema) | logs | sí | `logging 10m×3` |

**Herramienta**: `bash devops/scripts/ecoin-disk.sh <cmd>` (npm `devops:ecoin-disk`), hermano de
`hub-disk.sh`: mismo patrón (SSH vía `lib-host.sh`, `--local` para Docker Desktop, read-only).
`status` imprime `df`, `du` de la cadena, tamaño/permisos de `wallet.dat`, `getinfo`
(blocks/connections/balance) y memoria de ambos contenedores; `check` aplica los umbrales 75/90 %;
`--json` se apéndalo a `devops/logs/ecoin-disk.jsonl` (no versionado). `deploy-status.sh` imprime
una línea best-effort. Cadencia: cierre del deploy, 24 h, 7 días, después semanal con la del HUB.

`/` estaba al 59 % antes de WP-O102 y la imagen `ecoin` es nueva: **parar el build si `/` > 70 %**
y podar antes (`docker image prune -f && docker builder prune -f`).

## 7. Memoria (VPS de 4 GB, 2,6 GB disponibles)

| Contenedor | Límite | Nota |
|---|---|---|
| `oasis-pub-ecoin` | 512m · `cpus 0.75` | `-maxconnections=16` |
| `oasis-pub-wallet-bot` | 768m · `cpus 1.0` | `--max-old-space-size=512` |
| `oasis-pub-hub` | **1536m → 768m** | medido 205-252 MiB; `docker update --memory 768m --memory-swap 768m oasis-pub-hub` en vivo + `OASIS_HUB_MEM_LIMIT=768m` (y `OASIS_HUB_NODE_OPTIONS=--max-old-space-size=512`) en `.env.prod` para el siguiente recreate. `pub/config/hub/oasis-config.json` **no se toca** |
| `oasis-pub-hub-cache` | 128m | sin cambios |
| caddy + panel | ≈ 250m | sin cambios |
| **suma de límites** | **≈ 2,4 GB** | + el pub, **sin límite** |

**Regla de las 24 h** (la del HUB): tras 24 h de `docker stats`, `límite = ceil(1,5 · pico)` para
`ecoin` y para el bot. El pico de `ecoind` es el **sync inicial**: medirlo en G6 y en el paso 6.
Un OOM-kill de `ecoind` es el peor caso para BDB: por eso `stop_grace_period 60s`, el límite
holgado y el backup previo. El pub sigue sin `mem_limit` → **WP-O47**.

## 8. Cartera: backup, restore, reglas

**Backup** — `bash devops/scripts/backup-ecoin.sh` (npm `devops:backup:ecoin`):

- Por defecto, en caliente: RPC `backupwallet` dentro del contenedor → copia a
  `devops/backups/ecoin/<TS>/` (no versionado) con **sha256 remoto = local**, `RESTORE.txt` y
  metadatos (`getinfo`, dirección).
- `--cold`: `stop` → copia de `wallet.dat` → `start`. Es el que se usa antes de un rollback N2 y
  si `backupwallet` no existiera en este binario (no verificado hasta G5).
- `--verify`: recomprueba los sha256 de un backup existente.
- Guardas: nunca `rm` fuera de `devops/backups/`; nunca toca `wallet.dat` en origen.

**Cuándo**: tras el bootstrap y **antes de comunicar la dirección** (§3) · antes y después de
recibir la dote · antes de encender el motor · antes de cualquier upgrade de la imagen `ecoin` ·
mensual con el motor encendido (el keypool rota con los envíos).

**Restore** (ensayado en G5; el detalle va en el `RESTORE.txt` de cada backup):

```bash
$C stop oasis-wallet-bot ecoin                                   # bot primero: que no pague a medias
D=/srv/oasis/ecoin; mv $D/wallet.dat $D/wallet.dat.bak-$(date +%F)   # APARTAR, nunca borrar
install -o 1000 -g 1000 -m 600 <backup>/wallet.dat $D/wallet.dat
$C up -d --no-deps ecoin                                         # esperar healthy
# validateaddress <dirección publicada> → "ismine": true · misma dirección que en el feed del bot
$C up -d --no-deps oasis-wallet-bot
```

**Reglas.** Sin `encryptwallet` · saldo pequeño (dote repartible, no tesorería) · `wallet.dat` 600,
datadir 700, uid 1000 · el backup es material sensible: **fuera de git** y fuera de cualquier
imagen · una sola `wallet.dat` por dirección publicada: si se pierde sin copia, la dirección del
feed queda huérfana para siempre (el mensaje `wallet` es permanente) · el cliente **nunca** apunta
a este `ecoind` (WP-O103: guarda anti-remoto del entrypoint, `../CLIENT-PROTOCOL.md` §8).

## 9. El motor de RBU: encender, comprobar, pausar

> **Reescrito el 2026-09-19 para Oasis 1.1.4 (WP-O107, D-O21).** El interruptor de 1.1.2
> (`OASIS_WALLET_BOT_PUB_ID` → `walletPub.pubId`) ya no existe: upstream lo eliminó.

**Qué es y qué no es.** El motor **no crea dinero**. Paga los `ubiClaim` pendientes con `sendtoaddress`
desde la cartera del bot, es decir, **redistribuye ECO que ya están ahí**: dote, donaciones y el
excedente que otros pubs reparten solos (lo que pase de 2000 ECO, máximo 200 por pub y época). Pool de la
época: `min(saldo − 500, 2000, 0,2 · saldo)`; con saldo ≤ 500 no se paga nada. Tope por persona 50 ECO
por época; solo cobran feeds con ≥ 30 días, dirección publicada y actividad. Oasis no trae panel de admin:
solo `POST /banking/run` y `/banking/simulate` desde el loopback de un nodo pub.

**El interruptor.** `isPubNode()` = `pub: true` en el ssb-config del proceso **y** `wallet.url` no vacía.
La `wallet.url` la pone el render (§2); `pub` lo decide **qué fichero se monta** como `~/.ssb/config`:

| Fichero | `pub` | Para qué |
|---|---|---|
| `pub/config/wallet-bot/ssb-config` | `false` | bootstrap (invite) y **pausa**: motor apagado |
| `pub/config/wallet-bot/ssb-config.engine-on` | `true` | motor encendido |

Se elige con `OASIS_WALLET_BOT_SSB_CONFIG_FILE` en el env-file del host + recreate del bot. `pub: true`
también cambia el plugin `ssb-invite-client` por `ssb-invite` y quita `ssb-lan`; la conexión al pub va
por `conn.json` y **no se ve afectada** (ensayado). El bootstrap del invite se hace siempre con `pub: false`.
Los dos ficheros deben ser idénticos salvo esa línea (`diff` = 1 línea): `caps.shs` rota en los dos.

**La gestión** es `devops/scripts/hub-wallet.sh` (`--local` para el stack local):

```bash
bash devops/scripts/hub-wallet.sh status     # modo, log del motor, mensajes propios, anuncio, saldo, pool
bash devops/scripts/hub-wallet.sh ready      # precondiciones, sin encender (exit 0 = listo)
bash devops/scripts/hub-wallet.sh on --yes   # ready + interruptor + recreate + verificación
bash devops/scripts/hub-wallet.sh pause      # vuelve a pub:false; no publica nada
```

`ready` exige: bot y `ecoind` healthy · RPC responde · cadena sincronizada con la altura que anuncian los
pares · dirección en `oasis/banking` y `ismine: true` · **un** mensaje `wallet` propio · backup local de
`wallet.dat` de menos de 24 h (`backup-ecoin.sh`) · el pub ve conectado al bot · `ssb-config.engine-on`
presente. Las credenciales RPC no salen del contenedor de `ecoind`.

**Encender es irreversible** (`AGENTES.md` §3) y pide GO del custodio: a los 15 s del arranque el motor
publica un `pubAvailability` (y después solo al cambiar de estado o cada 12 h) y el pub **aparece en la
lista de pubs de Banking** de todos los clientes 1.1.3+. Sin fondos sale con ✗ (`available: false`) y pool
0: es lo esperado hasta la dote. `on` hace backup del env-file (`*.bak-hubwallet-<fecha>`), verifica
`pub=true` y `[UBI] PUB engine on` en el log, y si no, lo dice y propone `pause`.

**Encender sin fondos tiene un coste, y no es solo la ✗.** En su primer tick el motor **abre la época del
mes** con el saldo que haya. Con saldo ≤ 500 la fija con **pool 0** y, por el suelo de upstream
(`floor_user: 1`), publica una `ubiAllocation` de **1 ECO sin respaldo** por cada habitante elegible que
vea, incluido él mismo. La época **no se recalcula** aunque la dote llegue ese mes: hasta el mes siguiente
nadie cobra de este pub más que ese 1 ECO. `ready` lo avisa. Regla: **si se puede elegir, primero la dote
y después `on`**; si se enciende antes para aparecer en Banking, se hace sabiéndolo.

**Pausar** no publica nada: deja de anunciar, y la tarjeta de Banking **caduca sola a los 3 días**.
Pausar antes de cualquier duda (upgrade del bot, cartera en mantenimiento, saldo que no cuadra).

**Dos cosas que hay que saber con el motor encendido:**

- **Cada anuncio lleva una dirección nueva.** `pubAvailability.address` sale de `getnewaddress`, no de la
  dirección publicada como `wallet`. Es de la misma cartera (`ismine: true`) y sale del *keypool* (100
  claves pregeneradas): un backup de `wallet.dat` cubre las ~100 direcciones siguientes. Regla:
  **`backup-ecoin.sh` semanal mientras el motor esté encendido**, y siempre tras recibir fondos.
- **Paga cualquier `ubiClaim` elegible que vea**, no solo los dirigidos a él (§12): a hops 3, eso es media
  red. La cartera es caliente y pequeña por diseño (§8); si el saldo se mueve de forma que no entiendes, `pause`.

Registro del encendido en la casa (VPS, 2026-09-19 17:09 UTC, GO del custodio «encender»): `pub=true`,
1 × `[UBI] PUB engine on`, `pubAvailability` 1 (`available:false, balance:0, pool:0`), `wallet` sigue en 1,
2 reclamos `skipped: PUB wallet balance is 0`, **época 2026-09 fijada con pool 0 y 6 `ubiAllocation` de
1 ECO** (lo descrito arriba; el aviso de `ready` se añadió a raíz de esto).

Registro del ensayo (local, 2026-09-19): `on` → `pub=true`, 1 × `[UBI] PUB engine on`, `pubAvailability`
+1 (`available:false, balance:0, pool:0`), `wallet` sigue en 1, el pub lo ve `CONNECTED`; `pause` →
`pub=false`, 0 en el log, ningún mensaje nuevo.

## 10. Rollback

- **N0 (segundos)**: apagar el motor (§9).
- **N1 (< 1 min, sin tocar el pub)**: `$C stop oasis-wallet-bot`. `ecoind` sigue sincronizado, la
  cartera intacta, nadie paga. El feed del bot queda en la red (append-only).
- **N2 (retirar)**: `backup-ecoin.sh --cold` → `$C rm -sf oasis-wallet-bot ecoin` → restaurar
  `docker-compose.pub.yml.bak-wallet-<fecha>` y `.env.prod.bak-wallet-<fecha>` in place. Revertir
  la memoria del HUB es opcional.
- **Siempre se conservan** `/srv/oasis/ecoin/wallet.dat` y `/srv/oasis/oasis-wallet-bot/ssb-data/secret`.
  El `contact` del pub hacia el bot queda en su log; opcional `unfollow`.
- El `.ssb` del pub no está montado en ningún servicio nuevo: ningún rollback lo toca.

## 11. Realidad del VPS — leer antes de tocar

Todo `HUB-PROTOCOL.md` §9 aplica sin cambios: layout vivo pre-refactor en
`/opt/oasis-scriptorium/OASIS_PUB` sin git (`REMOTE_REPO_DIR`), `ssb-admin.js` en
`/app/OASIS_PUB/tools/` dentro de la imagen viva, compose vivo con el mount del Teatro añadido a
mano (**subir diffeado**), `su` como PID 1. Propio de este protocolo:

- `build: ../ecoin` es relativo al compose: en el layout vivo el contexto es
  `/opt/oasis-scriptorium/ecoin/`. Subir ahí `Dockerfile`, entrypoint, conf, `.sha256`, `.txt` y
  `fetch-deb.sh`; el `.deb` se descarga **en el VPS** con `fetch-deb.sh`.
- Perfiles, comprobado en local (Docker Compose v5.1.3, gate G1): `compose ps` **sin** `--profile wallet`
  sí lista los contenedores perfilados en marcha; `compose down` sin perfil **no** los para (baja el
  resto y la red queda «still in use»); `--profile wallet down` lo bajaría **todo**, pub y HUB
  incluidos: **no usarlo en el VPS**. Para bajar solo estos dos: `$C stop ecoin oasis-wallet-bot` o `$C rm -sf ecoin oasis-wallet-bot` (siempre con los nombres de servicio).
  En el VPS, confirmar en el paso 4 con `$C config --services`.
- El render deja `oasis-config.json` a **400 del usuario que lo ejecuta**. Si lo renderiza root, el
  proceso del contenedor (uid de `oasis` en la imagen) no puede leer el bind `:ro`: renderizar como
  ese uid o hacer `chown` al uid de `oasis` tras el **primer** render (se reescribe in place: el
  propietario sobrevive a los re-renders). El directorio `config/` debe existir antes (el script no hace `mkdir`).
- Sufijo de backups de este WP: `.bak-wallet-<fecha>`.

## 12. Hallazgos de upstream a reportar

Leídos en 1.1.2 (`src/models/banking_model.js`); ninguno se parchea en el fork (delta en `src/` = cero):

1. **`processPendingClaims` no filtra por `pubId`** (`:1399-1430`): el `ubiClaim` lleva `pubId`
   (`:1045`) pero el pagador no lo compara con su feed. Cualquier pub con motor paga reclamos de otro.
2. **`pubAvailability` se publica en cada tick sin detección de cambio** (`:1119-1129`, y otra vez
   en cada `listBanking`, `:1152-1156`): 48 mensajes/día por pub, idénticos, para siempre.
3. **Suelo sin fondos**: `computeEpoch` aplica `floor_user` (1 ECO) aunque el pool sea 0
   (`:953`, `:966`) y `executeEpoch` lo publica como `ubiAllocation` (`:990-1014`): promesas que la
   cartera no puede pagar.
4. **`ReferenceError` latente en `ensureSelfAddressPublished`** (`:93-126`): la función es de
   ámbito de módulo y en `:107` usa `services`, que solo existe como parámetro de la factoría
   (`:232`). El `try/catch` que la envuelve se traga el error y `ssb` queda `null` salvo que exista
   `global.ssb` o el `require` de `SSB_server.js`: la dirección puede guardarse en el mapa local
   **sin** publicarse y aun así devolver `published`. Verificar en G3 que el mensaje `wallet` existe
   de verdad en el feed (por eso §3 paso 7 prevé `POST /banking/addresses`).

## 13. Registro

**Activación 2026-09-18.** `ecoind` arrancado 17:44 UTC, sincronizado 17:58 (51.766 bloques, 13,5 min
con `cpus 0.75`, el pub sin degradarse). bot-2 creado 17:59, follow-back del pub 18:01, `about` 18:03,
dirección publicada **una vez** 18:06:26, backup de `wallet.dat` 18:06:43
(`devops/backups/ecoin/20260918T180643Z`, verificado), modo público y gate 18:08. Journal
`--mode server+hub+wallet` 18:11:27 UTC.

| Dato | Valor |
|---|---|
| Feed de bot-2 | `@NYAqUzX7OACl+Fs866J8aVeKcqPxbbXccV/phcKx9UU=.ed25519` |
| Dirección ECOin | `EYdruXgDVQGhBpSsns83VA1BmDfAKBP4Lc` (`ismine: true`, saldo 0) |
| Tipos propios del feed de bot-2 | `contact`, `pub`, `about`, `oasisVersion`, `karmaScore`, `wallet` (uno de cada); `private` 0; `pubAvailability` y `ubiAllocation` 0 tras 120 s de observación |
| Pub, HUB y Caddy | `StartedAt` idénticos antes y después (pub 2026-09-17T11:41:19Z); Caddyfile con el mismo sha256; UFW sin cambios |
| Feed del pub | un único mensaje nuevo: el `contact` hacia bot-2 |
| Línea base de disco | `{"ts":"2026-09-18T18:11:27Z","srvOasisPct":20,"rootPct":60,"ecoinChainBytes":57296933,"walletDatBytes":61440,"blocks":51768,"connections":11,"balance":0.00000000,"botFlumeBytes":5534477,"ecoinMemMiB":82,"botMemMiB":111}` |
| Memoria al cierre | ecoind 82 MiB / 512 · bot-2 111 MiB / 768 · HUB 204 MiB / **768** (bajado en caliente de 1536 con `docker update`; `.env.prod` actualizado para el próximo recreate) · pub 113 MiB · disponible 2,4 GB |
| Disco | `/` 59 → 60 % (imagen de 141 MB) · `/srv/oasis` 20 % · datadir de ecoin 46 MB |
| Backups en el VPS | `.env.prod.bak-wallet-2026-09-18` y `…-18b`, `docker-compose.pub.yml.bak-wallet-2026-09-18` |

**Desviaciones del plan durante el deploy**: (1) el paso de publicar la dirección lo denegó el
clasificador de permisos de la sesión a un agente; el agente paró sin buscar otra vía y lo ejecutó el
orquestador, una sola vez, tras comprobar que seguía sin publicarse. (2) La altura de los pares no
sale de `height=` (§3 paso 7 corregido). (3) El entrypoint imprimía el usuario RPC en los logs:
corregido en la rama; la imagen del VPS lo lleva aún hasta el próximo build (la contraseña nunca se
imprimió). (4) `healthy` tardó 70 s en el VPS, no 35.

**Pendiente**: dote → encender el motor (§9) con confirmación expresa · ajuste de límites a las 24 h
(§7) · WP-O103 · revisión adversarial · merge. Reporte: `plan/REPORTES/WP-O102-hub-wallet.md`.

WP futuro anotado (sin numerar): **presentación comunitaria de los bots oficiales** — maquetar para
la comunidad quiénes son los bots Azofaifo, qué firma cada uno y por qué la RBU llega de bot-2.

**Upgrade 2026-09-19 (registro, WP-O106).** bot-2 en Oasis 1.1.4: estado bancario copiado a
`ssb-data/oasis/banking/` (mismo sha256) y compose vivo sin `OASIS_BANKING_DIR`; **misma dirección**
`EYdruXgDVQGhBpSsns83VA1BmDfAKBP4Lc`, un solo mensaje `wallet`, `private` = 0, motor apagado (`pub: false`,
0 × `[UBI] PUB engine on`). `ecoin` no se recreó. La cuenta pasa a llamarse `ecoin.escrivivir.co` con
`visibilityPrefs.wallet: true` (HUB §12). La carpeta vieja `/srv/oasis/oasis-wallet-bot/banking` se conserva
como backup. Reporte `plan/REPORTES/WP-O106-aplicacion-vps-1.1.4.md`.

**Encendido 2026-09-19 17:09 UTC (registro, WP-O107).** `hub-wallet.sh on --yes` con GO del custodio: detalle
en §9 y en `plan/REPORTES/WP-O107-motor-rbu.md`. Backup posterior de `wallet.dat`:
`devops/backups/ecoin/20260919T171116Z`. Journal `--mode server+hub+wallet-engine-on`.

## 14. Hallazgos de los gates locales G1-G6 (2026-09-18)

Contra el stack local en Docker Desktop, con una identidad desechable. Todos pasados.

| Gate | Hallazgo | Qué se hizo |
|---|---|---|
| G1 | Este binario **sí** tiene `backupwallet`; el P2P enlaza en **7408**; el staking se gobierna con `reservebalance`. El build falla con el `.sha256` alterado; sin credenciales o con las de por defecto el contenedor sale con 1 | confirmado, sin cambios |
| G2 | **`rpcallowip` no entiende CIDR.** Con `172.16.0.0/12` este `ecoind` (base 0.7) devolvía **403 a toda la red Docker** aun con credenciales correctas: compara la IP como texto con comodines | `ecoin.conf` y la conf de reserva del entrypoint usan `172.16.*` … `172.31.*` y `192.168.*` |
| G2 | `healthy` llega en unos 35 s porque `getinfo` responde sin estar sincronizado | §3 paso 7 exige `blocks` = altura de los pares |
| G2/G5 | El entrypoint recopiaba `bootstrap.dat` en **cada** arranque (miraba `blkindex.dat`, que esta build no crea): unas 1600 líneas «already have block» por reinicio | la condición mira `blk0001.dat`, `txleveldb/` y `bootstrap.dat.old` |
| G3 | La publicación automática de la dirección **no ocurre** (§12.4); `POST /banking/addresses` no es idempotente; el primer `GET /banking` crea dos direcciones; `GET /banking` publica un `karmaScore` aun con el motor apagado | §3 pasos 7-9 reescritos; `karmaScore` ya estaba en los tipos permitidos |
| G3 | **Interruptor ensayado**: encender → a los ~20 s `pubAvailability {available:false}` y una `ubiAllocation` de 1 ECO del bot a sí mismo con pool 0; apagar → deja de publicar | §3 paso 11: no ensayarlo en el VPS antes de la dote |
| G3 | El 302 del modo público exige que el host del Referer sea idéntico a `Host` (si no, 403 con el mismo texto) | §3 paso 10 |
| G3 | En Git Bash con `MSYS_NO_PATHCONV=1` el render daba un falso «no parsea como JSON» (node recibía la ruta sin convertir) | `render-wallet-bot-config.sh` usa `cygpath -m` si existe; en Linux no cambia nada |
| G4 | Con `ecoind` parado, `GET /banking` del bot tarda ~7,7 s: el alias `ecoin` deja de resolver (ENOTFOUND, ~3,9 s por consulta) en vez de rechazar al instante. El bot no tiene ruta pública: nadie lo sufre. Pub intacto | documentado |
| G4 | `docker stop` del bot acaba en SIGKILL (137): PID 1 es `su` y no propaga SIGTERM a node (entrypoint raíz, igual que el HUB). Rearranca limpio y reconecta | documentado; no se toca el entrypoint raíz |
| G5 | Backup en caliente y `--cold` verificados por sha256; **simulacro de restore**: con la cartera apartada la dirección del bot deja de ser `ismine`, tras restaurar vuelve a serlo | — |
| G5 | `ecoin-disk.sh` no sumaba `txleveldb/` (el índice de esta build) | añadido a `chain_bytes` y a `status` |
| G6 | Cadena **completa a 51.750 bloques ≈ 50 MB** de datadir (`blk0001.dat` 21 MB, `txleveldb/` 23 MB). Pico de `ecoind` 122 MiB sincronizando desde cero, ~30 MiB en reposo, CPU < 1 % ya sincronizado; bot 139 MiB de pico | los límites 512m / 768m sobran; ajuste a las 24 h en el VPS |
