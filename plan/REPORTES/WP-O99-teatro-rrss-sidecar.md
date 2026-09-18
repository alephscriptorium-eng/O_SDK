# Reporte · WP-O99 · Teatro: sidecar de RRSS con fuente en exports de x.com

- **Fecha**: 2026-09-18 · **Rama**: `wp/O99-teatro-rrss-sidecar` sobre `7adb5e2` · **Método**: plan aprobado por el custodio (3 exploraciones + 1 diseño; una revisión del plan a petición suya: lore dentro de o-sdk), un solo operador.
- **Resultado**: **desplegado**. `https://pub.escrivivir.co/teatro/aleph-cero/` sirve la generación 2026-09-18 (1940 posts, 891 voces ajenas a dos niveles, 315 páginas enlazadas en Markdown) desde el volumen de datos, generada íntegramente desde o-sdk. Queda abierta la tanda de navegador (12 enlaces) y, como punto aparte, la reorganización semántica.
- **Asiento**: D-O16. **Docs vivas**: `docs/PUB/RRSS-SIDECAR-PROTOCOL.md`, `docs/PUB/TEATRO-PROTOCOL.md`, `pub/rrss-sidecar/**/README.md`, `ARCHIVO/LORE/README.md`.

## Estado de partida (verificado, solo lectura)

| Pregunta del custodio | Hallazgo |
|---|---|
| ¿Git cubre la infra? | **No.** El generador (9 scripts Python, CSS, protocolo de agentes) solo existía en un repo git anidado **sin remoto** fuera de o-sdk, y dentro del zip publicado. En o-sdk: protocolo, plantilla del catálogo, mount y un deploy con `aleph-cero` hardcodeado en ~13 sitios. Cero WP, asiento, CHANGELOG ni script npm. |
| ¿El archivo está en el volumen de datos? | **Sí.** 1,6 GB en `/srv/oasis/teatro` (`/dev/xvdb`, 40 G al 16 %); en el disco de sistema solo el mountpoint vacío y dos `.bak`. Pero: permisos **0777**, sin backup, soft-404 bajo `/teatro/` (cualquier ruta devolvía la landing con 200), sin CSP, y `verify-debian13-base.sh` no lo comprobaba aunque el README decía que sí. |
| Invariantes publicados | El árbol servido incumplía su «cero JS» (visor de X: 5 `<script>`, 47 `.js`) sin que la verificación lo detectara. |
| Export nuevo | **Completo** (`isPartialArchive: false`): 1940 tuits (+490 en 28 días, 4 borrados), +553 ficheros de media, mismo esquema. |
| Voces ajenas | 537 cacheadas (RT y réplicas). **Las citas nunca se cubrieron**: el export no trae `quoted_status`; la cita es una URL en `entities.urls`. |
| Enlaces externos | 364 URLs distintas, 39 conversaciones con agentes. Ninguna herramienta ni caché previa. |
| `.dockerignore` | Excluía `archive/` pero **no `ARCHIVO/`**: un lore de varios GB habría entrado en el contexto de build. |

## Qué se entregó

| Pieza | Commit |
|---|---|
| Importación **verbatim** (sha256 verificado) de los builders, CSS y `AGENTS.md` | `ca91a80` |
| `pub/rrss-sidecar/twitter_x/` parametrizado (`lib/`, `sidecar.py`, builders sobre corpus normalizado, parche multi-vídeo declarativo, tests) + `ARCHIVO/LORE/` (esqueleto, deny-by-default) + `.dockerignore`/`.gitignore`/`.gitattributes` + READMEs + `CORPUS-SCHEMA.md` | `36c4a91` |
| Deploy por obra, `teatro-wsl.sh`, `backup-teatro.sh`, bloque `@teatro` de Caddy, `verify-debian13`, `hub-disk`, `.env*.example`, protocolos, MAPA, BACKLOG WP-O99, D-O16, CHANGELOG | `c814bb0` |
| Tanda de enlaces robusta (proxy vacío ≠ privado; fusión del store) | `2fc4a99` |
| Catálogo: cifras de la generación 2026-09-18 y zip completo destacado | `6d496e2` |
| Guardas sin rutas de instancia; salida UTF-8 desde npm | `33c82cb` |

## Criterios de aceptación · evidencia

