# Reporte · WP-O112 · Protocolo de upgrade: orquestador por roles, diff de comportamiento y gates de publicación

- **Fecha**: 2026-10-01 · **Rama**: `wp/O112-protocolo-upgrade` · **Asiento**: D-O25.
- **Resultado**: `UPGRADE-PROTOCOL.md` orquesta el ciclo entero y mide lo que antes no medía: qué
  cambia de comportamiento entre dos versiones y qué publica cada nodo al subir. Cinco herramientas
  nuevas o ampliadas, probadas contra el host (solo lectura) y contra el stack local.
- **Origen**: al ejecutar el protocolo viejo contra 1.1.10, los guards encajaron en minutos y todos
  los greps de los anexos dieron ≥ 1, mientras el delta traía un visor que elige idioma por
  cabecera delante de una caché que no lo sabe, una ruta nueva que anula la dirección ECOin y un
  servicio de IA que ya no responde al test. El protocolo comprobaba «sigue existiendo», no «se
  comporta igual».
- **Fuera de alcance**: el upgrade (WP-O113 local, WP-O114 host). El overlay y los guards de 1.1.10
  quedan aparcados en `upgrade/oasis-1.1.10` (`cc21d0d`, `b6b1828`).

## Qué se entregó

| Pieza | Commit |
|---|---|
| `host.env` con el layout medido; preflight con `OLD_REF`/`NEW_REF` y ficheros por rol | `b7f30d7` |
| `upgrade-closure.js`: qué carga de verdad cada punto de entrada; corrección de «el pub no publica» | (commit de cierre) |
| `lib-node.sh`: versión, feed, `sequence` y registros propios por tipo (cifrados incluidos) | `047457e` |
| `deploy-status.sh`: piezas vivas, deriva host↔repo, restos de rollback | `f0bf7c8` |
| `upgrade-behaviour-diff.sh` + `upgrade-invariants.d/{hub,ecoin}.tsv` | `a695687` |
| `upgrade-gates.sh`: `snapshot`, `check`, `hub`, `backup`, `restore`, `up`, `worst` | `6f38d80`, `b0c341f` |
| `UPGRADE-PROTOCOL.md` reescrito como orquestador; scripts npm | `0b1fe78` |
| Anexos: HUB §1, §2, §5, §9 · ECOIN §1, §5 | `fa78431` |
| `AGENTES.md` §1, §3, §4 · ficha de instancia | `6eb8c4f` |
| `CLIENT-PROTOCOL.md` sin el duplicado | `e4892b5` |

## Criterios de aceptación · evidencia

