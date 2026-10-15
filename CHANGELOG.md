# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es/1.0.0/).
Web &amp; docs: <https://o-sdk.escrivivir.co> · Código: <https://github.com/alephscriptorium-eng/O_SDK>

## [Unreleased]

### Changed — El cliente cablea la config viva de Oasis ≥ 1.2.4 (WP-O145, 2026-10-15)

Preparación del cliente real para 1.2.2 → 1.3.0 (misma imagen que el pub, WP-O141). Desde 1.2.4 `config-manager.js` lee
y escribe `~/.ssb/oasis/oasis-config.json` y de `src/configs/oasis-config.json` solo copia una vez; el symlink de WP-O103
daba dos verdades (medido en el drill de 1.2.5). Ahora **la config viva es ese fichero** (en el host
`volumes-dev/ssb-data/oasis/oasis-config.json`, 600, regular: `saveConfig` escribe por `rename`), y
`volumes-dev/client-state/oasis-config.json` queda como **legado de solo lectura** (sembró la viva una vez; se retira en
un WP posterior). Drill con identidad desechable en verde; **el cliente real sigue en 1.2.2** hasta el GO.

- `docker-entrypoint.sh`: `persist_client_state` siembra la viva (default de la imagen + legado, gana el legado) o la
  funde (default + viva, gana lo vivo), en todos los modos (también `server`, para `sync-only.sh`); repone el default en
  `src/configs` si quedó un enlace; con backend `OASIS_CONFIG_FILE` apunta a la viva, así `wire_wallet_config` («el
  entorno manda») y `setup_oasis_config` escriben donde lee la GUI. HUB y bot no cambian (bind `:ro` en el sitio nuevo).
- `client:ecoin:verify`: V4 lee la viva; V5 exige viva regular a 600, `src/configs` sin enlace, legado presente.
- CLIENT-PROTOCOL §4 reescrito (dónde vive la config, receta con retag antes del build y copia en frío, **delta
  declarado del cliente** `oasisVersion+1 about+1 karmaScore+0..1` medido con `count-feed-type.js`, salto de motor ya
  pasado); §6 salvedad al volver por retag a ≤ 1.2.3; §8.3/§8.4/§8.8; drill D10-D14.
- **Secreto**: la viva lleva `wallet.user/pass` y viaja con cualquier copia de `ssb-data` (el backup de la GUI la
  excluye: `NOT_BACKED_UP`, `src/models/backup_model.js`).

### Fixed — Restos del host tras O143 (WP-O144, 2026-10-15)

El entrypoint llevaba un `\r` literal dentro de las comillas de un `tr -d` (l.393-394): ahora `tr -d ' \n\r'`, sin bytes
invisibles (una tubería que filtre CR lo dejaba un byte distinto y convertía ese `tr` en un no-op). En el host: ese
fichero y `tools/ssb-admin.js` convergidos al blob de HEAD, y el pub recreado en la imagen actual (misma versión, Δ0):
los tres nodos «imagen al día».

### Added — Enlace garantizado de los nodos de soporte con el pub (WP-O143, D-O38, 2026-10-15)

**Aplicado en el host el 2026-10-15** (GO-1 … GO-3): compose, los tres `ssb-config`, el entrypoint y `tools/` in place
(sha del vivo comprobado antes de pisar); imagen `8639c5f9…` con `SMOKE OK`; `link pub` (el pub abrió el enlace con el
HUB, que no tenía visto desde su lado); HUB y bot recreados con el keepalive: **Δ0 en los tres nodos**, `pub_link=connected`
medido en cada `check`. Dos tropiezos del operador, contados en el reporte: el primer build salió sin keepalive porque
el entrypoint y `tools/` no estaban en «qué viaja» (ahora sí, UPGRADE §3.2), y una tubería que filtraba `\r` dejó el
entrypoint un byte distinto (el fichero lleva un `\r` literal intencional): el sha lo paró y se reescribió con el blob tal cual.

Lo que lo motivó: en el ciclo 1.3.0 la precondición de `hub-wallet.sh on` destapó que el sbot del bot de cartera llevaba
desde 2026-10-14T23:02Z sin conectar con el pub (hasta 2026-10-15T14:55Z, forzado por RPC con GO), con `conn.json` sano
y TCP en orden. Causa medida: `ssb-conn` mantiene **4 plazas salientes** por nodo (`conn-scheduler.js:316-317`; las
entrantes no cuentan), las llena por `oasisPeerRank` y rota ~2 h/√N (`network_pause.js:75-90`); `autoconnect` solo
filtra, no hay par prioritario, y `pub: true` marca `autoconnect` a todo pub conocido (`syncPeerBook`). Medido: bot
17 pubs / 17 autoconnect / 4 salientes; HUB 12 / 9 / 4; pub 19 / 17 y 1 saliente.

- **El enlace se mide**: `peers` y `pub_link` (`connected in|out` · `ausente` · `?`) en la foto de `upgrade-gates.sh`
  y criterio del `check` para `GATE_LINK_NODES` (`?` NO MEDIBLE; `ausente` «todavía no» con `--wait`, DESVIACIÓN al
  tope); `hub-wallet.sh status` línea `pares:` y `ready` por `conn.peers()` del bot, no por el log del pub;
  `deploy-status.sh` líneas `LINK`. Sonda `ssb-probe.js` con `peers[]` (inbound, failure) y `link` por clave.
- **Dos capas, homogéneas para HUB y bot**: el pub guarda a sus nodos sin `autoconnect` y conecta solo con el que no tenga el enlace (`upgrade-gates.sh link pub --yes`: conexión
  entrante que no gasta su cupo) y el entrypoint repone el enlace cada 60 s (`start_pub_link`, `pub/tools/pub-link.js
  --ensure`; `OASIS_PUB_LINK_HOST` por defecto `oasis-pub`, vacío = desactivado; `OASIS_PUB_LINK_EVERY_S` 60,
  `OASIS_PUB_LINK_FIRST_S` 30, `OASIS_PUB_LINK_ADDR` opcional). Log `[pub-link]` solo en cambios de estado; 0
  publicaciones; el healthcheck no cambia.
- `conn.populatePubs: false` en los `ssb-config` del HUB y del bot (×3): no se descubren pubs nuevos; los conocidos siguen.
- Subcomando `upgrade-gates.sh link <alias> [--yes]` (permitido en `--remote` con `--yes`): restablece y vuelve a
  medir; `alias = pub` carga la libreta del pub. UPGRADE §4 pasos 8-9: si el `check --wait` deja `ausente`, `link`
  con GO; nunca un `on` a ciegas.
- `hub-conn-fix.js` retirado (D-O37): subsumido en `pub-link.js --forget-seeded/--remember/--connect`. Invariantes
  nuevos `upgrade-invariants.d/link.tsv` (cupo, `inbound`, `oasisPeerRank`, `populatePubs`, `start_pub_link`).
- Protocolos: UPGRADE §0.2, §3.4, §4, §6; HUB §2, §3, §5, §11; ECOIN §2, §3, §9, §14; AGENTES §4 (trampa nueva).

### Changed — Oasis 1.3.0 en pub, HUB y bot de cartera (WP-O141, 2026-10-15)

Salto 1.2.8 → 1.3.0 (1.2.9 dentro), sin cambio de motor; primer ciclo con el protocolo v3 (WP-O140). Overlay limpio
desde `37e0fc93`; 7 guards repuestos (uno con conflicto, resuelto); invariante de 7 ficheros. **El quinto guard cambia
de fichero**: upstream borra `snh-invite-code.json` y lee la entrada 0 de `invite-codes.json` (`defaultInvite()`): solo
`url`, el código de SNH se conserva (D-O22, nota). Gates locales U0-U7 y US en verde (`up` ×3 en 23 s, `check --wait`
en 70 s). Host con GO por paso: pub `oasisVersion+1`; HUB `oasisVersion+1`; bot `oasisVersion+1 karmaScore+1`; nada más.

- **1.3.0 trae un tipo nuevo, `pub-invites`**: un backend con `pub: true` anuncia a los 60 s y cada 24 h el uso de sus
  invites (`pub_invites.announce`), solo si ha creado alguno. No se declaró y no salió (ni en local ni en el host).
