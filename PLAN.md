# PLAN — el gran puzzle por etapas (2026-07-25) · **[cita inerte]**

> ⛔ **SUPERADO el 2026-07-26.** El plan vigente del carril es
> **[`plan/BACKLOG.md`](plan/BACKLOG.md)** (10 lanes · 65 WPs) con sus
> asientos en [`plan/DECISIONES.md`](plan/DECISIONES.md). Este documento se
> conserva como traza: varias de sus etapas fueron **rechazadas o
> recortadas** después (rad quedó en solo seed-web, no réplica de suite ni
> «colección datos»; las rotaciones E0 están ⛔ bloqueadas por el custodio;
> el «diseño target» fue retirado por O). No ejecutar nada de aquí.
> Consolidación pendiente: WP-O03.

> Complemento de [MAPA.md](MAPA.md) («inventario, no plan»). Esto ES el plan.
> Propuesta del agente, no doctrina: lo existente no es la autoridad y esto
> tampoco — cada etapa se aprueba en su tick. Regla anti-bola al final.
> Cada afirmación con ref verificada hoy; lo no verificado, `<pendiente>`.

## 0 · La imagen de la caja (visión)

Tres redes, cada una en lo que es buena, unidas por **manifests como raíz de
confianza** (doctrina ya escrita en z-sdk `plan/DATOS.md` §5 y D-14):

```
                    ┌─ colección CÓDIGO (la suite de repos)
   rad (Radicle) ───┤
                    └─ colección DATOS (contrato ZEUS_VOLUMES_ROOT,
                         manifests con `cid` opcional)
                                  │ los manifests apuntan ↓
   IPFS (kubo) ────── LARGES inmutables (firehose, media) por CID
                                  │ pineados en el VPS
   pub (SSB) ──────── capa social/runtime: feeds, invites, blobs vivos
                         (sidecar blobstore cuando tenga GO)
```

- **rad no usa IPFS** (eso era el alpha 2019; Heartwood es git-nativo). Los
  juntamos nosotros: rad replica los git; IPFS sirve los bytes que los
  manifests del repo de datos apuntan. Ninguna red necesita saber de la otra.
- **ssb-blobs vs IPFS**: ambos content-addressed pero con ciclos distintos —
  SSB = flujo social del juego en runtime; IPFS = base inmutable de
  arranque/distribución. No forzar uno dentro del otro.
- La identidad de capa 2 (peercard/ACL, `operador-rooms`) es transversal y
  tiene su propia etapa.

## 0b · Piezas verificadas hoy (dónde está cada una)

| Pieza | Dónde | Estado verificado |
| ----- | ----- | ----------------- |
| Pub SSB + edge TLS 6 vhosts | o-sdk `pub/` | ✅ vivo en VPS; migración de layout **pendiente** ⟨`devops/MIGRATION-2026-07.md`⟩ |
| Sidecar blobstore | o-sdk `pub/blobstore-sidecar/` | código+tests ✅, deploy ❌, fragmento fuera del compose a propósito |
| Contrato VOLUMES + doctrina IPFS | z-sdk `VOLUMES/README.md`, `plan/DATOS.md` §5, D-14, WP-U71 | manifests toleran `cid`; transporte = horizonte |
| Juegos + startpacks + **Ciudad** | **g-sdk** (`Z_SDK-games-library`): `packages/{ciudad,delta,pozo,solve-coagula,startpack-*}` | ✅ local — corrige al MAPA §8, que la buscaba en z-sdk |
| Base histórica Scriptorium | a-sdk (`aleph-scriptorium`, **cuenta vieja**) | monorepo viejo; fuente de líneas existentes |
| Suite local | 8 repos git: a,e,g,o,s,v,z-sdk + skills-library | remotes en `alephscriptorium-eng` **salvo a-sdk** (escrivivir-co) |
| Token PUBLIC_ROOM en página pública | `pub/site/scriptorium/index.html:303` | ✅ ya saneado en working copy (`SOLICITAR`), **sin commit** |
| `curl \| bash` cuenta+rama vieja | `pub/site/scriptorium/index.html:313` | ❌ sigue |
| Rooms server / node-red contribs | externo (`escrivivir-co/scriptorium-vps`) | código NO está en la suite local |
| Radicle/IPFS en backlogs | `pub/BACKLOG.md`: 0 menciones | terreno virgen — este plan es la primera escritura |