| Criterio | Comando | Salida |
|---|---|---|
| El diff saca **solo** lo que WP-O105 encontró a mano en 1.1.2 → 1.1.4 | `upgrade-behaviour-diff.sh 3c9bf9a 45a1cd4` | `files + src/configs/state-manager.js` · 18 entradas `state +` · 7 JSON de `src/configs` borrados · `config - "walletPub"` · `env OASIS_BANKING_DIR — usos: 1 → 8` · `env OASIS_TEST — usos: 2 → 3` |
| El diff saca los hechos de 1.1.4 → 1.1.10 | `upgrade-behaviour-diff.sh 45a1cd4 f770dbb` | 175 líneas, 141 a disponer. `routes +`: `GET /c/rss/:module`, `GET /c/sitemap.xml`, `POST /settings/inbox-bots`, `POST /settings/wallet/disconnect` · `loopback +`: la última · `publish +`: `publishSelfAddress("")`, `setUserAddress(me, addr, true)` · `headers +`: dos líneas con `accept-language` · `env +`: `OASIS_AI_TOKEN` y otras tres |
| `--check` obliga a disponer | registro vacío → `rc=1`, 4 `SIN DISPONER`; con los 4 IDs → `rc=0` | conforme |
| Invariantes de los anexos como datos | `--section annex` sobre el árbol 1.1.4 | 26 líneas `ok`, ninguna `!` |
| La medida por nodo cuadra | `lib-node.sh` sobre los cuatro logs locales | `seq` == registros: pub 5, HUB 5, bot 12, cliente 76 (4 cifrados) |
| La comparación responde bien | siete fotos sintéticas | delta declarado → `rc=0`; publicación no declarada, `wallet` +1, cifrado nuevo, feed cambiado → `rc=1`; `Δseq` ≠ suma por tipos → `NO MEDIBLE`, `rc=3` |
| Recrear con la **misma** imagen no publica | local: `snapshot base114` · `up pub` · `up hub` · `up bot` · `check base114` | `pub/hub/bot v1.1.4 · Δseq=0 · sin publicaciones → ok` · `GATE OK` |
| Gate del visor | `upgrade-gates.sh --local hub` y `--remote hub` | las dos: `/c → 200` · `caché: MISS → HIT` · idioma por defecto «en» igual con `Accept-Language` de/es/fr y con cookies · 3 avisos de lo que es nuevo de 1.1.10 · `GATE OK (con avisos)` |
| `deploy-status.sh` da versión y piezas | contra el host | tres nodos en `1.1.4` (`server`, `backend`, `backend`), «imagen al día» |
| Preflight | `upgrade-preflight.sh` | `OLD_REF=45a1cd4` · `NEW_REF=f770dbb` · «pub en modo server = 6 de los 15 ficheros que carga · backends y cliente = 73» |
| Docs | `npm run docs:build` · `verificar-sitio.mjs --no-external` | build completo · 0 enlaces rotos, 0 anclas rotas |

## Estado del host medido (línea base para WP-O114)

`upgrade-gates.sh --remote snapshot base-1.1.4` (2026-10-01T15:33Z), `deploy-status.sh`:

| Nodo | Versión | `sequence` (log = registros = sbot) | Tipos propios |
|---|---|---|---|
| pub | 1.1.4 | 15 | `about` 3 · `contact` 5 · `karmaScore` 1 · `oasisVersion` 4 · `pub` 1 · **cifrado 1** |
| HUB | 1.1.4 | 11 | `about` 2 · `contact` 1 · `oasisVersion` 3 · `pub` 1 · **cifrado 4** |
| bot | 1.1.4 | 50 | `about` 2 · `contact` 1 · `karmaScore` 2 · `oasisVersion` 2 · `pub` 1 · `pubAvailability` 24 · `ubiAllocation` 16 · `wallet` 1 · **cifrado 1** |

- Bot: motor `pub=true`, saldo 0, épocas abiertas `2026-09,2026-10`, flag de primer contacto presente.
- Deriva: `Dockerfile`, `.dockerignore` y `docker-compose.pub.yml` del host **no están en la
  historia del repo**; `docker-entrypoint.sh` es una versión anterior (`584dd90`); `Caddyfile` y
  `config/hub/*` son los de `HEAD`.
- Restos de rollback: `src.old`, imagen `:1.1.2`, `src-0.9.6.tgz`, `src-1.0.8.tgz`, `src-1.1.2.tgz`.

## Hallazgos

1. **El control «cero `private`» era vacío.** `grep '"private":true'` no casa nunca: un cifrado se
   guarda como `"content":"….box"`. La evidencia «`private` = 0» de WP-O105 y WP-O106 no probaba
   nada. Con el contador nuevo aparecen **4 cifrados propios en el HUB**, 1 en el bot y 1 en el pub.
   No se pueden retirar. Qué son queda como seguimiento (WP-O111); el invariante pasa a «ningún
   cifrado nuevo».
2. **Un upgrade publica y un rollback también**: un `oasisVersion` por **nodo** cada vez que
   arranca en una versión distinta de la última anunciada. Lo publica el propio sbot
   (`SSB_server.js:244-258`), así que vale también para el pub en modo `server`: sus 4
   `oasisVersion` cuadran con una por subida de versión (no leí su contenido; lo confirmará el
   gate U3 de WP-O113). Ningún rollback es gratis. Entra en `AGENTES §3`.
