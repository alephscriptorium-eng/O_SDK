# WP-O132 · visor `/c`: idioma por petición y selector de tema (sexto guard) — reporte

Rama `wp/O132-visor-idioma-tema` (desde `main` 1b5b8722). 2026-10-08. Custodio: GO para el host; decisión D-O30.

## 1. Síntoma y medida

El custodio veía en `/c` de `pub.escrivivir.co` el texto en ES y el selector de idioma en «AR».

| Medida (antes) | Resultado |
|---|---|
| `curl /c` sin cookies ni cabeceras | `<html lang="es">`, selector ES: la config del HUB manda; nginx no reenvía `Accept-Language` ni `Cookie` (D-O25) |
| `curl /c?lang=ar` | página en **PT** |
| `upgrade-gates.sh --remote hub --strict` (gate de D-O25: 2 idiomas × 8) | GATE OK, «sin cruce» |
| 18 peticiones concurrentes en 6 idiomas (3 tandas) | **6 de 18** salieron en otro idioma |

Causa (código): `src/views/main_views.js:628-640` guarda el idioma en una variable **global del proceso**; el
middleware (`backend.js:14376`) lo fija por petición; la ruta `/c` (`:8592-8606`) espera (`await`) y mientras tanto
otra petición lo cambia (cada página lleva 12 enlaces `?lang=` que los rastreadores siguen). `renderClearnetPage`
leía el global al renderizar: `<html lang>`, selector y textos en el idioma de **otra** petición. El gate antiguo
no lo veía por probar solo dos idiomas en una tanda.

## 2. Qué se entregó

| Pieza | Commit | Qué |
|---|---|---|
| Sexto guard | `1e825d55` | `backend.js` (3.er edit): `clearnetLanguage` deja siempre el idioma resuelto en el scope de la petición (AsyncLocalStorage); `clearnetTheme` valida `?theme=`. `clearnet_view.js` (nuevo en el delta): re-afirma el idioma del scope antes del render síncrono; selector de tema (Dark, Clear, Matrix, Purple); `cnWithQuery`/`propagateQuery` llevan `lang` y `theme` a todo enlace y formulario |
| Gate e invariantes | `b4b9c2f7` | `hub --strict`: 6 idiomas × 3 tandas, `?lang=ar` coherente, tema (paleta, desconocido, enlaces, caché, cruce de temas); `hub.tsv` +2 |
| Protocolo y gobierno | `c0a1e843` | UPGRADE §2 (fila, «tres edits», 7 ficheros, grep en §4, historial), HUB §1 y §5, AGENTS.md, roadmap P2P, ficha §1, D-O30, WP-O132, CHANGELOG |

Delta de `src/` contra upstream: 7 ficheros (6 guards + `blockchain-cycle.json`). Prueba unitaria del guard dentro
de la imagen (11 comprobaciones, `scratchpad/test-guard.js` → en el dosier no: es efímera; el gate la cubre).

## 3. Gates

- **Local** (imagen reconstruida, stack `pub:local`): `hub --strict` GATE OK (0/18 cruces, tema, 45/54 enlaces con
  parámetros, variante HIT, 0/9 cruce de temas); recrear el HUB en la misma versión: pub, hub y retro Δ0; `annex`:
  0 invariantes rotas, las 2 nuevas en `ok`; `docs:verificar` completo (ceguera: 52 = base).
- **Host** (GO): `snapshot pre-o132`; `docker tag …:pre-o132` (84828fc054c6) y `/srv/oasis/src-pre-o132.tgz`;
  `git archive` sin CRLF a `src.new` (1.2.3, enlace y vendorizado ok, 5.º guard `url`, 6.º guard 4/2); `mv src
  src.old-pre-o132`; `build oasis-pub` → `2c25fb3c1c65`; humo `--network none` con la prueba del guard: todo ok;
  `up -d --no-deps oasis-hub` → healthy en 80 s sobre la imagen nueva; `prune-cache`; `--remote hub --strict`
  **GATE OK** (0/18 cruces en 6 idiomas, `?lang=ar` en AR, tema Clear/Matrix, 336/345 enlaces con parámetros,
  variante HIT, 0/9 cruce de temas, sitemap 192 URL); `check pre-o132`: **pub, hub, bot-2 y retro Δ0**.
  En vivo: `/c` ES/Dark; `/c?lang=ar` AR; `/c?theme=Clear-SNH` claro; `/c?theme=Purple-SNH&lang=en` los dos.
  Journal `deploy-log.sh` (mismo modo). El pub y los bots siguen con la imagen anterior en memoria (misma
  versión; no sirven `/c`): se recrean en el próximo ciclo de upgrade.

## 4. Hallazgos

1. El gate de D-O25 medía poco: dos idiomas y una tanda no bastan para ver un cruce que en el host era de 6/18.
2. Un `?lang=ar` que sale en PT es la firma del cruce: el idioma de la **otra** petición concurrente.
3. `src/server/node_modules` es un enlace que en Windows no resuelve: la prueba unitaria del guard se corre
   **dentro de la imagen** (`docker run --rm -i --entrypoint node <imagen> - < test.js`), también como humo en el host.
4. El stack local se cae por memoria al arrancar `oasis-client` (5 GB, GPU) con el pub local vivo: `Exited 137`
   en pub, bot y Caddy; antes de un gate local, `docker ps` de los seis contenedores.

## 5. Rollback (no ejercido)

`docker tag oasis-pub-scriptorium:pre-o132 oasis-pub-scriptorium:latest && up -d --no-deps oasis-hub`; `src/` desde
`src.old-pre-o132` o `/srv/oasis/src-pre-o132.tgz`. Misma versión: ningún nodo publica. Los restos
(`src.old-pre-o132`, el tgz, la etiqueta) se retiran al cerrar el siguiente ciclo, como los de 1.2.2.

## 6. Seguimiento

- Merge a `main`, web (CI `Docs`) y estado ✅ en el backlog.
- Pendiente de fondo (fuera de alcance): `i18n` por petición en toda la GUI; el guard solo cubre el visor `/c`.