---

## Etapas

Diseñadas para **no hacer bola**: cada etapa cabe en 1–3 sesiones, tiene gate
verificable, y ninguna abre la siguiente por arrastre. Orden: primero cerrar
heridas, luego el hilo nuevo (rad→datos→IPFS), luego los GO diferidos, al
final los movimientos de horizonte.

### E0 — Cerrar la herida (VPS + secretos) · ~1 sesión

La base de todo lo demás: no se monta infra nueva sobre un VPS a medio migrar.

1. Commit del saneado de `index.html:303` + mergear `refactor/estructura` → `main` + push.
2. Migrar el VPS según `devops/MIGRATION-2026-07.md` (mover `.env.prod`,
   redeploy con rebuild; **no reiniciar `pub-web` a ciegas**).
3. Rotaciones: clave SSH `gandi_pub_ed25519` (horneada en imagen construida
   en el VPS), `ROOMS_SECRET` (estuvo público), `PUB_PANEL_TOKEN`.

**Gate**: `npm run devops:status` verde; `whoami.sh` devuelve el mismo feed
id; los 3 secretos rotados y anotados en `devops/hosts/scriptorium/host.env`.
**No hace**: nada de rad/IPFS/sidecar.

### E1 — Hardening del panel (riesgos #1 y #4 del MAPA) · ~1 sesión

- `docker.sock` rw + root = root del VPS tras un Bearer ⟨`pub/docker-compose.pub.yml:52`⟩
  → socket-proxy (p. ej. `tecnativa/docker-socket-proxy`, solo endpoints
  restart/logs) o retirar `/api/pub/restart` hasta tenerlo.
- DoS por invite no cacheado ⟨`pub/panel-api/src/server.mjs:167-173`⟩ →
  caché negativa con TTL + expiración del invite cacheado.

**Gate**: un GET anónimo repetido a `/public/status` no dispara `docker exec`;
el contenedor panel ya no ve el socket crudo.

### E2 — Saneado de `pub/site/` (deuda de ceguera) · ~1 sesión

Los 17 enlaces a la cuenta anulada + duplicado + bootstrap:

- Reapuntar o retirar los enlaces `escrivivir-co/*` (la propia doctrina
  `BASE-3-MECANISMO.md:21` los prohíbe en superficie pública).
- `curl | bash` de `index.html:313`: **retirarlo** de la página hasta E8
  (rooms propio); mientras, dejar «pide el bootstrap al admin». Un onboarding
  público que ejecuta código de una cuenta anulada es peor que ninguno.
- Borrar `pub/site/scriptorium/catalog.json` (huérfano byte-idéntico, 487 líneas).
- Los diagramas ASCII con `*.scriptorium.escrivivir.co` son texto: se quedan.

**Gate**: grep de ceguera (`escrivivir-co\/|@tMJzSfcZ`) sobre `pub/site/` → 0
(salvo excepciones decididas y anotadas). `docs/public/legacy.html`: decisión
PO aparte (congelar con nota o migrar) — no bloquea.

### E3 — Nodo Radicle en el VPS: colección CÓDIGO · ~2 sesiones

El bloque git 1. Todo **fuera del stack del pub** (compose/systemd propio,
misma filosofía que el fragmento del sidecar: nada entra al compose vivo por
arrastre).

1. Local: WSL2 + `rad` (no hay rad para Windows; ojo a no mezclar git de
   Windows y de WSL sobre la misma working copy).
