# Protocolo de recuperación de Oasis (fork dockerizado)

Checklist operativo reutilizable para recuperar un despliegue de Oasis (cliente o pub) tras
corrupción de disco, pérdida del log SSB o daño en el repositorio git. Complementa a
`UPGRADE-PROTOCOL.md`. Deriva de una recuperación real completa (repo + imagen + identidad).

> **Modelo mental.** Solo hay UNA cosa irremplazable: el `secret` (identidad SSB) y las claves
> (GPG, SSH). Todo lo demás es derivable: el **log** se re-replica desde el pub, los **índices**
> (flume) se reconstruyen del log, los **blobs** son content-addressed y se re-descargan, el
> **código** vive en GitHub y la **imagen** Docker se reconstruye del árbol. El pub es la fuente
> de verdad de los feeds: lo que el pub no tenga de tu feed, no existe.

## 0. Triaje — verificar integridad ANTES de usar nada

Nunca confiar en un fichero de un disco sospechoso sin verificarlo. El daño típico: fichero con
tamaño intacto pero contenido a ceros (total o por tramos alineados a 4KB).

```bash
# Texto: buscar bytes NUL (un fichero de texto sano tiene CERO)
rg -la '\x00' <dir>                    # lista los dañados
tr -dc '\000' < fichero | wc -c        # debe dar 0

# Binarios: NUL no discrimina (un PNG sano tiene NULs) → comprobar magic bytes
head -c 8 fichero | od -An -tx1
#   PNG=89504e47  JPG=ffd8ff  GGUF=47475546  gzip=1f8b  PACK(git)=5041434b
```

**Trampas conocidas de las herramientas:**
- `grep -qP '\x00'` NO detecta NUL de forma fiable → falsos negativos silenciosos. Usar `rg`.
- `grep -c` en ficheros binarios cuenta **líneas**, no ocurrencias → usar `grep -ao ... | wc -l`.
- Los greps son case-sensitive: buscar nombres propios con `-i`.
- Un fichero "legible" que muestra solo espacios en el editor puede ser 100% NUL (el render
  los pinta como blancos). Verificar con `od`.

## 1. Prioridades (en este orden, siempre)

1. **Blindar lo insustituible**: copiar `secret`/claves a otro medio físico y VERIFICAR la copia
   (tamaño, sin NUL, estructura). Un backup no verificado no es un backup.
2. **Blindar el working tree**: `robocopy /E /XD node_modules volumes-dev` a una carpeta de
   recovery ANTES de tocar git. Los uncommitted viven en disco, no en `.git`.
3. **Sacar el código de la máquina**: commit + push a GitHub en cuanto haya algo verificado.
4. Solo después: reconstruir imagen, contenedor y log.

## 2. Recuperar el repositorio git

Si el object store está corrupto, NO reparar in-place: dejar el `.git` dañado intacto como
forense y reconstruir aparte.

```bash
# 1) Clon limpio en carpeta de recovery
git clone <origin-url> recovery-clean

# 2) Apuntar el .git sano al working tree real (sin copiar nada)
git --git-dir=recovery-clean/.git --work-tree=<working-tree> status --short

# 3) Elegir la base correcta: la rama remota MÁS CERCANA al working tree
#    (comparar diff --name-status contra cada candidata; menor huella gana)

# 4) Commit por plumbing (no toca el working tree):
git ... add -A && WTREE=$(git ... write-tree)
git ... commit-tree $WTREE -p <base> -m "recover: ..." && git ... update-ref ...
```

**Del store corrupto aún se puede salvar:**
- El **reflog** (`logs/HEAD`) es texto plano: da los SHAs de los commits locales perdidos.
- Commits/árboles individuales pueden ser legibles aunque la punta esté corrupta:
  `git cat-file -p <sha>` uno a uno, del más nuevo al más viejo.
- **Truco blob-id**: el hash de un blob está en el árbol (legible) aunque el blob esté corrupto.
  Si el blob-id local == blob-id en una rama remota, la versión de GitHub es **byte-exacta** a
  la local → recuperación exacta garantizada sin leer el blob.

**Antes del push, SIEMPRE:**
- Dry-run de secretos: `git add -An` + grep de `.env|secret|.key|.gpg|.ssh|id_ed25519` por
  nombre Y por contenido (`BEGIN.*PRIVATE KEY`).
- Verificación NUL/magic de todo lo que entra (§0) — commitear un árbol dañado obliga a un
  commit correctivo después.
- Si hay daño mezclado: separar por **procedencia** (¿este diff es trabajo real o es daño?);
  los binarios que el trabajo no tocó se restauran wholesale de la rama remota.

## 3. Reconstruir la imagen y el contenedor cliente

