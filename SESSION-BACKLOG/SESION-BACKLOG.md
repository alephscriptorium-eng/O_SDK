# 🎯 BACKLOG SESIÓN - Oasis Docker Setup

**Fecha**: 2025-12-25  
**Objetivo**: Levantar Oasis en Docker, crear cuenta, poner avatar, usar invitación PUB, backup USB

**Última actualización**: 2026-04-28  
**Estado actual**: Oasis Docker actualizado a `0.7.4` en rama `upgrade/oasis-0.7.4`

---

## 🆕 ACTUALIZACIÓN DE SESIÓN · 2026-04-28

- Oasis Docker ha pasado de `0.6.3` a `0.7.4` y quedó verificado en estado `healthy`.
- El protocolo completo de upgrade y el índice de sesión viven ahora en:
  - `SESSION-BACKLOG/README.md`
- El handoff técnico de ECOin quedó consolidado en:
  - `SESSION-BACKLOG/ECOIN_DOCKER_HANDOFF_REPORT_2026-04-28.md`
- El informe para discutir la integración de la `42` con Scriptorium quedó consolidado en:
  - `SESSION-BACKLOG/SCRIPTORIUM_INTEGRATION_OPPORTUNITIES.md`
- La carpeta `docs/` no debe usarse para esta sesión porque forma parte de `gh-pages`; la documentación viva de esta iteración queda en `SESSION-BACKLOG/`.

---

## 🤖 INSTRUCCIONES PARA AGENTES

### Herramientas MCP disponibles:
| Herramienta | Uso |
|-------------|-----|
| **Playwright MCP** | Navegación web automatizada (browser_navigate, browser_click, browser_snapshot, etc.) |
| **Copilot Container Tools** | Gestión Docker (list_containers, logs_for_container, run_container, etc.) |
| **VS Code builtins** | Archivos, terminal, búsqueda, edición |

### Buenas prácticas:
- **Inspeccionar herramientas disponibles** antes de cada sesión
- Usar `browser_snapshot` para verificar estado de UIs web
- Usar `logs_for_container` para debug de contenedores
- Mantener este backlog actualizado en cada iteración

---

## 📋 BACKLOG

| ID | Estado | Tarea | Notas |
|----|--------|-------|-------|
| 0 | ✅ COMPLETADO | **Análisis profundo del repositorio** | Ver hallazgos abajo |
| 0.1 | ✅ COMPLETADO | **Pre-Hackaton: Requisitos sistema** | VS Code, git, gh CLI ✅ |
| 0.5 | ✅ COMPLETADO | **Pre-Sprint: Actualización Oasis** | 0.4.9 → 0.6.3 ✅ |
| 0.6 | ✅ COMPLETADO | **Upgrade Oasis Docker** | 0.6.3 → 0.7.4 ✅ |
| 0.7 | ✅ COMPLETADO | **Handoff ECOin Docker** | Ver `SESSION-BACKLOG/ECOIN_DOCKER_HANDOFF_REPORT_2026-04-28.md` |
| 0.8 | ⏳ SIGUIENTE | **Discusión 42 / Scriptorium** | Ver `SESSION-BACKLOG/SCRIPTORIUM_INTEGRATION_OPPORTUNITIES.md` |
| 1 | ✅ COMPLETADO | Preparar entorno (volúmenes, configs) | volumes-dev/ listo |
| 2 | ✅ COMPLETADO | Build imagen Docker | 208s ✅ |
| 3 | ✅ COMPLETADO | Levantar contenedor | histórico v0.6.3; estado actual: `0.7.4 healthy` ✅ |
| 4 | ✅ COMPLETADO | Verificar acceso web localhost:3000 | Playwright verificado ✅ |
| 5 | ✅ COMPLETADO | Crear identidad / perfil / avatar | AlephLucas ✅ |
| 6 | ✅ COMPLETADO | **BACKUP credenciales USB** | Backup completo en ALEPHLUCAS_WALLET_OASIS |
| 7 | ✅ COMPLETADO | Usar invitación PUB | Conectado a La Plaza (solarnethub.com) ✅ |

