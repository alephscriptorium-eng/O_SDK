# WP-O148 · Memoria del host: swap en el disco raíz, `memswap_limit` en los nodos, medida y docs

Rama `wp/O148-swap-memoria` desde `main` 3ca91107 (merge de WP-O147). 2026-10-25. Sin cambio de versión de Oasis
(1.3.8 tras O147). Sin rebuild y sin recrear ningún nodo: **Δ0**. Encargo del custodio: reducir la máquina
(2 CPU / 4 GB) sin que un pico mate un nodo; el redimensionado en sí lo hace él en el panel de Gandi (fuera de este WP).
Preparado en paralelo con WP-O147 (upgrade 1.3.8) en carpeta aparte; host solo tras su cierre (PRÁCTICAS §6).

## 1. Estado de partida

**Host** (2026-10-25 ≈ 17:23Z, por SSH, solo lectura; `free -m`, `uptime`, `docker stats --no-stream`, `ps`,
`journalctl -k`, `lsblk`, `findmnt`, `/proc/diskstats`, `docker inspect`):

| Medida | Valor |
|---|---|
| CPUs · carga 1/5/15 min | 2 · 0.07 / 0.20 / 0.23 (uptime 75 d) |
| RAM total / usada / disponible | 3905 / 2272 / 1633 MiB · buff/cache 1752 |
| Swap | **ninguna** (`/proc/swaps` vacío; `swapon` no instalado) |
| Suma de los 9 contenedores (`docker stats`) | 1591 MiB |
| `oasis-pub-hub` · `oasis-pub-wallet-bot` (límite 768m) | 470 · 362 MiB |
| `oasis-pub-scriptorium` (1 GiB) · `oasis-pub-ecoin` (512m) · `hub-cache` (128m) | 116 · 78 · 99 MiB (77 %) |
| Fuera del pub, mismo host | `dockerd` 361 MiB RSS · node-red 175 · verdaccio («Aleph Scriptorium Registry») 98 · journald 135 |
| OOM-kill en el journal del kernel | 2, ambos `CONSTRAINT_MEMCG`: 2026-10-05 20:35Z nginx (hub-cache, 128m) · 2026-10-22 11:51Z node `anon-rss:769652kB` (un backend al techo de 768m) |
| `HostConfig.Memory` / `MemorySwap` | pub 1 GiB / 2 GiB · hub 768m / 1536m · bot 768m / 1536m · hub-cache 128m / 256m · ecoin 512m / 1 GiB (los 4 sin límite: 0 / 0) |
| Discos | `xvda` 25 G ext4 `/` (14 G libres, `discard`) · `xvdb` 40 G ext4 `/srv/oasis` (20 G libres, `stripe=8`); ambos `mq-deadline`, no rotacionales; Xen |
| Latencia media acumulada (`/proc/diskstats`, 75 d) | `xvda` 0,49 ms/lectura · 0,92 ms/escritura · `xvdb` **12,2** ms/lectura · 7,3 ms/escritura |
| `vm.swappiness` | 60 (defecto de Debian; medido con el verificador nuevo, G2) |

Conclusiones que fijan el WP: la máquina no cabe en 2 GB (2272 usados sin swap); el swap va en el disco raíz (20× menos latencia
que el volumen de datos; 14 G libres bastan para 2 G de swap y los ~3 G de un rebuild); los límites de los nodos conceden hoy el
doble en swap (defecto de Docker), así que con swap y sin `memswap_limit` el presupuesto de ECOIN §7 dejaría de valer.

**Repo**: ni `swap`, ni `memswap_limit`, ni `swappiness` en ningún fichero; `capacity.sh` no mide RAM ni swap del host ni
`MemorySwap` por nodo, y no mide `oasis-pub-ecoin` ni `hub-cache`; `devops/logs/capacity.jsonl` anunciado en la cabecera del
script y nunca escrito; «el pub sigue sin `mem_limit`» en HUB §7, ECOIN §7 y la fila WP-O47 del backlog, falso desde WP-O121
(`pub/docker-compose.pub.yml` l.14); `OASIS_PUB_MEM_LIMIT` sin fila en ningún `.env*.example`; `hub-cache` con `128m` fijo.

## 2. Qué se entregó (rama)

