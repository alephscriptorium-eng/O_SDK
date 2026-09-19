# Reporte · WP-O105 · Upgrade mínimo Oasis 1.1.2 → 1.1.4

- **Fecha**: 2026-09-19 · **Rama**: `upgrade/oasis-1.1.4` · **Asientos**: D-O21, D-O22.
- **Resultado**: `src/` en 1.1.4 (upstream `45a1cd4`) con **5 guards**; pub, HUB y bot-2 arrancan en
  local sobre estado real de 1.1.2 sin perderlo; motor de RBU **apagado**. Listo para el VPS (WP-O106).
- **Diferido a propósito**: interruptor nuevo y gestión de admin (WP-O107), cliente (WP-O108),
  `limit_req` y agente en frío (WP-O109).

## Qué se entregó

| Pieza | Commit |
|---|---|
| Overlay limpio de `src/` (con `git rm` previo) + guards sin cambios upstream por checkout | `b6beabe` |
| Guards a mano: `/update` y aviso en ajustes | `bf546d4` |
| 5.º guard: `snh-invite-code.json:url` | `ef36f4f` |
| bot-2 sin `OASIS_BANKING_DIR` ni bind `/app/banking` | `2300e50` |
| Docs: UPGRADE §2, ECOIN §5.1/§5.3/§5.4/§9, aviso en CLIENT §8 | `4a3c3e3` |
| Entrypoint: `gossip_unfollowed.json` vale en `oasis/peers/` | `bc8f776` |

## Gates locales · evidencia

Estado de partida: los volúmenes de los gates de 1.1.2 (`volumes-dev/oasis-{pub,hub,wallet-bot}`),
identidades desechables. Copia previa `*.bak-pre114`.

| Gate | Resultado |
|---|---|
| Invariante de `src/` | ✅ `git diff oasis-upstream/main --stat -- src/` = 6 ficheros; `node --check backend.js`; versión 1.1.4 |
| Build con node 20 | ✅ imagen construida (upstream pide node ≥ 22 solo en su `.deb`) |
| **G0 migración de estado** | ✅ en HUB y bot-2 aparece `ssb-data/oasis/{banking,content,flags,keys,multiverse,peers}`; `oasis-first-contact` y `oasis-political-seen` migran a `oasis/flags/`; `private` = 0 en ambos feeds (sin PM de bienvenida); sin `EROFS`/`EACCES`/`ReferenceError` en los logs |
| bot-2: estado bancario | ✅ con la copia manual de §5.4, tras `GET /banking`, `/wallet` y `/activity` desde el loopback: **misma dirección** en `oasis/banking/wallet-addresses.json`, `wallet` = 1, `pubAvailability` = 1 y `ubiAllocation` = 1 (los tres igual que la línea base) |
| bot-2: motor | ✅ 0 apariciones de `[UBI] PUB engine on` |
| Conexión | ✅ el pub registra `CONNECTED` de los dos bots; `conn.json` intactos |
| **G4 HUB** | ✅ `/c` 200; `POST /settings/invite/accept` → 302 con `?error=` de modo público |
| Renombrado (HUB §12) | ✅ receta ensayada: 302, exactamente +1 `about`, descripción UTF-8 intacta; con `vis_wallet=on`, +1 `about` y `wallet` sigue en 1 |

## Hallazgos

1. **`vis_wallet` en un bot de cartera.** Sin él, y mientras no esté anunciado como pub de RBU, los
   clientes no pueden usar su dirección desde la UI (`sharedEcoAddress`). Llevado a HUB §12 paso 3.
2. El `about` que publica el formulario incluye `deviceSource` y `visibilityPrefs.device: true` aunque
   no se envíe ningún `vis_*`: inocuo en un bot, anotado.
3. `migrateAll()` también muda `gossip_unfollowed.json`: el chequeo del entrypoint habría mentido en cada
   arranque. Corregido.
4. Un `walletPub` sobrante en `oasis-config.json` no produce error ni aviso: se confirma que es inofensivo.
5. En Git Bash, `node -e "require('/c/…')"` falla bajo `MSYS_NO_PATHCONV=1` (trampa ya listada en `AGENTES.md` §4).

## No medido

Latencia de `/c/<tipo>/<slug>` con índice grande (local casi vacío) → WP-O109. Efecto de `pub: true` → WP-O107.