3. **El riesgo va por rol, y el rol no es una carpeta.** El pub carga el cierre de requires de
   `SSB_server.js`: 15 ficheros, entre ellos `banking_model.js` (el sbot llama a
   `ensureSelfAddressPublished` a los 5 s en cualquier modo; sin cartera alcanzable no hace nada).
   En este ciclo cambian 6 de esos 15; para backends y cliente, 73.
4. **El idioma de Oasis es una variable global del proceso** (`setLanguage` en `main_views.js`):
   con el visor de 1.1.10 dos peticiones concurrentes en idiomas distintos pueden cruzarse. D-O25
   lo acota y el gate `hub` lo mide.
5. **`mv src src.old` con un `src.old` presente mete `src` dentro**, y en el host existe. Corregido
   en UPGRADE §4 (nombre con versión + `test ! -e`).
6. **La época de octubre ya está abierta** en el bot (con el motor de 1.1.4 y pool 0): subir a
   1.1.10 no abre época, y `ubiAllocation` debe dar delta 0.
7. **`upgrade-preflight.sh` buscaba `master`** (upstream usa `main`) y tomaba la versión de partida
   de `HEAD`, que en la rama de upgrade ya es la nueva.

### Revisión de las conclusiones del primer tramo de la sesión

| Afirmación | Veredicto tras leer el código |
|---|---|
| «La autopublicación de la dirección es nueva en 1.1.10» | A medias: 1.1.4 ya publicaba al abrir la GUI sin dirección local (`ensureSelfAddressPublished`). Lo nuevo es la rama «dirección local sin publicar → publica». Lo que queda viejo es `ECOIN §3` pasos 7-8 (WP-O113, tras medirlo) |
| «El PM de bienvenida ahora corre en el arranque» | Falso: `setTimeout(welcomePmTick, 3000)` ya estaba en 1.1.4 y la lógica del flag es idéntica |
| «Hay prisa: la época de octubre la fijará 1.1.4» | Falso: ya estaba abierta y con saldo 0 el pool es 0 en cualquier versión |
| «No hay secuencia de upgrade del bot» | A medias: existía repartida; ahora la orquesta UPGRADE §4 |
| Caché de `/c` por idioma, `walletPub` sobrante, test de IA roto, «desconectar cartera» | Ciertas |

## Correcciones al protocolo que devolvió la propia ejecución

0. **El protocolo recién escrito decía que el pub no publica al subir y que «solo ejecuta
   `src/server/`».** Las dos cosas eran falsas y venían de una revisión delegada que no comprobé
   contra el código. Lo destapó el propio dato medido (4 `oasisVersion` en el pub) al escribir este
   reporte. Corregido en protocolo, anexos, `AGENTES §3` y herramientas (`upgrade-closure.js`:
   el preflight y la sección `roles` cuentan el cierre de requires, no la carpeta).
1. `upgrade-gates.sh up` no recreaba con la misma imagen (`up -d` sin cambios): `--force-recreate` (`b0c341f`).
2. El flag de primer contacto no lleva siempre el feed: Oasis solo mira que **exista**. La foto
   distingue «presente con su feed», «presente sin su feed» y «ausente».
3. El diff etiquetaba como `ev/null` los ficheros borrados y no veía variables de entorno que
   cambian de uso sin ser nuevas (`OASIS_TEST`): corregido antes del commit.

## No medido / pendiente

- **El comando literal del humo de la imagen** construida en el host (UPGRADE §4, paso 6): se
  ensaya y se escribe en WP-O113.
- La prueba de **agente en frío** del protocolo nuevo (D-O23): WP-O113 la hace de hecho al
  ejecutarlo; la formal sigue en WP-O109.
- Si `.env.prod` y `src.old` están entrando en la imagen del host por el `.dockerignore`
  pre-refactor (hipótesis; se comprueba en el paso 0 de WP-O114).
- Qué son los cifrados del hallazgo 1.

## Seguimiento

- **WP-O113**: upgrade en local con este protocolo. **WP-O114**: host, con GO en cada puerta.
- Para upstream: falta `Vary` en `/c`; idioma global por proceso.
