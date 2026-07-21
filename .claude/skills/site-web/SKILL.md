---
name: site-web
description: >-
  Método de copy + protocolo de publicación web (VitePress, Pages, piel
  zine). Parametriza «el mundo»; separa método (aquí) de datos (cantera /
  entrega del consumidor). Sin nombres de mundo real ni del marco.
---

# Skill `site-web`

Generá y publicá la capa de contenido de un portal FOSS: argumento,
inventario del sistema, mecanismo de generación (backtracking + filtros) y
pipeline Pages. El skill lleva el **método**. Los datos concretos viven en
la calibración local del mundo (o en `instancias/` del paquete, fuera de
esta carpeta).

## Cuándo aplicar

Cuando el agente deba:

1. Redactar / regenerar superficies de un portal a partir de bases
   fundacionales.
2. Empaquetar reemplazos verbatim para un swarm consumidor (§E).
3. Montar o auditar el pipeline de docs → GitHub Pages (CNAME, base,
   workflow, piel zine).

## Parámetros del mundo (calibración)

Leé primero la calibración local (si existe). Mínimo:

| clave | ejemplo de forma | para qué |
| ----- | ---------------- | -------- |
| `mundo.id` | slug corto | nombre lógico |
| `mundo.docs` | `docs/` | raíz VitePress |
| `mundo.dominio` | `portal.ejemplo.co` | CNAME + checklist DNS |
| `mundo.base_env` | `DOCS_BASE` | env del guard de `base` |
| `mundo.registry` | URL del registry | anuncios de canal real (C8) |
| `mundo.ceguera` | regex | prueba delta 5 del mundo |
| `mundo.lexico_no` | regex | filtro C1 |

Nunca hardcodees rutas absolutas de otro árbol ni nombres de mundos ajenos
en la copy pública ni en plantillas del skill.

## Separación método / datos

```
skill (método)          mundo (datos / instancia)
─────────────────        ──────────────────────────
BASE-1/2/3 plantilla  →  cantera/  (inventarios, snapshots)
protocolo ghpages     →  entrega/  (paquete §E vigente)
filtros C1–C9         →  decisiones vivas del marketing local
piel zine (patrón)    →  custom.css copia-release del mundo
```

`CANTERA` y `ENTREGA-*` de un mundo concreto **no** entran en este skill.
Son instancia: el consumidor las mantiene fuera.

## Pasos

### A · Capa de contenido (método de bases)

1. Completar / actualizar las tres bases del mundo desde
   `reference/plantillas/` (argumento, sistema, mecanismo).
2. Consultar cantera local **solo** para datos; no deja dirigir.
3. Generar superficies con `reference/metodo-mecanismo.md` §B–§D.
4. Pasar filtros §C (incl. C8 canal real, C9 listas vivas, ceguera del
   mundo).
5. Si el destino es un swarm: empaquetar en formato §E (reemplazos
   verbatim + CA).

### B · Iteración de backtracking

Si marketing pide «otra iteración de backtracking»:

1. Marketing edita a mano el paquete de entrega (bloques canónicos =
   verbatim).
2. El agente extrae el patrón → escribe regla en BASE-2 y/o BASE-3.
3. Re-ejecuta la pipeline sobre el **resto**; no toca bloques canónicos.

### C · Protocolo ghpages

1. Config VitePress con `base` parametrizado + guard MSYS
   (`reference/protocolo-ghpages.md`).
2. Workflow `docs.yml` (npm ci, paths `docs/**`, concurrency, deploy solo
   `main`).
3. `docs/public/CNAME` = dominio del mundo (frágil #1).
4. Piel zine: copia-release con cabecera de procedencia; tipografía local;
   cero CDN / fuentes web.
5. Checklist DNS → Pages + Enforce HTTPS.
6. Mitigar los 7 frágiles documentados en el protocolo.
7. **Gate de verificación**: correr `scripts/verificar-sitio.mjs` sobre el
   `dist/` (enlaces internos + anclas + externos + verdad de contenido)
   antes del deploy. Falla ante roto interno/ancla; cubre los hrefs de
   componentes `.vue` que `ignoreDeadLinks` no ve.

## Recursos

- `reference/metodo-argumento.md` — BASE-1 abstraída
- `reference/metodo-sistema.md` — BASE-2 abstraída
- `reference/metodo-mecanismo.md` — BASE-3 (backtracking, C8/C9, §E)
- `reference/protocolo-ghpages.md` — Pages + 7 frágiles
- `reference/plantillas/` — ficheros listos para copiar al mundo
- `examples/mundo-limpio/` — fixture inventada (sin datos de mundo real)
- `scripts/ceguera.sh` — grep de ceguera sobre `skills/site-web/`
- `scripts/generar-sitio.sh` — scaffold parametrizado a un dir destino
- `scripts/verificar-sitio.mjs` — gate de enlaces (dist) + anclas +
  externos (warning) + verdad de contenido; falla ante roto interno/ancla

## Prueba de ceguera (antes de publicar el skill)

```bash
skills/site-web/scripts/ceguera.sh '<patron-del-paquete-publico>'
```

El patrón lo fija la doctrina del paquete (delta 5); no se hardcodea en
el skill para no auto-contaminar. Debe salir 0 matches. El mundo aplica
además **su** `mundo.ceguera` sobre su propia entrega.
