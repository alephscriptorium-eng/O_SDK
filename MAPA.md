# MAPA — qué tenemos (o-sdk, 2026-07-25)

> Estado real del repo tras el refactor de estructura. Inventario, no plan.
> Regla: cada afirmación con `⟨ref⟩` a fichero real. Lo no verificado se marca
> `<pendiente>`. Alcance: **solo este repo** — lo externo se nombra, no se supone.

## 0 · Los dos ejes del objetivo

| Eje | Qué es | Dónde está hoy |
| --- | ------ | -------------- |
| **pub** (SSB) | Nodo de federación social | ✅ vivo en VPS ⟨`pub/`⟩ |
| **rad** (repos) | Nodo Radicle para la suite de repos | ❌ no existe en este repo ⟨`next-steps.md`, sin trackear⟩ |

o-sdk aporta al pack: el **rol pub**, el **edge TLS compartido** y el
**contrato de identidad** (peercard/ACL) que rooms necesita.

---

## 1 · Lo que corre (y quién lo posee)

### 1.1 Roles de este repo

| Rol | Artefacto | Estado |
| --- | --------- | ------ |
| Cliente | `docker-compose.yml` → `oasis-client` | ✅ funcional (GUI :3000, SSB :8008) |
| Pub | `pub/docker-compose.pub.yml` → `oasis-pub` + `pub-panel-api` + `pub-web` | ✅ desplegado en VPS |
| Wallet | `ecoin/` (profile `ecoin`) | ✅ opcional, desacoplado |
| Sidecar blobs | `pub/blobstore-sidecar/` | ⚠️ **huérfano**: no está en ningún compose vivo |
| Frontend pub | `pub-frontend` (profile `frontend`) | ❌ **superficie muerta**: `PUB_FRONTEND_DIR=./frontend` no existe |

### 1.2 El edge que poseemos y no controlamos

`pub/caddy/Caddyfile` sirve **6 vhosts**, pero solo **1** tiene su backend en
este repo:

| Vhost | Backend | ¿En este repo? |
| ----- | ------- | -------------- |
| `pub.escrivivir.co` | `pub-panel-api` + estático `pub/site/` | ✅ sí |
| `scriptorium.escrivivir.co` | `scriptorium-nodered:1880` | ❌ externo |
| `admin.scriptorium.escrivivir.co` | `scriptorium-nodered:1880` (editor) | ❌ externo |
| `mcp.scriptorium.escrivivir.co` | `scriptorium-mcp-devops:3003` | ❌ externo |
| `npm.scriptorium.escrivivir.co` | `scriptorium-verdaccio:4873` (registry) | ❌ externo |
| `rooms.scriptorium.escrivivir.co` | `scriptorium-rooms:3010` (Socket.IO) | ❌ externo |

**Consecuencia operativa**: este repo es el **punto único de fallo TLS** de 5
servicios cuyo código vive en `escrivivir-co/scriptorium-vps` (cuenta vieja).
Por eso `devops/MIGRATION-2026-07.md` prohíbe reiniciar `pub-web` a ciegas.
Frontera a formalizar antes de crecer.

---

## 2 · Deuda de la cuenta/dominios viejos

**La raíz ya está migrada** (README, `docs/`, `.npmrc`, CI → `alephscriptorium-eng`
+ `o-sdk.escrivivir.co`). **`pub/site/` está entero en el esquema viejo.**

| Deuda | Dónde | Cantidad |
| ----- | ----- | -------- |
| Enlaces a `github.com/escrivivir-co/…` | `pub/site/**` | **17** en 6 ficheros |
| `curl \| bash` desde cuenta+rama vieja | `pub/site/scriptorium/index.html:313` | 1 (onboarding público) |
| Repos obsoletos citados | `BlockchainComPort`, `alephscript-network-sdk`, `scriptorium-vps`, `node-red-alephscript-sdk`, `para-la-voz-sdk`, `aleph-scriptorium` | — |
| `catalog.json` duplicado (487 líneas idénticas, huérfano) | `pub/site/scriptorium/catalog.json` | 1 |
| Enlaces a la Pages vieja | `docs/public/legacy.html` | 7 |