```bash
# SIEMPRE desde un árbol verificado (el working tree dañado hornea el daño en la imagen)
docker compose build oasis-dev
docker rm <contenedor-viejo>           # los datos viven en los bind mounts, no se pierden
docker compose up -d oasis-dev
```

- Un `docker-compose.override.yml` (no versionado) permite apuntar los bind-volumes al
  `volumes-dev` original desde otra carpeta de código.
- El modelo AI se re-descarga solo si falta (`download_ai_model` del entrypoint); opt-out con
  `OASIS_SKIP_AI_MODEL=true`. Apartar el dañado: el entrypoint decide por presencia del fichero.
- Síntoma "package.json parse error at position 4096" dentro del contenedor = imagen construida
  con árbol dañado → rebuild desde árbol limpio.

## 4. Restaurar un log SSB perdido — ⚠️ LA PARTE DELICADA

**REGLA DE ORO: nunca arrancar la GUI de Oasis con un log vacío.** `backend.js` auto-publica
`oasisVersion` al arrancar; sobre log vacío eso crea un seq-1 nuevo → **FORK del feed** frente
al historial que guarda el pub → la replicación del propio feed queda bloqueada para siempre
(EBT no puede reconciliar) y la identidad puede quedar marcada como bifurcada en la red.

Secuencia correcta:

```bash
# 1) Preservar: secret, config, gossip.json, blobs/. Apartar: flume/, ebt/ (derivados),
#    y borrar socket y manifest.json residuales.

# 2) Arrancar sbot PURO (sin GUI → nada puede publicar):
docker compose run -d --rm --no-deps --entrypoint "" --name oasis-sync-only oasis-dev \
  sh -c 'export HOME=/home/oasis SSB_PATH=/home/oasis/.ssb; cd /app/src/server && node SSB_server.js start'

# 3) Vigilar la re-replicación (termómetro = log.offset creciendo):
watch stat -c%s volumes-dev/ssb-data/flume/log.offset

# 4) Preguntar al pub qué tiene de tu feed (respuesta definitiva, no adivinar):
#    dentro del contenedor, con NODE_PATH=/app/src/server/node_modules:
#    ssb-client → createHistoryStream({id: <tu-feed>}) contra
#    net:<pub>:8008~shs:<pub-key>  → nº mensajes y último seq
#    Cuando el log local alcance ese seq: sincronización COMPLETA.

# 5) Solo entonces: parar el sbot puro y arrancar la GUI normal.
#    Su auto-publish caerá en seq N+1 = continuación legítima, sin fork.
docker stop oasis-sync-only && docker start oasis-server-dev
```

**Tips de diagnóstico SSB:**
- "Another Oasis instance is already running" también salta con un `OpenError` de LevelDB
  (flume corrupto), no solo con un lock real (`SSB_server.js`, `isLockError`).
- `conn.json` corrupto bloquea el marcado de conexiones y NO siempre se auto-sana → borrarlo;
  se regenera desde `gossip.json`.
- Conexión al pub verificable sin herramientas: `cat /proc/net/tcp` dentro del contenedor y
  buscar la IP del pub en hex little-endian, estado `01` = ESTABLISHED.
- Si EBT se estanca con la conexión caída y el scheduler no rediala: `docker restart` del
  contenedor fuerza el redial y EBT continúa desde el último seq.
- El `/dev/tcp/...` de bash no existe en el `sh` (dash) del contenedor → falso "no conecta".
  Probar con `curl telnet://host:puerto` (exit 0/52/56 = conectó).
- El perfil (nombre/avatar) son mensajes `about` DEL log: si la GUI muestra la clave truncada,
  no es pérdida de identidad — es que el log aún no tiene los abouts.

## 5. Healthcheck final

- Contenedor `healthy`; la web muestra la versión esperada.
- `Oasis ID` del boot = feed id de siempre.
- Log local en el mismo seq que el pub (paso 4.4) y mensajes nuevos apendizando en seq
  siguientes (sin errores de fork en logs).
- Perfil con nombre y avatar visibles.
- Anotar en el journal (`GANDI_DEVOPS_FOLDER/logs/deploy-history.jsonl`) qué se restauró,
  desde qué fuente y hasta qué seq.

## 6. Después: reducir la superficie de la próxima

- Backup periódico VERIFICADO de `secret` + claves en medio externo (y probar la restauración).
- El pub guarda tu feed: sincronizar el cliente con el pub a menudo ES el backup del log.
- No acumular trabajo sin push: el working tree es un único punto de fallo.
- Mantener `.gitignore` anidados en las carpetas de identidad (patrón `*` + whitelist de
  README/scripts) para que un `git add -A` de emergencia nunca pueda filtrar claves.
