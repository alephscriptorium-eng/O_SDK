# Reporte · WP-O98 · Cliente fresco en o-sdk + importación de identidad

- **Fecha**: 2026-09-17 · **Rama**: `wp/O98-cliente-fresco-identidad` sobre `e16c455` · **Método**: plan aprobado por el custodio (3 exploraciones + 1 diseño), un solo operador.
- **Resultado**: **cliente activo en este repo con la identidad del custodio, sin bifurcación**. Alta fresca probada (identidad desechable), importación de `@tMJzSf…` y sincronización con el pub en sbot puro; GUI arrancada a las 13:37 UTC; `Verification` forks 0; `seq_pub` = seq local = 46.
- **Doc viva**: `docs/CLIENT-PROTOCOL.md`. **Decisiones del custodio**: portar `secret` + `log.offset` + `gossip.json` (+ blobs); copiar el modelo IA existente; **no tocar** lo antiguo; backup solo en `devops/backups/client/`.

## Estado de partida

| Comprobación | Resultado |
|---|---|
| Cliente en este repo | **Nunca inicializado**: sin `volumes-dev/{ssb-data,ai-models,logs}`, sin imagen `o-sdk-oasis-client`, proyecto compose `o-sdk` inexistente |
| Cliente real del custodio | `oasis-server-dev` (imagen `alephscript-clean-oasis-dev`, **Oasis 0.8.8**, `Exited` desde 2026-08-01) con datos en `C:\Users\aleph\OASIS\aleph-scriptorium\BlockchainComPort\volumes-dev\` vía volúmenes con nombre `alephscript-clean_*` / `blockchaincomport_*` (mismo directorio físico) |
| Identidad | `@tMJzSfcZSNCsFRF3pl3rMoFDatz6VjDCjQ8/TpjYIRY=.ed25519`; cap ciclo 6 (= actual); `log.offset` 1 421 251 B, **1541 registros, 46 feeds, seq propio 44** (último `karmaScore` 2026-07-21 16:55 UTC); `gossip.json` con `pub.escrivivir.co` (`client:true`); `keys/` (tribus); 97 blobs (213 MB) |
| Pub de producción respecto al feed | `pub-feed-seq.sh`: `seq_pub=44`, `pub_follows_feed=true`, `feed_follows_pub=true` → el pub tenía el feed completo |
| `C:\Users\aleph\OASIS\_RECOVERY-20260721\alephscript-clean` | checkout git limpio del código 0.8.8 (mismo compose, `oasis-server-dev`), sin `volumes-dev`: referencia, no datos |
| Convivencia una carpeta | cliente (`o-sdk`: 3000/8008, `volumes-dev/{ssb-data,ai-models,logs,ecoin-data}`) y pub+HUB (`oasis-pub-scriptorium`: 8009/8088/8443/8788 con `pub/.env.local`, `volumes-dev/{oasis-pub,oasis-hub,teatro}`) disjuntos en puertos, nombres, redes y directorios. Los 5 contenedores del pub local estaban parados |
| Huecos del protocolo | Quickstart sin `npm run setup`; `setup.sh` creaba `configs` (muerto) y no `ecoin-data`; `test-ai-service.sh` roto (`/health` inexistente, `host.docker.internal` desde el host, `:4001` no publicado); `.gitignore` no cubría `.env.*` (`pub/.env.prod` commiteable); rollback del cliente irreal en `UPGRADE-PROTOCOL.md`; `RECOVERY-PROTOCOL.md` §4 citaba `oasisVersion` como vector de fork (en 1.1.2 está guardado; el vivo es el **PM de bienvenida**) |

## Qué se entregó

| Pieza | Commit |
|---|---|
| `docs/CLIENT-PROTOCOL.md` (§0-§8) + sidebar VitePress; `client/scripts/import-identity.sh`, `client/scripts/sync-only.sh`, `client/scripts/lib/inspect-log-offset.js`, `pub/tools/ssb-probe.js`, `devops/scripts/pub-feed-seq.sh`; `setup.sh`, `test-ai-service.sh`, `package.json` (5 scripts npm), `.gitignore`, README/`docs/index.md`, `client/README.md`, `UPGRADE-PROTOCOL.md`, `RECOVERY-PROTOCOL.md`, `pub/README.md`, `MAPA.md`, CHANGELOG, BACKLOG | `67b1ead` |
| Correcciones halladas en la ejecución (sonda como `oasis`, `cygpath -m` para node, blobs dañados no fatales, `test-ai` dispara `startAI`), estado en `CLIENT-PROTOCOL.md`, este reporte | cierre de rama |

## Ejecución (prueba del protocolo) · evidencia

### A. Alta fresca (§1)

| Paso | Resultado |
|---|---|
| `npm run setup` | `volumes-dev/{ssb-data,ai-models,logs,ecoin-data}` creados |
| Modelo IA | copiado desde el volumen antiguo: 4 081 004 224 B, magic `GGUF`, sha256 `08a5566d…` igual en origen y destino |
| `docker compose build` | imagen `o-sdk-oasis-client` `d4ecaab2…` |
| `docker compose up -d oasis-client` | **healthy a los 10 s**; `[Version: 1.1.2]`; parches 3/3 ✓; modelo detectado y enlazado (`aiMod: on`) |
| Identidad nueva | `secret` creado por el sbot: `@N3bc4CCNVMmRVEo0MuYIvUfWoq5d4bUzB1pbFkw5yHU=.ed25519` (desechable); `oasis-first-contact` = id + `welcome=pending` |
| `/settings` | `1.1.2` |
| Volumen | `docker volume inspect o-sdk_oasis-ssb-data-dev` → `device = C:\S_LAB\o-sdk\volumes-dev\ssb-data` |
| IA (`npm run client:test-ai`) | `GET /ai` dispara `startAI()` → `:4001` escucha → `POST /ai` **HTTP 200**: `{"answer":"Hello in five words: \"Federated social hello!\""}` |
| **Evidencia del vector de fork** | a los 3 s la GUI publicó el PM de bienvenida: `log.offset` de la identidad desechable = 1 registro, `mySeq: 1`, tipo `private` (sin flag válido, ese sería el seq 1 de una identidad importada) |

### B. Importación (§2) y sincronización (§3)

| Paso | Resultado |
|---|---|
| `docker compose stop oasis-client` | parado (la identidad desechable queda en `volumes-dev/ssb-data.pre-import-20260917-152921`) |
| `import-identity.sh --dry-run` | feed `@tMJzSf…`, `tailOk`, `badFrames 0`, `mySeq 44`, sin NUL en `secret`/`gossip.json`, caps iguales |
| `import-identity.sh --with-blobs --force` (1.ª) | **rechazó los blobs**: 20/20 muestreados no cuadran con su hash (rellenos de NUL: p. ej. 39 841 B con 28 981 NUL; 60/60 en el origen). Primera versión del script abortaba (exit 5); se corrigió para **descartar los blobs dañados y seguir** (la red los re-sirve) |
| `import-identity.sh --with-blobs` (2.ª) | ✅ copiados `secret`, `flume/log.offset`, `gossip.json`, `keys/`; sha256 iguales; `oasis-first-contact` = feed + `welcome=done`; manifiesto `.import-20260917-153020.txt`; backup verificado en `devops/backups/client/20260917-153020/` |
| `sync-only.sh start` | modo `server`: `Oasis ID: @tMJzSf…` (gate OK), `[Version: 1.1.2]`, hops 2; `CONNECTED net:pub.escrivivir.co:8008` + solarnethub, 3dcomunity, hacklab en el primer segundo; seq local 44 |
| Auto-publish del sbot puro | a los 7 s `SSB_server.js` publicó **`oasisVersion` en seq 45** (guardado: solo con log no vacío) y el pub lo aceptó: `seq_pub=45` a los 16 s → **continuación sin fork** |
| `status --pub` | `seq local 45/fichero 45/sbot · seq pub 45 · pub_sigue true`; `log.offset` 1,42 MB → 2,91 MB en 30 s (hops 2) y estable desde entonces |
| `status --pub --watch` | **SYNC-OK a las 13:36 UTC**: `log.offset` 2 910 883 B estable 311 s, seq local 45 = seq pub 45, pub_sigue true, 4 pares conectados |
| `sync-only.sh stop` | estable 60 s; contenedor eliminado; frame final íntegro; seq 45 |
| `docker compose up -d oasis-client` | **healthy a los 10 s**; `Oasis ID: @tMJzSf…`; `[Version: 1.1.2]`; **0 líneas de welcome-pm** (flag `welcome=done` respetado) |

### C. Healthcheck final (§5)

| Comprobación | Resultado |
|---|---|
| `whoami` (sonda por socket unix, como `oasis`) | `me = @tMJzSf…` |
| `/settings` | `1.1.2` |
| `POST /settings/verify` → `/settings#verification` | «Your feed: **46 messages, last sequence 46** ✓ · **Forks: 0** ✓ · Files: 5 present, 159 referenced · own files missing: 4 (blobs descartados) · other inhabitants' files not downloaded yet: 150» · 2967 mensajes en el log · 97 ms |
| Continuidad del feed | seq 44 (importado) → 45 `oasisVersion` (sbot puro, 13:30:48) → 46 `karmaScore` (GUI, 13:38:18); `pub-feed-seq.sh`: `seq_pub=46`, `last=13:38:18`, `pub_follows_feed=true`, `feed_follows_pub=true` → el pub acepta cada mensaje como continuación |
| Perfil | `/author/@tMJzSf…` muestra el nombre **«Alephillo»** (los `about` venían en el log) |
| IA | probada en el alta fresca (HTTP 200); misma imagen y modelo |
| Backup final | `client/scripts/backup-keys.sh devops/backups/client` → `ssb-backup-20260917_153845/` (secret, config, gossip.json, sha256 OK) |
| Limpieza | `volumes-dev/ssb-data.pre-import-20260917-152921` (identidad desechable `@N3bc4C…`) y el backup duplicado `20260917-152921` borrados |
| Convivencia | el stack del pub local siguió parado; `volumes-dev/` = `ai-models ecoin-data logs ssb-data` (cliente) + `oasis-hub oasis-pub teatro` (pub); `git check-ignore -v pub/.env.prod` → `.gitignore:44:.env.*` |

