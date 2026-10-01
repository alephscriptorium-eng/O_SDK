# Reporte · WP-O114 · Aplicación en el VPS: Oasis 1.1.10 en pub, HUB y bot de cartera

- **Fecha**: 2026-10-01, 17:04-17:43 UTC · **Host**: `pub.escrivivir.co` · **Origen**: `wp/O114-aplicacion-vps` (`bff2374`; `src/` = `main`).
- **GO del custodio**: cuatro puertas, dadas una a una con la medida delante: GO-1 (escribir en el
  host), GO-2 (reinicio del pub), GO-3 (HUB), GO-4a y GO-4b (bot en pausa; encender el motor). En el
  GO-1 decidió además el idioma por defecto del visor (`es`) y mantener `inboxMutedBots`.
- **Resultado**: pub, HUB y bot en **1.1.10**, sanos, mismos feed ids, misma dirección ECOin. Motor
  de RBU **encendido**. **Cada nodo publicó un `oasisVersion` y nada más.** Sin rollback. Sin paradas.
- Protocolo: `docs/PUB/UPGRADE-PROTOCOL.md` §4 tal como quedó en WP-O112/O113. Devolvió **cinco
  correcciones**, ya aplicadas.

## Secuencia y evidencia

| Paso | Evidencia |
|---|---|
| 0 · Medir (lectura) | `snapshot pre-o114`: tres nodos `v1.1.4` healthy; `seq` log = registros = sbot: pub 15, HUB 11, bot 50; motor `pub=true`; épocas `2026-09,2026-10`. `/` al 52 %. **Hallazgo**: `OASIS_PUB/.env.prod` y dos copias dentro de la imagen |
| 1 · Backups | pub → `devops/backups/oasis-pub/20261001T170503Z`; `wallet.dat` → `devops/backups/ecoin/20261001T170648Z` (sha256 `dd8f7938…`); en el host `/srv/oasis/oasis-{hub,wallet-bot}.bak-o114-2026-10-01.tgz` (600; 437 MB y 75 MB); copia `*.bak-o114-2026-10-01` de plantilla nginx, config del HUB, plantilla y script de render del bot, config renderizada del bot, Sala 04, compose y `.dockerignore` |
| 2 · Disco | retirados `:1.1.2`, `src.old` (comprobado: 1.1.2) y los tgz de 0.9.6, 1.0.8 y 1.1.2; prune: `/` del 52 % al 42 % |
| 3 · Rollback de este ciclo | imagen `:1.1.4` (`e19e5c81d9fc`); `/srv/oasis/src-1.1.4.tgz` |
| `.dockerignore` del host | añadidos `OASIS_PUB/.env.*` (con las tres plantillas `.example` re-incluidas), `src.old*`, `src.new*` |
| 4 · `src/` | `git -c core.autocrlf=false archive` → `src.new`; en destino: versión `1.1.10`, 0 líneas con CR, `url` del 5.º guard correcta, `src/configs` sin JSON de estado, 5738 ficheros (= git). `mv src src.old-1.1.4` |
| 5 · Plantilla nginx (HUB aún en 1.1.4) | `nginx -t` en contenedor desechable: ok · in place · `--force-recreate hub-cache` · `hub`: `GATE OK (con avisos)` · los 6 vhosts 200 |
| 6 · Build y humo | build en el host, con el pub sirviendo. Imagen `b31871c2d59b`: `1.1.10`; **sin `.env.prod` ni `src.old` dentro**; `server` y `backend` arrancan sin red, 3 parches «patcheado exitosamente», `GET /c → 200` |
| 7 · Pub (GO-2, 17:14) | `up -d --no-deps oasis-pub` → healthy en 30 s, `1.1.10`, feed igual. `check`: `pub Δseq=1 · oasisVersion+1`; HUB y bot sin tocar. `/public/status`: `version 1.1.10`. HUB y bot `CONNECTED` |
| 8 · HUB (GO-3, 17:17) | config del visor in place (mismo sha que el repo, JSON válido) → `up -d --no-deps oasis-hub` → healthy, `1.1.10`. `prune-cache` → `hub --strict`: idioma por defecto «es» igual con `Accept-Language` de/es/fr y con cookies · `?lang=` elige · sin cruce en 16 concurrentes · sitemap 200 con 90 URLs y RSS 200 con 12, todas `https` · MISS→HIT · una CSP. A los 5 min 40 s: `hub Δseq=1 · oasisVersion+1`, **cifrados 0** |
| Sala 04 | solo `site/hub/index.html` (el vivo era el del repo con CRLF, sin ediciones propias). Matriz pública: landing y `/hub/` 200, `/clearnet` 302, `POST /c` 405, rutas privadas sin `X-Cache-Status` |
| 9a · Bot en pausa (GO-4a, 17:29) | plantilla y script de render nuevos in place; re-render con `sudo` (mismo inodo, `999:999`, 400; con `inboxMutedBots`, sin `walletPub`) → `hub-wallet.sh pause` → healthy, `1.1.10`, `pub=false`, 0 × «PUB engine on». A los 6 min: `bot Δseq=1 · oasisVersion+1`; **misma dirección**, `wallet` = 1, cifrados sin cambio |
| 9b · Motor (GO-4b, 17:36) | `hub-wallet.sh on --yes`: `ready` con 10 ok → `pub=true`, 1 × «PUB engine on». A los 6 min: `bot Δseq=0`: `pubAvailability` +0 (el último anuncio es de las 12:38 UTC), `ubiAllocation` 0 |
| 10 · Cierre | `backup-ecoin.sh` (sha256 `0387474f…`); `snapshot post-o114`; `deploy-status`: tres nodos `1.1.10` «imagen al día», pub **VERDE** en el directorio (ciclo 6); journal `--version 1.1.10 --mode server+hub+wallet-engine-on`; memoria: HUB 196 MiB/768 · bot 129/768 · pub 47 · ecoind 73/512; `/` 52 %, `/srv/oasis` 22 % |

