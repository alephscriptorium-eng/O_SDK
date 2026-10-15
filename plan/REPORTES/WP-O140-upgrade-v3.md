# WP-O140 · Protocolo de upgrade v3: tiempos y comprobaciones

Rama `wp/O140-upgrade-v3` desde `main` 02061394 (merge de WP-O139). 2026-10-15. Toca `devops/scripts/upgrade-*`,
`upgrade-invariants.d/`, `deploy-status.sh`, `pub/docker-compose.pub.yml` (healthchecks), `docs/PUB/UPGRADE-PROTOCOL.md`,
`HUB-PROTOCOL.md` §0 y una trampa de `AGENTES.md` §4. **No toca** el host ni `src/`. Su prueba completa es WP-O141.

## 1. Estado de partida (medido)

Auditoría de solo lectura del protocolo (48 commits, parcheado en cada ciclo desde 0.8.3) y de sus cinco scripts:

- **≈22 min de espera ciega** en el camino feliz: `up` dormía 90 s fijos por nodo (×3, y U7 los repite), `worst` 30 s,
  el humo de la imagen 2×45 s, los healthchecks del HUB y del bot con `interval: 60s` sin `start_interval` (healthy no
  antes de ~60 s aunque el nodo llevara segundos listo), y la regla «`check` al menos 5 minutos después» contada a mano
  (en WP-O138 se hizo a los 3 minutos por error).
- El `--expect` «normal» de §3.4 (:348) no llevaba `karmaScore` ni `about`: copiado tal cual daba una desviación falsa.
- `--check` recalculaba el diff entero (>5 min en Windows, WP-O138 §7) para comprobar las disposiciones de un reporte.
- `--help` truncado en los tres scripts (`sed -n '2,41p'` con cabeceras que llegaban más abajo).
- Anécdotas de ciclos en medio del procedimiento (:139, :222, :333, :335, :379, :503, :576); §7 sin la fila 1.2.3→1.2.5 y desordenada.
- `deploy-status.sh:116` y `upgrade-preflight.sh:168` citaban «A5.1/A5.2», que no existen; el compose citaba `entrypoint:521-524` (hoy 859-862).
- Invariantes: sin `pub.tsv` ni `client.tsv`; dos filas duplicadas entre `hub.tsv` y `ecoin.tsv`; el snapshot dentro de `db2.tsv`.

## 2. Entregado (commit por pieza)

| Commit | Pieza |
|---|---|
| c2d99be1 | `fix(preflight)`: `--help` entero; «corre en la máquina operadora»; sin `(A5.2)` |
| 54012759 | `feat(compose)`: `start_interval: 3s` en pub, HUB y bot (no en el retro); `deploy-status.sh` imprime el Docker Engine del host (≥ 25 exigido) y pierde «A5.1»; cita del entrypoint corregida |
| 58d8b344 | `feat(gates)`: `check --wait [--max] [--every] [--stable]`, `check --min-age`, `smoke <imagen>`, `expect.conf` como delta por defecto, `up` sin settle (`GATE_SETTLE` opt-in), `worst` sin `sleep`, un `docker logs` por nodo, `--help` entero, retro a una línea |
| 5c264db3 | `feat(behaviour-diff)`: `--from-tsv`, `--skip`, un solo `git diff -U0` compartido, `--help` entero |
| 330611b0 | `feat(invariants)`: `pub.tsv` (14), `client.tsv` (9), `snapshot.tsv` (4, desde `db2.tsv`); `ecoin.tsv` sin los dos duplicados |
| fbb1a982 | `docs(upgrade)`: protocolo v3 (cuerpo en presente; §7 única historia, ordenada y completa; gates con subcomando; tabla «delta vigente»; tabla de variables; `smoke` en U2 y paso 6; `--min-age` en vez de la cuenta de 5 min; frase canónica D-O37); historia de la receta v0 del HUB → `HUB-PROTOCOL.md` §0; `AGENTES.md` §4 trampa del `secret` → `smoke` |

Semántica conservadora de `check`, intacta: NO MEDIBLE nunca pasa a verde; con `--wait`, una desviación firme (tipo
no esperado, `+N` por encima del rango, feed o dirección cambiados, errores en el log) corta en la primera vuelta,
«todavía no» (falta un tipo declarado, por debajo del mínimo, no healthy) se reintenta, y al agotar `--max` sin
alcanzar el delta el resultado es DESVIACIÓN, no verde.

## 3. Gates (comando + salida)

Ensayo local, imagen `oasis-pub-scriptorium:latest` = 1.2.8 sobre `volumes-dev/` (identidades desechables), 13:18-13:21 UTC.
Misma versión antes y después: el delta esperado no lleva `oasisVersion`.

