# Runbook del operador · activar la plantilla de tu colectivo con una secretaría

Para la **mesa técnica** de un colectivo que ya tiene un pub Oasis y quiere darle, de una vez, las tribus, salas,
calendarios, listas, wikis y mapas de su organigrama. Lo ejecutas tú, en tu máquina, desde un clon de este repo, con un
solo mando: `pub/scripts/secretaria.sh`. El método completo está en [`TEMPLATE-PROTOCOL.md`](./TEMPLATE-PROTOCOL.md);
este documento es el paso a paso. Los valores de tu instancia (pub, plantilla, nombres) van en tu ficha
([`INSTANCIA-PLANTILLA.md`](./INSTANCIA-PLANTILLA.md)); aquí no hay ninguno.

Lo que hace: nace una identidad nueva, la **secretaría** (un bot en modo `server`, sin pantalla), se une a tu pub como
un nodo más, publica su `about`, siembra la plantilla bloque a bloque y te da los primeros códigos de acceso. Lo que
**no** hace: no toca tu pub (ni su `secret`, ni su configuración, ni lo reinicia), no publica nada con la identidad del
pub, no imprime invites ni semillas. Cada paso marcado **PERMISO** publica algo que no se retira (AGENTES §3): se da uno
a uno, en el momento.

## 0. Qué tienes que tener antes de empezar

- **Una máquina con Docker (Compose v2) y Git**, 3 GB libres y salida al puerto 8008 de tu pub. Linux, macOS o Windows
  con Git Bash (medido en Windows 11 con Git Bash y en Debian 13).
- **El repo clonado**, en la rama o etiqueta que te hayan indicado:
  `git clone https://github.com/alephscriptorium-eng/O_SDK.git && cd O_SDK && git checkout <rama>`.
- **De tu pub**, tres datos que solo tú tienes:
  - su **`caps.shs`** (la «red» a la que pertenece: sin el mismo valor, la secretaría no puede ni saludar). Está en el
    `ssb-config` del pub: si lo desplegaste con este repo, `pub/config/ssb/config` en el host; si es un Oasis upstream sin
    caps propio, es el de `ssb-caps` por defecto (lo imprime `node -e "console.log(require('ssb-caps').shs)"` en
    `src/server`). Es un base64 de 44 caracteres; no es secreto, pero sí tuyo.
  - un **invite** de un uso (`node /app/pub/tools/ssb-admin.js invite.create 1` dentro del contenedor del pub, o
    `npm run pub:invite`). Lo guardas en un fichero que borrarás después. **Nunca por chat ni por correo escrito.**
  - su **feed id** (`npm run pub:whoami`): `join` lo deduce del invite y comprueba que coincide.
- **La plantilla y su kit**: `pub/templates/<id>.json` y `pub/templates/assets/<id>/` (los genera quien preparó tu dosier
  desde tu organigrama; `npm run pub:template:kit` o `pub:template:kit:<id>` si falta el kit).
- **El `about` de la secretaría**: un PNG cuadrado (avatar) y el nombre y la descripción literales, aprobados por el
  colectivo (plantilla en `INSTANCIA-PLANTILLA.md` §4).
- **Cuatro decisiones del colectivo**, tomadas y escritas en la ficha: dónde vive la secretaría (variante A o B, abajo);
  quién custodia su `secret` y las claves de tribu (`oasis/keys`); quién es la mesa técnica (quien reparte códigos); qué
  tribus son **estrictas** (cada alta pasará por la secretaría) y cuáles abiertas (QR en la calle).
- **Las cinco leyes** de [`AGENTES.md`](../AGENTES.md): mide antes de tocar, para ante una desviación, pide permiso en lo
  irreversible, los secretos no viajan, evidencia = comando + salida. Un agente de código las lee solo.

## 1. Dónde vive la secretaría: dos variantes

| | **A · junto al pub** | **B · en otra máquina** (por defecto) |
|---|---|---|
| Dónde | el host del pub, en su mismo `docker compose` | el ordenador de la mesa técnica (o cualquier máquina con Docker) |
| Cómo | `SECRETARIA_COMPOSE=pub SECRETARIA_ENV=pub/.env.prod` delante de cada orden; servicio `oasis-retro-bot`, perfil `retro`, contenedor `oasis-pub-retro-bot` | `pub/docker-compose.secretaria.yml`: un proyecto con un solo servicio, contenedor `secretaria-<id>-bot`, datos en `volumes-real/secretaria-<id>/` |
| `caps.shs` | ya coincide (mismo `pub/config`) | lo escribes con `caps` |
| Red | el bot llega al pub por su dirección pública | igual: el invite trae host y puerto |
| Cuándo | si el pub se desplegó con este repo y tienes SSH al host | si el pub es de otro, o no quieres tocar su host, o quieres la secretaría en tus manos |

