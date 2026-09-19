# Reporte · WP-O106 · Aplicación en el VPS: Oasis 1.1.4 y renombrado de los dos bots

- **Fecha**: 2026-09-19, 16:33-16:48 UTC · **Host**: `pub.escrivivir.co` · **Origen**: `main` (`74d5c6a`).
- **GO del custodio**: «GO a todo» (upgrade con reinicio del pub + los dos `about`), dado tras el preflight.
- **Resultado**: pub, HUB y bot-2 en **1.1.4**, sanos, mismos feed ids. Bots renombrados a
  `clearnet.escrivivir.co` y `ecoin.escrivivir.co`. Motor de RBU **apagado**. Sin rollback. Sin paradas.
- Ejecutado por el mismo agente que escribió el protocolo (la prueba de agente en frío es WP-O109):
  aun así la ejecución devolvió **cinco correcciones** al protocolo (abajo), ya aplicadas.

## Secuencia y evidencia

| Paso | Evidencia |
|---|---|
| Preflight (solo lectura) | 3 nodos en 1.1.2 healthy; `/` 9,6 G libres; línea base por autor: bot-1 `about` 1 · bot-2 `about` 1, `wallet` 1; dirección `EYdru…Lc` |
| Backups | pub → `devops/backups/oasis-pub/20260919T163345Z`; `wallet.dat` → `devops/backups/ecoin/20260919T163453Z` (sha256 `b0ee1617…`); en el VPS `/srv/oasis/oasis-{hub,wallet-bot}.bak-o106-2026-09-19.tgz` (600), compose `.bak-o106-2026-09-19`, imagen `:1.1.2`, `/srv/oasis/src-1.1.2.tgz`, `src.old` |
| Disco | retirada la imagen `:1.0.8` + prune: `/` del 60 % al 40 %; tras el build, 50 % |
| `src/` | `git -c core.autocrlf=false archive main src`; en destino versión 1.1.4, 0 ficheros con CR, `url` del 5.º guard correcta, `src/configs` sin JSON de estado |
| Build | en el VPS, con el pub sirviendo |
| Pub | `up -d --no-deps oasis-pub` → healthy, `Version: 1.1.4`, feed `@/snvahva…` igual, web 200 |
| HUB | `up -d --no-deps oasis-hub` → healthy, 1.1.4, estado migrado a `ssb-data/oasis/**` (flags incluidos), `private` = 0, `CONNECTED` en el pub, `/c` 200 |
| bot-2 | parado → copia de `banking/` a `ssb-data/oasis/banking/` (mismo sha256, propietario 999) → compose vivo sin `OASIS_BANKING_DIR` ni bind `/app/banking` (diff de 2 líneas) → `up` → healthy, 1.1.4, **misma dirección**, `wallet` = 1, `private` = 0, 0 × `[UBI] PUB engine on`, `CONNECTED` |
| Renombrado bot-1 | ventana con `OASIS_HUB_PUBLIC=false` en el shell → POST 302 → `about` 1 → 2 (`clearnet.escrivivir.co`) → vuelta a público, gate 302 |
| Renombrado bot-2 | ventana con `OASIS_WALLET_BOT_PUBLIC=false` → POST 302 con `vis_wallet=on` → `about` 1 → 2 (`ecoin.escrivivir.co`), **`wallet` sigue en 1**, `visibilityPrefs.wallet: true` → vuelta a público, gate 302 |
| Cierre | memoria: bot-2 108 MiB/768 · HUB 171/768 · pub 66 · ecoind 81/512; `/srv/oasis` 21 %; journal `--version 1.1.4 --mode server+hub+wallet` |

`ecoin` no se recreó (23 h de uptime). Caddy no se tocó. `.env.prod` no se tocó.

## Correcciones al protocolo que devolvió la ejecución

1. **Contar por autor** (HUB §12 paso 2): a hops 3 el log de bot-2 tenía 146 `about` y 7 `wallet`, casi todos ajenos.
2. **`git archive` en Windows convierte a CRLF**: el primer envío de `src/` llegó con 12 337 líneas CR en
   `backend.js`. Rehecho con `-c core.autocrlf=false` antes del build. UPGRADE §4 y `AGENTES.md` §4.
3. **La ventana no pública no exige editar `.env.prod`**: el entorno del shell manda sobre `--env-file`. HUB §12 paso 1.
4. **La descripción viaja en fichero** (`-F 'description=</tmp/desc.txt'`): sin problemas de comillas ni acentos. HUB §12 paso 3.
5. **`vis_wallet=on` en un bot de cartera** (destapado ya en el gate local de WP-O105). HUB §12 paso 3.

## Observaciones

- En el gate de vuelta a público del HUB se envió también un `POST /profile/edit` de prueba: 302 de modo
  público y el conteo de `about` no se movió. No hace falta repetirlo: el gate canónico es el de invites.
- Recrear un backend **en la misma versión** no publica otro `oasisVersion` (bot-1: 3, bot-2: 2 tras las ventanas).
- `https://pub.escrivivir.co/settings` y similares dan 200 porque los sirve la landing estática (POST → 405); el HUB solo recibe `/c*`.
- El VPS conserva su `docker-entrypoint.sh` y `Dockerfile` pre-refactor: solo se sube `src/`. El arreglo del
  chequeo de `gossip_unfollowed.json` no está allí; es un log, no afecta.

## Seguimiento

- **WP-O107**: interruptor `pub: true` + `hub-wallet.sh`; hasta entonces no salimos en la lista de pubs de Banking.
- **WP-O108**: cliente en 1.1.4. **WP-O109**: agente en frío, `limit_req`.
- Tras 24 h: memoria de HUB y bot-2 en 1.1.4. Rollback disponible hasta entonces (`:1.1.2`, `src.old`, tgz);
  después, retirar `:1.1.2` y `src.old` para recuperar disco.
- Mover a almacenamiento cifrado los backups de hoy (contienen `secret` y `wallet.dat`).