2. VPS: `radicle-node` con **identidad propia** (opción 1 de `next-steps.md`);
   backup cifrado de `~/.radicle` de ambas identidades (la del VPS y la tuya).
3. `rad init` + seed de la suite local (8 repos). La «colección» en Radicle
   **es la política de seeding del nodo** — mantener `devops/rad/seeds-codigo.txt`
   versionado como fuente de verdad de qué se seedea.
4. **DECISIÓN previa**: a-sdk sigue en la cuenta vieja — ¿se migra de org
   antes de seedearlo, se seedea tal cual (rad no depende de GitHub), o se
   archiva? Propuesta: seedearlo ya (rad es agnóstico del remote) y migrar la
   org después con calma.
5. Los «27 repos» = org completa `alephscriptorium-eng`; empezar por los 8
   locales y crecer la lista de seeds, no al revés.

**Gate**: `rad clone rad:<RID-de-o-sdk>` funciona desde una máquina externa
con el portátil apagado.
**No hace**: Forgejo (decisión en E7), datos (E4).

### E4 — Colección DATOS: el repo de volúmenes · ~2 sesiones

El bloque git 2. Repo nuevo y **genérico** (regla del mundo: no diseñar para
nuestras líneas mock, sino para uso por otros). Nombre propuesto:
`zeus-volumes` (org nueva).

1. Layout = contrato `ZEUS_VOLUMES_ROOT` tal cual lo define z-sdk:
   ```
   volumes.json                  # ids canónicos: firehose, lineas, forces, ssb
   DISK_02/LINEAS/ + registry.yaml
   DISK_03/FORCES/ + registry.json
   DISK_01/, DISK_04/            # solo manifests; los dumps pesados van por cid
   ```
2. Regla de peso: texto y registries en git; todo objeto > ~5–10 MB **no
   entra** — manifest con `cid` (campo ya tolerado por D-14) y bytes a E5.
3. Inicialización con la base default del juego. Fuentes candidatas, en orden:
   los `startpack-*` de g-sdk (base ya empaquetada por juego) y las líneas
   históricas del Scriptorium en a-sdk. **DECISIÓN**: qué juego(s) forman la
   base default del repo (propuesta: la de `startpack-delta`, que es la que
   la autoridad delta/pozo ya sabe montar).
4. Relación con startpacks: el repo de datos pasa a ser la **fuente** desde la
   que g-sdk construye `@zeus/startpack-*` (git = fuente, Release/npm =
   empaquetado, IPFS = bytes). Un solo origen, tres canales.
5. `rad init` + añadir a `devops/rad/seeds-datos.txt` (segunda colección del
   mismo nodo de E3).

**Gate**: en una máquina limpia, `rad clone` del repo de datos +
`ZEUS_VOLUMES_ROOT=<clon>` + arrancar el mesh de z-sdk → los resolvers
(`resolveVolume`/`browseVolume`) sirven la base default.
**Nota de gobernanza**: esto NO viola «start packs y volúmenes nunca en git»
(ARQUITECTURA §6 habla del *monorepo*; este repo externo es exactamente el
«árbol externo» que `VOLUMES/README.md` prevé). Y no toma WP-U71 «por la
espalda» en z-sdk: cero código nuevo en el mesh.

### E5 — IPFS para larges · ~1-2 sesiones

La doctrina ya lo dejó a huevo: **«añadir IPFS será pinnear y anotar, no
migrar»** ⟨z-sdk `plan/DATOS.md` §5⟩.

1. **DECISIÓN de recursos primero**: el VPS tiene 4 GB y ya corre el stack pub
   (+ rad-node de E3, ligero). kubo con `Routing.Type=dhtclient` y
   `ConnMgr` bajo cabe, pero medir tras E3; plan B: segundo VPS mínimo solo
   para kubo, o pinning service como colchón.
2. Compose propio (`devops/ipfs/` o repo aparte), nunca dentro del compose
   del pub.
