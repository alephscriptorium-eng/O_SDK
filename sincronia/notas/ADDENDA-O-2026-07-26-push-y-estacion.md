# ADDENDA · O — push a CUADERNOS y estabilización de estación

| dato | valor |
| ---- | ----- |
| Emisor | **O** · `WORLD_ROOT = C:\S_LAB\o-sdk` |
| Fecha | 2026-07-26 04:00 |
| Autorización | GO del custodio: *«push ahora … tienes mi GO si el skill te explica»* + estabilizar estación |
| Rango | addenda de ejecución — cierra NEXT-1 |

## 1 · Push ejecutado — verificado de facto

| ítem | valor |
| ---- | ----- |
| Repo | `github.com/alephscriptorium-eng/scriptorium-cuadernos` |
| Rama | **`o_sdk-vigilancia`** (nueva, desde `origin/main` `596d607`) |
| Commit | **`e451926`** · 10 ficheros, 670 inserciones |
| Worktree | `C:\S\_fuentes\cuadernos-vigia-O` |
| Identidad | `vigia-O <alephscriptorium@gmail.com>` |
| Verificación C8 | `git ls-remote origin o_sdk-vigilancia` → `e451926…` = HEAD local · fichero releído **desde** `FETCH_HEAD` ✅ |
| Secrets (§10.6) | 0 ficheros `*.env` / `*secret*` / `*token*` / `*.key` en el snapshot ✅ |

Layout publicado (precedente de V, no inventado):

```text
README-o_sdk-vigilancia.md
o_sdk/estacion/BITACORA-sprint-CIUDAD.md
o_sdk/sincronia/{BUZON,TIMBRE,DRAFT,ESTACION}.md + notas/
```

### ⚠️ Corrección al censo de INFORME-R1 §7

El censo daba la rama de O como **`o_sdk`**. Verificado contra el remoto:
`origin/o_sdk` existe pero **no es una rama de vigilancia** — es un rescate
(`chore(o_sdk): rescue untracked from alephscript-clean (IB-01)`), árbol
`{README.md, o_sdk/}`, ajeno a este sprint. Todas las demás siguen el patrón
`RAMA(X)` de §0: `g_sdk-vigilancia`, `v_sdk-vigilancia`, `z_sdk-vigilancia`,
`skills_library-vigilancia`, `scriptorium-vigilancia`, `script_sdk-vigilancia`.

Decisión aplicada: crear **`o_sdk-vigilancia`** por patrón. Motivo de no
consultar: el custodio condicionó el GO a que el método lo explicase, y lo
explica en tres sitios convergentes — PROTOCOLO §0 (`RAMA(X)`), el README
raíz de CUADERNOS (*«próximos mundos: `<mundo>-addenda` / `<mundo>-vigilancia`»*)
y el precedente de V de esta misma sesión. `origin/o_sdk` queda intacto.
◆ Anfitrión: corregir el censo.

## 2 · Estación estabilizada

| acción | resultado |
| ------ | --------- |
| Preflight identidad-raíz | `PASS` (git toplevel = `WORLD_ROOT`) |
| Preflight identidad de commits | detectó placeholder → corregido a `vigia-O` |
| Rotación de logs | `C:\S_LAB\vigilancia\o\archivo\2026-07-26-0300\` — **movidos, no borrados** (1,9 MB conservados como evidencia) |
| Estaciones relanzadas | vigilancia (método) + timbre v0.1, logs limpios |
| Calibración escrita | `sincronia/ESTACION.md` — params, preflights, residuos, rotación |

## 3 · ⛔ R-1 · Hallazgo que afecta a toda la mesa

**El watcher del skill marca como residuo la documentación del propio
método.**

- Qué: `!!RESIDUO markdown de info en carpeta de IDE (regla 15)` disparado
  por `.claude/skills/**` y `.cursor/skills/**`.
- Cuánto: **11.842 líneas en la primera hora — el 100 % de `anomalias.log`**.
  Cero anomalías de otra clase.
- Por qué es falso positivo: la regla 15 persigue **notas de sesión
  efímeras** (fuente de verdad paralela que se pierde al cerrar). El espejo
  de skills es lo contrario: **generado** por `skills:sync` desde un paquete
  **versionado** (`@alephscript/skills-scriptorium@0.11.0`) y **gitignorado**.
  Su fuente de verdad no es efímera, es el lock.
- Consecuencia operativa: cualquier anomalía real queda sepultada bajo miles
  de líneas. El principio del propio skill — *«vigía silencioso: el falso
  positivo no es inocuo»* — queda invertido por su herramienta.
- Alcance: **todo carril que haya corrido `skills:sync`**, no solo O.

Mitigación local mientras siga abierto (no toco el skill, es método):

```bash
grep -v '/skills/' C:/S_LAB/vigilancia/o/anomalias.log | tail -20
# salida vacía = estación limpia, aunque el log tenga miles de líneas
```

★ Arreglo de fondo que propongo (para L, que porta el skill): que la regla
15 **excluya el directorio del espejo materializado** — detectable sin
heurística por el `README.md` generado (`<!-- GENERADO por
alephscript-skills-sync — NO editar a mano -->`) o por el propio
`.gitignore`. No es calibración del consumidor: es del método.

## 4 · Estado

`ESTADO: PUSH_CUADERNOS=✅ e451926 verificado; RAMA=o_sdk-vigilancia; GATE_10.5_O=✅ cumplido; ESTACION=✅ estabilizada + calibrada; R-1=⛔ abierto (mesa); NEXT-2=⏳ tick; NEXT-3=⏳ dato de Z`

Con esto NEXT-1 queda cerrado. Quedo a tick para NEXT-2 (entrada real al
starter-kit, arista A2) y para entrar al contenido de la sesión.

— **O**
