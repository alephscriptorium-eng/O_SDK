# Scriptorium ↔ Oasis Docker: oportunidades de integración

Fecha de análisis: 2026-04-28

## Resumen ejecutivo

El repo `escrivivir-co/alephscript-mcp-model-sdk` en la rama `integration/beta/scriptorium` **no es hoy un reemplazo directo** de la 42 que corre dentro de este `Oasis` Docker.

Esa rama está simplificada para funcionar como **servicio de autoridad de presets MCP** y catálogo de servidores/tools, **sin inferencia AI**.

Eso abre una integración útil, pero de tipo **catálogo/presets/orquestación MCP**, no de sustitución directa del motor de respuesta.

## Qué aporta el repo externo realmente

Fuente inspeccionada:

- rama/ruta GitHub: `integration/beta/scriptorium`
- `README-SCRIPTORIUM.md`
- `package.json`
- `preset_service.mjs`
- `api_bridge.mjs`
- `ai_service.mjs`

### Naturaleza de la rama `scriptorium`

Según `README-SCRIPTORIUM.md`, esta rama simplifica `mcp-model-sdk` para servir **únicamente como fuente de autoridad de presets MCP**, eliminando la inferencia SLMo42.

### Endpoints relevantes del servicio

Servicio simplificado (`preset_service.mjs`):

- `GET /health`
- `GET /status`
- `POST /ai` → respuesta informativa, **sin inferencia**
- `GET /ai/ui/mcp/list`
- `GET /ai/ui/mcp/presets`
- `GET /ai/ui/mcp/preset/:name`
- `POST /ai/ui/mcp/set`

### Dependencias y puertos esperados

- puerto por defecto: `4001`
- Node >= 18
- dependencias mínimas:
  - `@modelcontextprotocol/sdk`
  - `express`
  - `cors`

### Topología prevista por Scriptorium

El README describe este flujo:

1. `Zeus (3012)` consulta catálogo MCP a `mcp-model-sdk (4001)`
2. `mcp-model-sdk` lee `PRESETS/mcp_servers.json`
3. `mcp-model-sdk` consulta `mcp-mesh-sdk (3003)`
4. devuelve catálogo/presets consolidados

### Importante: la rama simplificada no sustituye a la 42

`preset_service.mjs` deja explícito que:

- no hay inferencia
- no hay GPU
- no hay `node-llama-cpp`
- `POST /ai` solo devuelve una respuesta informativa

## Cómo está Oasis Docker hoy

### Acoplamiento actual de la IA

En este repo, `Oasis` usa una IA local muy acoplada:

- `src/backend/backend.js`
  - hace `spawn('node', '../AI/ai_service.mjs')`
  - la ruta `POST /ai` llama fijo a `http://localhost:4001/ai`
- `src/AI/ai_service.mjs`
  - expone `POST /ai` y `POST /ai/train`
  - escucha en `4001`
  - usa `node-llama-cpp`
  - espera el modelo en `src/AI/oasis-42-1-chat.Q4_K_M.gguf`

### Particularidades Docker del setup actual

- `docker-compose.yml`
  - monta `./volumes-dev/ai-models` en `/app/src/AI/models`
  - expone `3000` y `8008`
  - pasa variables GPU (`GPU_ENABLED`, `GPU_LAYERS`, `VRAM_PADDING`)
- `docker-entrypoint.sh`
  - descarga el modelo si falta
  - crea enlace de compatibilidad desde `/app/src/AI/models/...` a `/app/src/AI/...`
  - habilita `aiMod` si detecta modelo

### Idiosincrasia importante del setup actual

Aunque Docker exporta variables GPU, el `src/AI/ai_service.mjs` actual **no las usa** realmente: carga llama con `gpu: false`.

Eso significa que hoy el stack AI de Oasis:

- está funcional
- pero es bastante “legacy/local-first”
- y no está preparado para MCP/presets externos sin cambios

## Choques directos entre ambos mundos

## 1. Colisión de puerto `4001`

- Oasis actual usa `4001` para su `ai_service.mjs`
- Scriptorium por defecto también usa `4001`

Conclusión: **no pueden convivir tal cual** en el mismo contenedor/host lógico.

## 2. Diferencia de propósito

- Oasis actual: servicio de inferencia y respuesta
- Scriptorium branch: servicio de catálogo/presets MCP

Conclusión: no es un swap 1:1.

