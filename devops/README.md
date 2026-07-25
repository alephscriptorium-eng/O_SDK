# devops/ — operación remota

Todo lo necesario para operar por SSH un host remoto que corre un **pub**
Oasis. Los scripts son **genéricos** (método); los datos de cada host viven en
`devops/hosts/<instancia>/host.env` (datos). La instancia por defecto es
`scriptorium` (VPS Gandi, Debian 13).

Reglas:

- Aquí viven las claves SSH del VPS, los snapshots de configuración y cualquier secreto operativo.
- El `.gitignore` de esta carpeta es **deny-by-default**: solo se versionan `README.md`, `scripts/`, `docs/` y `hosts/`. Claves, backups y logs quedan fuera del repo.
- Nunca metas aquí archivos sin pensar antes en si son secretos. En `hosts/` solo datos NO secretos.

## Estructura

```
devops/
├── .gitignore         (deny-by-default)
├── README.md          (este fichero)
├── MIGRATION-2026-07.md  (migración del layout OASIS_PUB → pub en el VPS)
├── hosts/             (instancias: datos por host — ver hosts/README.md)
│   ├── default                    ← instancia activa por defecto
│   ├── scriptorium/host.env       ← VPS Gandi del Scriptorium
│   └── ejemplo/host.env.example   ← plantilla
├── docs/              (chuletas operativas, p.ej. pub-maint-ui.md)
├── scripts/           (scripts genéricos; lib-host.sh carga la instancia)
├── logs/              (journal de deploys y federación; NO se versiona)
├── backups/           (backups traídos del VPS; NO se versionan)
└── .ssh/              (claves por instancia; NO se versiona JAMÁS)
    ├── gandi_pub_ed25519        ← clave privada (NO COMPARTIR)
    └── gandi_pub_ed25519.pub    ← clave pública (la que se sube a Gandi)
```

## Instancias

Los scripts cargan `devops/hosts/$DEVOPS_HOST/host.env` vía `lib-host.sh`.
Para operar otra instancia: `DEVOPS_HOST=otra bash devops/scripts/...` o
cambia `devops/hosts/default`. Prioridad: entorno > host.env > default.

## Uso rápido

### 1. Generar clave SSH para el VPS

Desde la raíz del repo o desde esta carpeta, en bash (Git Bash en Windows):

```bash
bash devops/scripts/init-ssh-key.sh
```

Esto:

- Crea `devops/.ssh/` si no existe.
- Genera un par `gandi_pub_ed25519` / `gandi_pub_ed25519.pub` si aún no existe.
- Imprime la clave pública lista para pegar en el panel de Gandi al crear el VPS.

Por defecto la clave se genera **sin passphrase** para no añadir fricción al primer deploy.
Si quieres passphrase, pásala con la variable de entorno `SSH_PASSPHRASE`:

```bash
SSH_PASSPHRASE='algo-largo-y-aleatorio' bash devops/scripts/init-ssh-key.sh
```

### 2. Subir la clave pública al VPS desde Gandi

- Ir al panel de GandiCloud VPS.
- "Create a server" → introducir la public key cuando lo pida.
- O añadirla en `Account → SSH Keys` antes de crear el VPS.

### 3. Conectarse al VPS

Cuando Gandi entregue la IP del VPS:

```bash
ssh -i devops/.ssh/gandi_pub_ed25519 admin@<IP_DEL_VPS>
```

(Reemplazar `admin` por el usuario que cree la imagen del OS, normalmente `debian` o `ubuntu`.)

### 4. Preparar la base Debian 13 del VPS

Para la Fase 1 del pub se fija este layout del host:

- Código versionado en `/opt/oasis-scriptorium`
- Estado persistente en `/srv/oasis`

El script recomendado para dejar esa base lista en Debian 13 es:

```bash
bash devops/scripts/bootstrap-debian13-base.sh --device /dev/vdb
```

Qué hace:

- valida que el host sea Debian 13;
- detecta o usa el dispositivo indicado para el volumen de datos;
- crea `ext4` si el volumen aún no tiene filesystem;
- monta el volumen en `/srv/oasis` y lo persiste por UUID en `/etc/fstab`;
- crea el layout `/opt/oasis-scriptorium` + `/srv/oasis/oasis-pub/*`;
- instala Docker Engine y Compose v2 desde repos oficiales de Debian;
- aplica UFW para `22`, `80`, `443` y `8008`.

El endurecimiento SSH se deja en modo seguro por defecto: el script revisa la configuración efectiva, pero **no** desactiva autenticación por contraseña salvo que lo lances con:

```bash
bash devops/scripts/bootstrap-debian13-base.sh --device /dev/vdb --apply-ssh-hardening
```

Haz eso solo después de validar que ya puedes entrar por clave en una segunda sesión SSH. Más vale una sesión extra que una tarde romántica con el panel de rescate.

### 5. Verificar la base tras el reboot

Después del primer reinicio del VPS, verifica que el montaje, Docker, UFW y SSH han quedado bien con:

```bash
bash devops/scripts/verify-debian13-base.sh
```

Ese script comprueba:

- Debian 13
- montaje persistente de `/srv/oasis`
- layout de directorios del host
- Docker activo y habilitado al arranque
- `docker compose` disponible
- reglas UFW esperadas
- que `127.0.0.1:8787` no quede expuesto públicamente
- configuración SSH efectiva