### 📝 Tarea 5 - COMPLETADA ✅
- Nombre: AlephLucas
- Descripción: Lucas - Agente de Aleph Scriptorium
- Avatar: Imagen de lucas descargada de GitHub
- KARMA: 1

---

## 🔐 PROCESO DE BACKUP DE CREDENCIALES SSB (Tarea 6)

> ⚠️ **CRÍTICO**: Sin este backup, la identidad SSB se pierde para siempre.
> No hay "recuperar contraseña" - es criptografía asimétrica.

---

### 📋 PROTOCOLO COMPLETO DE BACKUP (Paso a paso)

Este protocolo genera un backup completo con:
- Clave privada en texto plano (`secret`)
- Clave privada cifrada (`oasis.enc`)
- Metadatos de trazabilidad
- Verificación de integridad

#### Paso 1: Crear carpeta destino

```bash
# Reemplazar <DESTINO> por la ruta deseada (USB, otra carpeta, etc.)
mkdir -p /<DESTINO>/<NOMBRE_WALLET>
```

#### Paso 2: Ejecutar script de backup

```bash
# Desde la raíz del proyecto
bash ./docker-scripts/backup-keys.sh /<DESTINO>/<NOMBRE_WALLET>
```

Esto copia automáticamente:
- `secret` (clave privada) con verificación SHA256
- `config` (configuración del nodo)
- `gossip.json` (peers conocidos)
- `README.txt` (instrucciones de restauración)

#### Paso 3: Exportar clave cifrada desde UI

```bash
# 1. Abrir navegador en:
#    http://localhost:3000/legacy

# 2. Copiar el password generado (32 chars hex) que aparece en la página
#    Ejemplo: 3625b8df24bb4357d9049d552d7a2f01

# 3. Pegarlo en el campo "Use lowercase, uppercase, numbers & symbols"

# 4. Click "Export"
#    → Esto genera /home/oasis/oasis.enc dentro del contenedor
```

#### Paso 4: Extraer archivo cifrado del contenedor

```bash
# Obtener nombre del contenedor
docker ps --format "{{.Names}}" | grep oasis

# Copiar oasis.enc al backup (reemplazar <CONTAINER_NAME>)
docker cp <CONTAINER_NAME>:/home/oasis/oasis.enc /<DESTINO>/<NOMBRE_WALLET>/
```

#### Paso 5: Crear archivo de metadatos

```bash
cat > /<DESTINO>/<NOMBRE_WALLET>/EXPORT_METADATA.json << 'EOF'
{
  "backup_info": {
    "created_at": "$(date -Iseconds)",
    "session": "<NOMBRE_RAMA_GIT>",
    "commit": "<HASH_COMMIT>"
  },
  "identity": {
    "ssb_id": "<TU_SSB_ID>",
    "profile_name": "<TU_NOMBRE_PERFIL>"
  },
  "exports": [
    {"file": "secret", "method": "backup-keys.sh", "description": "Clave privada plana"},
    {"file": "oasis.enc", "method": "Oasis UI /legacy", "description": "Clave cifrada AES-256-CBC"},
    {"file": "config", "method": "backup-keys.sh", "description": "Configuración nodo"},
    {"file": "gossip.json", "method": "backup-keys.sh", "description": "Lista peers"}
  ]
}
EOF
```

#### Paso 6: Guardar password de cifrado

```bash
cat > /<DESTINO>/<NOMBRE_WALLET>/ENCRYPTION_PASSWORD.txt << 'EOF'
Password: <EL_PASSWORD_DE_32_CHARS>
Algoritmo: AES-256-CBC
Para restaurar: http://localhost:3000/legacy → Import
EOF
```