## 3. `localhost` duro en backend

`backend.js` llama a:

- `http://localhost:4001/ai`

Eso impide:

- sidecar transparente
- servicio AI externo
- preset service en otro contenedor
- uso de `host.docker.internal` o nombre DNS docker

sin tocar código.

## 4. Suposición de `localhost:3003` en el repo externo

El `ai_service.mjs` del repo externo usa ejemplos MCP apuntando a:

- `http://localhost:3003`

Dentro de Docker, `localhost` sería el propio contenedor, no otro servicio del stack.

## 5. Configuración de Oasis demasiado estrecha

`src/configs/oasis-config.json` solo guarda hoy:

- `ai.prompt`

No hay:

- `ai.serviceUrl`
- `ai.mode`
- `ai.presetServiceUrl`
- `ai.mcpMeshUrl`
- `ai.defaultPreset`

## Oportunidades reales de integración

## Oportunidad A — Integración de bajo riesgo: Scriptorium como sidecar de presets MCP

### Idea

Mantener la 42 actual de Oasis tal como está y añadir Scriptorium como servicio auxiliar para:

- descubrir catálogo MCP
- gestionar presets
- persistir presets
- preparar un futuro salto a function-calling/MCP real

### Valor

- bajo riesgo funcional
- no rompe la IA actual
- permite empezar a modelar presets ya
- encaja bien con Docker Compose

### Cambios necesarios

1. Añadir nuevo servicio Compose, por ejemplo:
   - `scriptorium-presets`
2. Ejecutarlo en puerto **distinto de `4001`**:
   - sugerencia: `4011`
3. Añadir config en Oasis:
   - `ai.presetServiceUrl`
   - `ai.defaultPreset`
4. Añadir UI básica en `Settings` o `AI` para:
   - listar presets
   - elegir preset por defecto
   - refrescar catálogo

### Esfuerzo estimado

Bajo a medio.

### Recomendación

**Muy recomendable como primera fase.**

---

## Oportunidad B — Hacer configurable el endpoint AI de Oasis

### Idea

Desacoplar el backend de `http://localhost:4001/ai` y moverlo a configuración.

### Valor

Abre todas las puertas futuras:

- IA interna
- IA externa en sidecar
- gateway híbrido
- pruebas A/B
- fallback local/remoto

### Cambios necesarios

En `backend.js`:

- reemplazar `http://localhost:4001/ai` por algo como:
  - `getConfig().ai?.serviceUrl || 'http://localhost:4001/ai'`

En config:

- `ai.serviceUrl`
- `ai.mode` (`internal`, `external`, `hybrid`, `preset-only`)

### Esfuerzo estimado

Bajo.

### Recomendación

**Recomendación inmediata.**

---

## Oportunidad C — Gateway híbrido: Oasis responde, Scriptorium decide catálogo/preset

### Idea

La respuesta AI sigue saliendo de Oasis/42, pero el contexto de funciones/presets MCP lo resuelve Scriptorium.

### Valor

- camino más elegante a medio plazo
- separa responsabilidades
- permite usar Scriptorium como “control plane” MCP

### Problema actual

La IA actual de Oasis **no tiene** function-calling/MCP nativo ni pipeline de tools compatible con ese repo.

### Cambios necesarios

- enriquecer `src/AI/ai_service.mjs`
- o sustituirlo por un adaptador compatible con:
  - presets MCP
  - tools
  - modos de function calling
- integrar consulta a `scriptorium-presets`

### Esfuerzo estimado

Medio-alto.

### Recomendación

**Buena fase 2**, no fase 1.

---

## Oportunidad D — Sustituir la AI local de Oasis por el `ai_service.mjs` “full” del repo externo

### Idea

No usar la rama simplificada, sino recuperar/usar la variante completa del repo externo con:

- inferencia
- `node_llama_cpp_functions`
- `llama_MCP_functions`
- `node_llama_cpp_MCP_functions`

### Valor

- acercaría muchísimo Oasis a MCP real
- reutiliza infraestructura ya pensada para modos/fallbacks
- podría aprovechar mejor presets y handlers

### Problemas

- el branch `scriptorium` no sirve para esto tal cual
- habría que usar otra rama/mergear capacidades
- el servicio actual de Oasis y el externo tienen modelos de ejecución distintos
- hay diferencias de ruta del modelo y lifecycle

### Esfuerzo estimado