`ecoin` no se recreó. Caddy no se tocó. `.env.prod` solo lo tocó `hub-wallet.sh` (interruptor del
motor, con su copia `.bak-hubwallet-*`).

## Delta de publicación (de `pre-o114` a `post-o114`)

| Nodo | `sequence` | Publicado | Esperado |
|---|---|---|---|
| pub | 15 → 16 | `oasisVersion` +1 | `oasisVersion` +1 |
| HUB | 11 → 12 | `oasisVersion` +1 | `oasisVersion` +1 |
| bot | 50 → 51 | `oasisVersion` +1 | `oasisVersion` +1, `pubAvailability` +0..1 |

Ningún cifrado nuevo, ningún `wallet`, ninguna `ubiAllocation`. Igual que en el ensayo local.

## Deriva del host tras la aplicación

`Caddyfile`, `config/hub/*`, `config/wallet-bot/*` y `scripts/render-wallet-bot-config.sh`: **igual
que `HEAD`**. Siguen distintos, a propósito: `Dockerfile`, `docker-entrypoint.sh`, `.dockerignore` y
`docker-compose.pub.yml` (pre-refactor o editados en el host; la migración de layout sigue pendiente).

## Correcciones al protocolo que devolvió la ejecución

1. **Las copias de seguridad de ficheros bajo `site/` no se dejan en `site/`**: esa carpeta la sirve
   Caddy y la copia quedaría pública. La de la Sala 04 se movió fuera. UPGRADE §4, paso 1.
2. **El rollback con nombre versionado no lo excluye `src.old`** del `.dockerignore`: hace falta
   `src.old*`. Y `OASIS_PUB/.env.*` (el patrón `.env.*` solo casa en la raíz). UPGRADE §4, paso 4.
3. **`deploy-site.sh` sincroniza el sitio entero con `--delete`**: para un fichero, se comprueba que
   el vivo es el del repo (aquí lo era, salvo CRLF) y se escribe solo ese. UPGRADE §4, paso 8.
4. **El render de la config del bot necesita `sudo` en el host** (destino a 400, de otro uid). ECOIN §5.2.
5. **Tras recrear `hub-cache`, salud de todos los vhosts**, como tras un `reload` del edge. UPGRADE §4, paso 5.

## Observaciones

- El build en el host dejó `/` otra vez al 52 %: la imagen de rollback `:1.1.4` ocupa ~3 GB hasta
  que se retire.
- **La imagen de rollback `:1.1.4` todavía lleva el `.env.prod` dentro** (se construyó antes de
  corregir el `.dockerignore`). Se retira en cuanto el ciclo se dé por bueno.
- `/public/status` sirve un invite con semilla, como antes del upgrade: es así por diseño de la landing.
- El pub tiene `flag-primer-contacto=ausente`: en modo `server` no hay backend y no aplica.

## Seguimiento

- **A las 24 h**: memoria de HUB y bot en 1.1.10; `upgrade-gates.sh --remote check post-o114` (el
  siguiente `pubAvailability` toca hacia las 00:38 UTC: +1 esperado; cifrados 0). Si va bien,
  **retirar el rollback**: imagen `:1.1.4`, `src.old-1.1.4`, `/srv/oasis/src-1.1.4.tgz` y los
  `*.bak-o114-*`.
- **Backups de hoy a almacenamiento cifrado** fuera de la máquina (`devops/backups/{oasis-pub,ecoin}/20261001T17*`):
  llevan `secret` y `wallet.dat` sin cifrar.
- **Rotar lo que había en el `.env.prod`** es decisión del custodio: estuvo dentro de las imágenes
  construidas en el host, a la vista de los procesos de pub, HUB y bot. No he comprobado si alguna
  de esas imágenes salió del host.
- **Cliente del custodio** (identidad real): `CLIENT-PROTOCOL.md` §4, con su GO. Funciona con el
  modelo de IA que ya tiene.
- Para upstream: lista del reporte de WP-O113 §7.