3. `ipfs add` de los larges reales (firehose ~38 MB, media) → anotar `cid` en
   los manifests del repo de datos (E4) → script `pin-desde-manifests.mjs`
   que lee los manifests del clon y hace `ipfs pin add` (idempotente, estilo
   `proyectar-backlog.mjs`: fuente de verdad = git, artefacto = pins).
4. Gateway HTTP opcional tras Caddy (vhost nuevo, p. ej.
   `ipfs.scriptorium.escrivivir.co`, solo `/ipfs/*` read-only) — tick de
   deploy explícito, jamás reinicio ciego de `pub-web`.

**Gate**: un large real resoluble por CID desde fuera del VPS; el repo de
datos no contiene ningún blob > 10 MB (`git ls-files | tamaño` en CI).

### E6 — Sidecar blobstore: GO del carril SSB · tick de deploy

Aquí (y solo aquí) se levanta lo diferido — D-22 se reabre **cuando ops está
listo**, que es exactamente lo que D-22 pedía. Las 4 cosas del MAPA §5:

1. `profiles: ["blobstore"]` al integrar el fragmento (que `deploy.sh` no lo
   arrastre).
2. `BLOBSTORE_TOKEN` en `.env.prod` (sin él arranca sin auth).
3. `BLOBSTORE_MAX_TAMANO` acorde a 4 GB de RAM (procesa en memoria): ≤ 256 MB.
4. Montar **solo el socket**, no `~/.ssb` entero rw (hoy el fragmento monta el
   dir con el `secret`; el contenedor corre root). Ajustar el fragmento antes.

Después: rellenar `ZEUS_BLOB_SIDECAR_URL`/`ZEUS_BLOB_*` de z-sdk y correr el
harness U100/U101 que ya espera esto.

**Gate**: `GET /x/blobstore/v0/salud` 200 desde el harness de z-sdk; el check
F5c de s-sdk pasa de `⟨pendiente⟩` a verde con evidencia.

### E7 — Soberanía web/CI (la salida de GitHub) · decisión + ~2 sesiones

El acoplamiento duro es **Pages + Actions** (MAPA §3). Propuesta imaginativa
pero contenida — **Forgejo en el VPS como pieza única** que da: vitrina web de
los repos (complemento visual de rad), mirrors automáticos (Forgejo sabe
hacer mirror pull de los repos), Forgejo Actions (runner propio,
sintaxis compatible) e Issues propios (el adaptador de `proyectar-backlog.mjs`
es sustituible por diseño). Camino:

1. Mientras tanto: **dual asumido** (ya somos dual-dependientes: el CI de
   GitHub necesita el Verdaccio propio para construir).
2. Primer paso reversible: vhost en Caddy sirviendo `docs/.vitepress/dist`
   como espejo de `o-sdk.escrivivir.co` (Pages sigue siendo primario; el DNS
   decide después).
3. **DECISIÓN**: Forgejo sí/no y cuándo. Si no, se documenta el dual como
   estado terminal aceptado y esta etapa se cierra corta.

**Gate** (si Forgejo): el portal de o-sdk se construye y publica sin tocar
GitHub, end-to-end, una vez.

### E8 — Capa 2: rooms con peercard/ACL + Ciudad · ~3 sesiones

La mejora conceptual del MAPA §4: shared-secret → identidad por peer.

1. Traer el rooms server a la org nueva (hoy vive en
   `escrivivir-co/scriptorium-vps`, fuera de la suite) — requisito para todo
   lo demás. `<pendiente>`: inventario de qué contiene ese repo.
2. Ensayo **en local primero**: contenedor rooms en `oasis_pub_net` con alias
   `scriptorium-rooms` — el Caddyfile funciona sin tocarlo (resolución por
   alias, MAPA §4.3), junto a `pub:local:up`.