| Commit | Pieza |
|---|---|
| 689814de | `feat(devops)`: `bootstrap-debian13-base.sh` `ensure_swap` + `ensure_sysctl`, flags `--swap-gb N` (2) y `--only-swap`; idempotente; `/etc/fstab` con backup |
| 4ad3b797 | `feat(devops)`: `verify-debian13-base.sh` `check_swap` (swap activa ≥ tamaño, `/swapfile` 600, línea en fstab, `swappiness` 10) |
| 5969042a | `feat(devops)`: `capacity.sh` filas host RAM disponible / swap / `swappiness` (`CAP_RAM_MB`, `CAP_SWAP_PCT`), AVISO `memswap ≠ mem` por nodo, `CAP_MEM_NODES` (+ ecoin, hub-cache), `--json` → `devops/logs/capacity.jsonl` |
| 2a3ff93b | `feat(pub)`: compose `memswap_limit = mem_limit` ×6, `OASIS_HUB_CACHE_MEM_LIMIT`; `OASIS_PUB_MEM_LIMIT` y `OASIS_HUB_CACHE_MEM_LIMIT` en los tres `.env*.example` |
| 457e4d9d | `docs`: CAPACIDAD §2/§4, HUB §7, ECOIN §7, fichas de instancia, `devops/README` §4-5, `roles/pub`, AGENTES §3/§4 |
| (este) | `plan`: fila WP-O148, D-O41, CHANGELOG, este reporte |

## 3. Disposiciones

| Qué | Dónde | Valor | Por qué |
|---|---|---|---|
| Swapfile | `/swapfile` en `/` (xvda) | 2 GiB, `600`, `fallocate` + `mkswap` + `swapon`, línea `/swapfile none swap sw 0 0` en fstab | red de seguridad para picos (reindexado, dos nodos a la vez); el disco raíz es el rápido (§1) |
| `vm.swappiness` | `/etc/sysctl.d/90-oasis-swap.conf` | 10 | que el kernel no pasee heaps de node a swap en reposo; solo bajo presión |
| `memswap_limit` | compose, 6 servicios | = `mem_limit` | sin él Docker concede el doble en swap y el límite no limita |
| En vivo | `docker update --memory <m> --memory-swap <m>` en pub, hub, hub-cache, ecoin, wallet-bot | mismo valor que ya tienen en `Memory` | no recrea ni reinicia nada: Δ0. Precedente: ECOIN §7 (HUB 1536m → 768m) |
| Compose y `.env.prod` del host | in place, sin `up` | sha del vivo = blob del repo antes de pisar; `.bak-o148-<fecha>` | vale para el próximo recreate; recrear ahora solo por esto sería un reinicio sin motivo (AGENTES §2.4) |

## 4. Qué viaja al host

- `/swapfile`, `/etc/fstab` (+1 línea), `/etc/sysctl.d/90-oasis-swap.conf`: nuevos.
- `docker update` en 5 contenedores: solo `MemorySwap` cambia (de 2× a 1×).
- `<carpeta del compose>/docker-compose.pub.yml` y `.env.prod`: in place, para el siguiente recreate.
- Nada más: ni imagen, ni entrypoint, ni configs de los nodos, ni Caddy.

## 5. Gates

Locales (antes del host): G0 `bash -n` + shellcheck de los tres scripts y `docker compose -f pub/docker-compose.pub.yml config`
acepta `memswap_limit` · G1 `capacity.sh --local` muestra las filas nuevas y `--json` deja línea en `capacity.jsonl` ·
G2 `verify-debian13-base.sh` en local falla limpio solo en `check_swap` · G3 `npm run docs:verificar` (build + gate del sitio).

Resultado (2026-10-25, antes de tocar el host): **G0** ok (`bash -n` ×3; `docker compose config` muestra `memswap_limit` = `mem_limit`
en los 6 servicios; sin shellcheck en la máquina operadora). **G1** medido contra el **host**, solo lectura: los 7 AVISO esperados
(memswap ×5 con el doble del límite, «SIN SWAP», swappiness 60), 0 sin medir, exit 1; `--json` deja la primera línea de
`devops/logs/capacity.jsonl` (ignorado por git). **G2** en el host, solo lectura (`bash -s < verify-debian13-base.sh`): `check_swap`
da los 3 FAIL + 1 WARN esperados (sin swap, sin fstab, swappiness 60, sin sysctl.d); el resto de la base igual que antes (38 pass).
**G3** `npm run docs:verificar` en verde (build, sitio, piel, contraste, ceguera OK).

Host (tras el cierre de WP-O147, con GO, un paso cada vez, parada dura):