- `TRIBE_LOG_TYPES` incluye ya `tribe-open-invite` (la trampa de 1.2.5-1.2.8 queda acotada).
- Tropiezos del operador, contados en el reporte: el compose del host se escribió in place sin parar ante un sha que no
  era el esperado (el `.bak` y el diff previo lo cubrían); el encadenado de GO-4b siguió tras un `hub-wallet.sh on`
  abortado y el journal registró `wallet-engine-on` con el motor apagado (línea correctora añadida). Regla nueva en
  UPGRADE §6 del reporte: un comando por paso también para el operador.
- **Hallazgo previo al ciclo**: el sbot del bot llevaba desde el 14 sin conectar con nuestro pub (sí con cuatro pubs
  externos); lo destapó la precondición de `hub-wallet.sh on`. Se forzó por RPC (`conn.connect`) con GO y el motor
  volvió a encenderse. Backlog: WP-O143.

### Changed — Protocolo de upgrade v3: los gates miden en vez de dormir (WP-O140, 2026-10-15)

- `upgrade-gates.sh check --wait`: repite la foto hasta que el delta es el esperado **y** el `sequence` lleva 60 s
  quieto; verde solo por estabilidad, nunca por tiempo (una desviación firme corta en la primera vuelta; agotado el
  tope, DESVIACIÓN). `--min-age` (300 en el host) sustituye la regla de «5 minutos» contada a mano. `up` ya no duerme
  90 s por nodo; `worst` pierde su `sleep`.
- `smoke <imagen>`: humo de la imagen con contenedores efímeros (0 `secret`, nada del fork en `/app`, socket del sbot,
  `GET /c` = 200, 3 parches, 0 errores) en local y en el host; sustituye la receta a mano de U2 y del paso 6.
- `expect.conf`: el delta esperado vigente, leído por `check` cuando no se pasa `--expect` (el «normal» del protocolo
  se había quedado sin `karmaScore` ni `about`).
- `upgrade-behaviour-diff.sh --check --from-tsv`: de minutos a 2,4 s; `--skip`; un solo `git diff` compartido.
- `start_interval: 3s` en los healthchecks de pub, HUB y bot (Engine ≥ 25; `deploy-status.sh` lo imprime). Medido
  en local: `healthy` a los 4 s, `up` de los tres nodos en 25 s, `check --wait` verde en 75 s (antes ≈ 7 min).
- Invariantes nuevos `pub.tsv` (guards del pub) y `client.tsv`; `snapshot.tsv`; `--help` entero en los tres scripts.
- `UPGRADE-PROTOCOL.md`: el cuerpo en presente y la historia en §7 (completa, ordenada, con el ciclo 1.3.0 que viene);
  tabla «delta vigente»; tabla de variables de los gates. La historia de la receta v0 del HUB pasa a `HUB-PROTOCOL.md` §0.

### Removed — Documentos de entrada superados: `MAPA.md`, `PLAN.md`, `next-steps.md`, `docs/CHANGELOG.md` (WP-O139, D-O37, 2026-10-15)

Criterio nuevo (D-O37): un documento obsoleto se retira, no se marca; git ya archiva. `MAPA.md` describía julio
(Oasis 0.8.8, «no existe `oasis-upstream`», 4 guards) y se presentaba como estado real; su función vive en
`deploy-status.sh`, `docs/AGENTES.md`, `plan/BACKLOG.md` y `pub/site/scriptorium/estado.md`. `PLAN.md` estaba
superado por el backlog; `next-steps.md` era un transcript de ChatGPT sobre Radicle (D-O3); `docs/CHANGELOG.md`
era el changelog de upstream congelado en v0.7.4. También `scripts/check-docker-context.sh` (sin consumidor) y el
npm `pub:local:retro-bot:up` (arrancaba el nodo deprecated, D-O36). Las citas `MAPA.md:n` de los dosieres se leen
con `git show`.

### Changed — Un solo recuento de guards, tres modos, Habitante en las tablas, retro una vez (WP-O139)

- Frase canónica (D-O37): «7 guards en 6 ficheros; con `blockchain-cycle.json` el invariante es de 7 ficheros».
  README decía 5, BASE-2 5, MAPA 4. «Misma imagen, dos modos» → tres (`full`, `server`, `backend`). Upstream es
  `epsylon/oasis` también en BASE-1.
- `docs/AGENTES.md`: la puerta Habitante entra en la tabla de §0; la política del invite público pasa a
  `roles/habitante.md`; la deprecación del retro se dice en §2.9 y §3 y §5 solo la cita. La ficha de instancia
  deja de escribir tres versiones y se queda con la del journal («el estado presente se mide»).
- `plan/BACKLOG.md` al día: once WPs fusionados que figuraban sin estado o «pendiente de merge»; O80/O77 absorbidos
  por O112/O127; WP-O03 cerrado; altas WP-O139 … WP-O142. D-O34/D-O35 señaladas en su rama.
- Higiene: `ARCHIVO/DISCO/26sm-exported/` (124 MB de Canva) ignorado en `main` con las reglas de su rama;
  `ARCHIVO/README` completo; `BASE-1/2/3` enlazados desde `docs/proyecto.md`.

### Changed — Oasis 1.2.8 en pub, HUB y bot de cartera (WP-O138, 2026-10-11)

Salto 1.2.5 → 1.2.8 (1.2.6 y 1.2.7 dentro), sin cambio de motor. Overlay limpio desde `28fc1a68` y los 7 guards
repuestos sin conflictos (`git diff 28fc1a68 --stat -- src/`: 7 ficheros, el mismo diff que en 1.2.5). Solo viaja
`src/`. Gates locales U0-U7 y US en verde; en el host, GO por nodo: pub `oasisVersion+1`; HUB `oasisVersion+1` y
`karmaScore+1`; bot `oasisVersion+1`, `karmaScore+1` y `about+1`, todo declarado antes de tocar el servidor.

- **Desde 1.2.6 un backend publica solo su `karmaScore`** (upstream mueve la llamada de `GET /activity` al
  refresco de fondo, que arranca a los 5 s): lo destapó el gate U3 en el HUB. Aceptado por el custodio y declarado
  `karmaScore=+0..1` en HUB y bots (UPGRADE §3.4, AGENTES §4).
- Índice nuevo de db2 en todo sbot (`oasisActivity`); no migra el log.
- El reequilibrio de RBU entre pubs pierde el tope de 200 ECO por época y reparte hacia la media: sin efecto con
  el pool a 0, **decisión pendiente antes de la dote** (reporte, H2).

### Changed — El bot nº 3 (`retro.escrivivir.co`) queda DEPRECATED (D-O36, 2026-10-12)

No se arranca, no se recrea, no se sube de versión y no siembra; su identidad se conserva apagada en
`volumes-real/` y no se borra. La baja no constaba en ningún documento (D-O33 lo dejaba «mudado» y vivo): queda
asentada en `plan/DECISIONES.md` y marcada en AGENTES §2.9/§3/§5, la ficha de instancia, TEMPLATE §4.5 y
UPGRADE §0.2. La vía caliente y el servicio `oasis-retro-bot` siguen como método (otra instancia, drills).

### Fixed — `volumes-real/` fuera del contexto de build (WP-O138)

`.dockerignore` no excluía la carpeta del nodo real de la máquina operadora (D-O33): el primer build local posterior
metió en la imagen el `ssb-data` del bot retro, `secret` incluido. Lo cazó el humo de U2 antes de arrancar ningún
contenedor; la imagen no salió de la máquina y se reconstruyó limpia. El humo de U2 comprueba ahora 0 `secret`.

### Changed — Bot retro: mudado del VPS a la máquina operadora; Campamento deshecha; deshacer de siembras (WP-O135, D-O33, 2026-10-10)

