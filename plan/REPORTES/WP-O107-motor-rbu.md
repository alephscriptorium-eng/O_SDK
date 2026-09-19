# Reporte · WP-O107 · Motor de RBU en Oasis 1.1.4: interruptor y gestión de admin

- **Fecha**: 2026-09-19 · **Rama**: `wp/O107-motor-rbu` · **Asiento**: D-O21.
- **Resultado**: motor **ENCENDIDO** en `pub.escrivivir.co` desde las 17:09 UTC (GO del custodio:
  «encender»). La casa se anuncia como pub de RBU: `@ecoin.escrivivir.co`, `available: false`, pool 0
  hasta la dote. Gestión `encender → comprobar → pausar` en `devops/scripts/hub-wallet.sh`.

## Qué se entregó

| Pieza | Commit |
|---|---|
| Interruptor: `pub/config/wallet-bot/ssb-config.engine-on` (`pub: true`) | `964cc51` |
| `devops/scripts/hub-wallet.sh` `status · ready · on --yes · pause` (`--local`) | `047f8a0` |
| Retirada de `walletPub` / `OASIS_WALLET_BOT_PUB_ID` (plantilla, render, env de ejemplo) | `27a1689` |
| ECOIN §9 reescrito; trampa nueva en `AGENTES.md` §4 | `84ef10a` |
| Aviso de saldo ≤ 500 en `ready` y coste de encender sin fondos en §9 | (este cierre) |

## Evidencia

| Paso | Resultado |
|---|---|
| Ensayo local `on` | `pub=true`, 1 × `[UBI] PUB engine on`, `pubAvailability` +1, `wallet` = 1, el pub ve al bot `CONNECTED` con `pub:true` (el cambio a `ssb-invite` no afecta a `conn.json`) |
| Ensayo local `pause` | `pub=false`, 0 en el log, ningún mensaje nuevo; env-file con backup `*.bak-hubwallet-*` |
| Render sin `walletPub` | OK, JSON válido, 0 marcadores, resumen sin afirmar nada del motor |
| VPS `ready` | 10/10 ok, exit 0 |
| VPS `on --yes` | `pub=true (ssb-config.engine-on)`, 1 × `[UBI] PUB engine on`, `pubAvailability` = 1, `wallet` = 1, bot healthy |
| Backup posterior | `devops/backups/ecoin/20260919T171116Z` (sha256 `14bdcce1…`), ya con la dirección anunciada |

## Hallazgos

1. **Cada anuncio lleva una dirección nueva** (`getnewaddress`), no la publicada como `wallet`. Es de la
   misma cartera (`ismine: true`, keypool de 101). Regla nueva: backup semanal de `wallet.dat` con el motor encendido.
2. **Encender con saldo ≤ 500 fija la época del mes con pool 0** y publica una `ubiAllocation` de 1 ECO
   sin respaldo por habitante elegible: en el VPS, época `2026-09` y **6 asignaciones** (una al propio bot).
   Dos reclamos ya existentes se saltaron con `skipped: PUB wallet balance is 0`: **no se pagó nada**.
   **Error de proceso del agente**: la advertencia estaba escrita (ECOIN §3 paso 11) y no se le recordó
   al custodio al pedirle el GO. Corregido donde toca: `ready` lo avisa en pantalla y §9 lo explica.
   Efecto práctico: si la dote llega en septiembre, este pub reparte ese mes como mucho 1 ECO por
   persona; en octubre la época se abre con el saldo real.
3. `ready` no siempre encuentra en el log reciente de `ecoind` la altura que anuncian los pares; en ese
   caso acepta «RPC responde + conexiones > 0» y lo dice. Contrastado a mano con el nodo local (misma altura ± 3).

## Seguimiento

- **Dote** a la dirección que muestre la tarjeta de Banking (o a `EYdruXgDVQGhBpSsns83VA1BmDfAKBP4Lc`):
  ambas son de la misma cartera. Avisar a upstream de que ya estamos en la lista.
- Backup semanal de `wallet.dat` (`backup-ecoin.sh`) y `hub-wallet.sh status` en la ronda semanal de disco.
- Memoria del bot con el motor encendido, a las 24 h.
- Reportar a upstream: suelo de 1 ECO sin fondos y época fijada con pool 0.