> **Corrección a un supuesto de trabajo**: *hackería NO enlaza aún al dominio
> nuevo*. Grep de `-sdk.escrivivir.co` sobre `pub/site/` → **0 resultados**.
> El único `*-sdk.escrivivir.co` del repo es `o-sdk.escrivivir.co`, y vive
> fuera de `pub/site/`.

**Esto ya lo prohíbe nuestra propia doctrina**: `BASE-3-MECANISMO.md:21`
declara `mundo.ceguera = /(escrivivir-co\/|pub\.escrivivir\.co|@tMJzSfcZ|secret\b)/`.
`pub/site/` viola el filtro en 17 sitios; `docs/public/legacy.html` en 7.

### 2.1 Scopes npm

| Scope | Estado |
| ----- | ------ |
| `@alephscript` | 2 usos: dependencia `skills-scriptorium@0.11.0` + **paquete propio** `pub/blobstore-sidecar/package.json:2` |
| `@zeus` | declarado en `.npmrc:2`, **0 usos** |
| `z-sdk` | **0 apariciones en todo el repo** |

El paquete propio a re-scopear es **uno solo**: el sidecar.

---

## 3 · Dependencia de GitHub (para el dual y la salida)

| Servicio | ¿Se usa? | Dificultad de migrar |
| -------- | -------- | -------------------- |
| Hosting git | Sí | Baja — 8 URLs; 5 salen de `docs/.vitepress/config.mjs:23-29` |
| **Pages** | Sí (crítico) | **Alta** — hosting + CNAME. Alternativa: el Caddy de `pub/` ya podría servir `o-sdk.escrivivir.co` |
| **Actions** | Sí (crítico) | **Alta** — `upload-pages-artifact`/`deploy-pages` no tienen equivalente directo |
| Issues | Declarado | Baja hoy — **pero** ver `proyeccion-backlog` abajo |
| Releases | **No** | — |
| Registry npm | **No** (ya en Verdaccio propio) | ✅ migrado |

**Cuánto aguanta el dual**: indefinidamente para git+issues; el acoplamiento
duro es **Pages+Actions**. Nota de fragilidad ya presente: el CI hace
`npm ci` + `skills:sync` contra el **registry privado**, así que si Verdaccio
cae, el CI de GitHub no construye. Ya somos dual-dependientes.

**`proyeccion-backlog`**: no es un skill propio; vive dentro de
`swarm-orquestacion` (`scripts/proyectar-backlog.mjs` +
`reference/proyeccion-issues.md`). Proyecta `plan/BACKLOG.md` → issues
(unidireccional, markdown = verdad única, idempotente vía `.sync-map.json`).
Necesita **`gh` CLI autenticado**; el adaptador es sustituible por diseño.
Dos fail-safes: LOCAL-ONLY por defecto y **gate de ceguera** que rehusaría
exportar cualquier contenido con `escrivivir-co/` — coherente con §2.

---

## 4 · Rooms / node-red / Ciudad — el concepto a mejorar

### 4.1 Lo que hay hoy (layer 1 + layer 2 con secreto compartido)

Modelo actual: **un secreto estático publicado** → `curl | bash` → contribs de
Node-RED → Socket.IO contra `rooms.scriptorium.escrivivir.co/runtime`.
⟨`pub/site/scriptorium/index.html:300-343`⟩

Problemas estructurales (no solo el secreto filtrado):

1. **Un secreto para todos**: no hay identidad por peer, ni revocación
   individual, ni ACL. Rotar = romper a todos los peers a la vez.
2. **Onboarding = `curl | bash`** desde cuenta y rama viejas.
3. **Un nodo ↔ un Socket.IO**: acoplamiento directo, sin esquema de Ciudad.

