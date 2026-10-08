# Protocolo para agentes · operar o-sdk de forma reproducible

> **Para quién.** Un agente —o una persona— que llega en frío y tiene que levantar, ampliar, subir de
> versión o recuperar un pub de Oasis con este repo. **Para qué.** Que dos operadores distintos, con
> el mismo repo y la misma intención, lleguen al mismo resultado sin depender de la memoria de nadie.
>
> **Método e instancia.** Todo lo de esta página es genérico. Los datos de un despliegue concreto
> (dominio, feeds, rutas, nombres) viven en su **ficha de instancia**; la de la casa es
> [`INSTANCIA-SCRIPTORIUM.md`](./PUB/INSTANCIA-SCRIPTORIUM.md) y sirve de ejemplo relleno. La que
> se rellena para otro pub es [`INSTANCIA-PLANTILLA.md`](./PUB/INSTANCIA-PLANTILLA.md).
>
> **Criterio de aceptación de cualquier protocolo de este repo:** un agente sin contexto, al que solo
> se le da el repo y una intención, completa la tarea sin preguntar. Cada vez que tropieza, el defecto
> es del protocolo y se corrige aquí.

## 0. ¿Quién te manda? → la receta de su puerta

Quien te encarga algo llega por una **puerta** ([`docs/roles/`](./roles/index.md)). Cada puerta
tiene una receta: el encargo, lo que hace falta tener, los pasos con sus puntos de DECISIÓN y de
PERMISO, y el **estado medido** de ese encargo. Lee la receta antes que el protocolo: te dice hasta
dónde se puede llegar hoy.

| Te dicen algo como… | Puerta | Receta |
|---|---|---|
| «arráncame un cliente Oasis», «…con cartera» | Cliente Oasis | [`roles/cliente.md`](./roles/cliente.md) |
| «despliega un pub en mi servidor», «añádele la lectura web», «acoge esta obra» | Pub Oasis | [`roles/pub.md`](./roles/pub.md) |
| «quiero una cartera ECOin», «dale un banco a mi pub» | Economía Oasis | [`roles/economia.md`](./roles/economia.md) |
| «quiero mi propio pub, con mi nombre y mi dominio» | Hazlo tuyo | [`roles/tu-pub.md`](./roles/tu-pub.md) |
| «hay versión nueva, súbela», «algo se ha roto» | Mantener | [`roles/mantener.md`](./roles/mantener.md) |

Tres reglas de las recetas:

1. **Si el encargo está «en obras», lo dices antes de empezar**: qué puedes hacer hoy y dónde vas a
   parar. No rellenas el hueco improvisando sobre la identidad o el servidor de nadie.
2. **DECISIÓN** es que preguntas y esperas. **PERMISO** es que el paso no tiene vuelta atrás (§3):
   pides permiso expreso, cada vez, aunque el plan general ya esté aprobado.
3. **Quien quiere su propio pub no necesita nada de la instancia de demostración.** Sus datos van
   en su ficha. No copies a su despliegue nombres, dominios ni textos de la demo.

Los sellos de estado (`probado en frío`, `ejercido en la demo`, `en obras`) salen del frontmatter de
cada receta. Cuando completes un encargo en frío, el reporte de tu trabajo es lo que permite subirlo
a «probado».

## 1. ¿Qué quieres hacer? → qué leer

