# Reporte · WP-O102 · hub-wallet del pub (`ecoind` + `azofaifo-scriptorium-wallet-bot-2`)

- **Fecha**: 2026-09-18 · **Rama**: `wp/O102-hub-wallet` · **Método**: plan aprobado por el custodio, workflows de agentes con parada dura, commits por pieza.
- **Resultado**: **desplegado** en el VPS de `pub.escrivivir.co`, con el **motor de RBU apagado** por decisión del custodio hasta que llegue la dote.
- **Doc viva**: `docs/PUB/ECOIN-PROTOCOL.md` (estado en cabecera, registro en §13, hallazgos en §14). **Asiento**: D-O19.

## Qué corre ahora

| Pieza | Valor |
|---|---|
| `oasis-pub-ecoin` | `ecoind` v0.7.5.7 (paquete 0.0.4), sincronizado a la altura de la red, 11 pares, sin puertos publicados, estado en `/srv/oasis/ecoin` |
| `oasis-pub-wallet-bot` | `backend.js` en modo público, sin puertos ni ruta en Caddy, estado en `/srv/oasis/oasis-wallet-bot` |
| Identidad de bot-2 | `@NYAqUzX7OACl+Fs866J8aVeKcqPxbbXccV/phcKx9UU=.ed25519`, `about` = `azofaifo-scriptorium-wallet-bot-2` |
| Cartera del pub | `EYdruXgDVQGhBpSsns83VA1BmDfAKBP4Lc`, publicada una vez en el feed de bot-2, saldo 0 |
| Motor de RBU | **apagado**: `OASIS_WALLET_BOT_PUB_ID` vacío en `.env.prod` |
| Backup de `wallet.dat` | `devops/backups/ecoin/20260918T180643Z` (no versionado), sha256 remoto = local, posterior a la generación de la dirección |

## Criterios de aceptación · evidencia

| CA | Resultado |
|---|---|
| `ecoind` en contenedor propio, sin penalizar al pub | ✅ `cpus 0.75`, `mem_limit 512m`; durante los 13,5 min de sincronización el pub siguió healthy, `/c` 200 y por debajo del 1 % de CPU |
| RPC nunca sale de la red Docker | ✅ `docker port` vacío; `127.0.0.1:7474` y `:7408` rechazados desde el host; UFW sin cambios |
| Credenciales por defecto rechazadas | ✅ `ecoinrpc:ecoinrpc` → 401 desde la red; sin credenciales el contenedor sale con 1 (gate G1) |
| `.deb` reproducible | ✅ `fetch-deb.sh` en el VPS: descargado y verificado contra el sha256 versionado; el build falla con el hash alterado (G1) |
| bot-2 con identidad propia y sin ruta pública | ✅ feed distinto del pub y del HUB; sin `ports`; Caddyfile con el mismo sha256 |
| El feed del pub solo gana el `contact` del follow-back | ✅ `"contact":"<bot-2>"` = 1 |
| El pub no se reinicia | ✅ `StartedAt` de pub, HUB y Caddy idénticos antes y después |
| Dirección publicada exactamente una vez y respaldada | ✅ un mensaje `wallet`; `validateaddress` → `ismine: true`; backup verificado 17 s después |
| Motor apagado | ✅ 0 `pubAvailability` y 0 `ubiAllocation` en 120 s; tipos propios: `contact`, `pub`, `about`, `oasisVersion`, `karmaScore`, `wallet`; `private` 0 |
| Modo público efectivo | ✅ POST con Referer → 302 con error de modo público; sin Referer → 400 |
| Estado en el volumen de datos | ✅ `/srv/oasis/ecoin` (700, uid 1000; `wallet.dat` 600) y `/srv/oasis/oasis-wallet-bot`; `/` pasa de 59 a 60 % por la imagen de 141 MB |
| Memoria | ✅ ecoind 82 MiB, bot-2 111 MiB; HUB bajado en caliente de 1536m a 768m; 2,4 GB disponibles |

Gates locales G1-G6 pasados antes del VPS, con simulacro real de restauración de `wallet.dat` y
ensayo del interruptor del motor (encender → primer tick → apagar). Detalle en `ECOIN-PROTOCOL.md` §14.

## Lo que encontraron los gates y el deploy

1. **`rpcallowip` no entiende CIDR** en este `ecoind`: con `172.16.0.0/12` devolvía 403 a toda la red Docker. Corregido con comodines (`6bff789`). Habría bloqueado el VPS.
2. **La dirección no se publica sola**: `ensureSelfAddressPublished` falla en silencio por un `ReferenceError` de upstream (`banking_model.js:107`). Se publica con `POST /banking/addresses`, que **no es idempotente**: exactamente una vez.
3. **El backup va después de generar la dirección**; uno anterior no contiene esa clave.
4. El entrypoint recopiaba `bootstrap.dat` en cada arranque y `ecoin-disk.sh` no contaba `txleveldb/`: corregidos.
5. La altura de los pares sale de `receive version message … blocks=`, no de `height=`.
6. El entrypoint imprimía el usuario RPC en los logs: corregido en la rama; la imagen del VPS lo lleva hasta el próximo build. La contraseña nunca se imprimió.
7. Parada del deploy en el paso 4: el clasificador de permisos de la sesión denegó a un agente el POST de publicación. El agente no buscó otra vía; lo ejecutó el orquestador una vez, tras comprobar que seguía sin publicarse.

Hallazgos de upstream a reportar (no se corrigen en el fork: `src/` sigue con 4 guards):
`processPendingClaims` paga cualquier `ubiClaim` sin filtrar por pub · `pubAvailability` se publica en
cada tick sin detectar cambio · `executeEpoch` asigna 1 ECO sin fondos · el `ReferenceError` de `services`.

## Pendientes y seguimiento

- **Dote** a `EYdruXgDVQGhBpSsns83VA1BmDfAKBP4Lc` → **encender el motor** (`ECOIN-PROTOCOL.md` §9) con confirmación expresa del custodio. No ensayar el interruptor antes: fija el epoch del mes con pool 0.
- **24 h**: `docker stats` de ecoind y bot-2 → límites = `ceil(1,5·pico)` (mínimos 384m y 512m); `ecoin-disk.sh --json`.
- Mover el backup de `wallet.dat` a almacenamiento cifrado: la cartera va sin cifrar porque el motor no puede desbloquearla.
- **WP-O103**: ECOin en la app cliente (dos niveles; ensayo con identidad desechable antes de tocar el feed real). Necesita el feed de bot-2 como `walletPub.pubId`.
- Analizar la **1.1.3** cuando publique fuente, con la tabla de contingencia de §5.3.
- WP futuro: presentación comunitaria de los bots oficiales Azofaifo.
- Revisión adversarial · merge a `main`.