#### Paso 7: Verificar backup

```bash
# Verificar integridad
sha256sum /<DESTINO>/<NOMBRE_WALLET>/secret
# Debe coincidir con:
sha256sum ./volumes-dev/ssb-data/secret

# Listar contenido final
ls -la /<DESTINO>/<NOMBRE_WALLET>/
```

---

### 🔍 Mecanismos de backup disponibles:

| Método | Ubicación | Descripción |
|--------|-----------|-------------|
| **UI Web (Oasis)** | `/legacy` | Export/Import cifrado con password (min 32 chars) → `oasis.enc` |
| **Script Docker** | `npm run backup-keys` | Copia archivos del volumen a carpeta local con verificación SHA256 |
| **Manual** | Terminal | Copiar directamente `./volumes-dev/ssb-data/secret` |

### Archivos del backup:

| Archivo | Prioridad | Descripción | Método |
|---------|-----------|-------------|--------|
| `secret` | 🔴 CRÍTICO | Clave privada SSB (texto plano) | backup-keys.sh |
| `oasis.enc` | 🔴 CRÍTICO | Clave privada cifrada AES-256-CBC | UI /legacy + docker cp |
| `config` | 🟡 Importante | Configuración del nodo | backup-keys.sh |
| `gossip.json` | 🟢 Opcional | Lista de peers conocidos | backup-keys.sh |
| `EXPORT_METADATA.json` | 🟡 Importante | Trazabilidad de exports | Manual |
| `ENCRYPTION_PASSWORD.txt` | 🔴 CRÍTICO | Password para oasis.enc | Manual |
| `README.txt` | 🟢 Opcional | Instrucciones restauración | backup-keys.sh |

### Placeholders para esta sesión:

| Placeholder | Valor esta sesión | Descripción |
|-------------|-------------------|-------------|
| `<DESTINO>` | `/c/Users/aleph/OASIS` | Ruta base del backup |
| `<NOMBRE_WALLET>` | `ALEPHLUCAS_WALLET_OASIS` | Nombre carpeta wallet |
| `<CONTAINER_NAME>` | `oasis-server-dev` | Nombre del contenedor Docker |
| `<TU_SSB_ID>` | `@rZql/UwfYArm00RnK19+9HlBZhK7gxE++m/opHBG7vo=.ed25519` | ID SSB |
| `<TU_NOMBRE_PERFIL>` | `AlephLucas` | Nombre del perfil |
| `<PASSWORD_32_CHARS>` | `3625b8df24bb4357d9049d552d7a2f01` | Password cifrado |

---

### ⚠️ WARNING: BACKUP TEMPORAL - NO ES SEGURO

> **🔴 ACCIÓN PENDIENTE**: El backup actual está en el MISMO DISCO.
> 
> Si el disco falla → PIERDES TODO.
> 
> **DEBES copiar `C:\Users\aleph\OASIS\ALEPHLUCAS_WALLET_OASIS\` a:**
> - 📀 Un USB extraíble, O
> - 💻 Otro ordenador diferente, O  
> - ☁️ Almacenamiento en la nube cifrado

### ✅ Backup temporal completado:
```
Ubicación: C:\Users\aleph\OASIS\ALEPHLUCAS_WALLET_OASIS\backup-completo\

Archivos exportados:
  - secret              (869 bytes) - Clave privada plana ✅ [CLI backup-keys.sh]
  - oasis.enc           (880 bytes) - Clave privada cifrada ✅ [Oasis UI /legacy]
  - config              (406 bytes) - Configuración ✅ [CLI backup-keys.sh]
  - gossip.json         (2 bytes)   - Peers ✅ [CLI backup-keys.sh]
  - EXPORT_METADATA.json            - Trazabilidad de exports ✅
  - ENCRYPTION_PASSWORD.txt         - Password para oasis.enc ✅
  - README.txt                      - Instrucciones de restauración ✅
  
