# SESSION-BACKLOG · actualización 2026-04-28

## Estado actual verificado

- Rama de trabajo actual: `upgrade/oasis-0.7.4`
- Oasis Docker actualizado y verificado en `0.7.4`
- `oasis-dev` levantado en Docker en estado `healthy`
- Auto-update destructivo desde la UI desactivado para despliegue Docker
- Modelo `42` reutilizado desde `volumes-dev/ai-models` sin redescarga
- Handoff de `ECOin` completado a nivel infra/RPC
- Informe de oportunidades de `42`/`Scriptorium` ya movido a esta carpeta

## Artefactos de esta sesión

- `SESSION-BACKLOG/ECOIN_DOCKER_HANDOFF_REPORT_2026-04-28.md`
- `SESSION-BACKLOG/SCRIPTORIUM_INTEGRATION_OPPORTUNITIES.md`

## Protocolo de upgrade Docker → Oasis 0.7.4

### Objetivo

Actualizar Oasis preservando:

- datos SSB
- volumen del modelo AI
- wrapper Docker personalizado
- posibilidad de reconstruir sin mover `volumes-dev/`

### Secuencia aplicada

1. Crear rama de trabajo para el upgrade:
   - `upgrade/oasis-0.7.4`
2. Traer upstream oficial de Oasis y mergear preferencia upstream para app files:
   - remote de trabajo: `oasis-upstream`
   - merge realizado contra `main`
3. Reaplicar barandillas específicas del wrapper Docker:
   - `.dockerignore` para excluir `.git`, `node_modules`, `volumes-dev/`, etc.
   - desactivar auto-update destructivo desde Settings/UI
   - mantener reutilización del modelo `42`
   - enlazar compatibilidad del modelo desde `/app/src/AI/models/...` a `/app/src/AI/...`
4. Reconstruir imagen Docker de `oasis-dev`
5. Resolver residuos de Compose cuando aparezcan:
   - red antigua con labels incorrectas (`oasis-network-dev`)
   - contenedor viejo muerto (`oasis-server-dev`)
6. Recrear contenedor limpio desde la imagen nueva
7. Verificar:
   - `src/server/package.json` dentro del contenedor = `0.7.4`
   - logs con `@krakenslab/oasis [Version: 0.7.4]`
   - `docker compose ps oasis-dev` = `healthy`

### Ficheros tocados durante el upgrade de Oasis

- `.dockerignore`
- `docker-entrypoint.sh`
- `src/backend/backend.js`
- `src/backend/updater.js`
- `src/views/settings_view.js`

### Resultado final del upgrade

- upgrade a `0.7.4` completado
- modelo `42` reutilizado desde volumen persistente
- Docker funcionando con contenedor nuevo y `healthy`
- flujo de actualización seguro documentado para repetirlo

## Cambios exactos de la rama externa `integration/beta/scriptorium`

Comparada contra `dev/astillador`:

- estado: **auto-mergeable**
- commits: **1**
- commit principal: `438fe66` — `feat(scriptorium): sync v1.0.0 - preset service + README`
- archivos cambiados: **3**

### 1. `README-SCRIPTORIUM.md` (nuevo)

Añade documentación formal de la rama como integración de presets MCP para Scriptorium:

- propósito de la rama
- arquitectura Zeus → `mcp-model-sdk` → `mcp-mesh-sdk`
- endpoints MCP UI
- dependencias mínimas
- changelog y estado de integración

### 2. `preset_service.mjs` (nuevo)

Añade un servicio simplificado de presets en `:4001` con:

- `GET /health`
- `GET /status`
- `GET /ai/ui/mcp/list`
- `GET /ai/ui/mcp/presets`
- `GET /ai/ui/mcp/preset/:name`
- `POST /ai/ui/mcp/set`
- `POST /ai` solo informativo, sin inferencia

### 3. `package.json` (simplificado)

Transforma el repo desde host AI/SLMo42 a preset-service:

- `main` pasa a `preset_service.mjs`
- `start` pasa a `node preset_service.mjs`
- se eliminan scripts GPU / inference / testing AI anteriores
- se reducen dependencias a:
  - `@modelcontextprotocol/sdk`
  - `express`
  - `cors`
- `node` requerido baja a `>=18`

## Implicación para decidir paso a `main`

Pasar `integration/beta/scriptorium` a `main` **no es una promoción neutra**.

Lo que hace realmente es convertir ese repo en:

- servicio de catálogo/presets MCP
- sin inferencia local
- sin `node-llama-cpp`
- sin runtime GPU/42

Por eso, antes de llevarlo a `main`, el siguiente paso recomendado es discutir:

1. si el repo debe ser solo preset-service
2. si habrá otra rama/repo para el runtime AI completo
3. cómo encaja con el Oasis Docker actual, que todavía usa `localhost:4001/ai`

## Next steps acordados para la próxima iteración

1. **Discutir el informe de la 42**:
   - `SESSION-BACKLOG/SCRIPTORIUM_INTEGRATION_OPPORTUNITIES.md`
2. Decidir si la primera fase será:
   - endpoint AI configurable en Oasis
   - sidecar Scriptorium en puerto `4011`
   - sin submódulo todavía
3. Revisar si `integration/beta/scriptorium` debe pasar a `main` o permanecer como rama de integración
4. Cerrar validaciones residuales de ECOin:
   - puerto P2P `7408` vs `12000`
   - validación desde UI Wallet de Oasis
   - política del `.deb` versionado