En lugar de subir el bot nº 3 a 1.2.5 en el host, el custodio decide **mudarlo**: su identidad íntegra (`secret`,
keyring, log completo seq 150, blobs) sale del VPS parada, se verifica con sha256 por fichero y lectura del log en
frío, arranca en el `oasis-pub-retro-bot` local sobre `volumes-real/` (fuera de los drills; `.gitignore`,
`upgrade-gates.sh`, `lib-node.sh`, `capacity.sh` y `host.env` lo saben) y publica solo su `oasisVersion` 1.2.5, que el
pub acepta como continuación (seq 151); contenedor, bloque de env y datos salen del host con pub, HUB y bot Δ0.
Después, **deshacer de la siembra de Campamento**: nuevo `pub/tools/seed-tombstone.js` (+ `pub/scripts/retro-tombstone.sh`,
`npm run pub:local:retro-bot:tombstone`): dry-run por defecto, `--yes` por bloque en orden hojas → raíces, gates
(autora del ledger, no el pub, pub conectado), ledger propio reejecutable, `--skip` con motivo, evidencia por bloque;
115 retiradas en 11 bloques, bloque a bloque con el custodio; dos listas CLOSED privadas (un miembro) quedan.
Método nuevo: TEMPLATE §9 («Deshacer una siembra») y HUB §11 («Mudanza o baja de un bot»); evidencia en
`ARCHIVO/DISCO/scriptorium-exported/` (`runbook-mudanza.md`, `runbook-tombstone.md`, `vps/tombstone-o135.jsonl`,
`vps/ledger-tombstones.json`), que pasa a ser el sistema de deshacer de la siembra. Nada del repo se borra: el
servicio del compose, sus variables y `retro-seed.sh` quedan como receta, marcados «mudado». Hallazgos de upstream
1.2.5: `TRIBE_LOG_TYPES` sin `tribe-open-invite`; `deleteCalendarById` no desenvuelve sobres de tribu;
`mailing_model` no indexa listas CLOSED por el socket; las rutas de detalle de `/c` no filtran tombstones.
`capacity.sh` corregido (leía `blobCache` del sitio de antes de 1.2.4).

### Changed — Upgrade a Oasis 1.2.5, aplicado en el host; séptimo guard (WP-O135, D-O31, D-O32, 2026-10-10)

Rama `upgrade/oasis-1.2.5`: overlay de upstream 560580d7 (1.2.3 → 1.2.5, la 1.2.4 dentro del salto) con los
guards repuestos (`blobs.max` sigue en 50 MB frente a los 75 de upstream). Lo que el diff de comportamiento obligó a
adaptar: desde 1.2.4 `config-manager.js` lee `~/.ssb/oasis/oasis-config.json` (el de `src/configs/` solo se copia
una vez), así que el bind `:ro` del HUB y del bot de cartera va al sitio nuevo; el sbot deja de cargar
`ssb-gossip`/`ssb-friend-pub`/`ssb-plugins`/`ssb-partial-replication` y los cinco `ssb-config` pierden el bloque
`gossip`. **Séptimo guard** (D-O31, una línea en `backend.js`): `/c/blob` vuelve a pedir a la red (`getResolved`)
los blobs que la lista blanca `clearnetBlobAllowed` de upstream admite; sin él, lo publicado tras el upgrade no
tendría imágenes en `/c`. D-O32: se acepta el modelo de confianza de pubs de Banking de 1.2.4 (un habitante solo ve
bancos de los que redimió invite) y el cliente sigue en 1.2.2 hasta su WP. Documentado: token de admin por arranque
con `OASIS_ALLOW_HOST`, `chmod 700` del `.ssb`, `syncPeerBook`. 184 disposiciones y **gates U0-U7 + US en verde**
con cuatro nodos (`oasisVersion+1` por nodo y nada más, repetible; invite completo; guard medido) en
`plan/REPORTES/WP-O135-upgrade-oasis-1.2.5.md`. **Host pendiente** (GO por nodo).

### Fixed/Added — Visor `/c`: idioma por petición y selector de tema, sexto guard (WP-O132, 2026-10-08)

El idioma del visor era una variable global del proceso y el selector podía salir en el idioma de
otra petición concurrente (medido en el host: 6 de 18). Guard D-O30 en `src/views/clearnet_view.js`
y `src/backend/backend.js`: el idioma resuelto va al scope de la petición y se re-afirma antes del
render; `?theme=` (Dark, Clear, Matrix, Purple) con selector junto al de idioma; `lang` y `theme`
viajan en todos los enlaces y formularios de `/c`. Gate `upgrade-gates.sh hub --strict` ampliado
(6 idiomas × 3 tandas, tema, cruce de temas); invariantes en `hub.tsv`; UPGRADE §2 pasa a 7
ficheros. Defaults intactos (config del HUB, D-O25). **Desplegado el 2026-10-08** en el HUB de la demo (solo ese nodo,
misma versión, nadie publicó nada); reporte `plan/REPORTES/WP-O132-visor-idioma-tema.md`.

### Added — Vía caliente de plantillas: bot retro, kit visual y guía de reparto (WP-O131, 2026-10-08)

Rama `dev/scriptorium-exported`. `pub/tools/template-seed.js --hot` siembra una plantilla desde el bot
secretaría (`oasis-retro-bot`, bot nº 3 `retro.escrivivir.co`, modo `server`) por su socket, con dry-run,
`--yes` por bloque, bloque nuevo `clearnet` (sin `clearnetItem` nada sale en `/c`), ledger y evidencia
antes/después; `--reparto` genera la guía de reparto de accesos (una fuente, tres salidas: dosier, wiki en
Oasis, Sala 02 del sitio; sin códigos); `pub/tools/template-kit.py` genera un PNG por objeto (determinista,
blob id previsto en `manifest.json`); plantilla genérica `pub/templates/campamento.json` derivada por script
de la de Acampada26S; `ssb-admin.js publish-about --image`. Campos nuevos en `SCHEMA.md`: `image`,
`clearnetPublic`, `responsable`, `meta.reparto`. Devops: el cuarto nodo en `upgrade-gates`, `capacity`,
`lib-node`, `deploy-status`. Docs: TEMPLATE-PROTOCOL §4.3-§4.6, HUB §11-§12, fichas, AGENTES §5,
roles/pub, nav del sitio. Dosier: `ARCHIVO/DISCO/scriptorium-exported/`. **Drill local ejecutado**
(146 mensajes en 10 bloques, `/c` del HUB con lo marcado, 12 hallazgos y 7 correcciones:
`plan/REPORTES/WP-O131-retro-bot-via-caliente.md`). **Desplegado el 2026-10-08**: bot nº 3
`retro.escrivivir.co` dado de alta en `pub.escrivivir.co` y la plantilla Campamento sembrada (148 mensajes del
bot, el pub solo su `contact`), guía de reparto con enlaces reales en la Sala 02; mapa de entrada a la
exposición publicado por el bot como entrada de Blog (DRY: enlaza lo que ya existe, sin wiki nueva). D-O29.
Mergeado a `main` el 2026-10-08; la web vuelve a desplegarse (CI roto desde WP-O127) y pasa el gate de ceguera.

### Changed — Oasis 1.2.3 en local y en el host (WP-O128, 2026-10-07)

Reporte `plan/REPORTES/WP-O128-upgrade-oasis-1.2.3.md`. **Desplegado el 2026-10-07**: pub, HUB y bot en
1.2.3, mismo delta que en local (`oasisVersion` +1 por nodo y nada más); rollbacks de 1.1.10 y 1.2.1
retirados (`/` del 54 % al 35 %); `test-invite.sh` corregido para el layout del host. Upstream
`043f4634` «Oasis release 1.2.3»: `backend.js` +1354/−261 (textos largos troceados, borrados con
`tombstone`, contenido de tribus al clearnet, siete rutas de detalle nuevas bajo `/c/`), mapas
reescritos (SVG y teselas JPG), `opusscript` y buzón de voz en la centralita, ranking de pares por
versión en el sbot, `outgoing.onion` abierto por defecto (los tres nodos del pub lo dejan en `[]`:
DECISIÓN del custodio). Overlay con los 5 guards (solo `backend.js` había cambiado), 129 líneas del
diff dispuestas, 0 parches de upstream pendientes en lo vendorizado. Delta medido dos veces:
`oasisVersion` +1 por nodo y nada más; el `about` de `clearnetSince` que el código anuncia no sale
(falla a los 3 s y se reintenta en cada arranque: `about=+0..1` en el bot desde ahora). U6 completo
en local por primera vez (invite redimido por un nodo desechable: el pub publica un `contact`).
`.dockerignore` excluye `ARCHIVO/**`. Correcciones: UPGRADE §0.4, §3.4, §7; HUB §5.2; AGENTES §4;
`upgrade-behaviour-diff.sh` colapsa activos en `files`.

### Changed — Protocolo de upgrade: medir lo que se afirmaba de memoria (WP-O127, 2026-10-07)