```
$ compose up -d --no-deps oasis-pub oasis-hub oasis-wallet-bot          # recrea por el start_interval nuevo
oasis-pub-scriptorium healthy a los 4 s · oasis-pub-hub 0 s · oasis-pub-wallet-bot 0 s (ya estaban al medir)
$ $G snapshot t0 → pub seq=15 · hub seq=14 · bot seq=29; los tres «cuadra · sbot=»; rc=0
$ $G up pub; $G up hub; $G up bot → «healthy a los 4 s» cada uno; total 25 s      (antes: 3×(healthy + 90 s) ≈ 5-7 min)
$ $G check t0 --wait --max 420 --expect 'pub:=0 hub:karmaScore=+0..1 bot:karmaScore=+0..1,about=+0..1,pubAvailability=+0..1'
  …   12 s: pub=15 hub=14 bot=30 rc=0 estable=0 s
  …   43 s: pub=15 hub=14 bot=30 rc=0 estable=31 s
  pub  v1.2.8 · Δseq=0 · sin publicaciones → ok
  hub  v1.2.8 · Δseq=0 · sin publicaciones → ok
  bot  v1.2.8 · Δseq=1 · pubAvailability+1 → ok
GATE OK (delta esperado y sequence estable 60 s; 75 s en total)                     rc=0
$ $G check t0                                   → esperado: pub:oasisVersion=+1 … (expect.conf) · GATE: DESVIACIÓN (falta oasisVersion: misma versión)  rc=1
$ $G check t0 --min-age 3600 --expect '…'       → PREMATURO: bot 107 s, hub 113 s, pub 118 s (< 3600) · GATE: NO MEDIBLE  rc=3
$ $G smoke oasis-pub-scriptorium:latest         → 11 ok (1.2.8; node --check ×3; enlace a src/base; 0 secret; nada del fork en /app;
                                                  server socket a los 2 s; backend GET /c 200 a los 2 s; 3 parches ×2; 0 errores ×2) · SMOKE OK · 16 s
$ $G smoke alpine:3.20                          → FALLA la imagen no existe aquí · SMOKE: DESVIACIÓN  rc=1
$ docker ps -a (efímeros sobrantes)             → 0
$ upgrade-gates.sh --help | tail -3             → cabecera completa (códigos de salida, GATE_NODES, retro)
$ compose config | grep -c start_interval       → 3
$ time upgrade-behaviour-diff.sh --from-tsv <tsv 560580d7→28fc1a68> --check plan/REPORTES/WP-O138-upgrade-oasis-1.2.8.md
                                                → «todas las líneas tienen disposición … seis cabeceras» · rc 0 · real 2,36 s   (antes: minutos)
$ diff <tsv con el script de HEAD> <tsv con el nuevo>   → vacío (147 líneas, 73 piden disposición: IDs idénticos)
$ upgrade-behaviour-diff.sh --section annex 28fc1a68 28fc1a68 → 74 invariantes, 0 ROTO (client 9 · db2 9 · ecoin 11 · hub 20 · phone 7 · pub 14 · snapshot 4)
$ awk -F'\t' … *.tsv | sort | uniq -d           → vacío
$ npm run docs:build && npm run docs:gate       → build complete · verificar-sitio OK · piel OK · contraste OK · CEGUERA OK (trinquete 52 = base 52)
$ bash -n sobre los cuatro .sh                  → ok   (shellcheck no está instalado en esta máquina: pendiente)
```

Primer `smoke` dio una FALLA falsa (`/app/src/client`, código de upstream): la búsqueda de carpetas del fork se acotó
a la raíz de `/app`; repetido → `SMOKE OK`. El stack local quedó parado al terminar, como estaba.

## 4. Delta de tiempo (camino feliz local)

| Tramo | Antes | Ahora (medido) |
|---|---|---|
| U3: healthy + settle de 3 nodos | ≈ 150 s de latencia de healthcheck + 270 s de settle | 25 s de `up` + 75 s de `check --wait` |
| U5: `worst` + `sleep 30` | 30 s fijos | 0 (el `check --wait` mide) |
| U2 / paso 6: humo | 2×45 s fijos + receta a mano | 16 s, un subcomando |
| U1: `--check` del reporte | > 5 min (Windows) | 2,4 s |
| U7 (repite U3) | ≈ 7 min | ≈ 100 s |
| Host: regla de 5 min | a mano (falló una vez) | `--min-age 300` lo impone el script |

## 5. Correcciones al protocolo

Todas en este WP (es su objeto). Tropiezo propio: el humo marcaba `/app/src/client` como fuga del fork; el protocolo
dice ahora «en la raíz de `/app` (`src/client` es de upstream y no cuenta)». VitePress no admite `{{.Server.Version}}`
en código inline dentro de tablas: el comando exacto vive en el bloque bash de §3.4.

## 6. Seguimiento

- WP-O141 (1.2.8 → 1.3.0) ejercita el protocolo v3 entero, incluido `--remote smoke`, `check --wait --min-age 300` y
  el `start_interval` en el host (precondición: Engine ≥ 25, se lee en `deploy-status.sh`).
- `shellcheck` sobre los cuatro scripts en una máquina que lo tenga.
- `hub-wallet.sh` conserva su propio bucle de healthy y un `sleep 25` (fuera de alcance; anotar si molesta en O141).