| CA | Resultado |
|---|---|
| `npm run teatro:test` | ✅ 8 tests sobre export **sintético** generado en temporal (multi-parte y id duplicado; store aditivo idempotente; contrato del corpus; familias y claves de enlaces; `html2md`; render md→HTML escapado; build + guardas que **fallan** con `ip-audit.js` y `<script>` sembrados; migración del store v1 sin perder texto) |
| Autocontención | ✅ `git ls-files ARCHIVO/LORE` = `.gitignore` + `README.md` · `obra.json` sin rutas fuera del repo · `grep S_META` en sidecar, deploy y protocolos = 0 · origen del lore intacto (`git status` limpio, ningún fichero nuevo) |
| Copia del lore | ✅ 3 generaciones, 23 062 ficheros, 3,1 GB; recuento, bytes y sha256 de `manifest.js`/`tweets.js` verificados; stores antiguos en `legacy/` |
| Ingesta | ✅ store 1967 · **visibles 1940** · borrados 27 (solo en el store; no se publican) |
| Parche multi-vídeo | ✅ reconstruido byte a byte desde los dos bundles: stock `d171272a…` → `e119522c…` (= el aplicado a mano en el lore); 594 → 704 caracteres; se aplica en cada build |
| Protocolo (a) voces | ✅ worklist 662 ids (273 RT · 145 padres · **250 citas**) → **635 `ok`, 18 `unavailable`, 0 `error`**; **230 nodos de nivel 2** embebidos (0 peticiones extra); fuente `tweet-result` 861, `fxtwitter` 4; los RT resuelven a su original (272/273); 31 MB de foto/póster de terceros en local. Publicadas 891 voces alcanzables desde posts visibles |
| Protocolo (b) enlaces | ✅ 364 URLs → **315 `ok`**, 30 `gone`, 7 `error`, 12 `pending_browser`. **Agentes: 37/39** (DeepSeek 29/29 vía `r.jina.ai`, ChatGPT 2/2 por JSON, Claude 4/4, Grok 2/3). `links_blocked.json` **vacío** |
| Build | ✅ 2619 páginas · 259 hilos · 76 hashtags · 315 páginas de enlaces · invariantes OK |
| Caddy `@teatro` | ✅ probado en contenedor contra la obra local y aplicado en producción: `caddy validate` en el contenedor vivo → escritura in place (mismo inode 135503) → `caddy reload`. `/teatro/no-existe/` **404**, `data/ip-audit.js` **404**, CSP `script-src 'none'` en páginas y CSP propia en el visor. Vecinos como en la línea base de WP-O46 (pub 200 · scriptorium 404 · admin 404 · mcp 502 preexistente · npm 200 · rooms 200) |
| Permisos VPS | ✅ 755/644; 0 ficheros world-writable |
| Ensayo de deploy | ✅ 221 borrados, todos esperados: `second-brain.md`, 193 duplicados del store v1 de voces, 6 posts borrados por el autor, 2 de `profile_media` y las herramientas antiguas |
| Deploy + verificación automática | ✅ `TEATRO_OBRA=aleph-cero TEATRO_DELETE=1` por WSL: pre-vuelo de invariantes OK · `MANIFEST.sha256` 14 264 ficheros / 1,5 GB · rsync · **`sha256sum -c` en el VPS OK** · `aleph-cero.zip` 1,6 GB (`f7d753df…427b7b`, completo) y `aleph-cero-cerebro.zip` 34 MB · 3 firmas ed25519 · verificación pública: 200 ×6, **206** con `Range` sobre un mp4, **404** en `data/ip-audit.js` y `data/direct-messages.js`, hash estampado, portada sin `<script>`, 404 real, nada world-writable, `/` y `/public/status` 200 |
| Verificación independiente | ✅ `backup-teatro.sh --verify` → `OK_MANIFEST` · firma en frío: `Good "file" signature for teatro@escrivivir.co` para el zip y para el manifiesto · obra 3,1 GB; `/srv/oasis` 16 % → 20 % |
| Backup de lo no regenerable | ✅ `devops/backups/teatro/aleph-cero/20260918T093049Z/` (portada estampada, checksums, firmas, manifiesto y `lore-store.tgz` con stores y Markdown de enlaces; 3,8 MB, sha256 verificado) |

## Hallazgos del ciclo

