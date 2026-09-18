# client/ — rol cliente

Todo lo que pertenece al **cliente Oasis** (tu nodo personal) y a la
**identidad del usuario**, separado del pub (`pub/`) y de la operación
remota (`devops/`).

El cliente se levanta con el compose de la **raíz** del repo (la imagen es la
misma para cliente y pub; cambia el modo):

```bash
npm run up          # setup de volúmenes + docker compose up -d
# GUI en http://localhost:3000
```

## Estructura

```
client/
├── .gitignore                   deny-by-default (protege .gpg e identity.env)
├── README.md
├── docker-compose.drill.yml     drill de ECOin con identidad desechable (proyecto o-sdk-drill)
├── identity/                    identidad GPG del usuario
│   ├── init-gpg-key.sh          genera el par GPG (idempotente)
│   ├── identity.env.example     plantilla de identidad (alias, email)
│   ├── identity.env             TU identidad (ignorado por git)
│   └── .gpg/                    keyring aislado (ignorado; se crea al generar)
└── scripts/
    ├── setup.sh                 crea volumes-dev/ (ssb-data, ai-models, logs, client-state/banking)
    ├── backup-keys.sh           respalda secret/config/gossip.json (identidad SSB; avisa si hay cartera ECOin)
    ├── ecoin-init.sh            ECOin: .env raíz con credenciales generadas, volumen externo, modo address|own, --pub-id
    ├── backup-wallet.sh         ECOin: backup (caliente o --cold) y --restore de wallet.dat, con sha256
    ├── ecoin-verify.sh          ECOin: RPC solo por la red del compose, config cableada, 1 mensaje wallet, symlinks
    ├── guard-destroy.sh         ECOin: guarda de downDELETEVOLS/cleanDELETEVOLS (exige BORRAR y backup reciente)
    ├── import-identity.sh       trae un secret + log + gossip existentes SIN bifurcar el feed
    ├── sync-only.sh             sbot puro (sin GUI) para sincronizar con el pub antes de arrancar
    ├── lib/inspect-log-offset.js integridad y seq propio de un flume/log.offset (sin sbot)
    └── test-ai-service.sh       prueba POST /ai dentro del contenedor (:4001 no se publica)
```

## Las dos identidades del cliente

(La cartera ECOin no es una identidad, pero también es irremplazable: ver «ECOin en el cliente».)

| Identidad | Dónde vive | Backup |
|-----------|-----------|--------|
| **SSB** (`secret` Ed25519) | `volumes-dev/ssb-data/` (volumen Docker) | `npm run client:backup-keys` |
| **GPG** (perfil/cifrado opcional) | `client/identity/.gpg/` | copia manual a almacenamiento cifrado |

- El `secret` SSB **es** tu cuenta: sin él no recuperas tu feed. Respáldalo
  fuera de la máquina.
- De GPG solo se publica la **clave pública** (`.pub.asc`) en
  `http://localhost:3000/profile/edit`. El keyring privado no sale de aquí.

## Generar la identidad GPG

```bash
cp client/identity/identity.env.example client/identity/identity.env
# edita identity.env con tu alias y email
bash client/identity/init-gpg-key.sh
```

## Traer una identidad existente

Nunca copies un `secret` a `volumes-dev/ssb-data` y arranques la GUI: con el log vacío Oasis
publica un mensaje nuevo con `sequence: 1` y **bifurca tu feed**. El camino seguro, con el cliente
parado (`docs/CLIENT-PROTOCOL.md` §2-§3):

```bash
npm run client:import-identity -- --from "C:/ruta/al/.ssb/viejo" --with-blobs   # secret + log.offset + gossip.json + keys/
npm run client:sync-only -- start                                               # sbot puro, nada publica
npm run client:sync-only -- status --pub --watch                                # hasta SYNC-OK
npm run client:sync-only -- stop && docker compose up -d oasis-client           # ahora sí, la GUI
```

Las claves de tribus (`keys/`) viajan con la importación y con `backup-keys.sh` no: respáldalas aparte.

## ECOin en el cliente

Independiente del VPS, en dos niveles (`docs/CLIENT-PROTOCOL.md` §8; WP-O103, implementado en rama,
drill pendiente). Por defecto no hay nada cableado: `wallet.url = ""` y ningún RPC saliente.

| Nivel | Para qué | `.env` raíz |
|-------|----------|-------------|
| (i) solo dirección | aparecer, recibir y reclamar RBU | `COMPOSE_PROFILES=` · `ECOIN_RPC_URL=` |
| (ii) cartera propia | además saldo, envíos e historial | `COMPOSE_PROFILES=ecoin` · `ECOIN_RPC_URL=http://ecoin-wallet:7474` |

```bash
npm run ecoin:build                                   # verifica el sha256 del .deb
npm run client:ecoin:init -- --mode address           # o --mode own; genera credenciales en .env (ignorado) y el volumen
npm run ecoin:up                                      # ecoind healthy; sin puertos publicados en el host
npm run ecoin:address                                 # nivel (i): UNA dirección de tu wallet.dat; apúntala
npm run client:wallet:backup                          # SIEMPRE antes de publicar la dirección o de abrir la GUI en el nivel (ii)
npm run client:ecoin:verify
```

| Estado | Dónde vive | Backup |
|--------|-----------|--------|
| `wallet.dat` + cadena | volumen Docker externo `o-sdk-client-ecoin-data` (no es un bind: BDB sobre virtiofs es frágil) | `npm run client:wallet:backup` → `devops/backups/client-wallet/<TS>/` |
| `oasis-config.json` + `banking/` | `volumes-dev/client-state/` (bind a `/app/state`) | copia del directorio |

- La dirección se publica **una vez** y a mano en `http://localhost:3000/banking?filter=addresses`:
  el formulario no es idempotente y cada envío es un mensaje `wallet` **permanente**.
- En el nivel (ii), **abrir `/` llama a `getnewaddress`**: backup antes de abrir la GUI.
- **Env manda**: lo tecleado en `/settings/wallet` se pisa al arrancar (escape: `OASIS_WALLET_WIRING=manual`).
- Banco: `npm run client:ecoin:init -- --pub-id '@NYAqUzX7OACl+Fs866J8aVeKcqPxbbXccV/phcKx9UU=.ed25519'`
  (bot-2). Cada claim es un mensaje `ubiClaim` irreversible y hoy el motor del banco está **apagado**: no paga hasta la dote.
- **Nunca** apuntes `ECOIN_RPC_URL` al `ecoind` del VPS y **nunca** ejecutes `docker system prune --volumes`.
- El backup de la cartera no está cifrado y es material de claves: guárdalo fuera de la máquina.

## Relación con el resto del repo

| Carpeta | Rol |
|---------|-----|
| `client/` | tu nodo + tu identidad de usuario |
| `pub/` | nodo de federación (compose y operación propios) |
| `devops/` | operar por SSH el host remoto que corre un pub |
