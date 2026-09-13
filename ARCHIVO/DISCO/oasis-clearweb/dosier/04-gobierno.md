# 04 · Gobierno: backlog, decisiones, método, vocabulario

## 1. `plan/BACKLOG.md`

Régimen (`:3-19`): estados ⬜🔶✅⛔ · serie WP-Onn · método `swarm-orquestacion` · **P0** desbloquea la
mesa · **P1** núcleo · **P2** horizonte · «nada se abre sin GO del custodio; encolar de más cuesta cero» (`:15`).
Invariante transversal (`:44-45`): `CA-ANTI-AUTORIDAD`.

Lanes: L0 gobierno (`:50`) · L1 el NODO (`:119`) · L2 playground (`:225`) · L3 volúmenes (`:293`) ·
**L4 superficies (`:395`, O40-O45; O46-O49 libres)** · L5 pub/L1 (`:448`) · L6 soberanía (`:510`) ·
L7 seguridad (`:581`) · L8 upstream (`:649`) · L9 WAN (`:683`) · L10 aceptación (`:737`).

Conteo edición F2-unificada (`:789-800`): P0 **16** · P1 **38** · P2 **21** · total **75** (nota: `:124`
habla de «74 WPs»). Con WP-O46 (P1) y WP-O47 (P2): P1 39, P2 22, total 77. L4 pasa de 6 a 8.

WPs que tocan este plan:

| WP | Línea | Qué aporta |
|---|---|---|
| **WP-O41** Parlamento sidecar L2 | `:409-415` | doctrina «L1 = ∞, L2 = sesión; nada de la sala escribe directo al pub»; CA «caída del sidecar no rompe la sala» |
| WP-O44 superficie pública | `:432-437` | «anónimo base, card opt-in; cero material de identidad en la página» |
| WP-O45 retirar superficie muerta | `:439-444` | `pub-frontend` sin contexto |
| **WP-O50** GO del blobstore | `:452-460` | «montar **solo el socket**, no el directorio con la identidad · rootless/capabilities mínimas» → doctrina de pieza junto al pub |
| WP-O53 invites sin coste por visita | `:482-483` | «N peticiones anónimas → 1 operación · **caché negativa con caducidad**» → precedente doctrinal de caché |
| WP-O55 / WP-O78 | `:495, :503` | «si solo existen en un disco, no son permanentes»; «límites de disco, memoria y conexiones conocidos **antes** de que se crucen» |
| WP-O71 | `:599` | «ningún volumen aloja identidad; secretos por env» |
| **WP-O74** frontera del edge | `:633-637` | «punto único de fallo de cosas que no controla»; cada vhost con dueño; reinicio con consecuencia escrita |
| WP-O80..O83 upstream | `:653-681` | O82: «un dato de red vive en la zona que el overlay sobrescribe»; O83 devolver al upstream (candidatos: QR a localhost, 200 en not-accessible) |
| **WP-O91** volumen de datos separado | `:696-701` | «existe un volumen separado; **falta ruta y contrato operativo**» → la v2 fija el contrato para el HUB |
| WP-O31 | `:301-307` | separación física manifiesto/estado/corpora |

**No existe** en el backlog ni en el repo precedente de «segunda identidad», «cuenta de soporte», «bot»
o «nodo de soporte» (grep). Lo más cercano: `MAPA.md:139` «con identidad propia y revocable»,
`PLAN.md:116` «`radicle-node` con identidad propia».

## 2. `plan/DECISIONES.md` (D-O1..D-O12; regla `:4` «un asiento no se reabre: se supera con otro que lo cite»)

| id | línea | una línea | relación con la v2 |
|---|---|---|---|
| D-O1 | `:9-13` | o-sdk es el NODO, no el proxy; el edge TLS es plomería | el HUB es un nodo más, Caddy solo enruta |
| D-O2 | `:15-19` | foco en superficies de Zeus | — |
| D-O3 | `:21-25` | Radicle solo seed web | — |
| D-O4 | `:27-31` | puertos = env obligatorio; nunca resolución por ancestros | todas las rutas/puertos del HUB por env |
| D-O5 | `:33-39` | manifiesto/estado/corpora físicamente separados | estado del HUB en `/srv/oasis`, configs en `/opt` |
| **D-O6** | `:41-46` | `CA-ANTI-AUTORIDAD` invariante; «se verifica, no se sospecha» | opt-in del habitante; el HUB no decide por nadie; se declara |
| **D-O7** | `:48-52` | apertura anónima base + peercard opt-in; fail-closed en capacidades, fail-open en topología | `--public` (capacidades cerradas), cualquier nodo replicante puede servir el HUB (topología abierta) |
| D-O8 | `:54-57` | cerco exterior: ninguna ancla viva en el arranque | el HUB arranca sin red salvo replicación; `updater` es egress inocuo |
| D-O9 | `:59-78` | el ancla alimenta al volumen; «SSB = feed append-only»; «el runtime solo lee el volumen» | log del HUB = réplica en volumen |
| D-O10 | `:80-83` | saneamiento/rotaciones ⛔ (no tocar VPS ni claves salvo plan) | la v2 crea una identidad **nueva**, no toca las existentes |
| D-O11 | `:85-92` | transporte base vs capacidad opt-in | — |
| D-O12 | `:94-105` | relevo de estación; **jamás reescribir ficheros con acentos vía PowerShell**; identidad git `vigia-O` | este dosier se escribió por Bash (UTF-8) |

