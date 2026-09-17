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
├── identity/                    identidad GPG del usuario
│   ├── init-gpg-key.sh          genera el par GPG (idempotente)
│   ├── identity.env.example     plantilla de identidad (alias, email)
│   ├── identity.env             TU identidad (ignorado por git)
│   └── .gpg/                    keyring aislado (ignorado; se crea al generar)
└── scripts/
    ├── setup.sh                 crea volumes-dev/ (ssb-data, ai-models, logs, ecoin-data)
    ├── backup-keys.sh           respalda secret/config/gossip.json (identidad SSB)
    ├── import-identity.sh       trae un secret + log + gossip existentes SIN bifurcar el feed
    ├── sync-only.sh             sbot puro (sin GUI) para sincronizar con el pub antes de arrancar
    ├── lib/inspect-log-offset.js integridad y seq propio de un flume/log.offset (sin sbot)
    └── test-ai-service.sh       prueba POST /ai dentro del contenedor (:4001 no se publica)
```

## Las dos identidades del cliente

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

## Relación con el resto del repo

| Carpeta | Rol |
|---------|-----|
| `client/` | tu nodo + tu identidad de usuario |
| `pub/` | nodo de federación (compose y operación propios) |
| `devops/` | operar por SSH el host remoto que corre un pub |