Las órdenes son las mismas en las dos. Lo que sigue está escrito para B; en A, salta `prep` y `caps`.

## 2. Pasos

`<id>` es un nombre corto para tu secretaría (sin espacios: el id de tu plantilla vale). Todo desde la raíz del repo.

| # | Paso | Orden | Esperado | |
|---|---|---|---|---|
| 0 | Medir, sin tocar | `docker version`, `git status` (limpio, rama correcta); en tu pub: versión (pie de `/c`, o `oasisVersion` de su feed), `caps.shs`, que el 8008 responde | lo anotas en la ficha. Si la versión del pub no es la que la plantilla declara (`meta.version_oasis`), **parar** y preguntar | |
| 1 | Preparar | `bash pub/scripts/secretaria.sh <id> prep --template <plantilla>` | `pub/.env.secretaria-<id>` (no versionado) y `volumes-real/secretaria-<id>/oasis-retro-bot/{ssb-data,logs}` vacíos | |
| 2 | La red del pub | `bash pub/scripts/secretaria.sh <id> caps <caps.shs>` | `pub/config/retro-bot/ssb-config.<id>` con `pub:false`, `hops:3` y tu caps | |
| 3 | Comprobar el compose | `bash pub/scripts/secretaria.sh <id> config --services` | **solo** `oasis-retro-bot`; `config` entero: binds en `volumes-real/secretaria-<id>/…`, ninguno en `volumes-dev` | |
| 4 | Levantar | `bash pub/scripts/secretaria.sh <id> up` | construye la imagen si falta (minutos); `healthy`; imprime el **feed id nuevo** de la secretaría → ficha §3. Su `secret` acaba de nacer: `backup` (paso 13) ya mismo | |
| 5 | **PERMISO** · unirse al pub | `bash pub/scripts/secretaria.sh <id> join <fichero-con-el-invite>` (o sin fichero: lo pega quien lo tiene, sin eco) | `accept: true` → reinicio → `conn.json` sin semilla → reinicio → `connected al pub`. Escribe en el env `SECRETARIA_PUB_ID` y `SECRETARIA_PUB_ADDR` (públicos). **Borra el fichero del invite.** Si `accept: false` o nunca `connected`: el `caps` no es el del pub, o el 8008 no llega: **parar** | el pub publica un `contact` hacia la secretaría; la secretaría, `contact` + `pub` |
| 6 | Foto base | `bash pub/scripts/secretaria.sh <id> snapshot base` | feed de la secretaría en 3 (`contact`, `pub`, `oasisVersion`); guarda también el `sequence` del pub visto desde el bot | se toma **después** de `join`: un sbot sin mensajes no tiene log que fotografiar |
| 7 | **PERMISO** · `about` | `bash pub/scripts/secretaria.sh <id> about <avatar.png> <descripcion.txt> "<Nombre>"` | un solo `about` con `name`, `description` (no vacía) e `image` (blob del avatar). Léelo: `exec 'node /app/pub/tools/ssb-probe.js'`… o `check base --expect 'retro:about=+1'` | la descripción entra por stdin, nunca por `docker cp` |
| 8 | Ensayo en seco | `bash pub/scripts/secretaria.sh <id> seed` | gates `true` (no es el pub, `pub:false`, pub `connected`), N bloques, mensajes previstos por bloque, imágenes a subir, 0 publicados | sin `--yes` no publica nada |
| 9 | **PERMISO por bloque** · sembrar | `… seed --yes tribes` → `--yes subtribes` → `--yes invites` → `--yes rooms` → `--yes calendars` → `--yes events` → `--yes mailing` → `--yes wiki` → `--yes maps` → `--yes clearnet` | tras cada bloque, `delta = previsto` en su evidencia (`logs/seed-<tag>.json`); si no cuadra, el seeder **para solo** y tú también. `check base --expect '…'` al final con lo sembrado | el ledger `oasis/keys/plantilla-<id>.json` permite reejecutar sin duplicar |
| 10 | Que el pub lo vea | `status` → `seq del pub visto desde el bot` igual que antes (el pub no publicó nada); en el pub: `ssb-probe.js` con `SSB_FEED=<secretaría>` → su `seq` = el del bot. Si tu pub tiene HUB (`/c`): reiniciar el HUB si no replica y vaciar su caché (TEMPLATE §5) | el feed de la secretaría entero en el pub; `/c/sitemap.xml` con los objetos públicos | |
| 11 | Los primeros códigos | `… codigos list` (enmascarado) → `… codigos sheet --out <carpeta fuera del repo> [--brand <marca.json>]` → imprimir → **borrar la carpeta**. Por cada tribu estricta, cuando el órgano lo pida: **PERMISO** `… codigos one-use <id de la tribu> --yes` (lo muestra una vez) | 1 tarjeta con QR por tribu abierta; las estrictas listadas aparte. «Primer acceso» de la guía de reparto | la hoja es pública para quien la tenga: se reparte en mano |
| 12 | La guía con enlaces | `node pub/tools/template-seed.js --template pub/templates/<id>.json --reparto --ledger volumes-real/secretaria-<id>/oasis-retro-bot/ssb-data/oasis/keys/plantilla-<id>.json --out <guía.md>` (el ledger no contiene códigos) | guía de reparto con `/c/…` por objeto, para la mesa técnica | |
| 13 | Cerrar | `bash pub/scripts/secretaria.sh <id> backup <carpeta fuera del repo>` → quien custodia lo guarda cifrado; ficha de instancia al día (feed, fecha, plantilla, dónde vive, custodia); reporte con comando + salida de cada paso | un `.tgz` (600) con `secret`, `oasis/keys` y `conn.json`; nada de esto en git | |

