# WP-O122 · Snapshots construidos por el pub

Rama `upgrade/oasis-1.2.1` · 2026-10-04 · asiento D-O27 (puntos 3 y 4). **Solo local: en el host
no hay nada activado.**

## Por qué

En Oasis 1.2 un cliente que acepta un invite le pide al pub un fichero con el historial
(`<.ssb>/oasis/content/snapshot.oasissn`) y lo ingiere de golpe. Upstream lo construye con el
backend público del pub. Nuestro pub es solo sbot: carga el plugin que lo sirve
(`src/server/snapshot_plugin.js`) pero nadie le construye el fichero; y el HUB y el bot, que sí son
backends públicos, construirían cada 6 h los suyos, que nadie pide.

Tres hechos del código que fijaron el diseño:

- el fichero no va firmado; cada mensaje sí, y el cliente lo valida. Pero el formato admite además
  registros de blob y de fichero de estado que el cliente escribe en su `~/.ssb/oasis/` sin
  comprobar (`backup_model.js`, `readBackup` y `restoreBackup`);
- upstream construye cargando el log entero en memoria, dos veces (`readLog` con `pull.collect`);
- no hay interruptor ni clave de config.

## Qué se entregó

| Commit | Pieza |
|---|---|
| `0aac9bdb` | interruptor `OASIS_SNAPSHOT=off` en `src/backend/backend.js` (corta `runSnapshotBuild` y `bootstrapFromPub`) |
| `61611713` | el interruptor, puesto en HUB y bot (`pub/docker-compose.pub.yml`) |
| `be72a2c2` | `pub/tools/snapshot-build.js` y `devops/scripts/pub-snapshot.sh` (`status`, `build`, `off`, `cron`) |
| `b458e3d8` | invariantes del formato y de la ruta en `upgrade-invariants.d/db2.tsv` |
| `68e22ddc` | `HUB-PROTOCOL.md` §13; gate US en `UPGRADE-PROTOCOL.md` §3.4 |

## Gate US (stack local, identidades desechables)

**Construir.** `pub-snapshot.sh --local build`:

```
{"ok":true,"path":"/home/oasis/.ssb/oasis/content/snapshot.oasissn","messages":41,"feeds":5,"boxed":3,"bytes":11287,"ms":52}
```

El fichero empieza por `OASISSN1`, su primer registro es de tipo 1 (metadatos) y el resto de tipo 2.

**Construir no publica.** Foto `us-121` antes; después de construir y de tres invites:
`check us-121 --expect 'pub:contact=+1'` → `pub … Δseq=1 · contact+1 → ok` (el `contact` es el del
primer invite), HUB y bot «sin publicaciones», `GATE OK`.

**A quién se sirve.** Un nodo desechable (la imagen 1.2.1 en modo `backend`, con la config de un
nodo de soporte: sin semillas ni gossip global), preguntando al pub con su identidad:

```
antes del invite (el pub no le sigue): {"full":"snapshot: not allowed","recent":"snapshot: not allowed"}
después (el pub le sigue):             {"full":{"tier":"full","bytes":7077,…},"bajado":7077,"cabecera":"OASISSN1","error":null,"recent":"snapshot: not available"}
```

**El cliente arranca desde él, y el interruptor lo impide.** Mismo procedimiento
(`POST /settings/invite/accept` por loopback → 302), midiendo los registros del log del nodo:

| Nodo | Antes del invite | A los 5 s | A los 30 s | ¿El pub le sigue? |
|---|---|---|---|---|
| snapshots por defecto | 1 registro, 1 autor | **40 registros, 5 autores** | 40 | sí |
| `OASIS_SNAPSHOT=off` | 1, 1 | **3, 1** | 3 | sí |

**Techo.** `SNAPSHOT_MAX_MB=0.001 pub-snapshot.sh --local build` → `{"ok":false,"error":"el snapshot
supera el techo…"}`, código 3, y el fichero anterior sigue en su sitio.

## Lo que no se ha medido

- **La carrera del seguimiento.** El pub solo sirve a quien sigue, y sigue al redimir el invite. En
  local el cliente llegó a tiempo las dos veces; con un pub cargado podría pedir antes y recibir
  `not allowed`, y el cliente no reintenta. No rompe nada: replica sin snapshot.
- **Tamaño y tiempo con el log real del pub**: se miden al activarlo (WP-O123, paso 9b).
- **El temporizador del host**: la línea de `pub-snapshot.sh cron` no se ha instalado en ningún sitio.
- Un cliente con GUI y una persona delante: el nodo desechable es un backend sin interfaz.

## Decisiones tomadas por el camino

- **Sin cargar `backup_model.js`** de upstream para construir: al cargarse, `state-manager` muda
  ficheros del `.ssb`. El script escribe el formato él mismo y los invariantes vigilan que no cambie.
- **Dos pasadas por el log** (contar y escribir) para dar los metadatos exactos sin cargarlo en
  memoria. Lo que llega entre una y otra queda para la siguiente construcción.
- **El invite del stack local** hay que pedirlo con un `external` ficticio y reescribir el host: el
  pub de ensayo anuncia `localhost` (`AGENTES.md` §4).

## Seguimiento

- WP-O123, paso 9b: construir en el host, medir, instalar el temporizador. Pide GO.
- A upstream: un interruptor para la construcción; que el snapshot no acepte registros de estado ni
  de blob; reintento del cliente si el pub aún no le sigue.