Hash SHA256 secret: def0fc72eb668f2dda986fd9f54249fd37488d6f1c6a11af721ba0af15728d99
Password oasis.enc: 3625b8df24bb4357d9049d552d7a2f01
```

---

## 🌐 PROTOCOLO DE CONEXIÓN A PUB (Tarea 7) ✅ COMPLETADO

> **¿Qué es un PUB?** Un PUB (Public Peer) es un servidor SSB que actúa como relay.
> Sin un PUB, tu nodo solo puede comunicarse con peers en red local.
> Con un PUB, te conectas a la red global SSB y sincronizas con otros usuarios.

---

### 📋 PROTOCOLO COMPLETO DE CONEXIÓN A PUB (Paso a paso)

Este protocolo conecta tu nodo Oasis a un PUB de la red SSB y verifica la sincronización.

#### Prerrequisitos:
- ✅ Contenedor Oasis corriendo (`docker ps` muestra healthy)
- ✅ Identidad SSB creada (secret generado)
- ✅ Acceso web a `http://localhost:3000`
- ✅ Código de invitación PUB válido

---

#### Paso 1: Obtener código de invitación PUB

Los códigos de invitación PUB tienen el formato:
```
<host>:<puerto>:<@pub_id.ed25519>~<codigo_invitacion>
```

**Fuentes de invitaciones:**
| Fuente | URL/Contacto |
|--------|--------------|
| SSB Pubs List | https://github.com/ssbc/ssb-server/wiki/Pub-Servers |
| Oasis community | Canales SSB existentes |
| Administrador del PUB | Contacto directo |

**Anatomía del código:**
```
solarnethub.com:8008:@HzmUrdZb1vRWCwn3giLx3p/EWKuDiO44gXAaeulz3d4=.ed25519~pbpoWsf3r7uqzE6vHpnqTu9Tw2kgFUROHYBfLz/9aIw=
│               │    │                                                      │ │
│               │    └── SSB ID del PUB (clave pública ed25519)              │ │
│               └── Puerto SSB (por defecto 8008)                            │ │
│                                                                            │ │
└── Hostname del servidor                           Token de invitación ─────┘ │
                                                    (uso único, expira) ───────┘
```

---

#### Paso 2: Navegar a la página de invitaciones

```bash
# Abrir en navegador:
http://localhost:3000/invites
```

La página muestra:
- Campo de texto: "Enter PUB invite code"
- Botón: "Join PUB"
- Lista de PUBs ya conectados (si los hay)

---

#### Paso 3: Ingresar código de invitación

1. Copiar el código completo de invitación
2. Pegarlo en el campo "Enter PUB invite code"
3. Verificar que no haya espacios al inicio/final
4. Click en **"Join PUB"**

**Formatos aceptados:**
```bash
# Formato legacy (funciona)
host:puerto:@key.ed25519~invite

# Formato con protocolo (también funciona)
net:host:puerto~shs:key~invite
```

---

#### Paso 4: Verificar conexión en UI

Navegar a la página de peers:
```bash
http://localhost:3000/peers
```

**Estados esperados:**

| Estado | Significado | Icono |
|--------|-------------|-------|
| **Online** | Conexión activa con el PUB | 🟢 |
| **Discovered** | PUB conocido, pendiente sync | 🟡 |
| **Offline** | Sin conexión al PUB | 🔴 |

**Resultado exitoso:**
```
Online (1): PUB solarnethub.com
Discovered (1): PUB solarnethub.com
```

---

#### Paso 5: Verificar sincronización en logs

```bash
# Obtener nombre del contenedor
docker ps --format "{{.Names}}" | grep oasis

# Ver logs en tiempo real (últimas 50 líneas)
docker logs --tail 50 -f <CONTAINER_NAME>
```

**Indicadores de éxito en logs:**