| Intención | Protocolo | Antes, lee |
|---|---|---|
| Levantar un pub en un VPS | `pub/README.md` · `docs/PUB/deploy.md` (guía de upstream) | §2 y §3 de esta página |
| Subir Oasis de versión (con o sin piezas activas) | [`UPGRADE-PROTOCOL.md`](./PUB/UPGRADE-PROTOCOL.md): orquesta el ciclo entero | sus anexos por pieza: HUB §5, ECOIN §5, CLIENT §4 |
| Publicar en clearnet lo que los habitantes marcan (`/c`) | [`HUB-PROTOCOL.md`](./PUB/HUB-PROTOCOL.md) | — |
| Dar ECOin al pub: cartera, RBU | [`ECOIN-PROTOCOL.md`](./PUB/ECOIN-PROTOCOL.md) | HUB §3 (mismo bootstrap de bot) |
| Dar de alta o **renombrar un bot** de soporte | HUB-PROTOCOL [§11-§12](./PUB/HUB-PROTOCOL.md) | §5 de esta página (nombres) |
| App cliente: alta, importar identidad, cartera | [`CLIENT-PROTOCOL.md`](./CLIENT-PROTOCOL.md) | — |
| Saber **cómo entra una persona en el pub** (un habitante, con su móvil) | puerta [Habitante](./roles/habitante.md) y su manual | La portada del pub que trae el SDK **publica un invite de muchos usos**: lo crea el panel (`pub/panel-api`, `PUB_INVITE_USES`, 1000 si no se cambia) y lo sirve en `/public/status`. Es público **por diseño**. Los que genera un operador a mano (`devops/scripts/generate-invite.sh`) siguen siendo secreto: no van a logs ni reportes |
| Acotar o apagar la centralita de llamadas del pub (Phone y Rooms, Oasis ≥ 1.2.2) | [`HUB-PROTOCOL.md`](./PUB/HUB-PROTOCOL.md) §14 | [`CAPACIDAD.md`](./PUB/CAPACIDAD.md) §4 |
| Acoger y desplegar una obra del Teatro | [`TEATRO-PROTOCOL.md`](./PUB/TEATRO-PROTOCOL.md) · [curaduría](./PUB/TEATRO-CURADURIA-PROTOCOL.md) · [sidecar RRSS](./PUB/RRSS-SIDECAR-PROTOCOL.md) | — |
| Sacar una obra a la escena P2P (torrent, ed2k) y anunciarla en Oasis | [`TEATRO-P2P-PROTOCOL.md`](./PUB/TEATRO-P2P-PROTOCOL.md) | §3 de esta página: el anuncio es irreversible |
| Convertir el organigrama de un colectivo en tribus, salas, calendarios y listas de su pub (plantilla) | [`TEMPLATE-PROTOCOL.md`](./PUB/TEMPLATE-PROTOCOL.md) | §3 de esta página: cada tribu es permanente; nunca con la identidad del pub (D-O28) |
| Saber qué crece y si hay que limitarlo | [`CAPACIDAD.md`](./PUB/CAPACIDAD.md) · `devops/scripts/capacity.sh` | — |
| Algo se ha roto (disco, repo, identidad) | [`RECOVERY-PROTOCOL.md`](./PUB/RECOVERY-PROTOCOL.md) | **no toques nada antes de §0** |

Cómo se trabaja en el repo (ramas, commits, gates, reportes): `plan/PRACTICAS.md`. Por qué las cosas
son como son: `plan/DECISIONES.md`.

## 2. Reglas universales

1. **Preflight: mide el estado.** `devops/scripts/deploy-status.sh` contra el host antes de cualquier
   cambio. Compara con la ficha de instancia; si no cuadra, la ficha está vieja: corrígela primero.
2. **Parada dura.** Cada paso tiene una salida esperada. Si no aparece, paras, no avanzas y lo
   reportas con el comando y su salida. No hay «ya que estoy».
3. **Backup antes de escribir**, con sufijo `*.bak-<etiqueta>-<fecha>` junto al original.
4. **Un servicio cada vez:** `docker compose up -d --no-deps <servicio>`. Nunca un `up` global ni el
   `deploy.sh` en un host con piezas vivas. El pub no se reinicia si el cambio no es suyo.
5. **Binds de fichero: escribir in place** (`cat > fichero`), nunca reemplazar el inode (`mv`,
   `sed -i`, `scp` sobre el destino): el contenedor seguiría viendo el fichero antiguo.
6. **Edge (Caddy): validar y `reload`**, nunca `restart`; después, salud de todos los vhosts ajenos.
7. **Secretos.** Se generan en el destino; `.env.prod` solo existe allí. No se imprimen, no se
   copian a reportes, no se pasan por línea de comandos (quedan en `ps` y en el historial).
