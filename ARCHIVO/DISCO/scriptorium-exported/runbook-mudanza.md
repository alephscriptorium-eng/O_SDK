# Runbook · mudanza del bot nº 3 (`retro.escrivivir.co`) del VPS a la máquina operadora (WP-O135, D-O33)

**Ejecutado el 2026-10-10** con PERMISO 1-4 del custodio, uno a uno. Método genérico: `docs/PUB/HUB-PROTOCOL.md`
§11 («mudanza o baja de un bot»). Contexto: ciclo 1.2.3 → 1.2.5 a medio aplicar (pub, HUB y bot de cartera ya en
1.2.5); en lugar del GO-5 (subir el retro en el host) el custodio decide mudarlo: el gobierno de las tribus de
Campamento es su identidad (Oasis no traspasa autoría) y el retro «es nuestro drill de pruebas». Nada se publica
salvo el `oasisVersion` del arranque en 1.2.5, que el retro habría publicado igual con el GO-5.

Identidad: `@fJG3E7UKNlYVh0Aoc89LKPAAQsKNfy4iMaJtdVH0I8I=.ed25519`. Pub real: `@/snvahvaTP5obvdiYva9OX9NNnTSlUQbEUBSuDRzrZA=.ed25519`.

| # | Paso | Comando | Salida |
|---|---|---|---|
| A1 | Repo: gates y medición saben que el retro es un nodo real aparte | `.gitignore` `volumes-real/` · `upgrade-gates.sh` (`GATE_NODES` sin retro, `compose_local` sin `--profile retro`, `dirs` sin retro) · `lib-node.sh` lee `OASIS_RETRO_BOT_SSB_DATA_DIR` de `.env.local` · `capacity.sh` · `host.env` | `git check-ignore -v volumes-real/x` → `.gitignore:volumes-real/` |
| A2 | Imagen local | `docker run --rm --entrypoint sh oasis-pub-scriptorium:latest -c 'grep version …'` | `1.2.5` (`5cfdf8ddca7f`) |
| A3 | Retro desechable local fuera | `compose … --profile retro rm -sf oasis-retro-bot` · `mv volumes-dev/oasis-retro-bot volumes-dev/oasis-retro-bot.desechable-Oz7l6q-20261010T030533Z` | `Removed`; apartado, no borrado |
| A4 | `.env.local` → `volumes-real/` (con `.bak-mudanza-…`) | tres rutas `OASIS_RETRO_BOT_{SSB_DATA,LOGS,ASSETS}_DIR=../volumes-real/oasis-retro-bot/…` · `mkdir -p volumes-real/oasis-retro-bot` · `compose --profile retro config \| grep -c volumes-real.oasis-retro-bot` | `3`; `git status` sin `volumes-real` |
| B1 | Medir el host (03:06Z) | `$R snapshot pre-mudanza` (4 nodos) · `GATE_NODES="$N3" $R snapshot pre-mudanza3` (base de 3) · `pub-feed-seq.sh "$RETRO"` | retro `seq=150 registros=150 → cuadra · sbot=150`, `oasisVersion=1`; pub `seq_pub=150 pub_follows_feed=true feed_follows_pub=true` |
| B2 | **PERMISO 1** · parar en el VPS (03:19:34Z) | `$HC --profile retro stop oasis-retro-bot` | `Stopped`, `exited 143`; pub, HUB y bot `Up … (healthy)` |
| C1 | Copia de `ssb-data` | `backup-oasis-pub.sh --remote-data-root /srv/oasis/oasis-retro-bot --backup-root devops/backups/oasis-retro-bot --remote-config-file …/config/retro-bot/ssb-config` | `devops/backups/oasis-retro-bot/20261010T031959Z/ssb-data-….tar.gz` (3,7 MB). **Tropiezo**: sin `--remote-ssb-dir` el script rellenó `identity/` con los ficheros públicos del pub (no del retro): el tar sí es el del retro (`LEEME-retro.txt`) |
| C2 | Copia de `assets` + `logs` y hashes del host | `ssh … "sudo tar -C /srv/oasis/oasis-retro-bot -czf - assets logs"` · `sudo find . -type f ! -name socket -exec sha256sum {} +` → `SHA256SUMS.host.txt` | 791 KB; 173 ficheros (128 en `ssb-data`, 44 en `assets`) |
| C3 | Extraer y verificar | `tar -xzf … -C volumes-real/oasis-retro-bot/` ×2 · `sha256sum -c SHA256SUMS.host.txt` · `grep '"id"' secret` · `ls oasis/keys` | **173/173 iguales** (exit 0); `"id": "@fJG3…"`; `calendars-keys.json maps-keys.json plantilla-campamento.json tribes-keys.json`; 43 blobs; 43 assets; `conn.json` con `pub.escrivivir.co` |
| C4 | Log en frío, sin sbot | `docker run --rm -i --entrypoint sh -e SSB_FEED=… -v <ssb-data>:/home/oasis/.ssb:ro oasis-pub-scriptorium:latest -lc 'cd /app/src/server && node -' < pub/tools/log-bipf.js` | **`S 150` · `T 6292` · `D 0` · `A 95`**; tipos propios idénticos a `pre-mudanza.remote.snap` |
| — | Precondición | VPS `exited`; local 0 contenedores | ✓ |
| D1 | **PERMISO 2** · arranque local (03:23:39Z) | `npm run pub:local:retro-bot:up` | `healthy` a los 10 s; montajes en `volumes-real`; log sin errores; parches en orden; `Version: 1.2.5` |
| D2 | Medir el arranque | base sintética `retro-vps.local.snap` (líneas `retro` de la foto remota) · `GATE_NODES="$NR" $G check retro-vps --expect 'retro:oasisVersion=+1'` | `seq=151 … cuadra · sbot=151` · **`Δseq=1 · oasisVersion+1 → ok · GATE OK`** |
| D3 | Pub real en la libreta (0 publicaciones) | `hub-conn-fix.js 'net:pub.escrivivir.co:8008~shs:<clave>'` dentro del retro | `remember ok · connect ok · peer … connected pub @/snvahva…` (+ 3 pubs de terceros de su `gossip.json`) |
| D4 | El pub acepta la continuación | `pub-feed-seq.sh "$RETRO"` | **`seq_pub=151 pub_follows_feed=true`**: seq 151 sobre su 150, sin bifurcación |
| D5 | Reinicio = silencio | `docker restart oasis-pub-retro-bot` · 70 s · `check retro-vps` · `conn.json` · `ssb-probe.js peers` | sigue `Δseq=1`; la entrada persiste; `connected` a `@/snvahva` y a 3 pubs |
| E1 | **PERMISO 3** · retirar el contenedor (03:31:45Z) | `$HC --profile retro rm -sf oasis-retro-bot` | `Removed`; `StartedAt` de pub/HUB/bot sin cambios |
| E2 | `.env.prod` in place (`.env.prod.bak-mudanza-<ts>`) | `awk` que comenta `^OASIS_RETRO_BOT_` (6 líneas) → `cat >` | `activas RETRO: 0 · comentadas: 6`, inodo y 600 conservados; `compose config -q` ok |
| E3 | Los que se quedan | `GATE_NODES="$N3" $R check pre-mudanza3` · `pub-feed-seq.sh` · `deploy-status.sh` | **pub, HUB, bot `Δseq=0` → `GATE OK`**; `seq_pub=151`; tres nodos 1.2.5, imagen al día, deriva solo `.dockerignore` |
| E4 | **PERMISO 4** · datos del host (03:37Z) | `sudo tar -C /srv/oasis -czf /srv/oasis/oasis-retro-bot.mudado-20261010T033700Z.tgz oasis-retro-bot` · sha256 · descarga a `devops/backups/srv-oasis/20261010T033700Z/` · `sudo rm -rf /srv/oasis/oasis-retro-bot` | sha256 `29cdda3c…` igual en host y local (4 512 240 B); en `/srv/oasis` quedan `oasis-retro-bot.bak-o135-2026-10-10.tgz` y `.mudado-…tgz` hasta el PERMISO 5 |
| E5 | Journal y cierre del ciclo | `deploy-log.sh … --version 1.2.5 --mode server+hub+wallet-engine-on+pub-snapshot-6h+phone-relay` · `$R snapshot post125` · `check pre125-3` (base sin retro) · `capacity.sh` | registro sin `+retro`; post125 pub 24 · HUB 17 · bot 71; **`oasisVersion+1` por nodo y nada más → `GATE OK`**; `capacity` 2 avisos (ver WP-O135 §9: el script leía la config del sitio viejo) |

Lo que no se hizo, a propósito: unfollow del pub, `about` de despedida, tocar `pub/config/retro-bot/ssb-config`
del host (sigue, trackeado e inerte). Pendiente: PERMISO 5 (borrar los dos tgz del host cuando la cripta tenga la
copia) y el aviso al custodio para la cripta USB (WP-O135 §8).