1. **`chatgpt.com/backend-api/share` responde 403 de forma intermitente** (anti-bot): el mismo share da 200 al reintentar. Un 403 no es evidencia de «privado». El fetcher reintenta y, si persiste, va a la cola de navegador.
2. **Un resultado vacío de `r.jina.ai` tampoco es evidencia de «privado»**: la primera tanda se detuvo (exit 3) por un DeepSeek con 0 caracteres que después salió bien. Criterio nuevo: solo el navegador, que ve si la página pide login, puede declarar `blocked`.
3. **Condición de carrera**: una tanda larga tenía el store en memoria y pisaba lo guardado con `browser-save`. `merge_write` vuelca solo lo tocado y nunca degrada un enlace `ok`.
4. **Los artifacts de Claude son apps HTML en un iframe aislado**: no se leen desde la página. Al ser del usuario se leyeron por la vía propia de artifacts (uno declarado «shared with anyone with the link»); se publica el texto visible más la fuente HTML íntegra.
5. **Extraer texto de una página con CSP estricta** (x.com): la salida de la herramienta se trunca a ~1000 caracteres, `fetch` a localhost lo bloquea `connect-src`, y Chrome bloquea la segunda descarga automática. Funcionó la navegación de la pestaña a un receptor local con el texto en la URL, pero **deja la pestaña en `127.0.0.1` y la extensión se bloquea** hasta que el usuario la cierra.
6. **28 de los 66 enlaces al dominio propio dan 404**: entradas antiguas de `escrivivir.co/2025/…` que ya no existen. Quedan como `gone`; candidatas a Wayback Machine.
7. El store v1 indexaba cada RT por dos claves (id del RT e id final): 184 duplicados. Se conservan en el store y no se publican.
8. `pub/README.md` decía que el HUB estaba «planificado»: corregido en WP-O98.

## Segunda tanda (2026-09-18, tras reabrir el navegador)

| Asunto | Resultado |
|---|---|
| Artifacts de Claude | El custodio publicó los dos que faltaban: «Diez redes sobre Oasis» (nueva URL pública `claude.ai/artifact/8CzEhn5DK9Zxy9ttE4JEYX`, anotada como `public_url` en las dos entradas que lo citan; identidad comprobada en el navegador) y «Antes del argumento ontológico» |
| Blog propio | Decisión del custodio: las 26 URLs de `escrivivir.co` que dan 404 **se quedan como enlace** (se volverán a publicar en el blog). Nuevo `link_only_hosts: ["escrivivir.co"]` en `obra.json` → estado `link_only`, nunca se descargan ni se reintentan |
| Grok | 3/3. Método estable: la pestaña navega a un receptor local que guarda el texto y **responde 302 a una web normal**, de modo que la extensión no se bloquea |
| Vídeo (5 Twitch, 3 TikTok) | Solo metadatos con `browser-save --meta`; dos VOD de Twitch ya no exponen título (caducados) |
| Odysee y 3 páginas con anti-bot | `r.jina.ai` como segunda vía de páginas genéricas |
| Vistas `commits` de GitHub (3) | Nuevo fetcher `github:commits` por API, con ramas que llevan «/» |
| Caídos | Una página de GitHub Pages (404) y `hackstory.net` (timeout) marcados `gone` con `link-mark` |
| **Estado final de enlaces** | 364 URLs → **331 `ok`**, 26 `link_only`, 6 `gone`, **1 `pending_browser`** (Perplexity). Agentes **38/39**. `links_blocked.json` vacío |
| Build | 2635 páginas · 331 páginas de enlaces · invariantes OK |

## Pendientes

- **Perplexity** (1 enlace, `pending_browser`): la extensión de Chrome no tiene permiso para `perplexity.ai` y el proxy de lectura choca con el challenge de Cloudflare. Requiere que el custodio conceda el dominio a la extensión.
- Cuando el blog vuelva a publicar las 26 entradas, no hay que hacer nada: la obra ya las enlaza.
- Migración del layout del VPS a un checkout git (`MIGRATION-2026-07.md`), que sigue pendiente y explica por qué los ficheros se suben in place.
- **Punto final anotado — reorganización semántica de «Aleph Cero»**: se hará **en modo plan**, leyendo el feed hacia atrás desde el tramo final para construir el concepto de obra. Este WP deja reunidos los datos: `store/posts.json`, `external_tweets.v2.json` (voces a dos niveles), `links_store.json` y `cache/links/*.md` (conversaciones y páginas).
