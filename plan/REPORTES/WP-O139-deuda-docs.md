# WP-O139 · Deuda documental: docs de entrada, plan/ e higiene

Rama `wp/O139-deuda-docs` desde `main` d5a4e929 (merge de WP-O138). 2026-10-15. Solo documentos,
`.gitignore`, `.dockerignore`, `package.json` (un alias npm) y un comentario de script. **No toca** host, ni
`src/`, ni `docs/PUB/UPGRADE-PROTOCOL.md`, ni `devops/scripts/upgrade-*` (eso es WP-O140).

## 1. Estado de partida (medido)

Tres auditorías de solo lectura sobre `main` d5a4e929 (docs de entrada · protocolo y scripts de upgrade ·
plan/ e higiene). Lo que destaparon y que este WP paga:

- `MAPA.md` (último commit 2026-10-01, cabecera de julio) se presentaba como «estado real del repo» y decía
  Oasis **0.8.8**, «el remote `oasis-upstream` no existe» y guards de **4** ficheros, sin aviso de superado.
  `src/server/package.json` = 1.2.8; `git remote -v` lista `oasis-upstream`.
- Recuento de guards: 7 (AGENTS.md:14, UPGRADE §2), **5** (README.md:135, BASE-2:29), **4** (MAPA.md:279);
  D-O22/D-O27 «6 ficheros» frente a D-O31 «7 ficheros».
- `next-steps.md` (651 líneas, trackeado desde 4ba83ef9): transcript de ChatGPT («#### Tú dijiste: / ChatGPT
  Plus») sobre Radicle; MAPA.md:12 lo daba «sin trackear». Superado por D-O3.
- `docs/CHANGELOG.md`: changelog de **upstream** congelado en v0.7.4 (2026-04-25), con el mismo nombre que el del
  fork y excluido del portal.
- Deprecación del bot retro (D-O36) repetida tres veces en `docs/AGENTES.md` y cuatro en la ficha de instancia,
  con paréntesis anidados; la ficha decía «la versión no va aquí: se mide» (:9) y escribía 1.2.8/1.2.5/1.2.3 (:46-58).
- Puerta **Habitante** (`orden: 0`) ausente de la tabla de entrada de AGENTES §0 y de README.
- Backlog: O119, O128, O135 «pendiente de merge» estando en `main`; O129 🔶 fusionada; O46, O97-O102 sin línea
  de estado; O80/O77 abiertos aunque O112/O127 los entregaron; D-O34/D-O35 solo en `dev/26sm-exported`.
- `git status`: `ARCHIVO/DISCO/26sm-exported/` (124 MB: 51 PNG, 21 JPG, 1 PDF, 1 zip) sin ignorar en `main`
  (la rama que lo creó sí lo ignora); `.claude/settings.json` (allowlist del refactor de julio, nada sensible).

## 2. Decisión que lo gobierna

**D-O37** (custodio, 2026-10-15): git ya archiva. De cada documento se pregunta qué función cumplía y si está
subsumida por uno vivo; si lo está → `git rm`; si no → se recoge lo que falta y después se retira. Las citas
`MAPA.md:n` de los dosieres de evidencia (`docs/ROADMAP/aleph-net/`) se leen con `git show <sha>:MAPA.md`.
Fija además la frase canónica de guards. Supera el brief de WP-O03 («cita inerte»), que cierra.

| Fichero | Función | Dónde vive hoy | Acción |
|---|---|---|---|
| `MAPA.md` | estado real del repo (julio) | `deploy-status.sh` (host), `AGENTES.md` (operación), `BACKLOG.md` (deuda), `pub/site/scriptorium/estado.md` (sitio) | retirado |
| `PLAN.md` | plan de etapas (ya SUPERADO) | `BACKLOG.md` | retirado |
| `next-steps.md` | guía Radicle WSL/VPS | D-O3, WP-O60/O61 | retirado; fuera de `.dockerignore` |
| `docs/CHANGELOG.md` | changelog de upstream v0.7.4 | repo de upstream | retirado; fuera de `srcExclude` |
| `scripts/check-docker-context.sh` | diagnóstico de contexto de build | sin consumidor (solo `archive/HACKATON_GUIDE.md`, otro repo) | retirado |
| `BASE-1/2/3` | doctrina editorial del portal | **no subsumida** (`docs-ceguera.sh` y `verdad-checks.json` ejecutan parte; líneas-sello y cola §F solo aquí) | corregidos y enlazados desde `docs/proyecto.md` |

Riesgos de MAPA §7, uno a uno contra el backlog: 1 socket Docker → WP-O52; 2 token de rooms → WP-O73 (⛔ D-O10);
3 `curl | bash` cuenta vieja → WP-O72 (hoy `pub/site/scriptorium/index.html:349`); 4 DoS invite → WP-O53; 5 enlaces
a cuenta anulada → WP-O72 (`estado.md:66`); 6 Verdaccio en CI → **resuelto** (`docs.yml` usa `npm ci`); 7 datos de
instancia versionados → parcial: `devops/hosts/` existe, **`pub/BACKLOG.md` sigue en git con IP pública y fingerprint
SSH** (anotado, sin WP); 8 remote upstream → resuelto; 9 `caps.shs` en `src/` → WP-O82 + UPGRADE §5.

## 3. Entregado (commit por pieza, en el orden en que se entiende)