Alto.

### Recomendación

**No ahora**, salvo que la decisión estratégica sea converger Oasis hacia ese SDK como nuevo runtime AI.

---

## Oportunidad E — UI de catálogo MCP en Oasis sin tocar la IA aún

### Idea

Añadir una pequeña sección en Oasis para consumir:

- `GET /ai/ui/mcp/list`
- `GET /ai/ui/mcp/presets`

solo como vista/gestión operativa.

### Valor

- visibilidad inmediata
- poca fricción
- prepara UX antes de tocar la inferencia

### Esfuerzo estimado

Bajo.

### Recomendación

Buena pieza táctica, especialmente si se hace junto con la Oportunidad A.

## Recomendación de estrategia

## Recomendación principal

### Fase 1 — Preparación limpia

1. **No meterlo aún como submódulo oficial**
2. Añadir compatibilidad configurada en Oasis para:
   - `ai.serviceUrl`
   - `ai.presetServiceUrl`
   - `ai.defaultPreset`
3. Levantar Scriptorium como **sidecar** en puerto `4011`
4. Consumir desde Oasis:
   - health
   - catálogo MCP
   - presets

### Fase 2 — Integración útil

5. Añadir UI mínima en `Settings`/`AI`
6. Guardar preset por defecto en config
7. Preparar un adaptador Oasis → Scriptorium para enriquecer requests

### Fase 3 — Decisión grande

8. decidir entre:
   - mantener inferencia local Oasis + presets externos
   - migrar a runtime AI del SDK externo

## Recomendación sobre submódulo

### Mi consejo hoy

**Todavía no como submódulo.**

Motivos:

- la rama analizada es muy específica y simplificada
- todavía no está claro si será:
  - solo catálogo de presets
  - o futuro runtime AI unificado
- antes conviene estabilizar la interfaz entre repos

### Mejor opción por ahora

Usarlo como:

- repo hermano de exploración
- sidecar desacoplado
- o vendor temporal en carpeta de integración

Cuando la interfaz quede clara, entonces sí:

- submódulo fijado a commit
- rama concreta
- contrato de integración explícito

## Touchpoints concretos para futura implementación en Oasis

Archivos a tocar cuando arranque la integración real:

- `src/backend/backend.js`
  - `startAI()`
  - `POST /ai`
- `src/AI/ai_service.mjs`
  - modelo actual local
  - futura adaptación MCP/gateway
- `src/views/AI_view.js`
  - UX para preset/catálogo
- `src/views/settings_view.js`
  - configuración de endpoints/preset por defecto
- `src/configs/config-manager.js`
- `src/configs/oasis-config.json`
- `docker-compose.yml`
  - añadir sidecar Scriptorium
- `docker-entrypoint.sh`
  - opcional, si se quiere bootstrap de integración

## Variables/config que tendría sentido añadir

```json
{
  "ai": {
    "prompt": "Provide an informative and precise response.",
    "mode": "internal",
    "serviceUrl": "http://localhost:4001/ai",
    "presetServiceUrl": "http://scriptorium-presets:4011",
    "defaultPreset": "development",
    "usePresetTools": false,
    "mcpMeshUrl": "http://mcp-mesh:3003"
  }
}
```

## Oportunidades priorizadas

| Prioridad | Oportunidad | Impacto | Coste | Comentario |
|---|---:|---:|---:|---|
| 1 | Hacer configurable `ai.serviceUrl` | Alto | Bajo | desbloquea todo |
| 2 | Scriptorium como sidecar de presets | Alto | Bajo/Medio | camino más limpio |
| 3 | UI de catálogo/presets en Oasis | Medio | Bajo | visibilidad y operación |
| 4 | Gateway híbrido Oasis ↔ Scriptorium | Alto | Medio/Alto | fase 2 natural |
| 5 | Sustitución completa del runtime AI | Muy alto | Alto | decisión estratégica, no táctica |

## Conclusión práctica

La oportunidad más sólida hoy no es “cambiar la 42 por Scriptorium”, sino:

- **mantener la 42 actual viva en Oasis**
- **hacer configurable el endpoint AI**
- **levantar Scriptorium como sidecar de presets MCP**
- **conectar catálogo/presets primero**
- y solo después evaluar convergencia del runtime AI

Eso respeta la idiosincrasia actual del setup Docker y evita romper un flujo que ya está funcionando.
