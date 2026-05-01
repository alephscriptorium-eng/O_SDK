# GANDI_DEVOPS_FOLDER

Carpeta limpia y segura para todo lo que tiene que ver con el despliegue del PUB OASIS SCRIPTORIUM en GandiCloud VPS.

Reglas:

- Aquí viven las claves SSH del VPS, los snapshots de configuración, los inventarios y cualquier secreto operativo.
- El `.gitignore` de esta carpeta es **deny-by-default**: solo se versionan `README.md` y `scripts/`. Todo lo demás queda fuera del repo.
- Nunca metas aquí archivos sin pensar antes en si son secretos.

## Estructura

```
GANDI_DEVOPS_FOLDER/
├── .gitignore         (deny-by-default; solo README + scripts)
├── README.md          (este fichero)
├── scripts/           (scripts versionables)
│   └── init-ssh-key.sh
└── .ssh/              (se crea al ejecutar init-ssh-key.sh; NO se versiona)
    ├── gandi_pub_ed25519        ← clave privada (NO COMPARTIR)
    └── gandi_pub_ed25519.pub    ← clave pública (la que se sube a Gandi)
```

## Uso rápido

### 1. Generar clave SSH para el VPS

Desde la raíz del repo o desde esta carpeta, en bash (Git Bash en Windows):

```bash
bash GANDI_DEVOPS_FOLDER/scripts/init-ssh-key.sh
```

Esto:

- Crea `GANDI_DEVOPS_FOLDER/.ssh/` si no existe.
- Genera un par `gandi_pub_ed25519` / `gandi_pub_ed25519.pub` si aún no existe.
- Imprime la clave pública lista para pegar en el panel de Gandi al crear el VPS.

Por defecto la clave se genera **sin passphrase** para no añadir fricción al primer deploy.
Si quieres passphrase, pásala con la variable de entorno `SSH_PASSPHRASE`:

```bash
SSH_PASSPHRASE='algo-largo-y-aleatorio' bash GANDI_DEVOPS_FOLDER/scripts/init-ssh-key.sh
```

### 2. Subir la clave pública al VPS desde Gandi

- Ir al panel de GandiCloud VPS.
- "Create a server" → introducir la public key cuando lo pida.
- O añadirla en `Account → SSH Keys` antes de crear el VPS.

### 3. Conectarse al VPS

Cuando Gandi entregue la IP del VPS:

```bash
ssh -i GANDI_DEVOPS_FOLDER/.ssh/gandi_pub_ed25519 admin@<IP_DEL_VPS>
```

(Reemplazar `admin` por el usuario que cree la imagen del OS, normalmente `debian` o `ubuntu`.)

### 4. Preparar la base Debian 13 del VPS

Para la Fase 1 del pub se fija este layout del host:

- Código versionado en `/opt/oasis-scriptorium`
- Estado persistente en `/srv/oasis`

El script recomendado para dejar esa base lista en Debian 13 es:

```bash
bash GANDI_DEVOPS_FOLDER/scripts/bootstrap-debian13-base.sh --device /dev/vdb
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
bash GANDI_DEVOPS_FOLDER/scripts/bootstrap-debian13-base.sh --device /dev/vdb --apply-ssh-hardening
```

Haz eso solo después de validar que ya puedes entrar por clave en una segunda sesión SSH. Más vale una sesión extra que una tarde romántica con el panel de rescate.

### 5. Verificar la base tras el reboot

Después del primer reinicio del VPS, verifica que el montaje, Docker, UFW y SSH han quedado bien con:

```bash
bash GANDI_DEVOPS_FOLDER/scripts/verify-debian13-base.sh
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

## Por qué una carpeta separada

- Mantiene las claves del VPS fuera de `~/.ssh/` global, así no se mezclan con otras identidades personales.
- Permite revocar/rotar la clave del pub sin tocar nada más.
- Hace explícito qué pertenece al despliegue del pub (frente al cliente local).

## Notas de seguridad

- La clave privada (`gandi_pub_ed25519`) **no debe salir de tu máquina**.
- El `.gitignore` impide subirla al repo, pero si haces backups manuales, asegúrate de cifrarlos.
- Para rotar la clave, basta con borrar `GANDI_DEVOPS_FOLDER/.ssh/gandi_pub_ed25519*` y volver a ejecutar el script.
