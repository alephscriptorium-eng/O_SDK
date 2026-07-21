# 🚀 BACKLOG EXPANSIÓN - ECOin Wallet + Docker Network

**Fecha**: 2025-12-25  
**Prerequisito**: Completar SESION-BACKLOG.md (hackathon principal)  
**Objetivo**: Levantar ECOin wallet en Docker, vincular con Oasis, backup credenciales

**Última actualización**: 2026-04-28  
**Estado actual**: infraestructura ECOin Docker operativa; faltan solo validaciones residuales de integración/UI

---

## 🆕 ACTUALIZACIÓN DE SESIÓN · 2026-04-28

El módulo ECOin quedó **cerrado a nivel de handoff técnico** por otro agente. El detalle verificable vive ahora en:

- `SESSION-BACKLOG/ECOIN_DOCKER_HANDOFF_REPORT_2026-04-28.md`

Resumen corto del estado:

- `ecoin-wallet` construye correctamente
- `ecoin-wallet` arranca correctamente
- el contenedor queda `healthy`
- el RPC responde vía `getinfo`
- Oasis ya dispone de defaults de wallet compatibles con Docker
- quedan pendientes solo validaciones de producto/integración final, no de infraestructura base

---

## 🏗️ ARQUITECTURA DEL SISTEMA

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            HOST WINDOWS                                      │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                        Docker Desktop                                    │ │
│  │  ┌─────────────────────────────────────────────────────────────────────┐│ │
│  │  │              docker network: oasis-network (bridge)                 ││ │
│  │  │                                                                     ││ │
│  │  │   ┌─────────────────────┐       ┌─────────────────────┐            ││ │
│  │  │   │   oasis-server-dev  │       │    ecoin-wallet     │            ││ │
│  │  │   │   ─────────────────│       │   ─────────────────│            ││ │
│  │  │   │   Debian bookworm   │       │   Debian bookworm   │            ││ │
│  │  │   │   Node.js 20.x      │       │   ecoind + ecoin-qt │            ││ │
│  │  │   │   Oasis v0.7.4      │◄─────►│   RPC :7474         │            ││ │
│  │  │   │   :3000 (web)       │  RPC  │   P2P :12000*       │            ││ │
│  │  │   │   :8008 (SSB)       │       │   ~/.ecoin/         │            ││ │
│  │  │   └─────────────────────┘       └─────────────────────┘            ││ │
│  │  │            │                              │                         ││ │
│  │  └────────────┼──────────────────────────────┼─────────────────────────┘│ │
│  │               │                              │                          │ │
│  └───────────────┼──────────────────────────────┼──────────────────────────┘ │
│                  │                              │                            │
│    ┌─────────────┴──────────────┐   ┌──────────┴─────────────┐              │
│    │     localhost:3000         │   │    localhost:7474      │              │
│    │     (Oasis Web UI)         │   │    (ECOin RPC)         │              │
│    │     http://localhost:3000  │   │    Wallet Settings     │              │
│    └────────────────────────────┘   └────────────────────────┘              │
│                                                                              │
│    ┌────────────────────────────────────────────────────────────────────┐   │
│    │                    volumes-dev/ (bind mounts)                       │   │
│    │  ├── ssb-data/     → /home/oasis/.ssb       (Oasis identidad)      │   │
│    │  ├── ai-models/    → /app/src/AI/models     (AI LLM)               │   │
│    │  ├── ecoin-data/   → /home/ecoin/.ecoin     (ECOin wallet)         │   │
│    │  └── logs/         → /var/log/oasis         (logs)                  │   │
│    └────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

\* `12000` es el puerto publicado actualmente por Compose; el daemon ha mostrado bind interno en `7408` y queda pendiente validación final.

---

## 🔗 COMUNICACIÓN ENTRE CONTENEDORES

| Origen | Destino | Puerto | Protocolo | Uso |
|--------|---------|--------|-----------|-----|
| Oasis → ECOin | ecoin-wallet:7474 | 7474 | JSON-RPC | Consultar balance, enviar transacciones |
| Host → Oasis | localhost:3000 | 3000 | HTTP | UI Web Oasis |
| Host → Oasis | localhost:8008 | 8008 | SSB | Protocolo Scuttlebutt |
| Host → ECOin | localhost:7474 | 7474 | JSON-RPC | Debug wallet RPC |
| ECOin → Internet | 46.163.118.220 | `12000` publicado / `7408` observado en daemon | P2P | Red ECOin (validación final pendiente) |

### Configuración de red Docker:

