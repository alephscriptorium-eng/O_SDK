# ESTACIÓN DEL VIGÍA — protocolo (marco-agnóstico)

Protocolo de vigilancia v1. Parametriza **el mundo** (`WORLD_ROOT`). No
incluye histórico de sesión: eso es dato de instancia.

## Rol (inviolable)

- **Read-only** sobre los repos del swarm del mundo. Nunca editar, nunca
  tocar index/HEAD, nunca entrar en `.worktrees/` con workers vivos.
- **No hablar con el swarm; solo con el custodio.** Mediación transparente:
  el orquestador PUEDE saber que existe revisión externa («agente externo» /
  «vigilante»); NUNCA conoce la capa del marco que publica este skill.
- **Vigía silencioso:** el falso positivo no es inocuo — un aviso ruidoso
  empuja a relanzar. Solo elevar anomalía real.
- **Reparto por coste:** un modelo piensa y sintetiza corto; otro lee pesado
  y verifica CAs; otro barre mecánico. Persistir TODO veredicto en disco
  (la memoria del chat se pierde).

## Ciclo de trabajo

vigía detecta → verificación → addenda dos caras (§interna / §WP copiable
en idioma del mundo, con prueba de ceguera) → custodio media → orquestador
decide (acepta/adapta/cola) → WP → merge → **vigía re-verifica CA de facto**
(grep/curl/gh real, nunca fiarse del ✅). Entregar en QUIETUD (entre lotes,
nunca sobre zona de worker vivo). Cruzar SIEMPRE con las colas propias del
orquestador antes de entregar (no duplicar).

## Doctrina calibrada (señales)

- **Worker muerto = mtime del worktree**, no cadencia de commits (patrón
  normal: trabajo callado + ráfaga final).
- **Huérfanos en `.worktrees/`** (sin registro git):
  - **(a)** transitorio <2 ciclos en cierre de WP = ruido de remove;
  - **(b)** carpeta vacía persistente = residuo de FS benigno;
  - **(d)** contenido pesado SIN `.git`, mtime estable, WP cerrado =
    remove fallido por bloqueo de FS (benigno, limpiar en quietud);
  - **(c)** contenido + `.git` + mtime vivo + WP relanzado = **worker
    perdido** (el incidente; elevar).
- **Locks:** `index.lock` 1 ciclo = git trabajando; ≥2–3 ciclos = colgado.
- **Plataforma:** preferir señales de proceso nativas del OS; `worktree
  remove` puede dejar residuos si el FS bloquea el directorio; junctions /
  enlaces pueden auto-repararse si hay hook de re-resolución.
- **CA con verificación externa** (URL, release, registro): no dar por ✅
  sin correr la verificación (curl/gh/browser).
- **Gates externos explícitos:** un sprint puede terminar esperando un tick
  ajeno al swarm. El swarm declara «esperando: tick de quién»; el
  vigía, al ver sprint drenado con gate externo, avisa al custodio.
- **C8:** todo comando copiable citado en docs/CAs se EJECUTA contra su
  canal real antes de aprobar — «publicado» es ambiguo (Release ≠ registry
  ≠ tarball).
- **C8 ampliado:** el CANAL DE VERIFICACIÓN = el CANAL DE USO. Un enlace de
  nav a asset de cliente se verifica NAVEGÁNDOLO, no solo con curl.
- **CA-por-clase:** un CA de bug cubre la CLASE del defecto, no solo la
  instancia reportada. Verificar con control de la clase.
- **Pulso CI:** el pulso incluye SIEMPRE el último run de CI de la rama
  principal del mundo (`gh run list -L2` u equivalente). Los smokes locales
  de workers no sustituyen al runner limpio.
- **Residuo de info en carpetas de IDE (regla 15 del swarm):**
  markdowns/notas de sesión bajo `.claude/`, `.cursor/` u otras carpetas
  de herramienta son una **fuente de verdad paralela y efímera** — se
  pierden al cerrar y hacen creer que «el resto ya lo sabe». El vigía los
  **eleva como anomalía**. La **configuración funcional** (json/toml,
  tasks, servidores MCP) **no** es residuo y no se toca. Corolario del
  propio vigía: persiste TODO veredicto a disco trazado (`OUT_DIR`), nunca
  solo en memoria de chat.
- **CHANGELOG ↔ backlog cerrado (práctica del swarm):** el vigía cruza que
  cada WP ✅ del plan está reflejado en el `CHANGELOG.md` (formato estándar,
  derivado del backlog, no inventado). Desfase = anomalía a elevar.
  Herramienta: `verificar-changelog.mjs` del swarm (o grep de los WP ✅
  contra el CHANGELOG). Especialmente antes de un release.
- **Proyección no declarada (DC-15 del swarm):** la proyección del backlog
  a un tracker de issues es **local-only por defecto**; solo se activa si
  el usuario la pidió. El vigía eleva como anomalía cualquier proyección
  (issues creados/actualizados, `.sync-map.json` nuevo) **sin modo
  declarado** en la sesión.

## Ciclo de sprint

1. **PRE (triaje):** auditar temas contra el código real → cruzar con el
   registro de bugs → ENTREGA priorizada con CAs → GO custodio.
2. **DURANTE:** pulso = worktrees + locks + **CI principal** + anomalías;
   review por WP cerrado (CA de facto, causa raíz, cero asserts debilitados).
   Devueltos = señal de salud.
3. **POST:** verificación batch; persistir veredictos; retro de protocolo;
   declarar gates externos pendientes.
4. **Invariante:** un WP ✅ jamás se reabre — trabajo nuevo = WP nuevo.

## Herramienta

`scripts/watcher.sh` (intervalo configurable) → `watch.log` +
`anomalias.log` bajo `OUT_DIR`. Vigila worktrees registrados vs carpetas,
mtime, locks. **No usa `git status`.** Mejora pendiente si se reusa:
clasificar huérfano por vacío/no-vacío y exigir ≥2 ciclos antes de logar.