8. **Evidencia.** Reporte en `plan/REPORTES/` con comando + salida. Lo que no mediste, no lo afirmes.
9. **Gates locales antes del VPS.** Todo cambio se ensaya en Docker local; la identidad de prueba es
   desechable. La identidad real de nadie se usa para ensayar.

## 3. Acciones irreversibles y su puerta

Un feed SSB es append-only y se replica: lo publicado no se retira. Estas acciones exigen **permiso
expreso del custodio en el momento**, aunque el plan general ya esté aprobado.

| Acción | Por qué no tiene vuelta | Puerta |
|---|---|---|
| Publicar `about` (nombre, descripción, imagen) | queda en el log; el último gana, los anteriores siguen ahí | texto literal aprobado; ventana no pública (HUB §12) |
| Publicar `wallet` (dirección ECOin) | el alta **no es idempotente**: cada POST es otro mensaje | contar antes (`0` mensajes `wallet`), publicar **una** vez, contar después |
| «Desconectar cartera» en Settings (`POST /settings/wallet/disconnect`, desde Oasis 1.1.10) | publica un `wallet` con dirección **vacía** que anula la dirección en toda la red; en el cliente dockerizado, el siguiente arranque recablea la cartera y la GUI publica la dirección otra vez | no se usa: la cartera se retira por config (CLIENT §8.8). Si de verdad hay que anular una dirección: texto y momento aprobados, contar `wallet` antes y después |
| `contact` (seguir, bloquear), invites redimidos | cambian la replicación de terceros | lista cerrada aprobada |
| Recrear un nodo de Oasis (pub, HUB, bot, cliente) en **otra versión**: upgrade **o rollback** | publica un `oasisVersion` con su identidad cada vez que arranca en una versión distinta de la última que anunció (lo hace el propio sbot: también el pub en modo `server`) | uno por nodo y declarado antes (`upgrade-gates.sh check --expect`, UPGRADE §0.4 y §3.4); **ningún rollback es gratis**: pide GO |
| Arrancar un nodo por primera vez en una versión con **otro motor de base de datos** (Oasis 1.2: flume → db2) | migra el log, **borra el viejo** y deja una guarda; la versión anterior ya no arranca sobre ese `.ssb`, y reponer el log viejo sería arrancar con un log más corto que el de la red | migración ensayada sobre una copia (UPGRADE §0.5 y §4); nodo parado y copiado en frío justo antes; GO por nodo diciendo «sin retorno» |
| Arrancar la maint-ui (un backend sobre el `.ssb` del pub) durante un ciclo de upgrade | todo lo que un backend publica solo (avisos, PM de bienvenida si falta el flag, dirección si hay cartera) saldría **con la identidad del pub** | prohibida durante el ciclo (UPGRADE §0.2) |
| `pubAvailability`, `ubiAllocation`, pagos de RBU | anuncian el pub como banco y mueven ECO reales | ECOIN §9; saldo, backup y elegibilidad comprobados |
| Borrar o pisar `wallet.dat` o `secret` | son las claves: sin copia, el dinero o la identidad se pierden | **nunca**; se aparta con sufijo, no se borra |
| Arrancar un nodo con el `secret` y un log más corto que el de la red | bifurca el feed | RECOVERY §4 |
| `docker compose down -v`, borrar volúmenes | se lleva estado no derivable | `client/scripts/guard-destroy.sh`; backup < 24 h |
| Reload del edge | tumba todos los vhosts si la config es inválida | `validate` antes |

**Subagentes.** El clasificador de permisos de una sesión puede denegar a un subagente una
publicación aunque el plan la autorice. El subagente **para y lo dice**; no busca otra vía. La ejecuta
el agente principal tras volver a verificar la precondición (registro: ECOIN §13).

## 4. Trampas conocidas

Todas costaron una parada. Síntoma → causa → dónde está el detalle.