Antes del ciclo 1.2.3. `upgrade-preflight.sh` resuelve `NEW_REF` como el commit «Oasis release
X.Y.Z» (no la punta de la rama; `--to` para una intermedia), toma la versión desplegada del último
registro del pub y cuenta aparte los activos. Nuevo `upgrade-patches-audit.js`: ejecuta en seco el
`scripts/patch-node-modules.js` de upstream sobre `src/base` y dice por parche si lo vendorizado lo
trae (sección `patches` del diff de comportamiento; la copia del fork de ese script era la de
1.2.1). Los gates remotos leen la raíz de datos de `host.env` (`REMOTE_DATA_ROOT`; `GATE_NODES` y
`HUB_CACHE_CONTAINER` opcionales). El `--check` del diff exige las seis cabeceras del reporte de
ciclo. El cliente se apunta en el journal. `UPGRADE-PROTOCOL.md` §0.2, §1, §2, §3.1, §3.3, §4, §7;
`AGENTES.md` §4 (dos trampas).

### Added — Puerta «Habitante» y web al día tras los upgrades (WP-O125, 2026-10-05)

Sexta puerta del portal, para quien solo quiere entrar en la red con su móvil: el manual de
bienvenida de la red (`docs/habitante/manual.md`, de `ARCHIVO/DISCO/onboarding-sol-es.md`), lo que
cambia con este SDK (`docs/roles/habitante.md`) y la hoja de la casa
(`docs/PUB/INSTANCIA-SCRIPTORIUM-HABITANTE.md`), cada una con su etiqueta. Queda escrito para
agentes cómo entra un habitante: la portada del pub publica un invite de muchos usos. Al día lo
que los upgrades dejaron viejo en el portal, el README y el sitio del pub (db2 donde decía flume,
17 tipos, cliente real en 1.2.2, nombres de los nodos). `publish-profile.sh` exige el nombre.

### Changed — Oasis 1.2.2: Phone y Rooms, en el host y en el cliente (WP-O124, 2026-10-05)

Reporte `plan/REPORTES/WP-O124-upgrade-oasis-1.2.2.md`. **Desplegado el 2026-10-05**: pub, HUB y bot en 1.2.2. Al subir, HUB y bot publican un `about` cada uno (`visibilityPrefs.phone = off`). El pub pasa a llamarse `pub.escrivivir.co`. Upstream añade un plugin `phone` al sbot: llamadas y salas de voz cifradas extremo a
extremo, con los pubs de relé. La centralita se queda en el pub, acotada desde su ssb-config
(`phone`: relé solo para feeds que sigue, aforo de sala 12), y apagada en HUB y bots
(`regen-node-configs.js`). Invariantes en `upgrade-invariants.d/phone.tsv`; `HUB-PROTOCOL.md` §14,
`CAPACIDAD.md` §4.

### Changed — Oasis 1.2.1 en local: motor db2, dependencias vendorizadas (WP-O119 a WP-O122, 2026-10-04)

Reportes `plan/REPORTES/WP-O119-medida-db2.md`, `WP-O120-upgrade-oasis-1.2.1.md`,
`WP-O121-capacidad.md`, `WP-O122-snapshots-pub.md`. Asiento D-O27. **Desplegado el 2026-10-04**
(WP-O123, `plan/REPORTES/WP-O123-aplicacion-vps-1.2.1.md`): pub, HUB y bot en 1.2.1; cada nodo publicó
su `oasisVersion` y el bot, además, un `pubAvailability`.

- **`src/` es Oasis 1.2.1** (upstream `942d39c9`). Cambia el motor de base de datos (`ssb-db`/flume →
  `ssb-db2`): el primer arranque migra el log, borra el viejo y deja una guarda. **No hay rollback
  tras migrar** (`UPGRADE-PROTOCOL.md` §0.5).
- **`src/base/node_modules`** entra en el repo (dependencias que upstream vendoriza: 19 145
  ficheros). La imagen no instala nada: `Dockerfile` con Node 22, enlace a `src/base` e IA por
  `ARG OASIS_AI=none|nav|full`. La imagen del pub pasa de 4,46 GB a 1,58 GB.
- **Guards**: los cinco de siempre y un segundo edit en `backend.js`, `OASIS_SNAPSHOT=off`.
- **Medida** (`lib-node.sh`, `pub/tools/log-bipf.js`, `ssb-probe.js`, `upgrade-gates.sh`): lee el log
  en flume o en db2; lo ilegible es «no medible», no 0. Gates nuevos: UM (migración), UR
  (no-retorno), US (snapshot).
- **Snapshots**: el pub construye el suyo (`pub/tools/snapshot-build.js`,
  `devops/scripts/pub-snapshot.sh`); HUB y bots, apagados.
- **Capacidad**: `devops/scripts/capacity.sh` y `docs/PUB/CAPACIDAD.md`; límite de memoria y
  rotación de logs del pub; techo de blobs en HUB y bot; poda de blobs del pub.
- **Visor**: `/c/files/<id>` (Files); 17 tipos en la Sala 04.
- **Cliente**: `import-identity.sh`, `sync-only.sh` y los lectores de log aceptan los dos formatos.

### Added — Portal: puertas por rol con estado medido (WP-O115, 2026-10-01)

Reporte `plan/REPORTES/WP-O115-portal-roles.md`. Asiento D-O26.

- **«¿Quién llega?»** (`docs/roles/`): cliente, pub, economía, «hazlo tuyo» y mantener. Cada página
  es la receta que lee el agente: el encargo literal, lo que hace falta, los pasos con sus puntos de
  DECISIÓN y PERMISO, y un **sello** por encargo (`probado en frío` · `ejercido en la demo` ·
  `en obras`). Hoy ninguno está probado en frío; nueve están ejercidos en la demo y uno, la
  instancia propia, en obras (WP-O117).
- **`docs/AGENTES.md` §0** «¿Quién te manda?» y `AGENTS.md`: el agente entra por la receta de la puerta.
- **`docs/PUB/INSTANCIA-PLANTILLA.md`**: ficha de instancia vacía. La demo no es requisito de nada.
- **Portada**: sección de puertas; «Empezar» pasa a «Llévatela» (encargo al agente o a mano), con
  el aviso de que hoy el cliente pide GPU NVIDIA. La versión de Oasis se lee de
  `src/server/package.json`. **Banner** al día, con la misma voz.
- **Gate** `npm run docs:verificar`, también en CI: enlaces y anclas, verdad de contenido
  (`docs/.vitepress/verdad-checks.json`), piel, contraste y ceguera por ámbito
  (`devops/scripts/docs-ceguera.sh`).
- **Deja de publicarse** `legacy.html` (enlazaba a la cuenta anulada y cargaba fuentes de terceros);
  queda en `ARCHIVO/portal/`. El resto de URL se conserva.

### Changed — Oasis 1.1.10 desplegado en el pub (WP-O114, 2026-10-01)

Reporte `plan/REPORTES/WP-O114-aplicacion-vps-1.1.10.md`. Pub, HUB y bot de cartera en 1.1.10 con
el motor de RBU encendido; cada nodo publicó un `oasisVersion` y nada más. Visor clearnet en
español por defecto, con sitemap y RSS. El `.env.prod` deja de entrar en la imagen del host.

### Changed — Oasis 1.1.10 (WP-O113, 2026-10-01; en local)

Reporte `plan/REPORTES/WP-O113-upgrade-oasis-1.1.10.md`. Primera ejecución del protocolo de WP-O112.

- **`src/` en Oasis 1.1.10** (upstream `f770dbb`) con los 5 guards.
- **HUB clearnet** (D-O25): nginx no reenvía `Accept-Language` ni `Cookie` al HUB; `language` y
  `themes.current` fijadas en su config; `/c/sitemap.xml` y `/c/rss/<tipo>` publicados con URLs `https`.
- **Nodos de soporte sin mensajes cifrados a sí mismos**: `inboxMutedBots` en la config del HUB y
  del bot de cartera. `pub/scripts/regen-node-configs.js` regenera las dos copias desde la de upstream.
- **Cliente**: `client/scripts/test-ai-service.sh` habla el contrato de IA de 1.1.10 (token por
  sesión, puerto variable).
- **Documentado**: «desconectar cartera» publica un `wallet` vacío (`docs/AGENTES.md` §3); `GET /wallet`
  en un bot con el motor encendido republica la dirección (§4); el primer `GET /banking` de un nodo con
  cartera ya publica la dirección (`docs/PUB/ECOIN-PROTOCOL.md` §3).

### Changed — Protocolo de upgrade: mide comportamiento y publicación (WP-O112, 2026-10-01)

Reporte `plan/REPORTES/WP-O112-protocolo-upgrade.md`. Asiento D-O25.