```yaml
# docker-compose.yml (fragmento)
networks:
  oasis-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.28.0.0/16

services:
  oasis-server:
    networks:
      oasis-network:
        aliases:
          - oasis
    
  ecoin-wallet:
    networks:
      oasis-network:
        aliases:
          - ecoin
```

### Configuración Oasis → ECOin:

```json
// src/configs/oasis-config.json
{
  "wallet": {
    "url": "http://ecoin-wallet:7474",  // ← nombre del contenedor en la red
    "user": "ecoinrpc",
    "pass": "ecoinrpc",
    "fee": "5"
  }
}
```

---

## 📋 BACKLOG EXPANSIÓN

| ID | Estado | Tarea | Notas |
|----|--------|-------|-------|
| E1 | ✅ COMPLETADO | **Crear plan de arquitectura** | Diagrama y comunicación documentados |
| E2 | ✅ COMPLETADO | Crear Dockerfile para ECOin | ECOIN_DOCKERIZE/Dockerfile |
| E3 | ✅ COMPLETADO | Crear volumen ecoin-data | volumes-dev/ecoin-data/ creado |
| E4 | ✅ COMPLETADO | Actualizar docker-compose.yml | Servicio ecoin-wallet añadido |
| E5 | ✅ COMPLETADO | Configurar docker network | oasis-network bridge configurada |
| E6 | ✅ COMPLETADO | Build y deploy ECOin | Imagen y contenedor verificados |
| E7 | ✅ COMPLETADO | Sync base + RPC healthy | `getinfo` OK, conexiones activas |
| E8 | ✅ COMPLETADO | Generar wallet address operativa | `npm run ecoin:address` → `EY96LywBi9KC6U488STFexJa3snraeLkTw` |
| E9 | 🟡 PARCIAL | Configurar Oasis → ECOin | defaults Docker implementados; falta validar UI |
| E10 | ⏳ PENDIENTE | Backup credenciales ECOin | `wallet.dat` + política de backup |
| E11 | ⏳ PENDIENTE | Verificar integración completa | Wallet UI / puerto P2P / política `.deb` |

---

## ⚠️ NOTA HISTÓRICA SOBRE EL BUILD

> **Esta sección quedó supersedida por el handoff 2026-04-28.**
>
> ECOin ya no sigue el flujo principal de compilación desde fuente dentro de Docker.
> El build operativo actual usa el paquete precompilado:
> `ECOIN_DOCKERIZE/ecoin_0.0.4-1_amd64.deb`
>
> Detalle técnico completo:
> `SESSION-BACKLOG/ECOIN_DOCKER_HANDOFF_REPORT_2026-04-28.md`

### Comando para build:

```bash
# Build actual del módulo ECOin
npm run ecoin:build

# Levantar servicio
npm run ecoin:up

# Estado / RPC
npm run ecoin:status
npm run ecoin:info
```

---

## 📝 ESTADO ACTUAL (actualizado 2026-04-28)

**Infra cerrada**: sí  
**Handoff técnico**: `SESSION-BACKLOG/ECOIN_DOCKER_HANDOFF_REPORT_2026-04-28.md`

### ✅ COMPLETADO EN EL HANDOFF 2026-04-28:

1. Build de `ecoin-wallet` funcionando con paquete `.deb` precompilado
2. Arranque correcto del contenedor en estado `healthy`
3. Respuesta RPC verificada con `npm run ecoin:info`
4. Scripts npm específicos añadidos para operación ECOin
5. Defaults de wallet en Oasis resueltos desde variables de entorno Docker
6. Bootstrap inicial automatizado desde el paquete ECOin

### ⚠️ VALIDACIONES QUE QUEDAN PARA PRÓXIMA SESIÓN:

1. Confirmar si el puerto P2P publicado debe ser `7408:7408` en vez de `12000:12000`
2. Validar desde la UI de Oasis que Wallet/Banking operan con la config efectiva
3. Decidir política del binario versionado `ECOIN_DOCKERIZE/ecoin_0.0.4-1_amd64.deb`
4. Ejecutar backup explícito de `wallet.dat` cuando se quiera pasar a uso real

### ✅ COMPLETADO EN LA SESIÓN ORIGINAL (2025-12-25):