| Paso | Qué | Salida esperada | Hecho |
|---|---|---|---|
| 0 | `deploy-status.sh` · `capacity.sh` (foto pre) · `df -h /` · `cat /proc/sys/vm/swappiness` | VERDE; ≥ 5 G libres en `/` | 18:34Z: VERDE; 3 nodos 1.3.8 healthy; deriva compose = blob de main (precondición del paso 3 ok); 14 G libres; swappiness 60; `StartedAt` ×9 anotados. **Hallazgo**: HUB al 82 % de 768m (§9) |
| 1 | `cp /etc/fstab /etc/fstab.bak-o148-<fecha>` · `bootstrap-debian13-base.sh --only-swap --swap-gb 2` | `swapon --show`: `/swapfile 2G`; fstab +1 línea; `swappiness` 10 | 18:35Z: `/swapfile` 2047 MiB activo, 600; fstab +1 (`fstab.bak.20261025183553`); `swappiness` 10 vivo y en `sysctl.d`; `/` al 52 % |
| 2 | `docker update --memory <m> --memory-swap <m>` ×5 | `docker inspect`: `Memory = MemorySwap` en los cinco; `docker ps`: mismos `StartedAt` | 18:36Z: `Memory = MemorySwap` en los cinco (1 GiB, 768m, 128m, 512m, 768m); `StartedAt` sin cambios |
| 3 | compose y `.env.prod` in place (sha vivo = blob repo → `.bak` → `cat >`) | `sha1sum` del vivo = blob de HEAD; `docker compose config` en el host sin error | 18:37Z: vivo = `68f84184…` (blob de main) → `.bak-o148-2026-10-25` → escrito = `3b24e2aa…` (blob de HEAD); `.env.prod` +2 variables (backup 600); `compose config` en el host: memswap = mem ×5 |
| 4 | `verify-debian13-base.sh` · `capacity.sh` (post) · `deploy-status.sh` · `deploy-log.sh` | `check_swap` pass; sin AVISO nuevo; VERDE; journal +1 | 18:40Z: `check_swap` 5 PASS (43 pass, 1 warn preexistente, 0 fail); `capacity`: 1 aviso (el HUB al 82 %), swap usada 0 %, `capacity.jsonl` +1; `deploy-status`: compose «igual que HEAD», enlaces `connected` ×2; `StartedAt` ×9 idénticos a la foto pre → **Δ0** |
| 5 | a las 24 h: `capacity.sh` | swap usada en reposo ≈ 0; `capacity.jsonl` +1 | «pendiente: 2026-10-26» |

## 6. Delta de publicación

Ninguno, medido: `StartedAt` de los 9 contenedores idéntico antes y después (ningún nodo recreado ni reiniciado). Sin línea en
`deploy-history.jsonl`: no hubo deploy (ni imagen ni `up`); el journal de este WP es `capacity.jsonl` (líneas pre y post).

## 7. Correcciones al protocolo

- AGENTES §3: fila nueva «cambiar la memoria del host o de un nodo en vivo» (GO; `docker update` + compose, nunca `up` por esto).
- AGENTES §4: trampa `mem_limit` sin `memswap_limit`; matiz a «nada se instala en el host» (el swap es de la máquina).
- HUB §7 y ECOIN §7: el pub tiene `mem_limit` desde WP-O121; regla `memswap = mem`; swap como red de seguridad.
- CAPACIDAD §2: filas «Memoria del host» y «Swap» en «Del host»; fila Memoria por nodo con `memswap_limit`; §4 reindexado.

## 8. Decisiones

- D-O41 (este WP): swap y `sysctl` de memoria en la base del host; `memswap_limit = mem_limit`; cambios de límites en vivo por
  `docker update`, no por `up`. Tamaño de la máquina: del custodio, en el panel del proveedor (recomendado 3 GB / 1 CPU).

## 9. Seguimiento

- **HUB al 82 % de 768m** en la foto pre y post (recreado hoy en O147; el mismo contenedor que el OOM mató el 22-oct). HUB §7 pide
  1,5 × pico ≈ 1024m. **Hecho con GO** (18:45Z): `docker update --memory 1024m --memory-swap 1024m oasis-pub-hub` (sin reinicio:
  `StartedAt` igual; 645 MiB / 1 GiB = 63 %) y en `.env.prod` (backup `.bak-o148b-2026-10-25`, 600) `OASIS_HUB_MEM_LIMIT=1024m` y
  `OASIS_HUB_NODE_OPTIONS=--max-old-space-size=716` para el siguiente recreate (el heap vivo sigue en 512 hasta entonces). ECOIN §7 al día.
- Swap usada a las 24 h y tras el redimensionado (foto del custodio): si en reposo pasa de `CAP_SWAP_PCT`, bajar un límite
  siguiendo HUB §7, no subir el swap.
- node-red y verdaccio (≈ 270 MiB) viven en el mismo host y no son de este repo (`scriptorium-vps`): decisión del custodio
  si la máquina baja de 3 GB.
- `hub-cache` tocó su techo de 128m el 05-oct (nginx OOM): medir su pico a las 24 h y, si repite, `OASIS_HUB_CACHE_MEM_LIMIT=192m`
  (ya es variable) en el próximo recreate.
- `dockerd` con 361 MiB de RSS: se recupera en el próximo reinicio del host (el redimensionado lo trae); no se reinicia Docker
  solo por esto.
- `capacity.jsonl`: primera línea real; `deploy-status.sh` ya lo resume.