**Rollback.** `bash pub/scripts/secretaria.sh <id> down` para el bot y deja el pub como estaba. Lo publicado no se
retira: deshacer una siembra es `… tombstone --yes <bloque>` (TEMPLATE §9: de hojas a raíces, PERMISO por bloque) y el
pub puede dejar de seguir a la secretaría (`contact`, irreversible). Las claves repartidas y los códigos multiuso ya
entregados no se retiran.

## 3. Primer acceso: lo que la mesa técnica reparte

La secretaría es la autora de todo; no tiene pantalla. En esta versión de Oasis la tarjeta de una tribu **no** muestra
su código multiuso ni un botón de unirse, y «Generar invitación» solo lo ve quien ya está dentro. Por eso:

- **Tribus abiertas**: la hoja de códigos (paso 11) con un QR por tribu. Quien lo recibe: Menú → Tribus → INTRODUCIR
  INVITACIÓN → pega el código (el QR es el código en texto). Desde dentro, cualquier miembro genera más desde la tarjeta.
- **Tribus estrictas**: un código de un uso por persona, de la secretaría (`one-use`), entregado en mano. Cada alta pasa
  por la mesa técnica mientras la tribu sea estricta.
- **Salas, calendarios y mapas de una tribu**: se ven al entrar en la tribu. Los objetos sin tribu con invitación pública
  llevan el código en su propia tarjeta (calendarios y mapas `OPEN`).

La guía de reparto (`--reparto`) lo dice objeto a objeto: quién reparte y dónde se obtiene. Nunca cuál.

## 4. Trampas medidas

- **Invite por argumento**: queda en el historial de la shell. `join` lo lee de un fichero o lo pide sin eco.
- **Git Bash**: `MSYS_NO_PATHCONV=1` lo exportan los scripts; para `docker cp` a una ruta del host se usa `cygpath -w`
  (ya lo hace `retro-codes.sh`). Un `python` de Windows no abre `/c/…`: los scripts le pasan rutas relativas.
- **`caps.shs` distinto**: `accept: false` o `NO conectado` sin más error. Mide el del pub; no adivines.
- **Nodo `server`**: persiste `conn.json` **al parar**: por eso `join` reinicia dos veces. Y publica `oasisVersion` tras su
  primer mensaje: por eso la foto base se toma tras `join` y espera 3 mensajes.
- **HUB del pub**: a dos saltos; puede no replicar a la secretaría hasta reiniciarlo, y sirve 7 días la caché de antes.
- **Wikis**: cada página ≤ 5600 B y sin tablas (D-O34); lo garantiza el dosier, no lo toques a mano.
- **Volúmenes**: `volumes-dev/` es de ensayos con identidades desechables; la secretaría real vive en `volumes-real/`.
  `up` para si el env apunta a `volumes-dev`.

## 5. Lo que nunca

Invites, semillas, `secret` o códigos en git, en un chat, en un log o en un reporte. Publicar con la identidad del
pub (el seeder lo comprueba, exit 3). Sembrar sin el ensayo en seco. Un `--yes` sin su PERMISO. Borrar `volumes-real/`.
