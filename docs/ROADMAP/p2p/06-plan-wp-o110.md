# 06 · El plan aprobado (verbatim)

> Aprobado por el custodio el 2026-09-19. Se reproduce tal cual quedó; la ejecución abrirá la rama
> `wp/O110-teatro-p2p`. Si al abrirla el número de WP o de decisión ya está ocupado, se toma el siguiente libre.

---

## Plan · WP-O110 · Teatro P2P: las obras salen a la red (torrent + eD2k/Kad) con cartelera

### Contexto

El pub es un hub: acoge obras, las lanza y las suelta. Hoy cada obra del Teatro se descarga solo por
HTTPS desde el VPS. Este WP añade a o-sdk la infraestructura para **sacar las obras a la escena P2P**
—BitTorrent y eD2k/Kad (aMule 3.0.1, junio 2026)— en paralelo al Teatro: mismas fichas de
procedencia (sha256, firma ed25519, origen), nuevos modos de visita, y un **ciclo de vida de
cartelera** que permite al custodio moderar el hardware: mientras una obra está en cartelera el pub
la sostiene; cuando ya vive en la red, se retira el soporte con un comando.

Método genérico (cualquier pub, cualquier obra); los datos de Aleph Cero van a la ficha de instancia.
Hay otro agente trabajando en `upgrade/oasis-1.1.4` con `pub/docker-compose.pub.yml` y `pub/.env*.example`
sucios: **este WP no toca esos ficheros** — el seeder es un stack compose independiente.

### Modelo: cartelera

Estado **por obra**, en el VPS (`/srv/oasis/teatro-seed/estado/<obra>.json`), cambiable sin rebuild:

| Estado | HTTPS del zip (= semilla web BT) | Semillas del pub (BT + eD2k) | Fichas P2P | Disco |
|---|---|---|---|---|
| `cartelera` | ✅ | ✅ | ✅ | zip + generaciones retenidas |
| `red` | ❌ retirado | ✅ (o ❌ con `--sin-semilla`) | ✅ | solo la copia de la semilla |
| `retirada` | ❌ | ❌ | ✅ (hashes y enlaces quedan: quien la tenga puede verificarla y sembrarla) | 0 |

Las páginas de la obra (leer/navegar) no cambian nunca de estado: solo se modera el zip y las semillas.

Ajustes globales de hardware (`pub/teatro-seed/.env`, por env var, D-O4): `TEATRO_SEED_UP_KBPS`
(tope de subida por demonio), `TEATRO_SEED_MEM`, `TEATRO_SEED_CPUS`, `TEATRO_SEED_BT=on|off`,
`TEATRO_SEED_ED2K=on|off`, `TEATRO_SEED_RETENER=1` (generaciones anteriores vivas), puertos, trackers
(`TEATRO_SEED_TRACKERS`, 2-3 abiertos por defecto; vacío = solo DHT/PEX).

### Piezas

#### A. Artefactos por generación (sin demonio) — se generan en el VPS tras el zip

`gen = <fecha-export>-<sha8 del zip>`. Para `<obra>.zip` y `<obra>-cerebro.zip`:

- URL inmutable `…/teatro/<obra>/gen/<gen>/<fichero>` = **enlace duro** al zip vigente (0 bytes extra).
- `<fichero>-<gen>.torrent` — `mktorrent -l 22 -w <URL inmutable> -a <trackers> -c "<obra> · gen · sha256 · origen"`.
- magnet (`xt`, `dn`, `ws`, `tr`), enlace **ed2k con AICH** (`rhash --ed2k-link`), `.meta4` (metalink: HTTPS + sha256 + torrent).
- `p2p.json` (todo lo anterior + estado + tamaños + sha256 + URLs de firma) y `latest.torrent` → redirección al vigente.
- Todo bajo `…/<obra>/p2p/`; firmado con la misma clave ed25519 (`p2p.json.sig`). Fuera de `MANIFEST.sha256` y del zip.
- Herramientas en una imagen mínima `teatro-p2p-tools` (debian-slim + mktorrent + rhash + transmission-cli), invocada con
  `docker run --rm` sobre la carpeta de la obra: **no se instala nada en el host**.