| Commit | Pieza |
|---|---|
| 60d999a9 | `docs(decisiones)`: D-O37; nota D-O34/D-O35 en rama |
| db1ff988 | `chore(docs)`: retirados MAPA, PLAN, next-steps, docs/CHANGELOG, check-docker-context; `.dockerignore`, `srcExclude`, comentario de `roadmap-import.py` |
| b1c6c059 | `chore(retro)`: fuera el npm `pub:local:retro-bot:up`; cabecera de `retro-seed.sh`/`retro-tombstone.sh` (requieren el contenedor del bot; generalizar = WP-O142); TEMPLATE §4.5 sin el alias |
| ea5cbce7 | `docs`: frase canónica de guards en README, BASE-2, `roles/mantener.md`; tres modos (`full`/`server`/`backend`) en README, BASE-1, `proyecto.md`, `index.md`; `epsylon/oasis` en BASE-1; BASE-* sin «primera pasada», decisiones 07-21 tachadas; BASE enlazados desde `proyecto.md`; protocolos que faltaban en README/proyecto; «ejercidos en la demo» en la portada |
| 9cc7b3d4 | `docs(agentes)`: Habitante primera fila de §0; párrafo del invite público → `roles/habitante.md` («para quien opera»); retro en §2.9 y §3, §5 solo lo cita; trampa `TRIBE_LOG_TYPES` «desde 1.2.5 (sigue en 1.2.8)»; ficha de instancia con una sola afirmación de versión (la del journal), retro en una fila, «bot 2»/«bot 3»; plantilla sin el bot deprecated como ejemplo, filas simétricas, enlaces relativos |
| 40f00a6f | `chore(higiene)`: reglas de ignorado de 26sm-exported iguales a su rama; `__pycache__/` una vez; `ARCHIVO/README` con `portal/`, `installer-amd/`, `26sm-exported/` |
| d134c7e9 | `docs(plan)`: estados con sha+fecha de merge (O46, O97-O102, O119, O128, O129, O135); O80/O77 absorbidos; O03 ✅; O111 sin filas duplicadas; leyenda P3, 🟡→🔶; altas O139-O142; PRACTICAS (gates por protocolo, invariante contra `NEW_REF`); cabeceras de O100/O128/O132/O135; ROADMAP fase 0 P2P hecha |

Fuera de git: borrado `.claude/settings.json` (residuo de sesión).

## 4. Criterios de aceptación (comando + salida)

```
$ npm run docs:build                       → build complete in 8.60s
$ npm run docs:gate                        → [verificar-sitio] señales prohibidas ausentes: sí · [verificar-piel] OK · [verificar-contraste-piel] OK
$ bash devops/scripts/docs-ceguera.sh      → ámbito ciego: 8 ficheros, 0 menciones · trinquete: 52 (base 52) · CEGUERA OK
$ git grep -nE "5 fork-guards|5 divergencias|4 ficheros\)|Primera pasada|probados en producción|dos modos" \
    -- ':!archive' ':!ARCHIVO' ':!src' ':!CHANGELOG.md' ':!plan/REPORTES' ':!docker-compose.yml'
                                           → solo plan/BACKLOG.md:892-893 (el BRIEF/CA de este WP describe el síntoma) y
                                             plan/BRIEFS/WP-O103:77 («dos modos» de la cartera: otra cosa)
$ git grep -nE "MAPA\.md|PLAN\.md|next-steps\.md|docs/CHANGELOG|check-docker-context|retro-bot:up" \
    -- ':!archive' ':!ARCHIVO' ':!docs/ROADMAP' ':!plan' ':!src' ':!node_modules'   → vacío
$ git status --short                       → vacío
```

## 5. Hallazgos

- `pub/BACKLOG.md` (:88-113) sigue versionado con IP pública y fingerprint SSH del host: datos de instancia que
  D-O37 manda a la ficha o a `devops/hosts/`. **Pendiente, sin WP** (anotado en WP-O03 y en «fuera de alcance»).
- `.claude/skills/site-web/` está medio trackeado: `.gitignore:78` lo ignora y `git ls-files` da 8 ficheros;
  `npm run docs:gate` depende de ellos (`verificar-sitio.mjs`). Pendiente de decidir (trackear o `skills:sync` en CI).
- `CHANGELOG.md` lleva 600+ líneas bajo un único `[Unreleased]` y `package.json` sigue en 1.0.0 (WP-O05).
- WP-O129 está fusionada sin reporte ni entrada de CHANGELOG (anotado en su fila).
- Hito `ubiClaim` del bot ecoin ≥ 2026-10-18 (BACKLOG :630): DECISIÓN del custodio, irreversible, en tres días.
- En D-O36 queda un párrafo «Interpretación del agente, a confirmar por el custodio» (deprecated = retirado de la
  operación, no identidad destruida; dos listas CLOSED del bot sin retirar). No se ha editado: espera confirmación.
- Los dosieres `docs/ROADMAP/aleph-net/*.md` citan `MAPA.md:n` y `PLAN.md:n`; son evidencia congelada y D-O37 dice
  cómo leerlas. No se reescriben.

## 6. Seguimiento

- Merge a `main` con `--no-ff`; después WP-O140 (protocolo de upgrade v3), que toca `AGENTES.md` §4 y por eso va detrás.
- WP-O142 (P2): generalizar `retro-seed.sh`/`retro-tombstone.sh` con `--container`.

## 7. Correcciones al protocolo

Ninguna al protocolo de operación. Al método de trabajo: `plan/PRACTICAS.md` §3 numeraba los gates `G0…Gn` y
medía el invariante contra `oasis-upstream/main`; ahora remite a la numeración de cada protocolo y a `NEW_REF`.