**Propuesta D-O13** (redacción para el asiento): «El HUB clearnet de `pub.escrivivir.co` lo sirve un
**nodo de soporte** con identidad SSB propia (`oasis-hub`, `backend.js --public`, hops 2) que replica al
pub; el pub no sirve web. Estado y caché del HUB en el volumen de datos (`/srv/oasis/oasis-hub`). Supera
la receta de `UPGRADE-PROTOCOL.md §8` (proxy al backend dentro del contenedor del pub) y el plan v1.
Cita D-O6 (opt-in, la cuenta se declara), D-O7 (fail-open en topología), D-O9 (réplica en volumen).»

## 3. Método: BRIEF y revisión adversarial

- Plantilla real: `.claude/skills/swarm-orquestacion/reference/roles/BRIEF.md` (no existe `reference/` en la
  raíz). Campos obligatorios (`:24-29`): `ALCANCE_DIFF`, `MUNDO_RAIZ`, `RIESGO_REVISION: normal|independiente`,
  `MOTIVO_RIESGO`, `CONTRAEVIDENCIA_REQUERIDA`, `REVISOR_DISTINTO_WORKER: no requerido|sí`.
- Fuente canónica `reference/revision-adversarial.md`: `independiente` para «seguridad, permisos o fronteras
  de escritura; publicación/release; protocolo operativo que puede autorizar mutaciones» (`:12-15`); el
  orquestador puede elevar, **no rebajar** (`:17-20`); brief incompleto si la contraevidencia «solo repite el
  camino feliz» (`:31-32`); revisor read-only; salida `PASS | DEVUELTO`, «PASS no equivale a aceptación» (`:60`).
- Ejes de CA (`reference/ejes-ca.md`): I extracción con cableado · II demolición con destino canónico ·
  III gate de dedup · **IV el segundo consumidor como sensor** (el HUB es el segundo consumidor del
  contrato «estado en `/srv/oasis`») · V mediación transparente.
- Gate del orquestador: «Diff fuera de `ALCANCE_DIFF` → Devolver» (`reference/roles/ORQUESTADOR.md:161`).

## 4. Vocabulario: «correr su propio fan»

Grep de `fan|fans|fanout|fan.out|propio fan` sobre `.md/.html/.js/.mjs/.sh/.json/.yml` excluyendo
`node_modules` y `src/`: **0 hits** como concepto. Lo único que existe es **«fanzine» = piel estética**
(`docs/.vitepress/theme/custom.css:2`, `pub/site-templates/poster/README.md:3,111`, `pub/site/assets/fanzine.css`).

Lectura adoptada en la v2: «su propio fan» = **su propia replicación** (grafo de follows + hops), que en
config es `friends.hops`, `gossip`, `autofollow`, `replicationScheduler` (`pub/config/ssb/config:10-30`;
`docs/PUB/deploy.md:122-124`). Fundamento: `docs/PUB/clearnet.md:19-21` «every PUB that replicates the
inhabitant applies them… any replicating PUB can be used to share a link».

Vocabulario de federación que sí existe: `pub-federation.sh` (`status|announce|follow|follow-solarnethub`),
«follow-back» (`UPGRADE-PROTOCOL.md:154-157`, `test-invite.sh`).

## 5. `ARCHIVO/`

Antes de esta sesión, `ARCHIVO/` contenía **un solo fichero**: `ARCHIVO/DISCO/oasis-clearweb/v1.md` (336
líneas). No confundir con `archive/` (minúscula): `archive/devops/pub-federation.md`,
`archive/pub/vps-bootstrap-ubuntu.sh`, `archive/session-backlog/*`, etc.