- **`docs/PUB/UPGRADE-PROTOCOL.md` orquesta el ciclo entero**: riesgo por rol (el pub en modo `server`
  solo ejecuta `src/server/`), inventario de piezas, diff de comportamiento con disposición obligatoria,
  derivados fuera de `src/`, gates locales U0-U7 y deploy pub → HUB → bot con puertas de GO. HUB §5 y
  ECOIN §5 quedan como anexos.
- **`devops/scripts/upgrade-behaviour-diff.sh`** (`npm run devops:upgrade:diff`): candidatos a cambio
  de comportamiento entre dos versiones de upstream (rutas, publicación, temporizadores, cabeceras,
  entorno, estado, config, dependencias) con ID estable y `--check` contra el reporte. Los greps de
  los anexos pasan a `upgrade-invariants.d/*.tsv`.
- **`devops/scripts/upgrade-gates.sh`** (`npm run devops:upgrade:gates`): qué publica cada nodo al
  subir (Δ`sequence` propio == suma de Δ por tipo, cifrados incluidos, frente a un delta declarado) y
  matriz del visor por delante de la caché. Contra el host, solo lectura.
- **`devops/scripts/deploy-status.sh`**: versión de Oasis por contenedor, modo, deriva de los ficheros
  del host frente al repo y restos de rollback. **`upgrade-preflight.sh`**: `OLD_REF`/`NEW_REF` y
  ficheros por rol. **`host.env`**: layout medido (ya no hay que exportar `REMOTE_REPO_DIR`).
- **Lo que no se sabía**: un upgrade publica un `oasisVersion` por nodo (también el pub) y un rollback también
  (`docs/AGENTES.md` §3); el control «cero `private`» era vacío y el HUB tiene 4 cifrados propios.

### Fixed — Documentación (WP-O112)

- `docs/CLIENT-PROTOCOL.md`: fuera las secciones §0-§8 duplicadas y el aviso caducado de 1.1.4.
- «5 guards» en todos los protocolos; `walletPub` fuera de las comprobaciones; `mv src src.old` del
  deploy, que con un `src.old` existente metía `src` dentro.

### Added — Roadmap: dosier P2P (WP-O110, planificado; 2026-09-19)

- `docs/ROADMAP/p2p/`: el soporte nativo de Oasis a torrents (catálogo SSB, sin siembra), las
  opciones miradas (semilla web BEP 19, aMule 3.0.1/Kad, metalink; IPFS y otras descartadas), la
  extensión del pub (artefactos por generación, fichas P2P, semillas opcionales, **cartelera**) y
  el plan aprobado, verbatim.
- `scripts/roadmap-import.py --only <slug>`: reimporta un dosier sin tocar los demás ni `index.md`.

### Fixed — La GUI del cliente dockerizado daba 403 en Banking (2026-09-19)

- **Puente de loopback** en `docker-entrypoint.sh` (`OASIS_LOOPBACK_PROXY_PORT`) y GUI publicada como
  `127.0.0.1:3000:3001`: Oasis exige que Banking, Wallet y Settings lleguen desde el loopback. Sin tocar `src/`.
  `docs/CLIENT-PROTOCOL.md` §8.10; trampa en `docs/AGENTES.md` §4; hallazgo para upstream en ECOIN §12.
- Ficha P2P de la obra con la piel del sitio (`obra.css`) y banner 06 de publicidad.

### Added — Teatro P2P, fase 0 (WP-O110, 2026-09-19)

*Aleph Cero* sale a la red sin demonios nuevos. Reporte `plan/REPORTES/WP-O110-teatro-p2p-fase0.md`.

- **Congelar una obra**: `CONGELADO.json` en el host; `deploy-teatro.sh` deja de regenerar zips con enlaces
  publicados y una edición nueva sale con `TEATRO_ZIP_SUFIJO`.
- **`devops/scripts/teatro-p2p.sh`** `status · congelar · publicar` y la imagen efímera `teatro-p2p-tools`:
  torrent con **semilla web** (BEP 19), magnet, ed2k con AICH, metalink, `p2p.json` firmado y ficha sin JS.
- Verificado desde fuera: descarga completa solo con el `.torrent`, sin pares, sha256 correcto.
- Anuncio en el módulo Torrents de Oasis (2 mensajes) y **`docs/PUB/TEATRO-P2P-PROTOCOL.md`**.

### Changed — Cliente en Oasis 1.1.4 con cartera propia (WP-O108, 2026-09-19)

Reporte `plan/REPORTES/WP-O108-cliente-1.1.4.md`. Ensayado con identidad desechable y aplicado al cliente del custodio.

- **En 1.1.4, con la cartera cableada, abrir la GUI publica sola la dirección ECOin** (medido; idempotente).
  `docs/CLIENT-PROTOCOL.md` §8 reordenado: backup **antes** de abrir la GUI; no dar de alta a mano.
- `docker-entrypoint.sh`: sin `OASIS_BANKING_DIR` ni symlink del mapa (el estado vive en `ssb-data/oasis/banking`),
  copia única del `banking/` de 1.1.2, retirada de `walletPub`. El banco se autodescubre: fuera `OASIS_WALLET_PUB_ID`.
- `client/scripts/*` al día; `ecoin-verify.sh` comprueba el estado nuevo.
- Dosier P2P: `docs/ROADMAP/p2p/07-revision-y-secuencia.md` (revisión del plan WP-O110 contra 1.1.4).

### Added — Motor de RBU en 1.1.4: interruptor y gestión de admin (WP-O107, 2026-09-19)

**Motor ENCENDIDO en `pub.escrivivir.co` desde el 2026-09-19 17:09 UTC**: la casa se anuncia como pub de RBU
(`@ecoin.escrivivir.co`, sin fondos hasta la dote). Reporte `plan/REPORTES/WP-O107-motor-rbu.md`.

- Interruptor = qué ssb-config se monta: `ssb-config` (`pub:false`) o `ssb-config.engine-on` (`pub:true`).
- **`devops/scripts/hub-wallet.sh`** `status · ready · on --yes · pause` (`--local`): la gestión de admin que
  Oasis no trae. Las credenciales RPC no salen del contenedor de `ecoind`.
- Retirados `walletPub` y `OASIS_WALLET_BOT_PUB_ID` (upstream los eliminó).
- `docs/PUB/ECOIN-PROTOCOL.md` §9 reescrito: qué reparte el motor (no crea dinero), coste de encender sin
  fondos (época del mes fijada con pool 0 y asignaciones de 1 ECO sin respaldo), dirección nueva en cada
  anuncio → backup semanal de `wallet.dat`.

### Deployed — Oasis 1.1.4 y bots renombrados en `pub.escrivivir.co` (WP-O106, 2026-09-19)

Reporte `plan/REPORTES/WP-O106-aplicacion-vps-1.1.4.md`. Pub, HUB y bot-2 en 1.1.4, mismos feed ids, misma
dirección ECOin, motor de RBU apagado. Bots: **`clearnet.escrivivir.co`** y **`ecoin.escrivivir.co`**. La
ejecución devolvió cinco correcciones al protocolo (conteo por autor, `git archive` y CRLF, ventana no
pública sin tocar `.env.prod`, descripción en fichero, `vis_wallet=on`), ya en `HUB-PROTOCOL.md` §12,
`UPGRADE-PROTOCOL.md` §4 y `AGENTES.md` §4.

### Changed — Oasis 1.1.4 (WP-O105, 2026-09-19)

Reporte `plan/REPORTES/WP-O105-upgrade-oasis-1.1.4.md`. Gates locales pasados sobre estado real de 1.1.2.

- **`src/` = upstream 1.1.4** (`45a1cd4`) con **5 guards**: los cuatro de siempre más
  `src/configs/snh-invite-code.json:url` (D-O22), base de los enlaces de «compartir en clearnet».
- **Estado mudado por upstream a `~/.ssb/oasis/**`**: bot-2 deja de definir `OASIS_BANKING_DIR` y de montar
  `/app/banking`; copia manual previa documentada en `docs/PUB/ECOIN-PROTOCOL.md` §5.4.
- **Motor de RBU**: upstream eliminó `walletPub`; ahora depende de `pub: true` en el ssb-config. El nuestro
  es `pub: false` = apagado. ECOIN §9 queda marcado obsoleto; interruptor nuevo en WP-O107 (D-O21).
- **Cliente**: aviso en `docs/CLIENT-PROTOCOL.md` §8 — no reconstruir un cliente con cartera sobre 1.1.4
  hasta WP-O108.
- `docker-entrypoint.sh`: `gossip_unfollowed.json` vale también en `oasis/peers/`.
- `HUB-PROTOCOL.md` §12: un bot de cartera se renombra con `vis_wallet=on` (ensayado).

