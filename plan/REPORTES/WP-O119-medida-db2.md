# WP-O119 · La medida de los nodos deja de depender del formato del log

Rama `wp/O119-medida-db2` · 2026-10-04 · asiento D-O27 · precede a WP-O120 (upgrade a Oasis 1.2.1).

## Por qué

Al ejecutar el protocolo de upgrade contra 1.2.1 (`OLD_REF=f770dbb7`, `NEW_REF=942d39c9`) se vio que
upstream cambia el motor (`ssb-db`/flume → `ssb-db2`): el primer arranque migra `flume/log.offset` a
`db2/log.bipf`, borra `flume/` y deja un fichero-guarda de texto. Nuestra medida tenía dos fuentes y
las dos fallaban **en silencio**:

- `lib-node.sh` contaba con `grep` sobre `flume/log.offset` → sobre la guarda da 0.
- `ssb-probe.js` preguntaba con `getLatest`, que no existe en el sbot nuevo, y convertía el fallo en
  `seq: 0`.

`upgrade-gates.sh check` habría visto `0 = 0 = 0`: desviación falsa en U3 (Δseq negativo) y **verde
falso** en U5 y en cualquier foto tomada después de migrar.

## Qué se entregó

| Commit | Pieza |
|---|---|
| `30cf324f` | D-O27 y filas de WP-O119 a WP-O123 |
| `65270e4f` | `pub/tools/ssb-probe.js`: `createUserStream` en vez de `getLatest`; un fallo es un fallo; sin `manifest.json` del disco |
| `b024842b` | `pub/tools/log-bipf.js` (lector de solo lectura de `db2/log.bipf`) · `lib-node.sh` (`node_log_format`, `node_own_scan`) · `upgrade-gates.sh` (log ilegible = NO MEDIBLE, formato en la foto, `GATE_UP_TIMEOUT`) |
| `19415057` | `hub-wallet.sh` y `test-invite.sh` cuentan con la librería |
| `f6292a13` | `hub-disk.sh` y `ecoin-disk.sh` miden `db2/` (claves nuevas `hubDb2Bytes`, `botDb2Bytes`) |
| `6afc01df` | `upgrade-behaviour-diff.sh` y `upgrade-preflight.sh` no recorren `src/base` |

## Criterios de aceptación

**CA1 · Sobre 1.1.10, la foto nueva es la vieja.** Stack local (identidades desechables), tres nodos
`healthy` en 1.1.10. Foto con el código de `main` (`git stash`) y con el de la rama:

```
$ diff <(grep -v -E '^meta\||\|log\|' o119-old.local.snap) <(grep -v -E '^meta\||\|log\|' o119-new.local.snap) && echo IDENTICAS
IDENTICAS
$ grep '|log|' devops/logs/upgrade/o119-new.local.snap
pub|log|flume
hub|log|flume
bot|log|flume
```

La foto nueva, con las tres fuentes de acuerdo en cada nodo:

```
  pub  running healthy  v1.1.10  server   log=flume seq=6 registros=6 → cuadra · sbot=6
  hub  running healthy  v1.1.10  backend  log=flume seq=7 registros=7 → cuadra · sbot=7
  bot  running healthy  v1.1.10  backend  log=flume seq=17 registros=17 → cuadra · sbot=17
```

**CA2 · `check` sin cambios da verde.** `upgrade-gates.sh --local check o119-new` → `Δseq=0 · sin
publicaciones → ok` en los tres, `GATE OK`.

**CA3 · `hub-wallet.sh --local status`** cuenta por la librería: `wallet=1 about=3 pubAvailability=4
ubiAllocation=2`, y enseña el último anuncio.

**CA4 · Discos**: `hub-disk.sh --local --json` y `ecoin-disk.sh --local --json` emiten
`hubDb2Bytes: 0` y `botDb2Bytes: 0` (aún en flume) junto a las claves de siempre.

**CA5 · El diff de comportamiento termina.** `upgrade-behaviour-diff.sh f770dbb7 942d39c9`: 1 min
17 s (antes: cortado a los 5 min sin salida), con una línea
`deps + src/base dependencias vendorizadas: 19145 ficheros en 703 paquetes de primer nivel`.
Preflight: `backends y cliente = 125 · dependencias vendorizadas (src/base) = 19145`.

**Lo que este WP no ha medido.** El camino db2 (`log-bipf.js`, `node_log_format` = `db2`) no se puede
ejercer sin una imagen 1.2.1: se valida en WP-O120, gate UM. Hasta entonces es código sin evidencia.
Los caminos remotos (`--remote`) no se han ejecutado contra el host.

## Hallazgos

- **Carrera entre el log y la sonda.** En la primera pasada el bot publicó un `pubAvailability`
  (motor encendido, más de 12 h desde el anterior) entre la lectura del log y la pregunta al sbot:
  `seq=16 … sbot=17 ≠ log`. El código viejo lo enseñaba y salía con 0; el nuevo responde NO MEDIBLE.
  La foto se repite.
- **Descartado: medir solo por RPC.** La acción `own-types` de la sonda que preveía el plan no se ha
  hecho: `node_own_scan` cubre los dos formatos y conserva dos fuentes independientes (fichero y sbot).
- `test-invite.sh` contaba líneas con `"type":"contact"` de cualquier autor y con `grep -c`: ahora
  cuenta los `contact` propios del pub.

## Seguimiento

- WP-O120: validar el camino db2 (UM); invariantes de upstream de los que depende este código
  (`MIGRATED_MARKER`, `dangerouslyKillFlumeWhenMigrated`, `createUserStream` en `db2_legacy.js`), que
  entran con el overlay porque en el árbol 1.1.10 no existen; scripts del cliente
  (`import-identity.sh`, `sync-only.sh`, `inspect-log-offset.js`, `count-feed-type.js`).
- Documentación (`UPGRADE-PROTOCOL.md` §3.4, `AGENTES.md` §4 y lo que cita `flume/log.offset`): con
  WP-O120, cuando los gates nuevos estén medidos.
