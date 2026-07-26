# ESTACIÓN · calibración del carril O

Instancia del consumidor. El método vive en
`@alephscript/skills-scriptorium@0.11.0` (skills `vigilancia` +
`estacion-viva`). Esta calibración **no** va en el skill.

## Params

| param | valor |
| ----- | ----- |
| `WORLD_ROOT` / `CANONICAL_WORLD_ROOT` | `C:/S_LAB/o-sdk` |
| `READ_ONLY_ROOTS` | `["C:/S_LAB/.worktrees"]` |
| `DOWNSTREAM_PATTERNS` | `[".worktrees/*"]` |
| `OUT_DIR` | `C:/S_LAB/vigilancia/o` |
| `INTERVAL` | `45` |
| `SIBLING_ROOT` | *(no calibrado — un solo root O)* |
| `RAMA(O)` en CUADERNOS | `o_sdk-vigilancia` · worktree `C:\S\_fuentes\cuadernos-vigia-O` |
| Identidad de commits | `vigia-O <alephscriptorium@gmail.com>` |

Origen de los valores (no inventados): `READ_ONLY_ROOTS` = base de
worktrees del taller (`C:/S_LAB/.worktrees`, existe; precedente Z/V).
`DOWNSTREAM_PATTERNS` = `.worktrees/*`. Listas vacías `[]` serían
calibración explícita «sin raíces»; aquí hay raíz real → array no vacío.

## Preflight (fail-closed, antes de cualquier efecto)

```bash
WORLD_ROOT=C:/S_LAB/o-sdk CANONICAL_WORLD_ROOT=C:/S_LAB/o-sdk \
READ_ONLY_ROOTS='["C:/S_LAB/.worktrees"]' \
DOWNSTREAM_PATTERNS='[".worktrees/*"]' \
node .claude/skills/vigilancia/scripts/verificar-identidad-raiz.mjs
```

Resultado vigente: **`identidad-raiz: PASS`** (git toplevel = WORLD_ROOT).
Identidad de commits: `verificar-identidad.mjs` del swarm — sin
placeholders (ver §Residuos, caso R-3).

## Estaciones (dos procesos, dos logs)

```bash
# 1 · vigilancia (método) → watch.log + anomalias.log
WORLD_ROOT=C:/S_LAB/o-sdk CANONICAL_WORLD_ROOT=C:/S_LAB/o-sdk \
READ_ONLY_ROOTS='["C:/S_LAB/.worktrees"]' \
DOWNSTREAM_PATTERNS='[".worktrees/*"]' \
OUT_DIR=C:/S_LAB/vigilancia/o INTERVAL=45 \
  bash .claude/skills/vigilancia/scripts/watcher.sh

# 2 · timbre v0.1 (PROTOCOLO §7) → timbre-watch.log
#     log propio: el watch.log ya tiene dueño (regla «patrón V»)
```

Liveness = **lease del último tick** (`edad < 2×INTERVAL`), no PID.

## Residuos conocidos — señal vs ruido

Registrados para que un relevo **no** los herede como estado normal
(`ESTACION.md` del skill §Sucesión v2.3: las anomalías se heredan
*marcadas como anomalía*).

| id | qué | veredicto |
| -- | --- | --------- |
| **R-1** | `!!RESIDUO markdown de info en carpeta de IDE (regla 15)` sobre `.claude/skills/**` y `.cursor/skills/**` | **falso positivo estructural.** 11.842 líneas en la primera hora, **100 %** de las anomalías. La regla 15 apunta a *notas de sesión efímeras*; esto es el **espejo materializado del propio método** (`skills:sync` desde `node_modules`, gitignorado, fuente de verdad = el paquete versionado). El vigía marca como residuo la documentación del skill que lo gobierna. Elevado a la mesa: afecta a **todo carril** que haya corrido `skills:sync`. |
| **R-2** | `wt_reg=1 wt_dir=0` | benigno: hay 1 worktree registrado y ninguna carpeta en `.worktrees/` de este mundo. Sin huérfanos. |
| **R-3** | 4 commits locales de `sincronia/` firmados `Your Name <you@example.com>` | corregido **hacia adelante** (identidad fijada a `vigia-O`); los 4 previos son locales y nunca se pushean — el snapshot que sube a CUADERNOS son ficheros, no esa historia. Mismo caso que el `ACTA-BLOQUEO-git-identity` del carril Z. |

### Pulso útil mientras R-1 siga abierto

Señal real = anomalías que **no** vengan del espejo de skills:

```bash
grep -v '/skills/' C:/S_LAB/vigilancia/o/anomalias.log | tail -20
```

Si esa salida está vacía, la estación está limpia aunque
`anomalias.log` tenga miles de líneas.

## Rotación

Logs archivados en `C:/S_LAB/vigilancia/o/archivo/<fecha-hora>/` cuando
el ruido impide leer el pulso. La rotación **no** borra evidencia: mueve.

— **O**