### Added — Protocolo para agentes (WP-O104, 2026-09-19)

Asientos D-O20, D-O21, D-O22, D-O23. Solo documentación.

- **`AGENTS.md`** (raíz) y **`docs/AGENTES.md`**: entrada única para quien opera el repo — árbol
  intención → protocolo, reglas universales, **tabla de acciones irreversibles** con su puerta,
  **trampas conocidas** agregadas (estaban repartidas en ~15 ficheros) y convención de nombres.
- **Método genérico, datos aparte**: `docs/PUB/INSTANCIA-SCRIPTORIUM.md` es la ficha de la casa
  (registro de bots, `about` literales, rutas) y la plantilla para otro pub con su lore.
- **Nombres de bots (D-O20)**: forma libre, se prefiere corta, máximos de UI medidos. La casa pasa a
  `clearnet.escrivivir.co` y `ecoin.escrivivir.co`; la cadena tipo → piel → pub va en la descripción.
- **`HUB-PROTOCOL.md` §11-§12**: la serie de bots pasa a ser genérica y gana el **procedimiento de
  renombrado** (ventana no pública, un POST, contar antes y después).
- **`plan/PRACTICAS.md`**: el método del carril (WP, commits pedagógicos, gates, GO, cierre).
- README y `docs/proyecto.md` listan los 8 protocolos; portal con las dos páginas nuevas.

### Added — ECOin en la app cliente (WP-O103, 2026-09-18)

Estado: **en `main`; gate G1 y drill con identidad desechable pasados** (montaje, publicación única,
recreate, rebuild, `down -v`, backup y restore, arranque sin perfil, guarda anti-remoto). Es el
protocolo para que cualquier habitante se saque su cartera; no se ha aplicado a ninguna identidad
real (el custodio lo hará con su cliente cuando salga Oasis 1.1.3). Reporte
`plan/REPORTES/WP-O103-cliente-ecoin.md`. BRIEF `plan/BRIEFS/WP-O103-cliente-ecoin.md`; doc viva `docs/CLIENT-PROTOCOL.md` §8; asiento D-O19.

- **Dos niveles, independientes del VPS**: (i) *solo dirección* (aparecer, recibir y reclamar RBU
  con una dirección de una `wallet.dat` propia) y (ii) *cartera propia* (`ecoind` propio para saldo,
  envíos e historial). Por defecto `wallet.url = ""`: ningún RPC saliente y `/banking` sin latencia.
- **`docker-entrypoint.sh`** (zona *wholesale*; delta en `src/` = cero, siguen exactamente 4 guards):
  `persist_client_state` (config de la GUI y mapa de direcciones persistidos por symlink),
  `wire_wallet_config` (`ECOIN_RPC_URL|USER|PASS`, `OASIS_WALLET_FEE`, `OASIS_WALLET_PUB_ID` →
  `oasis-config.json`; **env manda**, escape `OASIS_WALLET_WIRING=manual`; **guarda anti-remoto**
  salvo `ECOIN_RPC_ALLOW_REMOTE=i-know`; nunca imprime credenciales) y `setup_oasis_config` reescrito
  en node. Solo actúan con `OASIS_CLIENT_STATE_DIR` y modo distinto de `server`: pub, HUB y bot-2 sin regresión.
- **`docker-compose.yml` raíz**: `ecoin-wallet` **sin `ports`** (RPC 7474 y P2P 7408 solo en la red
  del compose; el 12000 desaparece), credenciales del `.env` raíz con `ECOIN_REQUIRE_CREDS=1`,
  healthcheck, `mem_limit` (`ECOIN_MEM_LIMIT`, 512m), `logging`, `stop_grace_period 2m`;
  `wallet.dat` en el **volumen externo `o-sdk-client-ecoin-data`** (sustituye a
  `volumes-dev/ecoin-data`; `down -v` no lo borra). `oasis-client`: bind
  `./volumes-dev/client-state` → `/app/state`, `OASIS_BANKING_DIR=/app/state/banking`,
  `depends_on` opcional. `.env.example` raíz con los dos modos.
- **`client/scripts/`**: `ecoin-init.sh` (credenciales generadas, volumen, `--mode address|own`,
  `--pub-id`, `--ensure`), `backup-wallet.sh` (caliente, `--cold`, `--restore` que nunca sobrescribe;
  sha256; `devops/backups/client-wallet/<TS>/`), `guard-destroy.sh` (exige `BORRAR` y backup de menos
  de 24 h), `ecoin-verify.sh`; `setup.sh` e `import-identity.sh` dejan de tocar `ecoin-data`;
  `client/docker-compose.drill.yml` (proyecto `o-sdk-drill`, identidad desechable, 3100/8108).
- **npm**: `client:ecoin:init`, `client:wallet:backup`, `client:wallet:restore`,
  `client:ecoin:verify`; `ecoin:info|balance|address` sin credenciales en la línea de comandos,
  `ecoin:system` sin volcar `rpcpassword`, `ecoin:build` antepone `ecoin:fetch-deb`, `ecoin:up` espera
  a `healthy`; `downDELETEVOLS` y `cleanDELETEVOLS` pasan por la guarda.
- Docs y gobierno: `docs/CLIENT-PROTOCOL.md` §8 «ECOin en el cliente» (procedimientos, tabla
  variable → entrypoint → config, backup/restore, banco = bot-2, avisos, drill) y corrección de
  puertos y `volumes-dev/`; `client/README.md`; `UPGRADE-PROTOCOL.md` §3; referencia cruzada en
  `docs/PUB/ECOIN-PROTOCOL.md`; WP-O103 🔶 en `plan/BACKLOG.md`.

### Added — hub-wallet del pub: `ecoind` + `azofaifo-scriptorium-wallet-bot-2` (WP-O102, 2026-09-18)

Estado: **desplegado el 2026-09-18 (18:06 UTC)** con el motor de RBU APAGADO: bot-2 =
`@NYAqUzX7OACl+Fs866J8aVeKcqPxbbXccV/phcKx9UU=.ed25519`, cartera `EYdruXgDVQGhBpSsns83VA1BmDfAKBP4Lc`,
`ecoind` sincronizado, el pub sin reiniciar. Reporte `plan/REPORTES/WP-O102-hub-wallet.md`. Asiento D-O19; doc viva `docs/PUB/ECOIN-PROTOCOL.md`.

- **Imagen `ecoin/` endurecida** (compartida con el cliente): sha256 del
  `.deb` versionado (`ecoin_0.0.4-1_amd64.deb.sha256`) y `fetch-deb.sh`; el
  build **falla** si el binario no casa; conf completa de respaldo fuera del
  datadir; `port=7408` explícito; sin credenciales reales en git y arranque
  fail-closed (`ECOIN_REQUIRE_CREDS=1` rechaza vacío y `ecoinrpc`).
- **Dos servicios nuevos** en `pub/docker-compose.pub.yml`, perfil `wallet`
  (ni `pub:local:up` ni `deploy.sh` los arrastran), **sin `ports`** y sin ruta
  en Caddy: `ecoin` (`oasis-pub-ecoin`; 512m, `cpus 0.75`,
  `stop_grace_period 60s`) y `oasis-wallet-bot` (`oasis-pub-wallet-bot`; misma
  imagen que el pub, `command: ["backend"]`, hops 3, `OASIS_BANKING_DIR`
  persistente). El RPC no sale de `oasis_pub_net`.
- `pub/config/wallet-bot/` (`ssb-config`, `oasis-config.json.tpl`) y
  `pub/scripts/render-wallet-bot-config.sh`: la config con credenciales se
  renderiza **fuera de git**. **Motor de RBU armado y apagado**: el interruptor
  es `OASIS_WALLET_BOT_PUB_ID`, vacío hasta la dote.
- Herramientas: `devops/scripts/backup-ecoin.sh` (`backupwallet`, `--cold`,
  `--verify`; nunca borra `wallet.dat`), `devops/scripts/ecoin-disk.sh`
  (`status`/`check`/`--json`), línea en `deploy-status.sh`, rutas nuevas en
  `common.sh` y `verify-debian13-base.sh`, bloques `OASIS_ECOIN_*` /
  `OASIS_WALLET_BOT_*` en los tres `pub/.env*.example`, scripts npm
  `pub:ecoin:fetch-deb`, `pub:local:ecoin:up|info`, `pub:local:wallet-bot:up`,
  `pub:wallet-bot:render`, `devops:ecoin-disk`, `devops:backup:ecoin`.
