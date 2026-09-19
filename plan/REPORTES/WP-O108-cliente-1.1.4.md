# Reporte · WP-O108 · Cliente en Oasis 1.1.4 con cartera propia

- **Fecha**: 2026-09-19 · **Rama**: `wp/O108-cliente-1.1.4`.
- **Resultado**: entrypoint y scripts del cliente al día de 1.1.4, ensayados con identidad desechable; y
  **aplicado al cliente del custodio** (GO expreso: «cartera propia», «GO cuando sincronice»): 1.1.4, misma
  identidad, `ecoind` propio, **un** mensaje `wallet` publicado, backups antes y después.

## Qué se entregó

| Pieza | Commit |
|---|---|
| Entrypoint: sin `OASIS_BANKING_DIR`, sin symlink del mapa, copia única del `banking/` de 1.1.2, retirada de `walletPub`; compose raíz y `.env.example` | `41df12a` |
| Scripts: `ecoin-verify.sh` (estado nuevo), `ecoin-init.sh` (`--pub-id` avisa y no hace nada), `import-identity.sh` | `9dff8c6` |
| `CLIENT-PROTOCOL.md` §8 para 1.1.4 | `722edbb` |
| `setup.sh` / `ecoin-init.sh` ya no crean `client-state/banking` | `0b1c294` |

## Drill (proyecto `o-sdk-drill`, identidad desechable, desmontado sin restos)

| Comprobación | Resultado |
|---|---|
| Arranque 1.1.4 con un `client-state/banking` de 1.1.2 | ✅ copiado una vez a `~/.ssb/oasis/banking`, original conservado; `OASIS_BANKING_DIR` sin definir; sin mapa en `src/configs` |
| **¿Abrir la GUI publica la dirección?** | ✅ **sí**: 0 → 1 mensaje `wallet` tras las primeras visitas |
| ¿Se repite? | ✅ no: sigue en 1 tras más visitas, `--force-recreate` y nuevas visitas; `ismine: true` |
| `ecoin-verify.sh` | ✅ 14 PASS · 0 FAIL |

## Aplicación al cliente del custodio

| Paso | Evidencia |
|---|---|
| Línea base (solo lectura) | 1.1.2, compose anterior a WP-O103 (sin state dir), mapa `{}`, 0 mensajes `wallet` |
| Backup de identidad | cliente parado → copia completa de `ssb-data` en `devops/backups/client/20260919T172855Z`; sha256 de `secret` y `log.offset` iguales a los originales |
| Rollback preparado | imagen `o-sdk-oasis-client:1.1.2` |
| 1.1.4 **sin cartera** (`--mode address`) | healthy, `Version: 1.1.4`, mismo `secret`, estado migrado a `ssb-data/oasis/**` (flags incluidos), `wallet.url` vacía, 0 `wallet` |
| `ecoind` propio | `ecoin-wallet` sin puertos al host, volumen externo `o-sdk-client-ecoin-data`, sincronizado desde la red hasta la altura del nodo del VPS (52 410), keypool 101 |
| Backup previo de `wallet.dat` | `devops/backups/client-wallet/20260919T174827Z` (sha256 contenedor = host) |
| Cableado + visitas | cableado sin visitar: 0 · tras `GET /banking`: 0 · tras `GET /wallet` y `/`: **1** (`distinct` 1) |
| Verificación | `ismine: true` · backup posterior `…/20260919T175017Z` · `ecoin-verify.sh --expect-wallet-msgs 1`: **15 PASS · 0 FAIL** · `secret` intacto |
| Banking | en `/banking?filter=pubs` del cliente aparece `ecoin.escrivivir.co` |

## Hallazgos

1. **En 1.1.4 la publicación de la dirección es automática** con la cartera cableada. En el cliente real la
   disparó la visita a `/wallet` o `/` (no `/banking`, que en el drill iba mezclada con las demás). Es
   idempotente. El backup previo vale porque la dirección sale del keypool.
2. El cliente del custodio nunca había arrancado con el compose de WP-O103: no había estado bancario que migrar.
3. La imagen del drill es la misma que la del cliente (mismo `Dockerfile` y contexto): se reetiquetó en vez
   de reconstruir (~10 min ahorrados). Queda anotado como atajo válido solo con el árbol sin cambios entre ambos.
4. `visibilityPrefs.wallet` del perfil del custodio no se ha tocado: para que otros habitantes puedan pagarle
   desde la UI hace falta marcar «wallet» en su perfil (un `about`; decisión suya). La RBU no lo necesita.

## Seguimiento

- Backups de hoy (`secret`, `wallet.dat`) a almacenamiento cifrado fuera de la máquina.
- La RBU exige feed ≥ 30 días, dirección publicada y actividad; la paga cualquier pub con fondos que lo vea.
- Clientes Android del custodio (horizonte): protocolo propio pendiente; la app trae su cartera.
- WP-O110 fase 0 (torrent de Aleph Cero): `docs/ROADMAP/p2p/07-revision-y-secuencia.md`.
