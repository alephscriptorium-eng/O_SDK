# PRÁCTICAS · cómo se trabaja en el carril O

Método de trabajo del repo. Lo que se opera en un host está en `docs/AGENTES.md`; aquí está **cómo se
produce un cambio** desde la intención hasta `main`. Decisiones: `DECISIONES.md`. Cola: `BACKLOG.md`.

## 1. Unidad de trabajo: el WP

- Todo cambio es un **WP** (`WP-O<n>`), con fila en `BACKLOG.md`. El siguiente número libre se toma del
  backlog; no se reutilizan.
- Una **rama por WP**: `wp/O<n>-<slug>` (upgrades de Oasis: `upgrade/oasis-<versión>`).
- Si el WP no cabe en la fila del backlog, lleva **BRIEF** en `plan/BRIEFS/WP-O<n>-<slug>.md`: contexto,
  alcance, fuera de alcance, criterios de aceptación.
- Una decisión que condiciona WPs futuros se asienta en `DECISIONES.md` como **D-O<n>**, con fecha,
  quién decide y qué supera. Un asiento no se edita: se supera con otro.

## 2. Commits pedagógicos

El historial es material de estudio para el equipo: leyendo `git log` se debe poder recomponer la
secuencia y el porqué.

- **Una pieza por commit**, en el orden en que se entiende (primero lo que otros necesitan).
- Prefijo convencional (`feat`, `fix`, `docs`, `chore`, `merge`) + ámbito; el cuerpo explica el **porqué**
  y lo que se descartó, no repite el diff.
- Un arreglo descubierto en un gate va en **su propio commit**, contando qué lo destapó.
- Merge a `main` con `--no-ff` y mensaje que resume el WP. `main` siempre desplegable.

## 3. Gates: local antes que remoto

1. **Gates locales** (Docker local) numerados `G0…Gn`, cada uno con salida esperada. Bloqueantes.
2. **Drill con identidad desechable** para todo lo que publique en SSB o toque una cartera. La
   identidad real de nadie —tampoco la del custodio— se usa para ensayar.
3. `src/` no se toca fuera de los guards: invariante `git diff oasis-upstream/main --stat -- src/`.
4. Docs: `npm run docs:build` y `.claude/skills/site-web/scripts/verificar-sitio.mjs` (enlaces muertos rompen el build).
5. Solo entonces el host, paso a paso, con **parada dura** (`docs/AGENTES.md` §2).

Se prefiere **reducir tiempo a validar de más**: el gate cubre el riesgo que no tiene vuelta atrás, no
todo lo imaginable.

## 4. Cuándo se pide GO al custodio

- Antes de **desplegar en un host vivo** (aunque el plan esté aprobado).
- Antes de cada acción de la tabla de irreversibles (`docs/AGENTES.md` §3).
- Ante cualquier desviación del plan: **primero parar, después proponer**.
- No hace falta para: ramas, commits, push de ramas de WP, gates locales, lecturas en el host.

## 5. Cierre de un WP

- **Reporte** en `plan/REPORTES/WP-O<n>-<slug>.md`: qué se entregó (commit por pieza), criterios de
  aceptación con evidencia, hallazgos, seguimiento. Incluye la lista de **correcciones al protocolo**
  que destapó la ejecución; se aplican en el mismo WP.
- `CHANGELOG.md` (raíz) bajo `[Unreleased]`; estado en `BACKLOG.md`; protocolo afectado al día,
  incluida su sección de registro; ficha de instancia si cambió un dato del despliegue.
- Despliegues: línea en el journal con `devops/scripts/deploy-log.sh`.

## 6. Trabajo con varios agentes

- Un subagente recibe **contexto completo y salida esperada**; no hereda la memoria del principal.
- Los pasos sobre un host son **secuenciales**; en paralelo solo exploración y gates independientes.
- Un subagente al que se le deniega una acción **para y lo dice** (`docs/AGENTES.md` §3).
- La prueba de un protocolo es un **agente en frío**: solo el repo y la intención.