3. Sustituir shared-secret por **peercard firmada + ACL deny-by-default +
   salud observable** (contratos ya escritos en `operador-rooms/` y
   `estacion-viva/reference/GAME-MCP.md`).
4. Acoplar al esquema de **Ciudad que vive en g-sdk** (`packages/ciudad`,
   `startpack-ciudad`) — corrige el `<pendiente>` del MAPA §8 que la buscaba
   en z-sdk.
5. Reponer el onboarding público retirado en E2, ahora `curl | bash` desde la
   org nueva (o mejor: instalador servido por el propio Caddy).

**Gate**: dos peers con peercards distintas conectados a la vez; revocar una
no rompe la otra. El invite SSB (layer 1) y la peercard (layer 2) se emiten
por caminos separados.

### E9 — Higiene del fork Oasis · ~2 sesiones, sin prisa

- Añadir remote `oasis-upstream` + rama espejo (hoy el protocolo de upgrade
  es documentación sin cableado: `git remote -v` solo tiene origin).
- Consolidar los parches duplicados (`docker-entrypoint.sh` vs
  `scripts/patch-node-modules.js` — misma corrección, dos caminos).
- Sacar `caps.shs` de `src/` (riesgo #9: dato de red en zona de overlay).
- PRs al upstream de lo upstreamable: parche `ssb-blobs` wantCallbacks y
  `multiserver` unix-socket (ambos bugs genuinos).

**Gate**: `upgrade-preflight.sh` ejecuta de principio a fin sin error.

---

## Dependencias (qué desbloquea qué)

```
E0 ──► E1, E2, E3          (nada sobre VPS sin migrar)
E3 ──► E4 ──► E5           (el hilo del usuario: rad → datos → IPFS)
E0 ──► E6                  (sidecar = tick de deploy sobre VPS sano)
E5 + E6 = blobs completos  (SSB runtime + IPFS distribución)
E2 ◄──► E8                 (E2 retira el onboarding viejo; E8 repone el nuevo)
E7, E9                     (independientes, cuando haya hueco)
```

## Decisiones abiertas (marcar antes de su etapa, no durante)

| # | Decisión | Etapa | Propuesta del agente |
| - | -------- | ----- | -------------------- |
| D-a | a-sdk: ¿migrar org antes de seedear? | E3 | seedear ya; migrar org después |
| D-b | Base default del repo de datos | E4 | `startpack-delta` como semilla |
| D-c | kubo en el mismo VPS (4 GB) o aparte | E5 | medir tras E3; plan B 2º VPS |
| D-d | Forgejo sí/no | E7 | sí, como pieza única de soberanía |
| D-e | Scope npm definitivo (`@zeus` sin uso / `z-sdk` inexistente) | E7 | decidir con Forgejo/registry a la vista |
| D-f | `docs/public/legacy.html` (viola ceguera) | E2 | congelar con nota |

## Reglas anti-bola (las que hacen que esto no explote)

1. **Una etapa = un carril = una rama/WP.** No se mezclan etapas en un PR.
2. **Gate o no pasó.** Sin evidencia verificable, la etapa queda `🔶`, no `✅`
   (la lección del WP-F5c: el checkmark del índice no es el CA del camino).
3. **Nada entra al compose vivo del pub por arrastre**: todo servicio nuevo
   (rad, kubo, rooms local, sidecar) nace en compose propio o bajo `profiles`,
   y se integra solo en tick de deploy explícito.
4. **Manifests como raíz**: git dice qué existe (CIDs, registries); las redes
   (rad/IPFS/SSB) solo mueven bytes. Si un dato no está en un manifest, no
   existe para el sistema.
5. **Genérico antes que nuestro**: cada contrato nuevo (repo datos, peercard,
   pins) se escribe para un operador cualquiera; Scriptorium es la primera
   instancia, no el diseño.
6. **Las rotaciones no esperan**: cualquier secreto que toque una superficie
   pública se rota en la etapa en curso, no «al final».
