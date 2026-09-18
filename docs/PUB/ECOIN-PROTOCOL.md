# Protocolo de ECOin (hub-wallet del pub)

> **Este repo es el sitio del hub-wallet** (`C:\S_LAB\o-sdk`,
> `https://github.com/alephscriptorium-eng/O_SDK.git`). El hub-wallet **no tiene puerta web**:
> vive dentro de la red Docker del pub y solo se ve por lo que su bot publica en SSB.

> **Estado · IMPLEMENTADO en la rama `wp/O102-hub-wallet`, NO desplegado** (WP-O102, 2026-09-18).
> Nada de lo descrito aquí corre todavía en `pub.escrivivir.co`: ni `oasis-pub-ecoin` ni
> `oasis-pub-wallet-bot` existen en el VPS, el bot no tiene feed id y no hay `wallet.dat` de
> producción. Este bloque se cambia al activar (§3) y el registro se escribe en §13. Decisiones del
> custodio: `plan/DECISIONES.md` **D-O19**. Siguiente pieza: WP-O103 (ECOin en la app cliente).

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
  del feed del pub. Los clientes apuntan su `walletPub.pubId` al feed de bot-2.
- **Motor ARMADO y APAGADO hasta la dote.** El interruptor es `OASIS_WALLET_BOT_PUB_ID` en
  `.env.prod`. **Vacío** = `walletPub.pubId` vacío = `isPubNode()` falso = ni tick ni pagos ni
  `pubAvailability`. Se enciende solo con confirmación expresa del custodio (§9).
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
| Arranque de `ecoind` | `ecoin/docker-entrypoint.sh` · `ecoin/ecoin.conf` | siembra la conf **completa** si falta; `umask 077`, conf a 600; fail-closed con `ECOIN_REQUIRE_CREDS=1`; `port=7408` explícito; `rpcallowip=172.16.0.0/12`; marcadores en vez de credenciales | ✅ rama |
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
7. Con `ecoind` healthy: `GET /banking` **desde el loopback** guarda la dirección en
   `banking/wallet-addresses.json` y publica el mensaje `wallet`; `POST /banking/addresses`
   (solo loopback, `backend.js:10989-10990`) la fija si hiciera falta. Exactamente **un** mensaje `wallet`.
8. **Backup de `wallet.dat` ANTES de comunicar la dirección a nadie** (§8). Una dirección publicada
   sin copia de su clave es una dote que se puede perder.
9. `OASIS_WALLET_BOT_PUBLIC=true` + `up -d --no-deps`; gate: `POST` = 302 con `?error=` de modo
   público (400 sin Referer; nunca 200).

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
(verificadas sobre 1.1.2 el 2026-09-18):

```bash
grep -c 'async function runPubEngineTick' src/backend/backend.js          # el motor sigue en backend.js…
grep -c 'bankingModel.isPubNode()' src/backend/backend.js                 # …y sigue condicionado a isPubNode
grep -c 'function isPubNode' src/models/banking_model.js                  # interruptor = walletPub.pubId === feed propio
grep -c 'walletPub?.pubId' src/models/banking_model.js                    # clave de config del interruptor
grep -c '"walletPub"' src/configs/oasis-config.json                       # la clave sigue en la config por defecto
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

**5.3 Tabla de contingencia 1.1.3** (mecanismo de autodetección desconocido hasta que haya fuente):

| Si la 1.1.3… | Qué hacemos | Coste |
|---|---|---|
| sigue leyendo `wallet.*` de `oasis-config.json` | **nada**: es el cableado actual | 0 |
| sondea `localhost:7474` | `network_mode: "service:ecoin"` en `oasis-wallet-bot` (comparten pila de red; `ecoin` sigue sin `ports`) | compose, 1 recreate del bot; revisar `rpcallowip` |
| lee un `ecoin.conf` local para sacar credenciales | bind `:ro` de `/srv/oasis/ecoin/ecoin.conf` en la ruta que espere | compose, 1 recreate del bot |
| lanza (`spawn`) su propio `ecoind` | **no soportado**: rompe «ecoind en contenedor propio»; se desactiva por config o se reporta a upstream antes de subir | decisión del custodio |

En todos los casos: el motor se **apaga** antes del upgrade del bot si hay dudas (§9) y se
re-enciende tras verificar; la cartera no se mueve.

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
a este `ecoind` (WP-O103).

## 9. El interruptor del motor

**Encender** (solo con dote recibida, backup hecho y confirmación expresa del custodio):

```bash
# .env.prod (backup previo): OASIS_WALLET_BOT_PUB_ID=@<feed id de bot-2>.ed25519
bash scripts/render-wallet-bot-config.sh .env.prod               # reescribe in place la config (400)
$C up -d --no-deps oasis-wallet-bot                              # isPubNode() se evalúa al arrancar
# a los 15 s corre el primer tick; después cada 30 min (backend.js:11744-11747)
```

**Apagar**: vaciar `OASIS_WALLET_BOT_PUB_ID` → render → `up -d --no-deps oasis-wallet-bot`. Es
también el rollback N0: no toca `ecoind`, ni la cartera, ni el feed.

**Qué publica encendido.**

| Situación | Mensajes en el feed de bot-2 |
|---|---|
| **0 ECO** en la cartera | `pubAvailability` con `available:false` en **cada tick**: **48 al día**, haya cambio o no (`banking_model.js:1119-1129`). A primeros de mes, `executeEpoch` publica un `ubiAllocation` de **1 ECO** por dirección conocida **aunque no haya fondos** (el suelo `floor_user` se aplica sobre un pool de 0: `banking_model.js:953`, `:966`, `:990-1014`). No paga nada (`pubBal <= 0` → salta, `:1430`) |
| **Con dote** | los mismos 48 `pubAvailability`/día (ahora `available:true`) + los `ubiAllocation` de la época + **3 mensajes por reclamo pagado**: `ubiClaimResult`, `bankClaim` y `transfer` con tag `UBI` (`:1443-1447`) |

Además, cada `GET /banking` con el motor encendido publica otro `pubAvailability`
(`banking_model.js:1152-1156`): no abrir la GUI del bot por rutina.

**Por qué paga cualquier `ubiClaim` visible.** `processPendingClaims` (`banking_model.js:1399-1419`)
recorre `messagesByType({ type: "ubiClaim" })` sobre **todo el log replicado** y solo descarta los
ya resueltos por `epochId:userId`; **no compara `claim.pubId` con el feed propio**. Con hops 3,
un reclamo dirigido a otro pub que llegue al log del bot, de un autor con dirección ECOin válida
conocida, se paga (mínimo 1 ECO, `:1440`). Es política asumida (D-O19.6): la cota es el saldo de
la cartera. Si el drenaje molesta antes de que upstream lo filtre (§12): bajar hops o apagar.

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

**Pendiente.** Se escribe al activar: fecha y hora UTC, feed id de bot-2, dirección ECOin
publicada, línea base de `ecoin-disk.sh --json`, memoria al cierre, `StartedAt` del pub antes y
después, lista de backups `.bak-wallet-<fecha>`, línea del journal `--mode server+hub+wallet`,
desviaciones del plan. Reporte: `plan/REPORTES/WP-O102-hub-wallet.md` (al cerrar el WP).

WP futuro anotado (sin numerar): **presentación comunitaria de los bots oficiales** — maquetar para
la comunidad quiénes son los bots Azofaifo, qué firma cada uno y por qué la RBU llega de bot-2.