### 4.2 El contrato al que migrar (ya definido en nuestros skills)

| Pieza | Contrato | Fuente |
| ----- | -------- | ------ |
| Identidad | **peercard firmada**: `id`, `sig`, `issuedAt`, `features`; sin firma → falla cerrado | `operador-rooms/reference/peercard.md` |
| Autorización | **ACL deny-by-default**; lo no listado se deniega | `operador-rooms/reference/acl.md` |
| Salud | observable: `OK`/`DEGRADED`/`FAIL`; sin señal trazada **no** se declara OK | `operador-rooms/reference/salud.md` |
| Conexión al juego | `GAME_MCP` + peercard firmada + **kit desde el registry** (`player-mcp-kit`), prohibido sibling path | `estacion-viva/reference/GAME-MCP.md` |

**La mejora es exactamente esa sustitución**: shared-secret → peercard+ACL.
Encaja con "pub libre con 1000 invitaciones": el invite SSB reparte acceso a
*layer 1* (el pub), y la peercard gobierna *layer 2* (rooms/Ciudad), cada peer
con identidad propia y revocable.

**"Ciudad" no aparece en el repo** (0 coincidencias): el esquema vive en z-sdk.
Lo que sí tenemos aquí es el lado cliente del contrato. `<pendiente>`: el
esquema de Ciudad al que acoplarse.

### 4.3 ¿Se puede emular el VPS en local? — **Sí**

La topología ya está montada y probada en puertos alternos:

| Servicio | VPS | Local (`pub/.env.local.example`) |
| -------- | --- | ------------------------------- |
| SSB del pub | 8008 | **8009** (no choca con el cliente en 8008) |
| Web/Caddy | 80/443 | **8088/8443** |
| Panel API | 8787 | **8788** |
| Maint UI | 3000 (loopback) | **3001** |

`npm run pub:local:up` levanta el pub completo junto al cliente
(`oasis-client`) en la misma máquina, y `pub:local:join-client` ya automatiza
invite→follow-back entre ambos. La red `oasis_pub_net` existe en el compose
del pub, así que **un contenedor `rooms` local se puede añadir a esa red con
alias `scriptorium-rooms` y el Caddyfile funcionará sin tocar una línea** —
los upstreams se resuelven por alias de red, no por IP.

Lo único que falta para el ensayo completo en local: los contenedores
`scriptorium-*` (node-red, rooms) no están en este repo — hay que traerlos o
declarar un compose de emulación. `<pendiente>`: de qué repo salen.

---

## 5 · Sidecar de blobs — listo pero sin instalar

**Qué resuelve**: `blobs.max = 50 MB` ⟨`src/server/ssb_config.js:45`⟩ impide
ficheros grandes. El sidecar trocea en chunks de 5 MB, publica cada uno como
blob y un **manifiesto** cuyo cid identifica el objeto. Content-addressed,
sin cifrado ("la integridad ES el cid").

- **API**: `/x/blobstore/v0/{salud,objetos,objetos/:cid,estado/:cid,deseos}`,
  con `Range` (206/416). Cero dependencias, `node:http`.
- **Madurez**: **18 tests** verdes (núcleo + fachada HTTP). Cero TODOs.
- **Sin cobertura**: `cableado-sbot.mjs` y `servidor.mjs` (0 %) — justo lo que
  habla con el sbot real.

**Para instalarlo en el VPS faltan 4 cosas concretas:**

1. **Meterlo bajo `profiles: ["blobstore"]`** — si se pega tal cual en el
   compose, `pub/scripts/deploy.sh:16` (`up -d --build` sin servicios) lo
   arrastrará en **todos** los deploys.
2. **Declarar `BLOBSTORE_TOKEN`** en los `.env.*`: hoy no existe en ninguno, y
   sin él el servicio **arranca sin auth** (lo dice su propio log).
3. **Bajar `BLOBSTORE_MAX_TAMANO`** (default **1 GB**) — todo se procesa en
   memoria y el VPS tiene 4 GB.
