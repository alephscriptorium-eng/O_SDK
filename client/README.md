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
    ├── setup.sh                 crea volumes-dev/ (ssb-data, ai-models, logs)
    ├── backup-keys.sh           respalda secret/config/gossip.json (identidad SSB)
    └── test-ai-service.sh       health-check del servicio de IA local
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

## Relación con el resto del repo

| Carpeta | Rol |
|---------|-----|
| `client/` | tu nodo + tu identidad de usuario |
| `pub/` | nodo de federación (compose y operación propios) |
| `devops/` | operar por SSH el host remoto que corre un pub |
