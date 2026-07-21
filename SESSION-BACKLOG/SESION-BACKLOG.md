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

**Indicadores de éxito e                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             