| Log | Significado |
|-----|-------------|
| `Synced-peers: [ 1 ]` | Primera conexión al PUB |
| `Synced-peers: [ N ]` | N peers sincronizados (descubiertos vía PUB) |
| `Sync-time: Xms` | Tiempo de sincronización |
| `Connected to PUB` | Conexión establecida |

**Ejemplo de logs exitosos:**
```
Synced-peers: [ 1 ]
Sync-time: 127.456ms
Synced-peers: [ 17 ]
Sync-time: 8.777ms
```

---

#### Paso 6: Guardar invitación en wallet (trazabilidad)

```bash
# Crear archivo con invitaciones usadas
cat >> /<DESTINO>/<NOMBRE_WALLET>/PUB_INVITATIONS.txt << 'EOF'
================================================================================
PUB: <NOMBRE_PUB>
Fecha: <FECHA_CONEXION>
================================================================================
Host: <HOST>:<PUERTO>
PUB ID: <@PUB_ID.ed25519>
Código completo: <CODIGO_INVITACION_COMPLETO>

Estado: CONECTADO ✅
Peers sincronizados: <N>
================================================================================
EOF
```

---

#### Paso 7: Verificación final

Checklist de verificación:

| Check | Comando/Acción | Esperado |
|-------|----------------|----------|
| UI /peers | Navegador → localhost:3000/peers | Online (N): PUB visible |
| Logs container | `docker logs --tail 20 <container>` | Synced-peers: [ N ] |
| Feed | localhost:3000 (home) | Posts de otros usuarios |
| Activity | localhost:3000/activity | Menciones y actividad |

---

### 🔍 Troubleshooting conexión PUB

| Problema | Causa probable | Solución |
|----------|----------------|----------|
| "Invalid invite" | Código mal formateado o expirado | Solicitar nuevo código |
| Sin peers después de 5 min | Firewall bloquea puerto 8008 | Verificar firewall, abrir 8008 |
| PUB aparece Offline | Servidor PUB caído | Probar otro PUB |
| 0 synced-peers | Nodo muy nuevo, sin contenido | Esperar, seguir a alguien |

**Verificar conectividad al PUB:**
```bash
# Desde el host (fuera del container)
nc -zv solarnethub.com 8008

# Debería responder:
# Connection to solarnethub.com 8008 port [tcp/*] succeeded!
```

---

### 📦 Placeholders para conexión PUB:

| Placeholder | Valor esta sesión | Descripción |
|-------------|-------------------|-------------|
| `<CONTAINER_NAME>` | `oasis-server-dev` | Nombre del contenedor Docker |
| `<NOMBRE_PUB>` | `La Plaza (Ciclo 3)` | Nombre descriptivo del PUB |
| `<HOST>` | `solarnethub.com` | Hostname del PUB |
| `<PUERTO>` | `8008` | Puerto SSB del PUB |
| `<@PUB_ID.ed25519>` | `@HzmUrdZb1vRWCwn3giLx3p/EWKuDiO44gXAaeulz3d4=.ed25519` | ID SSB del PUB |
| `<CODIGO_INVITACION_COMPLETO>` | `solarnethub.com:8008:@HzmUrdZb1vRWCwn3giLx3p/EWKuDiO44gXAaeulz3d4=.ed25519~pbpoWsf3r7uqzE6vHpnqTu9Tw2kgFUROHYBfLz/9aIw=` | Código completo |
| `<FECHA_CONEXION>` | `2025-12-25` | Fecha de conexión |
| `<N>` | `17` | Número de peers sincronizados |

---

### ✅ Resultado sesión actual:

```
PUB: La Plaza (Ciclo 3)
Host: solarnethub.com:8008
PUB ID: @HzmUrdZb1vRWCwn3giLx3p/EWKuDiO44gXAaeulz3d4=.ed25519

Estado final:
- UI /peers: Online (1) ✅
- Synced-peers: 17 ✅
- Sync-time: 8.777ms ✅

Invitación archivada en:
C:\Users\aleph\OASIS\ALEPHLUCAS_WALLET_OASIS\backup-completo\PUB_INVITATIONS.txt
```