- Docs y gobierno: `docs/PUB/ECOIN-PROTOCOL.md` (invariantes, activación,
  preflight de upgrades, tabla de contingencia 1.1.3, cartera, interruptor del
  motor, hallazgos de upstream), `HUB-PROTOCOL.md` §11 fila 2 y §5.2
  (lockstep de `caps.shs`), D-O19, WP-O102 y WP-O103 en el backlog. Delta en
  `src/` = cero; el pub, el HUB y Caddy no cambian.

### Added — Roadmap futuro: los dosieres de trabajo (WP-O101, 2026-09-18)

- `docs/ROADMAP/`: seis dosieres (aleph-net, relacional, colectivizaciones,
  res-publica, oasis-faircoin, publicidad-rrss) con página índice; anexos
  (previews HTML, figuras, PDF, banners) en `docs/public/dosieres/`. Sección
  «Roadmap» en menú, barra lateral, portada y README.
- `scripts/roadmap-import.py <carpeta>`: importa los dosieres como copia
  saneada e idempotente (rutas locales, Google Fonts, artifacts privados y
  datos de conexión del pub).
- `ARCHIVO/README.md`: declara los territorios (`DISCO`, `LORE`) y la
  diferencia con `archive/`; fila en README y MAPA.

### Added — Teatro: puerta semántica, «El sistema» y «El cantar» (WP-O100, 2026-09-18)

- **Capa editorial declarativa** en el sidecar (`lib/editorial.py`): lee
  `ARCHIVO/LORE/<fuente>/<obra>/editorial/obra-semantica.json` (territorios →
  constructos, álbum, concepto, portada). Opcional: sin ella la obra se
  construye como antes. Subcomandos `editorial-init | editorial-check |
  editorial-delta` y scripts `teatro:editorial:*`; esqueleto en
  `editorial.example/`.
- Puertas curadas: `sistema/` (índice + una página por constructo: prosa,
  «Nace en», posts que lo explican, hilos, enlaces y, aparte, «También lo
  mencionan (búsqueda mecánica)») y `cantar/` (tracklist + corte: vídeo
  enlazado, letra, constructos que recapitula). Chips «curado en» en cada
  permalink; `indexes/sistema.md` e `indexes/cantar.md` en el segundo cerebro.
- Portada: **SVG inline** de la obra, texto de concepto y puertas en dos
  grupos, «Leer la obra» / «Recorrer el archivo».
- Puertas mecánicas nuevas: **Conversaciones** (shares de agentes por agente)
  e **Interlocutores** (réplicas, menciones y RT por cuenta;
  `indexes/interlocutores.md`). El registro normalizado gana `mentions[]`.
- Convención de cita verificable en los `.md` editoriales: `«…» [[id]]` debe
  ser literal en ese post; si no, el build se detiene.
- `docs/PUB/TEATRO-CURADURIA-PROTOCOL.md`: crear, revisar, actualizar tras un
  export nuevo, subir de versión y reglas para agentes.
- Aleph Cero, propuesta v1 (en el lore, fuera de git): 5 territorios, 21
  constructos, 13 cortes, 143 citas verificadas, sigilo de portada.

- Revisión del custodio: `album.lyrics` (letra de la obra entera, repartida por los cortes),
  `voice_notes` (descripción del custodio como `alt` de la media de una voz ajena),
  `obra.json → imprint` (cabecera y colofón con sello y licencia en todas las páginas) y
  `link-mark --waived-by` (dispensa expresa para dejar un share de agente como enlace).
  Aleph Cero: constructo «Sacar la cabeza» (22 constructos, 151 citas verificadas).

### Changed

- `lib/guards.py`: barre también `*.svg` y los `<svg>` inline (sin script,
  eventos, `<image>`, `<foreignObject>` ni `href` externos).
- `AGENTS.md` (plantilla): distingue índices mecánicos de capa curada.

### Added — Teatro: sidecar de RRSS con fuente en exports de x.com (WP-O99, 2026-09-18)

- `pub/rrss-sidecar/twitter_x/`: el generador de obras del Teatro, en git y
  parametrizado por obra (Python ≥ 3.10, solo stdlib). `sidecar.py`
  (`lore-import | init | ingest | fetch-voices | fetch-links | browser-* |
  build | check | manifest | pack`), `lib/` (obra, ytd multi-parte, store
  aditivo multi-generación, **normalize = la costura**, voices, links,
  html2md, guards), builders sobre el corpus normalizado, parche multi-vídeo
  del visor como JSON declarativo con sha256 verificado, tests sobre export
  sintético. `CORPUS-SCHEMA.md`: contrato para un futuro adaptador B.O.E.
- `ARCHIVO/LORE/`: casa del lore del usuario **dentro del repo y fuera de
  git** (deny-by-default; excluido de la imagen Docker). El protocolo es
  autocontenido; el lore del custodio se copió verificado (3 generaciones).
- Protocolo (a) voces ajenas a 1-2 niveles, incluidas las **citas** (el
  export no trae `quoted_status`); protocolo (b) enlaces externos a Markdown
  íntegro, con cola de navegador y **regla PARAR**. Puerta nueva «Enlaces».
- `docs/PUB/RRSS-SIDECAR-PROTOCOL.md` (nuevo) y `TEATRO-PROTOCOL.md`
  reescrito; scripts npm `teatro:*` y `devops:teatro:*`; asiento D-O16.

### Changed — Teatro: deploy por obra e higiene del VPS (WP-O99)

- `devops/scripts/deploy-teatro.sh`: `TEATRO_OBRA` obligatorio (adiós a
  `aleph-cero` hardcodeado), origen `volumes-dev/teatro`, pre-vuelo de
  invariantes + `MANIFEST.sha256`, `rsync --chmod=D755,F644` acotado a la
  obra, **dos zips** (completo como descarga principal; ligero para
  inspección), tres firmas ed25519 y **verificación post-deploy automática**
  (incl. `data/ip-audit.js` → 404). Nuevos `teatro-wsl.sh` y
  `backup-teatro.sh` (`--verify`; backup de firmas y stores del lore).
- `pub/caddy/Caddyfile`: bloque `@teatro` — 404 real (sin fallback a la
  landing), whitelist de `data/*.js`, CSP estricta para páginas y propia para
  el visor, caché larga de media.
- `verify-debian13-base.sh` comprueba `/srv/oasis/teatro` (volumen de datos,
  nada world-writable); `hub-disk.sh status` lo mide;
  `OASIS_PUB_TEATRO_DIR` en `pub/.env.example` y `.env.local.example`.

### Security — (WP-O99)

- `.dockerignore` no excluía `ARCHIVO/`: añadidos `ARCHIVO/LORE/**` y
  `pub/rrss-sidecar/**` (un lore de varios GB con datos personales habría
  entrado en el contexto de build). Guardas de publicación como única fuente
  de verdad (`lib/guards.py`): denylist de nombres sensibles en árbol y zips,
  email/teléfono del export, recursos externos, `<script>` fuera del visor.

### Added — Protocolo del cliente: alta fresca e importación de identidad (WP-O98, 2026-09-17)

- `docs/CLIENT-PROTOCOL.md` (nuevo): estado y convivencia con el pub local, alta fresca,
  importación de identidad sin bifurcar el feed, sincronización con sbot puro, upgrade,
  healthcheck, rollback y retirada de instalaciones antiguas.
- `client/scripts/import-identity.sh` (secret + `flume/log.offset` + `gossip.json` + `keys/`
  [+ blobs]; verificación por frames, backup verificado en `devops/backups/client/`, flag
  `oasis-first-contact` con `welcome=done`), `client/scripts/sync-only.sh`
  (`start|status|invite|stop`, gate de identidad, veredictos SYNC-OK/AHEAD/BEHIND/PUB-UNKNOWN),
  `client/scripts/lib/inspect-log-offset.js`, `pub/tools/ssb-probe.js` (sonda por stdin, sin
  rebuild) y `devops/scripts/pub-feed-seq.sh`. Scripts npm `client:import-identity`,
  `client:sync-only[:status]`, `client:inspect-log`, `devops:pub-feed-seq`.