#### B. Fichas en el Teatro (sitio sin JS)

- `sidecar.py p2p-ficha --obra <obra> --meta p2p.json` → `p2p/index.html`: estado de cartelera, tabla por fichero
  (torrent · magnet · ed2k · metalink · sha256 · firma), «cómo verificar», «cómo ayudar: deja tu cliente sembrando»,
  generaciones anteriores vivas. HTML generado (los `magnet:`/`ed2k://` no pasan por Markdown).
- `build_site.py`: puerta **«P2P»** en «Recorrer el archivo», enlace en `nav()` y en el bloque `descarga`
  (que en estado `red` dice «esta obra ya vive en la red» en lugar del botón HTTPS — lo estampa el script de estado).
- `pub/site-templates/teatro/index.html`: insignia de estado y enlace «P2P» en la tarjeta de cada obra.
- `lib/guards.py` / `sidecar.py`: `.torrent`, `.meta4`, `p2p/` y `gen/` excluidos de manifiesto y zips; `PLACEHOLDER` cubre `__P2P_*__`; test nuevo.

#### C. Semillas del pub — stack independiente `pub/teatro-seed/`

`compose.seed.yml` con **nombre de proyecto propio**, sin red compartida ni dependencia del compose del pub
(ningún deploy del pub lo arrastra; no toca el Caddy):

| Servicio | Imagen | Puertos (env) | Montajes |
|---|---|---|---|
| `seed-bt` | transmission-daemon (fijada por digest) | 51413 tcp+udp | `share/:ro`, `bt/` rw, `watch/` |
| `seed-ed2k` | `ghcr.io/ngosang/amule:3.0.1-2` (por digest; no el paquete 2.3.3 de Debian) | 4662/tcp · 4672/udp · 4665/udp | `share/:ro` como carpeta compartida, `amule/` rw |

Ambos: solo-semilla (sin descargas, sin UI/RPC expuesta, EC/web a loopback), `cap_drop: ALL`, usuario no root,
`mem_limit`/`cpus`/tope de subida por env, `restart: unless-stopped`, logs rotados. aMule en **Kad-only**
(sin servidores eD2k) con auto-rescan de la carpeta compartida. `share/<obra>/<gen>/` son enlaces duros
(mismo volumen): la copia de la semilla sobrevive cuando se retira el zip de la web.

#### D. Operación — `devops/scripts/teatro-p2p.sh` (+ npm `devops:teatro:p2p`)

`status [--json]` (estado por obra, peers, subido, HighID/Kad, disco; journal `devops/logs/teatro-p2p.jsonl`,
patrón `hub-disk.sh`) · `publicar <obra>` (pieza A; lo llama `deploy-teatro.sh` con `TEATRO_P2P=1`) ·
`cartelera|red|retirar <obra> [--sin-semilla]` (mueve enlaces, estampa el letrero, actualiza `p2p.json` y lo refirma) ·
`seed up|down [bt|ed2k]` · `medir` (tráfico saliente real de la interfaz y de cada demonio, para fijar el tope con datos) ·
`podar` (aplica `TEATRO_SEED_RETENER`). Todo idempotente, con `--local` para gates sin VPS.

Cambios mínimos en lo existente: `deploy-teatro.sh` (gancho tras los zips; `--exclude /p2p/ /gen/` en el rsync para que
`TEATRO_DELETE` no los borre), `teatro-wsl.sh` (lista blanca: `TEATRO_P2P`), `backup-teatro.sh` (recuento ignora `p2p/` y `gen/`;
**respalda `p2p.json`, `.torrent`, `.meta4`**: cuando el zip se retira son el único registro), `bootstrap-` y
`verify-debian13-base.sh` (puertos de semilla opcionales por env; `teatro-seed/` en el volumen de datos), Caddyfile
(`@teatro`: MIME `application/x-bittorrent` y `application/metalink4+xml`; `validate` + `reload`).

#### E. Anuncio dentro de Oasis