## Hallazgos del ciclo (ya recogidos en `CLIENT-PROTOCOL.md`)

1. **Los blobs del origen estaban todos dañados** (NUL) por el incidente NVMe de julio; la verificación por hash del script lo detectó. Importar blobs sin verificar habría servido ficheros rotos con nombre correcto.
2. La sonda (`ssb-probe.js`) **debe correr como `oasis` con `HOME=/home/oasis`**: como root, `ssb_config.js` resuelve `~/.ssb = /root/.ssb`, genera claves nuevas y habla con el sbot como un desconocido (o no conecta). `pub-feed-seq.sh` había funcionado por el fallback TCP, pero como cliente anónimo.
3. En modo `full` el sbot embebido escucha 8008 solo en **tcp6**; el socket unix `noauth` funciona en el bind de Windows. Ambas rutas están en la sonda.
4. En Git Bash con `MSYS_NO_PATHCONV=1`, las rutas que se pasan a `node` (binario Windows) deben ir por `cygpath -m`.
5. El sbot puro **sí publica** (`oasisVersion`, guardado por log no vacío): la GUI no es la única que escribe. Con log vacío no publicaría; con log importado publica la continuación legítima.
6. Fresh start: el PM de bienvenida es seq 1 a los 3 s (confirmado en la identidad desechable).

## Pendientes (fuera de este WP, decisión del custodio)

- Retirar lo antiguo (`CLIENT-PROTOCOL.md` §7): `docker rm oasis-server-dev`, `docker rmi alephscript-clean-oasis-dev` (4,36 GB), `docker volume rm alephscript-clean_* blockchaincomport_*`, redes; el directorio físico como backup frío (sus `*.nul-damaged-bak` suman 5,7 GB).
- Copiar `devops/backups/client/20260917-153020/` fuera de la máquina.
- Los 4 blobs propios ausentes (`Verification`) llegarán de la red si algún par los conserva; si no, son las imágenes dañadas en julio.