4. **Montar solo el socket**, no `~/.ssb` entero: hoy el fragmento monta el
   directorio con el `secret` del pub en rw, y el contenedor corre como root.

Si se expone por Caddy (hoy no hay ruta), el token pasa de opcional a
**obligatorio** + `request_body max_size`.

---

## 6 · Panel API — lo que falta y lo que asusta

**Implementado**: `/health`, `/public/status`, `/public/network` (sin auth);
`/api/pub/{status,logs,restart}` (Bearer).

**Riesgo dominante — no es "una API de restart"**: monta `/var/run/docker.sock`
**rw sin proxy** ⟨`pub/docker-compose.pub.yml:52`⟩ y el proceso corre como root.
Quien controle ese proceso puede crear un contenedor privilegiado con `/:/host`
⇒ **root del VPS**. El propio `pub/BACKLOG.md:279` lo tiene anotado sin resolver.

**Dos correcciones a la documentación** (el README dice algo que el código no cumple):

1. El panel **no es loopback-only**: bindea `0.0.0.0` y el loopback lo pone
   Docker. Cualquier contenedor de `oasis_pub_net` — incluidos los
   `scriptorium-*` externos — alcanza `/api/*`. El token es la única defensa.
2. El **mTLS de Caddy declarado obligatorio antes de VPS**
   ⟨`pub/BACKLOG.md:234,241`⟩ **no está implementado**, y el pub ya está en VPS.

**Bug operativo concreto**: `/public/status` no cachea los fallos de invite, así
que **cada GET anónimo dispara un `docker exec invite.create 1000`** contra el
pub. Ruta pública vía Caddy ⇒ DoS trivial. Además el invite de 1000 usos se
publica sin auth y **su caché no expira nunca** (invite muerto sin detección).

**Pendiente del BACKLOG con lógica ya escrita**: endpoint de invites (existe
`getInvite()`, falta la ruta), métricas de disco, indicador de peers,
auditoría de acciones admin, alertas de caída.

---

## 6b · Mecanismo de upgrade — documentado pero **no cableado**

Versión actual: **0.8.8** ⟨`src/server/package.json`⟩.

### Las divergencias del fork (verificadas en código, no en doc)

| Fichero | Qué cambia | Ref |
| ------- | ---------- | --- |
| `src/backend/backend.js:7543` | `POST /update` ya no hace `git reset --hard && git pull` + `install.sh`: solo `console.warn` + redirect | ✅ |
| `src/backend/updater.js:98,111` | auto-update degradado a aviso | ✅ |
| `src/views/settings_view.js:58` | guard del botón de update en la UI | ✅ |
| `src/server/ssb_config.js:37-45` | `mergeDeep` + `OASIS_SERVER_CONFIG_OVERRIDE` + `blobs.max = 50 MB` forzado | ✅ |
| `src/configs/blockchain-cycle.json` | `{cycle:6, url:laplaza}` — **no lo lee ningún código**, solo `pub/scripts/deploy.sh:24` para el journal | ✅ |

**Quinta divergencia no listada como tal**: `src/configs/server-config.json:6`
contiene el **`caps.shs` del ciclo 6** — un dato de red **dentro de `src/`**,
justo la zona que el overlay sobrescribe con cada upgrade. Es un pie de banco:
si el overlay se aplica sin cuidado, el cap se pierde silenciosamente. También
lo lee `devops/scripts/upgrade-preflight.sh:35` para detectar drift de ciclo.

### El bloqueo

```
git remote -v  →  solo 'origin'
```

**El remote `oasis-upstream` no existe.** Todo el protocolo depende de él:
`upgrade-preflight.sh` (drift de versión), el overlay
(`git checkout oasis-upstream/master -- src/`) y la verificación de invariantes
(`git diff oasis-upstream/master --stat -- src/`). Hoy el mecanismo es
**documentación sin cableado**: no se puede ejecutar ni un paso.