El módulo Torrents de Oasis es un **catálogo** (mensaje SSB `torrent` + el `.torrent` como blob; no siembra).
Protocolo: el custodio (o un bot del pub) sube el `.torrent` en `/torrents` con la ficha de la obra y lo marca visible
en clearnet → aparece en `/c/torrents/<id>`; la ficha P2P enlaza ese id. Es un mensaje SSB: **irreversible, pide GO expreso**
y texto literal aprobado (AGENTES §3). Paso manual documentado, no automatizado.

#### F. Gobierno y docs

Rama `wp/O110-teatro-p2p` · WP-O110 en `plan/BACKLOG.md` (BRIEF en `plan/BRIEFS/`) · **D-O24** (cartelera; semilla web + demonios
opcionales; stack independiente; Kad-only; artefactos por generación inmutable; demonio p2p = puertos propios, no vhost, como D-O3;
se alinea con WP-O93: el manifiesto firmado es la raíz de confianza y nada de esto está en el camino de arranque) ·
**`docs/PUB/TEATRO-P2P-PROTOCOL.md`** (método genérico: §0 invariantes, publicar, cartelera, semillas, medir y moderar, verificar,
anunciar en Oasis, acoger la obra de un tercero, registro) · fila en `docs/AGENTES.md`, sidebar, `TEATRO-PROTOCOL.md`,
`INSTANCIA-SCRIPTORIUM.md` §5 (infohash, ed2k, gen, puertos, topes) · CHANGELOG · MAPA · reporte. Anotado como siguiente paso, fuera de
este WP: paquetes delta por generación.

### Ejecución

| # | Paso | Hecho cuando |
|---|---|---|
| 1 | Medir estado (`deploy-status.sh`, `git status`, rama del otro agente); rama + WP + D-O24 + BRIEF | sin colisión de ficheros |
| 2 | Imagen de herramientas + `teatro-p2p.sh publicar --local` sobre `volumes-dev` | torrent/magnet/ed2k/meta4/p2p.json correctos; `transmission-show` lista la semilla web |
| 3 | Ficha, puerta, catálogo, guardas, tests | `npm run teatro:test` verde; guardas verdes con `p2p/` presente |
| 4 | Stack de semillas en local (Docker Desktop, obra de prueba) | BT: un segundo cliente completa y el sha256 coincide · aMule: Kad conectado, fichero compartido, enlace = `rhash` |
| 5 | Ciclo `cartelera → red → cartelera → retirada` en local | HTTPS del zip 200/404 según estado; fichas coherentes; semilla sobrevive en `red` |
| 6 | Protocolo + docs (`docs:build` y gate verdes) | — |
| 7 | **GO** · VPS: Caddy MIME (validate+reload, 6 vhosts sanos) → deploy con `TEATRO_P2P=1` | `/p2p/` 200; `.torrent` con su MIME; descarga por semilla web desde fuera completa y verifica |
| 8 | **GO** · VPS: UFW (puertos de semilla) → `seed up` un demonio cada vez → `medir` y fijar topes | BT con peers entrantes · aMule **HighID** y Kad OK · RAM y tráfico dentro del tope · pub y HUB intactos |
| 9 | **GO** · Anuncio en Oasis (texto aprobado) | `/c/torrents/<id>` enlazado desde la ficha |
| 10 | Ficha de instancia, journal, reporte, merge `--no-ff`, push | main al día |

### Verificación

- Local: tests; guardas; `transmission-show`; descarga real con `aria2c <fichero>.meta4` (HTTPS+BT a la vez) y `sha256sum -c`.
- Producción: `teatro-p2p.sh status --json`; desde fuera del VPS, el `.torrent` del cerebro (33 MiB) completa solo con la semilla web,
  y con `seed-bt` arriba aparece un peer real; `amulecmd` en el contenedor muestra HighID, Kad conectado y 2 ficheros compartidos;
  el enlace ed2k publicado coincide con `rhash`; firma de `p2p.json` verifica con `allowed_signers`.
- Hostil-omite: obra sin firma no se publica ni se siembra · estado ausente = `retirada` · `TEATRO_DELETE=1` no borra `p2p/` ni `gen/` ·
  UI/RPC de los demonios inalcanzable desde fuera · `seed down` no afecta al pub · un deploy del pub no levanta las semillas.