| Síntoma | Causa y salida | Detalle |
|---|---|---|
| `ecoind` responde 403 a todo el RPC | `rpcallowip` no entiende CIDR: usar comodines (`172.16.*` … `172.31.*`) | ECOIN §14 |
| El invite no conecta desde otro contenedor | el invite lleva el host público; reescribirlo a la IP del bridge del pub | HUB §3 · ECOIN §3 |
| Tras el invite el bot conecta a una dirección muerta | `conn.json` guarda la entrada con semilla; normalizar con `pub/tools/hub-conn-fix.js` y reiniciar | HUB §2 |
| El invite responde `alreadyFederated` | `seeds` en el `ssb-config`, o clave vieja en `gossip.json` | HUB §5, §10 |
| Aparecen dos mensajes `wallet` | `POST /banking/addresses` no es idempotente | ECOIN §3 · CLIENT §8.1 |
| Un backup de cartera no contiene la dirección publicada | el backup se hizo **antes** de generar la dirección | ECOIN §8 |
| Un contador sobre `log.offset` no se mueve | `grep -c` en binario cuenta líneas: `grep -a -o … \| wc -l` | RECOVERY §0 |
| En Git Bash un path `/c/…` o `/app/…` llega destrozado | conversión de rutas de MSYS: `MSYS_NO_PATHCONV=1`; y con él, `git -C /c/…` falla: `cd` + ruta relativa, `cygpath -m` para node | ECOIN §14 · CLIENT §8 |
| Una sonda a mano (`docker exec … -e HOME=/home/oasis … node -`) dice «could not connect to sbot» y los gates sí conectan | la misma conversión: `HOME` llega como `C:/Program Files/Git/home/oasis` y `ssb-client` busca el socket donde no está. `MSYS_NO_PATHCONV=1` **delante de esa orden**, no exportada: exportada rompe el `curl` del gate `hub` (todo `000`) | UPGRADE §3.4 |
| `MODULE_NOT_FOUND` al llamar a `ssb-admin.js` | la ruta dentro de la imagen viva depende del layout del host | HUB §9 |
| Un POST desde el loopback da 403 o 400 | `Host` y el host del `Referer` deben ser idénticos (mismo host:puerto) | ECOIN §3, §14 |
| «¿Está sincronizado `ecoind`?» da alturas absurdas | la altura de los pares sale de `receive version message … blocks=N`, no de `height=` | ECOIN §3 |
| `bootstrap.dat` se reimporta en cada arranque | comprobar `blk0001.dat`/`txleveldb`/`bootstrap.dat.old`, no `blkindex.dat` | ECOIN §14 |
| Tras un upgrade reaparece estado viejo o ficheros fantasma | el overlay se hizo sin `git rm -r src`: los ficheros que upstream borró siguen ahí | UPGRADE §2 |
| Desde Oasis 1.1.3: una segunda dirección ECOin, o el mapa de direcciones «vacío» | el estado vive en `~/.ssb/oasis/**`; `OASIS_BANKING_DIR` solo lo honra medio código | ECOIN §5 · UPGRADE §2 |
| `src/` llega al host con CRLF | en Windows `git archive` aplica `autocrlf` al empaquetar: `git -c core.autocrlf=false archive …` | UPGRADE §4 |
| Tras subir `src/`, el build usa el árbol viejo y `src` aparece dentro de `src.old` | `mv src src.old` con un `src.old` que ya existía mueve **dentro**: comprobar `test ! -e` y dar al rollback un nombre con versión (`src.old-X.Y.Z`) | UPGRADE §4 |
| Un contador de mensajes cifrados da 0 siempre | `grep '"private":true'` no casa nunca: un cifrado se guarda como `"content":"….box"`. Medir con `upgrade-gates.sh snapshot`, que cuenta por autor e incluye `(cifrado)` | HUB §1 |
| `/c` sale en el idioma (o con el tema) del primer visitante | el backend decide algo por una cabecera o una cookie y la caché lo sirve a todos: en clearnet la presentación es del pub y lo del visitante viaja en la URL (D-O25) | HUB §2 |
| Se cambió la plantilla de nginx y `hub-cache` sigue igual | la plantilla se renderiza al arrancar el contenedor: `reload` no la relee; `up -d --no-deps --force-recreate hub-cache` | HUB §5.2 |
| El preflight no encuentra de qué commit partir | upstream no etiqueta las versiones de Oasis; el commit es el titulado `Oasis release X.Y.Z`, y la versión de partida es la **desplegada**, no la de `HEAD`: `--from X.Y.Z` | UPGRADE §1 |
| El overlay trae cosas que no son de la release | `NEW_REF` es el commit `Oasis release X.Y.Z`, no la punta de `oasis-upstream/main`: si upstream empujó después, el preflight avisa y el `git checkout $NEW_REF -- src/` se hace desde ese commit (`--to X.Y.Z` para una intermedia) | UPGRADE §1, §2 |
| «Lo vendorizado ya trae ese parche» dicho de memoria | el `scripts/patch-node-modules.js` de upstream es la lista de lo que espera parcheado y el fork no lo corre sobre el repo; la copia del fork se quedó en 1.2.1 sin que nadie lo viera. Se mide con `upgrade-patches-audit.js $NEW_REF` (ningún `pendiente`) | UPGRADE §2 |
| Un gate de upgrade da «sin cambios» y sí los hubo | se midió sobre un estado que ya había pasado por la versión nueva (el `oasisVersion` ya estaba): `upgrade-gates.sh restore` antes de repetir | UPGRADE §3.4 |
| Un contador de mensajes da cientos en un bot recién nacido | con `hops` > 0 el log trae los mensajes de media red: contar **por autor** | HUB §12 |
| El pub anuncia para donaciones una dirección que no es la publicada | cada `pubAvailability` pide `getnewaddress`: es de la misma cartera (keypool). Backup semanal de `wallet.dat` con el motor encendido | ECOIN §9 |
| Tras abrir `/wallet` en un bot de cartera aparecen dos mensajes `wallet` y la dirección publicada es otra | `GET /wallet` (y `/wallet/history`…) compara la dirección «actual» de la cartera con la del mapa local y, si difieren, **la republica**; con el motor encendido difieren siempre, porque cada anuncio pide una nueva. Pasa en 1.1.4 y en 1.1.10 (medido). **No se abre `/wallet` en un bot de cartera**; `hub-wallet.sh ready` exige un único `wallet` y dejaría de dar listo | ECOIN §9 |
| Un nodo de soporte publica mensajes cifrados que nadie ha pedido | los avisos automáticos del backend (político, empleo, banca, recordatorios) corren con cualquier petición y se envían a uno mismo. Desde 1.1.10 se silencian con `inboxMutedBots` (`node pub/scripts/regen-node-configs.js`); antes no se podía | HUB §1, §2 |
| Un torrent o un enlace ed2k publicado deja de completar | los bytes detrás de la URL cambiaron: una obra con enlaces publicados se **congela**; la edición nueva sale con sufijo | TEATRO-P2P §1 |
| Activar una casilla de visibilidad deja el perfil sin nombre | `POST /profile/edit` publica un `about` entero con lo que llegue: solo desde el formulario del navegador | TEATRO-P2P §4 |
| La GUI del cliente da **403 vacío** en Banking, Wallet o Settings | Oasis exige que esas acciones lleguen desde `127.0.0.1`; en Docker el navegador del host entra por el mapeo de puertos. Puente de loopback del entrypoint + puerto publicado **solo** en `127.0.0.1` | CLIENT §8.10 |
| Una medida de mensajes da 0 en un nodo con Oasis ≥ 1.2 | el log ya no es `flume/log.offset` (queda una guarda de texto) sino `db2/log.bipf`, binario; y la RPC `getLatest` no existe. Medir con `upgrade-gates.sh snapshot` o `lib-node.sh` (`node_own_scan`): lo ilegible es `?`, no 0 | UPGRADE §3.4 |
| Tras un `npm install` en `src/server` cambian miles de ficheros de `src/base` | `src/server/node_modules` es un enlace a `src/base/node_modules`: se escribe a través de él. No se instala nada ahí; `git checkout -- src/base` | UPGRADE §2 |
| El pub no da invite en el stack local: «Server has no public ip address» | el pub de ensayo anuncia `localhost` y `ssb-invite` no emite invites para un host privado: pedirlo con `invite.create({ uses: 1, external: '<dominio.con.punto>' })` y reescribir el host a la IP del bridge | HUB §3 |
| Un cliente nuevo no arranca desde el snapshot del pub | el pub solo lo sirve a quien **sigue**; antes del invite responde `not allowed`. Y debe existir: `pub-snapshot.sh status` | HUB §13 |
| `crontab -l` no devuelve nada y se da por «crontab vacío» | puede ser que el host no tenga `cron`: la orden falla y, con el error tapado, parece vacío. Medir con `command -v crontab` y `systemctl list-timers`. Y antes de instalar nada en el host: lo que una pieza necesita para funcionar va **en el compose o en la imagen**, no en el host | HUB §13 |
| El backend arranca sin sbot embebido | `OASIS_TEST` definido en el entorno (desde 1.1.3) | UPGRADE §1 |
| El nombre nuevo de un feed no aparece | `nameCache` es memoria del proceso: reiniciar el nodo que lo muestra | HUB §12 |
| Una página del sitio del pub en el host **no coincide** con la del repo | el repo guarda la plantilla; el host, la página con sus **valores vivos fusionados a mano** al desplegar. `deploy-site.sh` sincroniza con `--delete` y los borraría. Antes de subir un fichero del sitio: sha256 del vivo contra el del repo; si coinciden, se sustituye in place; si no, se cambian **solo las líneas** que tocan, sobre el fichero vivo, y se comprueba que el `diff` con la copia previa son exactamente esas | ficha de instancia, §5 |
| El build del portal rompe | tokens entre ángulos fuera de código (Vue los lee como etiquetas) o enlaces muertos (`ignoreDeadLinks: false`) | `docs/proyecto.md` |