Además el paso 2 exige **re-aplicar a mano** el guard de `backend.js` (fichero
de ~7500 líneas) tras cada overlay — el único guard que no se recupera con
`git checkout HEAD --`, porque su fichero cambia en cada release upstream.

### Para PRs al upstream (cuando el sidecar esté listo)

Clasificación de lo que tenemos:

| Divergencia | ¿Upstreamable? |
| ----------- | -------------- |
| Parche `ssb-blobs` (wantCallbacks) ⟨`docker-entrypoint.sh:124-178`⟩ | ✅ **sí** — bug genuino, no específico de Docker |
| Parche `multiserver` unix-socket (ENOENT en chmod) | ✅ **sí** — mismo caso |
| Parche `ssb-ref` (quitar `deprecate`) | 🔶 quizá — depende de su política de deprecación |
| `OASIS_SERVER_CONFIG_OVERRIDE` + `mergeDeep` | 🔶 útil a cualquiera que containerice |
| Guards de auto-update (4 ficheros) | ❌ **no** — solo-fork, decisión de despliegue |
| `blockchain-cycle.json`, `caps.shs` | ❌ no — datos de instancia |

Lo que faltaría montar (hoy no existe nada de esto): remote del upstream,
rama espejo, y una carpeta de parches exportados con registro de cuál es
upstreamable.

**Nota sobre los parches**: viven **duplicados** en dos sitios con caminos de
activación distintos —

- `docker-entrypoint.sh:90-206` (`apply_node_patches`) → **es el que corre en
  Docker**, en cada arranque del contenedor.
- `scripts/patch-node-modules.js` → invocado por
  `"postinstall"` de `src/server/package.json:21`, que el `Dockerfile:47`
  **neutraliza** con `npm install --ignore-scripts`. Solo actúa en bare-metal.

Es decir: la misma corrección mantenida dos veces, con solo una activa por
ruta de instalación. Para preparar un PR upstream habría que consolidarlas.

---

## 7 · Riesgos abiertos (ordenados)

| # | Riesgo | Evidencia | Acción |
| - | ------ | --------- | ------ |
| 1 | Docker socket = root del host tras un Bearer | `pub/docker-compose.pub.yml:52` | socket-proxy + mTLS |
| 2 | Token de rooms estuvo público (2 sitios) | saneados hoy; siguen en git history | **rotar en el servidor** |
| 3 | `curl \| bash` desde cuenta vieja en página pública | `pub/site/scriptorium/index.html:313` | reapuntar |
| 4 | DoS por invite no cacheado en fallo | `pub/panel-api/src/server.mjs:167-173` | cachear negativo + TTL |
| 5 | 17 enlaces a cuenta anulada (viola ceguera propia) | `pub/site/**` | migrar |
| 6 | CI depende de Verdaccio propio | `.github/workflows/docs.yml:34-38` | asumido, documentar |
| 7 | Datos de instancia versionados (IP, feedId, fingerprint) | `pub/BACKLOG.md:88-113` | mover a `devops/hosts/` |
| 8 | Upgrade no ejecutable: falta el remote `oasis-upstream` | `git remote -v` | añadir remote + rama espejo |
| 9 | `caps.shs` (dato de red) dentro de `src/`, zona de overlay | `src/configs/server-config.json:6` | sacarlo o blindarlo en el protocolo |

---

## 8 · Qué falta por decidir (`<pendiente>`)

- Esquema de **Ciudad** al que acoplar la conexión de nodos (vive en z-sdk).
- De qué repo salen los contenedores `scriptorium-*` para emular en local.
- Reparto **zeus vs o-sdk**: qué queda aquí (rol pub, edge, sidecar SSB) y qué
  sube al pack (Ciudad, rooms, node-red contribs, registry).
- Nombre definitivo del scope (`@zeus` declarado y sin usar; `z-sdk` inexistente).
- Destino de `docs/public/legacy.html` (congelar o migrar; hoy viola ceguera).
