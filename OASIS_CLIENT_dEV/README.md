# OASIS_CLIENT_DEV

Carpeta local para credenciales del **cliente Oasis** (Docker `oasis-dev`), separada del repo y del despliegue del pub en Gandi.

Reglas (mismo criterio que `GANDI_DEVOPS_FOLDER/`):

- Las claves viven aquí, **no** en `volumes-dev/ssb-data/` ni en git.
- El `.gitignore` de esta carpeta es **deny-by-default**: solo se versionan `README.md` y `scripts/`.
- La clave **privada GPG** no debe subirse a Oasis: en `/profile/edit` solo se publica la **pública** (`.asc`).

## Estructura

```
OASIS_CLIENT_DEV/
├── .gitignore
├── README.md
├── scripts/
│   └── init-gpg-key.sh
└── .gpg/                    (se crea al ejecutar init-gpg-key.sh; NO se versiona)
    ├── pubring.kbx          ← keyring GnuPG aislado (privada + pública)
    ├── alephillo.pub.asc    ← export para subir en Oasis UI
    └── README.txt           ← recordatorio de huella y uso
```

## Generar clave GPG para el perfil Oasis

Desde `BlockchainComPort/` en Git Bash:

```bash
bash OASIS_CLIENT_DEV/scripts/init-gpg-key.sh
```

Variables opcionales:

```bash
GPG_NAME=alephillo \
GPG_EMAIL=alephillo@escrivivir.co \
GPG_COMMENT='Oasis client @tMJzSfc…' \
GPG_PASSPHRASE='' \
bash OASIS_CLIENT_DEV/scripts/init-gpg-key.sh
```

## Asociar en la UI de Oasis

1. Cliente Docker en marcha: `http://localhost:3000/profile/edit`
2. Campo **Clave Pública GPG (.asc)**
3. Selecciona: `OASIS_CLIENT_DEV/.gpg/alephillo.pub.asc`
4. Guarda perfil

Oasis publica la clave en tu feed SSB (blob + huella). **Nunca** subas el keyring privado ni un `.asc` que contenga `BEGIN PGP PRIVATE KEY BLOCK`.

## Backup

Copia `OASIS_CLIENT_DEV/.gpg/` a almacenamiento cifrado (USB, vault). Sin esa carpeta no podrás descifrar mensajes ligados a esa clave GPG.

## Relación con Gandi

| Carpeta | Uso |
|---------|-----|
| `GANDI_DEVOPS_FOLDER/.ssh/` | SSH al VPS del **pub** |
| `OASIS_CLIENT_DEV/.gpg/` | GPG del **usuario cliente** (alephillo) en Oasis |

Son identidades distintas: SSB (`secret` en `volumes-dev/ssb-data/`) vs GPG (perfil / cifrado opcional en Oasis).