## 5. Nombres de los bots de soporte

Un pub delega funciones en **bots**: cuentas SSB propias, una por servicio, cada una en su contenedor
(HUB §11). Su nombre aparece en menciones, listas, actividad y —si reparte RBU— en la **tarjeta de
pub de Banking**, junto a los de otros pubs. La regla:

1. **El nick dice qué es y de quién, y nada más.** Quien lo ve debe poder trazar la cadena
   *tipo de bot → piel que lo organiza → pub que lo crea*. El nick lleva los extremos (tipo y pub); la
   cadena completa va en la **descripción**.
2. **Forma libre, se prefiere corta.** No hay gramática obligatoria: cada pub elige la suya y la
   mantiene. Recomendación: jerarquía tipo DNS, **`<tipo>.<dominio del pub>`**, porque se lee sola, no
   colisiona entre pubs y, si el operador quiere, puede hacerse resoluble.
3. **Máximos medidos** (Oasis 1.1.4; Oasis no valida ni recorta el nombre):
   - Tarjeta de pub en Banking: rejilla de 3 columnas (1 bajo 900 px); la cabecera es un flex con
     *wrap* y **sin elipsis**: un nombre largo parte línea o empuja el botón de donar. Caben
     **≈20-22 caracteres** en una línea junto al botón.
   - En campos de tarjeta y pies (`.card-field`, `.card-footer`) el enlace de usuario se recorta con
     elipsis a 220 px (≈28-30 caracteres).
   - **Sin `about` publicado se muestra el feed id entero** (53 caracteres): un bot sin nombre es lo
     peor que puede salir en una lista.
   - Caracteres: letras, cifras, punto y guion. Los puntos son seguros: las menciones viajan por feed
     id. Sin espacios, sin ángulos (se eliminan al sanear).
4. **Descripción: plantilla.** Tipo y cardinal en la serie del pub · piel que lo organiza · pub que
   responde por él · qué sirve · qué firma · qué **no** hace. Menos de 6 KB (el formulario no comprueba
   el límite de mensaje SSB: si te pasas, 500).
5. **Cambiar el nombre** es publicar otro `about`: irreversible (§3) y con procedimiento propio, HUB §12.
   El feed id no cambia nunca; lo que identifica al bot es el id, el nombre es cortesía.

Ejemplo (instancia Scriptorium): `clearnet.escrivivir.co` y `ecoin.escrivivir.co`. Sus descripciones
literales, en la ficha de instancia.
