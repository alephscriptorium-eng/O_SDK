# Hackería Scriptorium — Guía de Mantenimiento

> Catálogo público accesible en `/scriptorium/` del OASIS PUB.  
> Estética: fanzine/poster (fanzine.css). Sin build, HTML estático puro.

---

## Cómo añadir o editar una herramienta

Editar únicamente **`catalog.json`**. El HTML lee este archivo al cargarse.  
No es necesario tocar `index.html` salvo para cambios estructurales de layout.

### Estructura de un ítem

```json
{
  "id": "mi-herramienta",
  "sku": "PLG-CAT-01",
  "name": "Nombre Visible",
  "short": "Descripción de una línea (máx. ~100 chars). Sin puntos finales.",
  "useCase": "Cuándo y por qué usar esta herramienta.",
  "status": "ready | beta | wip",
  "tags": ["tag1", "tag2", "tag3"],
  "agent": "@nombre-agente-bridge",
  "links": {
    "source": "ruta/en/repo/",
    "data": "ARCHIVO/PLUGINS/ID/",
    "url": "https://url-externa-si-aplica"
  }
}
```

**Campos obligatorios**: `id`, `sku`, `name`, `short`, `status`, `tags`  
**Campos opcionales**: `useCase`, `agent`, `links`

### SKU — Prefijos por categoría

| Prefijo | Categoría |
|---------|-----------|
| `PLG-CORE-` | Mostrador (infraestructura) |
| `PLG-AUT-`  | Banco de Autoría |
| `PLG-AGT-`  | Taller de Agentes |
| `PLG-LOG-`  | Herramientas de Lógica |
| `PLG-WIR-`  | Flujos y Wiring |
| `PLG-VEC-`  | Vectorización y Memoria |
| `PLG-PUB-`  | Publicación y Red |
| `INF-PUB-`  | Infraestructura pública |
| `SDK-MCP-`  | SDKs MCP Base |
| `SDK-COG-`  | SDKs Cognitivos (Copilot/VS Code) |
| `SDK-AGT-`  | SDKs de Agentes |
| `SDK-UI-`   | SDKs de UI |
| `SDK-STR-`  | SDKs de Streaming |
| `SDK-UTL-`  | SDKs de Utilidades |

### Categorías disponibles

| ID en JSON | Label visible |
|------------|---------------|
| `mostrador` | Mostrador |
| `autoria` | Banco de Autoría |
| `agentes` | Taller de Agentes |
| `logica` | Herramientas de Lógica |
| `wiring` | Flujos y Wiring |
| `vectorizacion` | Vectorización y Memoria |
| `publicacion` | Publicación y Red |
| `sdks` | SDKs Base |

Para **añadir una categoría nueva**, agregar un objeto al array `categories` con `id`, `label`, `icon` (emoji), `description` e `items`.

---

## Fuentes canónicas (regla DRY)

Esta landing **resume** el ecosistema. No duplica ni sustituye:

| Fuente | Propósito |
|--------|-----------|
| `.github/plugins/registry.json` | Fuente de verdad de plugins instalados |
| `.gitmodules` | Fuente de verdad de submódulos/SDKs |
| `ARCHIVO/DEVOPS/Funcional.md` | Índice funcional DRY (navegación de usuarios) |
| `ARCHIVO/DEVOPS/Tecnico.md` | Índice técnico DRY (arquitectura) |
| `package.json` | Identidad, versión y descripción del Scriptorium |

**Antes de editar items**, consultar `registry.json` para verificar versión, descripción y estado actuales del plugin.

---

## Ruta pública

Servido automáticamente por Caddy vía `try_files`:

```
BlockchainComPort/OASIS_PUB/site/scriptorium/index.html
    → https://pub.escrivivir.co/scriptorium/
```

No requiere cambios en el `Caddyfile`.

## CSS

Usa `/assets/fanzine.css` compartido con el resto del sitio `OASIS_PUB`.  
Los overrides mínimos para la página están en el bloque `<style>` dentro de `index.html`.  
**No crear un archivo CSS separado** salvo que los overrides superen ~100 líneas.

## Futura automatización

El archivo `catalog.json` está preparado para generación parcial automática.  
Un script `scripts/generate-scriptorium-catalog.mjs` podría:

1. Leer `.github/plugins/registry.json` → actualizar items de categorías `PLG-*`.
2. Leer `.gitmodules` → actualizar items de categoría `sdks`.
3. Escribir un nuevo `catalog.json` preservando campos manuales (`useCase`, tags curados).

Hasta implementar ese script, el catálogo se mantiene manualmente consultando las fuentes canónicas.