### 6. Crear un backup local del pub remoto

Para traer a tu máquina operadora un backup del pub del VPS dentro de esta carpeta segura:

```bash
bash devops/scripts/backup-oasis-pub.sh
```

Por defecto crea una carpeta con timestamp en:

- `devops/backups/oasis-pub/<timestamp>/`

Contenido por defecto:

- `identity/secret`
- `identity/config`
- `identity/gossip.json`
- `identity/gossip_unfollowed.json`
- `identity/manifest.json`
- `ssb-data-<timestamp>.tar.gz`
- `SHA256SUMS.txt`
- `BACKUP_METADATA.json`
- `RESTORE.txt`

Si solo quieres copia mínima de identidad y configuración, sin tarball completo:

```bash
bash devops/scripts/backup-oasis-pub.sh --identity-only
```

Importante:

- el backup queda **ignorado por git** por el `.gitignore` deny-by-default de esta carpeta;
- aun así contiene secretos en claro, así que debes moverlo a almacenamiento cifrado externo cuanto antes;
- el archivo más crítico es `secret`: quien lo tenga puede suplantar la identidad del pub.

### 7. Levantar una UI temporal de mantenimiento del pub

El servicio `oasis-pub-scriptorium` del VPS corre en modo `server`, así que no expone la UI completa de Oasis para editar el avatar o entrar en `/legacy`.

Para tareas de mantenimiento de perfil (por ejemplo cambiar avatar, nombre o descripción del pub), usa el contenedor temporal de UI:

```bash
bash devops/scripts/pub-maint-ui.sh up --stop-pub
```

Eso:

- detiene el contenedor del pub si sigue activo;
- levanta una UI temporal solo en `127.0.0.1:3000` del VPS;
- reutiliza la misma identidad y el mismo volumen `ssb-data` del pub.

Después abre el túnel SSH sugerido por el script o imprímelo explícitamente con:

```bash
bash devops/scripts/pub-maint-ui.sh tunnel
```

Y entra localmente en:

- `http://localhost:3000/profile/edit`
- `http://localhost:3000/legacy`

Cuando termines, baja la UI temporal y vuelve a arrancar el pub:

```bash
bash devops/scripts/pub-maint-ui.sh down --restart-pub
```

Notas de seguridad y consistencia:

- la UI temporal se publica solo en loopback del VPS (`127.0.0.1`), no en Internet;
- no debes dejar el pub normal y la UI temporal escribiendo al mismo `.ssb` a la vez;
- por eso el script exige `--stop-pub` para el arranque de mantenimiento.

### 8. Anunciar el PUB y federar con otros PUBs

Una vez el pub está en marcha, hay dos mensajes SSB que necesitas publicar para entrar en la red:

1. **Announce** — publica la dirección pública de tu PUB para que otros nodos puedan encontrarlo.
2. **Follow** — suscribe el feed de otro PUB para iniciar la replicación mutua.

> **IMPORTANTE**: los mensajes SSB son **inmutables** — no hay botón de deshacer. Usa `--dry-run` para ver exactamente qué se va a publicar antes de confirmar.

El script `pub-federation.sh` orquesta estas operaciones desde tu máquina local, verificando siempre antes de publicar que el `caps.shs` remoto coincida con el `EXPECTED_SHS` de la instancia (`devops/hosts/<instancia>/host.env`). Si no coincide, aborta sin publicar nada.

```bash
# 1. Verificar estado del pub y caps.shs antes de tocar nada
bash devops/scripts/pub-federation.sh status

# 2. Preview del announce (no publica nada)
bash devops/scripts/pub-federation.sh announce --dry-run

# 3. Publicar announce con confirmación interactiva
bash devops/scripts/pub-federation.sh announce

# 4. Preview de follow hacia solarnethub.com "La Plaza"
bash devops/scripts/pub-federation.sh follow-solarnethub --dry-run

# 5. Publicar follow hacia solarnethub.com con confirmación interactiva
bash devops/scripts/pub-federation.sh follow-solarnethub

# Para seguir cualquier otro PUB de confianza
bash devops/scripts/pub-federation.sh follow @feedId=.ed25519
```

Todas las operaciones se registran en `devops/logs/federation.log` (ignorado por git).

El peer inicial recomendado es `solarnethub.com` / `@0qSCyK3xyL71X4qKkmf84Cb2riP6OeUqxCvbP2Z6HWs=.ed25519` (seed ciclo 6 / Oasis 0.8.3), documentado en `docs/PUB/deploy.md`.

## Por qué una carpeta separada

- Mantiene las claves del VPS fuera de `~/.ssh/` global, así no se mezclan con otras identidades personales.
- Permite revocar/rotar la clave del pub sin tocar nada más.
- Hace explícito qué pertenece al despliegue del pub (frente al cliente local).

## Notas de seguridad

- La clave privada (`gandi_pub_ed25519`) **no debe salir de tu máquina**.
- El `.gitignore` impide subirla al repo, pero si haces backups manuales, asegúrate de cifrarlos.
- Para rotar la clave, basta con borrar `devops/.ssh/gandi_pub_ed25519*` y volver a ejecutar el script.