1. **SESION-BACKLOG.md** - Cerrado con resumen final del hackathon
2. **SESION-BACKLOG-EXPANSION.md** - Creado con plan de arquitectura
3. **ECOIN_DOCKERIZE/Dockerfile** - Dockerfile inicial del módulo (posteriormente sustituido por flujo `.deb` en 2026-04-28)
4. **ECOIN_DOCKERIZE/ecoin.conf** - Configuración RPC para comunicación con Oasis
5. **ECOIN_DOCKERIZE/docker-entrypoint.sh** - Script de inicialización
6. **docker-compose.yml** - Actualizado con servicio ecoin-wallet y red compartida
7. **volumes-dev/ecoin-data/** - Directorio creado para persistencia

### ⏳ PENDIENTE PARA PRÓXIMA SESIÓN:

1. Validar Wallet/Banking desde Oasis UI
2. Revisar mapeo del puerto P2P real de ECOin
3. Decidir si el `.deb` se mantiene en Git o pasa a descarga reproducible
4. Registrar la dirección generada y ejecutar backup de `wallet.dat` si ya se quiere uso funcional

### 🔧 ARCHIVOS CREADOS/MODIFICADOS:

```
alephscript-network-sdk/
├── SESION-BACKLOG.md           # ✏️ Actualizado (cierre hackathon)
├── SESION-BACKLOG-EXPANSION.md # 🆕 Creado
├── docker-compose.yml          # ✏️ Actualizado (+ecoin-wallet)
├── ECOIN_DOCKERIZE/            # 🆕 Carpeta nueva
│   ├── Dockerfile              # ✏️ Runtime ECOin desde paquete `.deb` precompilado
│   ├── ecoin.conf              # 🆕 Config RPC
│   └── docker-entrypoint.sh    # 🆕 Entrypoint script
└── volumes-dev/
    └── ecoin-data/             # 🆕 Directorio creado
```

---

## 🐳 E2: DOCKERFILE PARA ECOIN

### Estrategia actual del Dockerfile

El flujo actual ya no compila `ecoind` desde fuente. El Dockerfile vigente:

- instala `ecoind` desde `ecoin_0.0.4-1_amd64.deb`
- evita la fragilidad de Boost/toolchain en build
- copia `bootstrap.dat` desde el paquete si procede
- normaliza `CRLF` para Debian en `ecoin.conf` y `docker-entrypoint.sh`
- deja scripts npm operativos para build/arranque/RPC

Ficheros clave del flujo vigente:

- `ECOIN_DOCKERIZE/Dockerfile`
- `ECOIN_DOCKERIZE/docker-entrypoint.sh`
- `ECOIN_DOCKERIZE/ecoin_0.0.4-1_amd64.deb`

Detalle técnico y motivación del cambio:

- `SESSION-BACKLOG/ECOIN_DOCKER_HANDOFF_REPORT_2026-04-28.md`

### ecoin.conf para Docker:

```ini
# ECOIN_DOCKERIZE/ecoin.conf
# Configuración ECOin para Docker

# RPC - Comunicación con Oasis
rpcuser=ecoinrpc
rpcpassword=ecoinrpc
rpcport=7474
rpcallowip=172.28.0.0/16

# Server mode
server=1
daemon=0
listen=1
noirc=1

# Peers conocidos (red ECOin)
addnode=46.163.118.220
addnode=82.223.99.61
addnode=5.253.247.48
addnode=primoroso.laenre.net
addnode=alzamoreno.myasustor.com
addnode=ecoin.hacksito.com
addnode=ecoin0.vps.webdock.cloud
addnode=ecoin1.vps.webdock.cloud
addnode=ecoin3.vps.webdock.cloud
addnode=ecoin4.vps.webdock.cloud
```

---

## 🔧 E4: ACTUALIZACIÓN DOCKER-COMPOSE.YML

### Cambios propuestos:

```yaml
# docker-compose.yml (versión expandida)
services:
  oasis-server:
    # ... configuración existente ...
    networks:
      - oasis-network
    environment:
      - ECOIN_RPC_URL=http://ecoin-wallet:7474
      - ECOIN_RPC_USER=ecoinrpc
      - ECOIN_RPC_PASS=ecoinrpc
    depends_on:
      ecoin-wallet:
        condition: service_healthy

  ecoin-wallet:
    build:
      context: ./ECOIN_DOCKERIZE
      dockerfile: Dockerfile
    container_name: ecoin-wallet
    restart: unless-stopped
    networks:
      - oasis-network
    ports:
      - "7474:7474"    # RPC (para debug desde host)
      - "12000:12000"  # P2P publicado actualmente; validar si debe migrar a 7408
    volumes:
      - ./volumes-dev/ecoin-data:/home/ecoin/.ecoin
    healthcheck:
      test: ["CMD", "ecoind", "getinfo"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 120s  # blockchain sync puede tardar

networks:
  oasis-network:
    driver: bridge
```

---

## 📦 E3: ESTRUCTURA DE VOLÚMENES

```bash
volumes-dev/
├── ssb-data/           # Oasis SSB (existente)
│   ├── secret          # Clave privada SSB
│   ├── config          # Config SSB
│   └── gossip.json     # Peers SSB
├── ai-models/          # Modelos AI (existente)
│   └── oasis-42-1-chat.Q4_K_M.gguf
├── ecoin-data/         # ← NUEVO: ECOin wallet
│   ├── wallet.dat      # 🔴 CRÍTICO - Clave privada ECOin
│   ├── ecoin.conf      # Configuración
│   ├── blkindex.dat    # Índice blockchain
│   ├── blk0001.dat     # Datos blockchain
│   └── debug.log       # Logs
└── logs/               # Logs (existente)
```

---

## 🔐 E10: PROTOCOLO BACKUP ECOIN

### Archivos críticos:

| Archivo | Prioridad | Descripción |
|---------|-----------|-------------|
| `wallet.dat` | 🔴 CRÍTICO | Contiene claves privadas ECOin |
| `ecoin.conf` | 🟡 Importante | Configuración (user/pass RPC) |

### Comando backup:

```bash
# Desde host Windows (Git Bash)
mkdir -p /c/Users/aleph/OASIS/ALEPHLUCAS_WALLET_OASIS/backup-ecoin

# Copiar wallet.dat (PARAR CONTENEDOR PRIMERO)
docker stop ecoin-wallet
cp ./volumes-dev/ecoin-data/wallet.dat \
   /c/Users/aleph/OASIS/ALEPHLUCAS_WALLET_OASIS/backup-ecoin/

# Hash para verificación
sha256sum /c/Users/aleph/OASIS/ALEPHLUCAS_WALLET_OASIS/backup-ecoin/wallet.dat

# Reiniciar
docker start ecoin-wallet
```

---

## 🎯 ORDEN DE EJECUCIÓN

```
E1 (Plan) ─► E2 (Dockerfile) ─► E3 (Volumen) ─► E4 (Compose) ─► E5 (Network)
                                                                    │
                                                                    ▼
E11 (Verificar) ◄─ E10 (Backup) ◄─ E9 (Config Oasis) ◄─ E8 (Address) ◄─ E6+E7 (Build+Sync)
```

---

## 🤖 INSTRUCCIONES PARA AGENTES

### Herramientas MCP a usar:

| Tarea | Herramienta |
|-------|-------------|
| Crear archivos Docker | `create_file` |
| Build imagen | `run_in_terminal` → `docker-compose build` |
| Verificar contenedores | `mcp_copilot_conta_list_containers` |
| Ver logs ECOin | `mcp_copilot_conta_logs_for_container` |
| Configurar Oasis UI | `mcp_playwright_browser_*` |
| Backup wallet | `run_in_terminal` → `docker cp` |

### Comandos útiles:

```bash
# Build ECOin
docker-compose build ecoin-wallet

# Levantar solo ECOin
docker-compose up -d ecoin-wallet

# Ver logs sync blockchain
docker logs -f ecoin-wallet

# Verificar RPC funciona
docker exec ecoin-wallet ecoind getinfo

# Obtener nueva dirección
docker exec ecoin-wallet ecoind getnewaddress ""

# Ver balance
docker exec ecoin-wallet ecoind getbalance
```

---

## 📊 ESTADO ACTUAL

| Componente | Estado |
|------------|--------|
| Plan arquitectura | ✅ Documentado |
| Dockerfile ECOin | ✅ Actualizado a flujo `.deb` precompilado |
| docker-compose actualizado | ✅ Modificado |
| Red oasis-network | ✅ Configurada |
| ECOin corriendo | ✅ Healthy |
| Integración Oasis | 🟡 Defaults listos; falta validación UI |
| Backup ECOin | ⏳ Pendiente |

---

## 🔄 PRÓXIMOS PASOS (Siguiente sesión)

```bash
# 1. Ver estado y logs
cd /c/Users/aleph/OASIS/alephscript-network-sdk
npm run ecoin:status
npm run ecoin:info

# 2. Si hace falta dirección operativa
npm run ecoin:address

# 3. Validar desde Oasis UI
# → http://localhost:3000/settings
# → Wallet section
# → comprobar URL/credenciales efectivas

# 4. Revisar puerto P2P real observado en logs
# → confirmar 7408 vs 12000 antes de cerrar integración
```

---

**SIGUIENTE PASO**: Validación final UI/puertos/política del `.deb`; la infraestructura base ya está resuelta