- Correcciones: `setup.sh` crea `ecoin-data` y no `configs` (muerto); `test-ai-service.sh`
  prueba `POST /ai` dentro del contenedor (no había `/health` ni `:4001` publicado); Quickstart
  con `npm run setup`; `.gitignore` cubre `.env.*` (antes `pub/.env.prod` era commiteable);
  `UPGRADE-PROTOCOL.md` cliente (rollback = imagen anterior), `RECOVERY-PROTOCOL.md` §4
  (en 1.1.2 el vector de fork es el PM de bienvenida), `pub/README.md` HUB activo.

### Changed — Upgrade Oasis 1.0.8 → 1.1.2 con el HUB activo (WP-O97, 2026-09-17)

- Rama `upgrade/oasis-1.1.2`: overlay limpio de `src/` desde upstream
  `3c9bf9a` (releases 1.0.9–1.1.2), 4 fork guards repuestos
  (`git diff oasis-upstream/main --stat -- src/` = guards +
  `blockchain-cycle.json`), `docs/PUB/clearnet.md` actualizado con la nota
  del fork. Ciclo de red sin cambios (cap `H5EC+V5B…`, ciclo 6).
- HUB (`HUB-PROTOCOL.md` §5.5): el visor pasa a `/c/assets/*` → nueva
  `location` cacheada en `pub/config/hub/nginx.conf.template`; cuatro rutas
  de detalle nuevas (market, feed, wiki, bookmarks) → Sala 04 pasa de 12 a
  16 tipos; `/c/qr/:feedId` entra por `/c/*` sin caché (`no-store`).
  `ssb-*`, `oasis-config.json`, `server-config.json` y cabeceras del backend
  sin cambios upstream.
- `UPGRADE-PROTOCOL.md`: guards por fichero (checkout de HEAD solo si
  upstream no lo tocó), aviso CRLF en Windows, chequeos post-upgrade del HUB.

### Added — HUB clearnet como nodo de soporte, implementación (WP-O46, 2026-09-13)

- Rama `wp/O46-hub-nodo-soporte`. `pub/docker-compose.pub.yml`: servicios
  `oasis-hub` (misma imagen, `command: ["backend"]`, identidad propia, sin
  puertos) y `hub-cache` (nginx, caché en disco acotada); `oasis-pub` intacto.
  `pub/config/hub/{ssb-config,oasis-config.json,nginx.conf.template}`;
  bloque `@hub` en `pub/caddy/Caddyfile`; variables `OASIS_HUB_*` en
  `pub/.env*.example` y `pub/scripts/common.sh`; `pub/tools/hub-conn-fix.js`
  (normaliza `conn.json` tras el invite: ssb-invite deja la dirección con
  seed y sin `key`); `devops/scripts/hub-disk.sh` (`status`/`check`/
  `prune-blobs`/`prune-cache`/`--json`, npm `devops:hub-disk`) y línea de
  `check` en `deploy-status.sh`; layout `/srv/oasis/oasis-hub/*` en
  `verify-debian13-base.sh`; Sala 04 `pub/site/hub/` + puerta en el
  vestíbulo y en Accesos. Gates locales G1-G7 pasados (hallazgos en
  `ARCHIVO/DISCO/oasis-clearweb/v2.md`).
- **Desplegado en `pub.escrivivir.co` el 2026-09-13 (19:55 UTC)**: `/c` servido por
  la cuenta de soporte `azofaifo-scriptorium-skin-bot-1`
  (`@KM+ZBipR18VSyjNTFjAOnsmz6EiobGYHb3ZCZ4ZxQYI=.ed25519`), Sala 04 en `/hub/`,
  el pub sin reiniciar. Tres paradas durante el deploy, corregidas en la
  rama: ruta de `ssb-admin.js` en la imagen viva, `seeds` retirado del
  `ssb-config` (bloqueaba el invite con `alreadyFederated`) y filtro de
  `hub-conn-fix.js` por host. Reporte: `plan/REPORTES/WP-O46-hub-nodo-soporte.md`.
- HUB a **hops 3** (D-O15): con 2 el HUB solo alcanzaba los 3 seguidos
  directos del pub y `/c` quedaba vacío.

### Docs — HUB clearnet como nodo de soporte (2026-09-13)

- Nuevo `docs/PUB/HUB-PROTOCOL.md`: activar, operar, mantener en disco y llevar
  a través de los upgrades el HUB web `/c`. Diseño v2: **segundo nodo SSB con
  identidad propia** (`oasis-hub`, misma imagen, `command: ["backend"]`, sbot
  embebido, hops 2), caché nginx en disco (`hub-cache`, `max_size`) y todo el
  estado en el volumen de datos (`/srv/oasis/oasis-hub/*`). El pub no cambia.
  Estado: **planificado, no desplegado** (WP-O46; plan y dosier en
  `ARCHIVO/DISCO/oasis-clearweb/`).
- `UPGRADE-PROTOCOL.md`: §4 pasa a «tres modos» (`server`/`backend`/`full`);
  pasos del HUB en §0, §2 (invariantes upstream que verifica), §4, §5, §6;
  §8 retira la receta v0 (entrypoint `server-hub`, proxy al backend del pub,
  `/qr/*`) y apunta al protocolo del HUB.
- `clearnet.md` (upstream) lleva nota del fork; `devops/README.md` §9 (disco
  del HUB, `hub-disk.sh`); `pub/README.md` (servicios planificados); portal
  VitePress (nav/sidebar); `plan/DECISIONES.md` D-O13 y D-O14 (serie de
  bots de soporte `<nombre>-<tipo>-bot-<cardinal>`; el HUB es
  `azofaifo-scriptorium-skin-bot-1`); `plan/BACKLOG.md` WP-O46 y WP-O47
  (tope duro de disco + `mem_limit` del pub).

### Changed — refactor de estructura (2026-07-25)

- **Una carpeta por responsabilidad**: `OASIS_PUB/`→`pub/`,
  `GANDI_DEVOPS_FOLDER/`→`devops/`, `OASIS_CLIENT_dEV/`+`docker-scripts/`→
  `client/`, `ECOIN_DOCKERIZE/`→`ecoin/`; histórico y transcripts →
  `archive/`. Migración del VPS: `devops/MIGRATION-2026-07.md`.
- **Generalización cliente+pub**: datos de instancia fuera de los scripts —
  `devops/hosts/<instancia>/host.env` (IP, clave, cap, dominio; instancia por
  defecto `scriptorium`) y `client/identity/identity.env` (identidad GPG del
  usuario). Los scripts de `devops/` cargan la instancia vía `lib-host.sh`.
- Servicio del compose raíz renombrado `oasis-dev`→`oasis-client`; el wallet
  ECOin pasa a profile opcional (`npm run ecoin:up`). Scripts npm
  reorganizados en espacios `client:` / `pub:` / `devops:`.
- CI de docs: el gate materializa las skills (`npm run skills:sync`) en vez de
  depender de un espejo commiteado.

### Security

- `.dockerignore` reescrito: `devops/` (claves SSH), `client/` (GPG),
  `archive/` y demás superficies ya **no entran en la imagen Docker** (antes
  la clave privada del VPS se horneaba en `oasis-pub-scriptorium:latest`).
  Requiere rebuild + rotación de la clave SSH si la imagen se compartió.
- Retirado un `ROOMS_SECRET` en claro de `pub/site/scriptorium/index.html`
  (página servida públicamente): rotar el secret en el servidor de rooms.
- `pub/.env.example` regenerado (estaba corrupto por el incidente NVMe — 1153
  bytes NUL) — el flujo genérico de `deploy.sh` vuelve a funcionar.

### Added

- Portal de documentación FOSS (VitePress) publicado en
  <https://o-sdk.escrivivir.co> vía GitHub Pages (skill `site-web`): portada,
  Proyecto/DevOps y los protocolos de operación.
- `docs/PUB/RECOVERY-PROTOCOL.md` — protocolo de recuperación (repo, imagen e
  identidad SSB), gemelo del de upgrade.
- Tooling de skills de agente: `@alephscript/skills-scriptorium` +
  `.claude/skills/` (espejo materializado con `npm run skills:sync`).
- Enlaces FOSS de fuente única (repo, registry, CI, issues) en el pie del portal.

### Changed

- Migración del fork a **Oasis 0.8.8** (cliente + pub dockerizados).
- Repositorio movido a `alephscriptorium-eng/O_SDK` (rama por defecto `main`);
  referencias a `escrivivir-co` retiradas de README y portal.

### Fixed

- Recuperación tras corrupción de disco: contenido restaurado por procedencia
  (commits locales legibles + rama del equipo), purgado de daño NUL; working
  tree, imagen Docker e identidad SSB (feed continuo) restaurados y verificados.