---

## 🛠️ PRE-HACKATON: REQUISITOS SISTEMA (0.1) ✅ COMPLETADO

| Requisito | Estado | Notas |
|-----------|--------|-------|
| VS Code | ✅ | En uso |
| Git | ✅ | Funcionando |
| Docker | ✅ | v29.1.3 + Compose v2.40.3 |
| NVIDIA Runtime | ✅ | Quadro P2000 detectada |
| gh CLI | ✅ | v2.83.2 instalado |
| Auth GitHub | ✅ | escrivivir-co autenticado |
| **🔴 USB extraíble** | ⏳ | **CRÍTICO** - Para backup de credenciales SSB |

---

## 🔧 PRE-SPRINT: ACTUALIZACIÓN OASIS (0.5) ✅ COMPLETADO

**Resultado**: Merge exitoso de oasis 0.6.3

```
Rama: hackaton_261225
Commit: 678819e - Merge oasis 0.6.3 - take theirs for app files
Versión: 0.6.3 (antes 0.4.9)
```

### Archivos PRESERVADOS (nuestros) ✅:
- Dockerfile
- docker-compose.yml  
- docker-entrypoint.sh
- docker-scripts/*
- package.json (raíz)

### Archivos ACTUALIZADOS (theirs) ✅:
- src/backend/backend.js (+168 líneas - fix menciones)
- src/models/*.js (nuevos: courts, parliament, favorites)
- src/views/*.js (nuevos: courts, parliament, favorites)
- src/server/package.json → 0.6.3
- docs/CHANGELOG.md

### Conflicto resuelto:
- `src/AI/ai_service.mjs` - aceptado versión upstream

> ℹ️ **Nota histórica**: este checkpoint queda supersedido por el upgrade del 2026-04-28 a `0.7.4`. Ver `SESSION-BACKLOG/README.md`.

---

## 🔄 PROTOCOLO DE UPGRADE OASIS DOCKER → 0.7.4 (0.6) ✅ COMPLETADO

**Rama de trabajo**: `upgrade/oasis-0.7.4`

### Resumen del protocolo aplicado

1. Crear rama de upgrade aislada.
2. Traer upstream oficial de Oasis y mergear preferencia upstream para app files.
3. Reaplicar personalizaciones Docker imprescindibles:
  - `.dockerignore`
  - desactivación del auto-update destructivo en UI
  - reutilización del modelo `42` desde volumen persistente
  - enlace de compatibilidad al path legacy del modelo
4. Reconstruir la imagen de `oasis-dev`.
5. Limpiar residuos de Docker Compose si aparecían:
  - red `oasis-network-dev` con label antigua
  - contenedor viejo muerto
6. Recrear el contenedor desde la imagen nueva.
7. Verificar en runtime:
  - `version = 0.7.4`
  - contenedor `healthy`
  - modelo `42` reutilizado sin redescarga

### Resultado verificado

- Contenedor nuevo de `oasis-dev` arriba y `healthy`
- Logs con `@krakenslab/oasis [Version: 0.7.4]`
- Modelo reutilizado desde `volumes-dev/ai-models`
- Auto-update de UI convertido en aviso informativo para Docker

### Ficheros relevantes tocados en el upgrade

- `.dockerignore`
- `docker-entrypoint.sh`
- `src/backend/backend.js`
- `src/backend/updater.js`
- `src/views/settings_view.js`

### Documentación detallada

- `SESSION-BACKLOG/README.md`

---

## 📝 ANÁLISIS COMPLETO DEL REPOSITORIO

### Arquitectura descubierta:

```
package.json scripts:
├── npm run setup      → docker-scripts/setup.sh (crea volumes-dev/)
├── npm run build      → docker-compose build
├── npm run up         → setup + docker-compose up -d
├── npm run logs       → docker-compose logs -f
├── npm run shell      → acceso bash al contenedor
├── npm run backup-keys→ docker-scripts/backup-keys.sh ⚠️ NO EXISTE
└── npm run web        → abre http://localhost:3000
```

### docker-entrypoint.sh (501 líneas) hace:
1. `setup_ssb_config()` - Genera clave SHS y config SSB
2. `download_ai_model()` - Descarga modelo 3.8GB si no existe
3. `install_runtime_deps()` - Instala deps faltantes
4. `apply_node_patches()` - Parchea ssb-ref, ssb-blobs, multiserver
5. `setup_oasis_config()` - Activa/desactiva AI según modelo
6. Inicia `backend.js` en modo full

### docker-compose.yml:
- Puerto 3000 (web) y 8008 (SSB)
- GPU NVIDIA habilitada (tu Quadro P2000 sirve)
- Volúmenes bind a `./volumes-dev/{ssb-data,ai-models,logs}`

### ⚠️ PROBLEMAS DETECTADOS:

1. **`npm run backup-keys` referencia un script que NO EXISTE**
   - `docker-scripts/backup-keys.sh` no está en el repo
   - SOLUCIÓN: Crearlo nosotros

2. **El setup.sh crea un dir `configs/` que el compose NO usa**
   - setup.sh: `mkdir -p volumes-dev/{ssb-data,ai-models,configs,logs}`
   - compose: solo monta ssb-data, ai-models, logs
   - No es problema, simplemente sobra

3. **Permisos en Windows**
   - `chmod 700` en setup.sh no aplica en NTFS
   - No debería ser problema para Docker (Linux dentro)

### ✅ COSAS QUE ESTÁN BIEN:

- Los volúmenes `volumes-dev/` YA EXISTEN (los creé antes precipitadamente)
- Docker tiene nvidia runtime configurado
- Tu GPU Quadro P2000 4GB es suficiente para el modelo Q4_K_M

---

---

## 🚨 ISSUE CRÍTICO: ACTUALIZACIÓN DE VERSIÓN

### Situación actual:
| Concepto | Valor |
|----------|-------|
| **Versión local** | 0.4.9 (Sept 2025) |
| **Versión upstream** | 0.6.3 (10 Dic 2025) |
| **Salto** | 14 releases (0.4.9 → 0.5.0 → ... → 0.6.3) |

### Análisis del salto 0.4.9 → 0.6.3:

**Cambios mayores entre 0.5.0 y 0.6.3:**
- 🆕 Parliament plugin (sistema de gobierno)
- 🆕 Courts plugin (resolución de conflictos)
- 🆕 Footer añadido (Core plugin)
- 🆕 Favorites para módulos media
- 🔧 Muchos fixes en Feed, Mentions, Search, Activity
- 🔒 Security fixes en 0.6.2

**Archivos modificados en 0.6.3 específicamente:**
- `src/backend/backend.js` (+168/-66 líneas) ← **CAMBIO GRANDE en mentions**
- `src/models/feed_model.js` (+38/-7 líneas)
- `src/views/activity_view.js`, `feed_view.js`, `main_views.js`, `market_view.js`
- `src/server/package.json` (version bump)

### 🎯 DECISIÓN ESTRATÉGICA:

**OPCIÓN A - Actualizar primero (RECOMENDADO)**
- Pros: Tendremos la última versión, security fixes, mejor UX
- Cons: Puede romper algo del entorno Docker personalizado
- Riesgo: MEDIO (solo fixes, no breaking changes según semver)

**OPCIÓN B - Continuar con 0.4.9**  
- Pros: Sin riesgo de romper nada
- Cons: Versión desactualizada, bugs conocidos en mentions/feeds

### ⚠️ EVALUACIÓN DE RIESGO:

El commit 0.6.3 es **solo FIXES**, no hay breaking changes:
```
+ Fixed mentions (Core plugin).
+ Fixed feeds (Feed plugin).
+ Minor details at market view (Market plugin).
```

El cambio en `backend.js` es una **reescritura de la función `preparePreview`** 
para arreglar las menciones. Es interno, no cambia API.

**VEREDICTO**: Actualizar es **seguro** según semver. El riesgo está en si el 
entorno Docker del fork `alephscript-network-sdk` tiene modificaciones propias 
que conflicten.

---

## 🔄 HISTORIAL DE ITERACIONES

### Iteración 0 - Análisis profundo
**Estado**: ✅ COMPLETADO  
**Hallazgos**: Ver arriba. El repo está bien estructurado pero falta backup-keys.sh

### Iteración 1 - Análisis de versiones
**Estado**: ✅ COMPLETADO  
**Hallazgos**: 
- Local: 0.4.9, Upstream: 0.6.3 (14 releases de diferencia)
- Cambios son fixes, no breaking changes
- Archivos críticos modificados: backend.js, feed_model.js, views

### Iteración 2 - Decisión de actualización
**Estado**: ✅ COMPLETADO  
**Decisión**: Opción A - Actualizado a 0.6.3

---

## 🏁 CIERRE DE HACKATHON - RESUMEN FINAL

**Fecha cierre**: 2025-12-25  
**Estado**: ✅ TODOS LOS OBJETIVOS COMPLETADOS

### Logros de esta sesión:

| Objetivo | Estado | Resultado |
|----------|--------|-----------|
| Levantar Oasis en Docker | ✅ | v0.6.3 funcionando, GPU habilitada |
| Crear cuenta y avatar | ✅ | AlephLucas creado, KARMA: 1 |
| Usar invitación PUB | ✅ | Conectado a La Plaza (17 peers) |
| Backup credenciales | ✅ | Protocolo documentado, backup temporal |

### Identidad SSB creada:

```
Nombre: AlephLucas
SSB ID: @rZql/UwfYArm00RnK19+9HlBZhK7gxE++m/opHBG7vo=.ed25519
PUB: solarnethub.com:8008 (La Plaza Ciclo 3)
Peers sincronizados: 17
```

### Archivos de backup:

```
Ubicación temporal: C:\Users\aleph\OASIS\ALEPHLUCAS_WALLET_OASIS\backup-completo\
⚠️ ACCIÓN REQUERIDA: Copiar a USB externo
```

### Protocolos documentados:

1. **Protocolo de Backup SSB** (7 pasos) - Sección "PROCESO DE BACKUP"
2. **Protocolo de Conexión a PUB** (7 pasos) - Sección "PROTOCOLO DE CONEXIÓN A PUB"

### Próximos pasos sugeridos (actualizado 2026-04-28):

- 🧠 **PRIORIDAD 1**: Discutir el informe de la `42` y decidir la estrategia con Scriptorium:
  - `SESSION-BACKLOG/SCRIPTORIUM_INTEGRATION_OPPORTUNITIES.md`
- 🔀 Revisar el delta exacto de la rama externa `integration/beta/scriptorium` y decidir si debe pasar a `main` o seguir como rama de integración.
- 💰 Cerrar validaciones residuales del módulo ECOin:
  - `SESSION-BACKLOG/ECOIN_DOCKER_HANDOFF_REPORT_2026-04-28.md`
- 📀 Mantener la recomendación histórica: copiar el backup SSB a USB externo.
- 🌐 Continuar exploración funcional de Oasis ya sobre `0.7.4`.

---

**FIN DEL BACKLOG HACKATHON PRINCIPAL**

---

> 📘 **¿Quieres más?** Continúa con `SESION-BACKLOG-EXPANSION.md` para:
> - Levantar ECOin wallet en Docker
> - Vincular wallet con Oasis
> - Configurar minería PoS/PoW/PoT  

