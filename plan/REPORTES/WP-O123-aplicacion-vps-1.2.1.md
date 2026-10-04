# WP-O123 · Aplicación en el VPS del upgrade a Oasis 1.2.1

2026-10-04 · rama `upgrade/oasis-1.2.1` · asiento D-O27 · BRIEF `plan/BRIEFS/WP-O123-aplicacion-vps-1.2.1.md`.
GO del custodio en cada puerta: GO-1 (build), GO-2 (pub), GO-3 (HUB), GO-4a y GO-4b (bot).
GO-5 (snapshot del pub): construido y servido; **falta su temporizador**. Pendiente también el cliente.

## Resultado

Pub, HUB y bot de cartera en **Oasis 1.2.1**, sobre el motor db2, con la misma identidad. Cada nodo
publicó lo declarado y nada más: **mismo delta que en local**.

```
$ upgrade-gates.sh --remote check pre-o123 --expect 'pub:oasisVersion=+1 hub:oasisVersion=+1 bot:oasisVersion=+1,pubAvailability=+0..1'
  pub  v1.1.10 → v1.2.1 · Δseq=1 · oasisVersion+1 · log: flume → db2 → ok
  hub  v1.1.10 → v1.2.1 · Δseq=1 · oasisVersion+1 · log: flume → db2 → ok
  bot  v1.1.10 → v1.2.1 · Δseq=2 · oasisVersion+1 pubAvailability+1 · log: flume → db2 → ok
GATE OK
```

Medido a los cinco minutos de recrear el último nodo. Ningún `(cifrado)` nuevo, misma dirección
ECOin (`EYdruXgDVQGhBpSsns83VA1BmDfAKBP4Lc`), un único mensaje `wallet`, mismas épocas
(`2026-09,2026-10`: la de octubre ya estaba abierta, así que encender el motor no publicó
`ubiAllocation`). Foto final: `devops/logs/upgrade/post-o123.remote.snap`.

## Pasos

| Paso | Qué pasó |
|---|---|
| 0 · Medir | foto `pre-o123` con la medida nueva: pub 16, HUB 12, bot 55 mensajes propios; las tres fuentes cuadran. Ficheros de build del host traídos y diferenciados (BRIEF) |
| 1 · Backups (GO-1) | pub → `devops/backups/oasis-pub/20261004T015515Z`; `wallet.dat` → `devops/backups/ecoin/20261004T015710Z`; en el host `/srv/oasis/oasis-{hub,wallet-bot}.bak-o123-2026-10-04.tgz` (600) y `*.bak-o123-2026-10-04` de siete ficheros |
| 1 · Convergencia | `Dockerfile`, `docker-entrypoint.sh` y `docker-compose.pub.yml` sustituidos por los del repo (sha256 verificado); `.dockerignore` del host **ampliado**, no sustituido (es de su layout). `compose config -q` válido. Diferencia efectiva del compose: `mem_limit` y `logging` del pub, `logging` de panel-api y web, `OASIS_SNAPSHOT=off` en HUB y bot |
| 2 · Disco | retirados `src.old-1.1.4`, `src-1.1.4.tgz` e imagen `:1.1.4`; `builder prune` recuperó 2,26 GB. `/` del 52 % al 42 % |
| 3 · Rollback previo | tag `:1.1.10` · `/srv/oasis/src-1.1.10.tgz` · `src.old-1.1.10` |
| 4 · `src/` | `git -c core.autocrlf=false -c core.eol=lf archive`. En el host: versión 1.2.1, 0 CR en `backend.js`, `is-map` y `ssb-ref`, enlace real a `../base/node_modules`, 24 901 ficheros (los del repo), guard del dominio, guards de `backend.js` y `ssb_config.js` |
| 5 · Herramientas | `snapshot-build.js`, `log-bipf.js`, `ssb-probe.js` en `OASIS_PUB/tools/` (sha256 verificado) |
| 6 · Build y humo | imagen 1.2.1 de **1,08 GB** (la 1.1.10: 2,97 GB); `nucleo vendorizado: carga en node v22.23.3`. Humo sin red: `server` y `backend` `running`, tres parches, `GET /c → 200`, ningún `.env.prod` ni resto de rollback dentro de la imagen |
| 6 · Ensayo de migración | abajo |
| 7 · Pub (GO-2) | parado 02:21:19; tgz en frío `oasis-pub.cold-o123-2026-10-04.tgz` (582 MB); arriba y `healthy` a los 30 s; guarda escrita a las 02:23:01. Unos dos minutos de caída. Invite, `/public/status` (versión 1.2.1), landing y `/c` en 200; directorio `online`, ciclo 6 |
| 8 · HUB (GO-3) | config in place tras comprobar que la viva era la de `main`; tgz en frío (476 MB); `healthy` a los 60 s. `prune-cache` (249 MB) y `hub --strict`: `GATE OK` |
| 8 · Sala 04 | `site/hub/index.html` in place tras comprobar que la viva era la de `main`: 17 tipos |
| 9a · Bot en pausa (GO-4a) | backup de cartera, tgz en frío (76 MB), plantilla in place, render con `sudo`, `hub-wallet.sh pause`: 1.2.1, `pub=false`, `oasisVersion` +1 |
| 9b · Motor (GO-4b) | `hub-wallet.sh on --yes`: `ready` con todas las precondiciones en `ok`; `pubAvailability` 28 → 29; backup de cartera posterior (`20261004T024950Z`) |
| 10 · Cierre | `check` a los 5 min, `snapshot post-o123`, journal (`deploy-log.sh`), `capacity.sh`, ficha de instancia |

## Ensayo de migración en el host (antes de recrear a nadie)

Copia del `flume/log.offset` de cada nodo, sin `secret`, contenedor efímero `--network none` de la
imagen nueva; la copia se borró al acabar.

| Nodo | Antes (flume) | Después (db2) | Guarda a los | `db2/` | Memoria | Errores |
|---|---|---|---|---|---|---|
| pub | 4 552 registros · 77 autores · `tailOk` | T 4552 · A 77 · D 0 | 3 s | 5,7 M | 78 MiB | 0 |
| HUB | 3 778 · 66 | T 3778 · A 66 · D 0 | 2 s | 4,8 M | 75 MiB | 0 |
| bot | 4 242 · 65 | T 4242 · A 65 · D 0 | 2 s | 5,4 M | 75 MiB | 0 |

Ni un registro de más ni de menos. A diferencia del ensayo local, el total no subió en uno: la
identidad desechable del ensayo no publicó `oasisVersion` en los 15 s de espera. No se investigó.

## Visor en producción

```
$ upgrade-gates.sh --remote hub --strict
  ok    /c → 200
  ok    caché: MISS → HIT
  ok    una sola cabecera Content-Security-Policy
  ok    idioma por defecto «es» igual con Accept-Language de/es/fr y con cookies
  ok    ?lang= elige el idioma (de, es)
  ok    sin cruce de idiomas en 16 peticiones concurrentes
  ok    /c?type=files → 200
  ok    /c/sitemap.xml → 200, 130 URLs, todas https
  ok    /c/rss/feed → 200, 20 URLs, todas https
  ok    /c/rss/files → 200, 3 URLs, todas https
GATE OK
```

## Capacidad del host tras el ciclo

`capacity.sh`: **0 avisos · 0 sin medir** (6 s). Por nodo: log db2 3 MB e índices 1 MB; blobs pub
554 MB (sin recolector), HUB 462 MB (techo 2048), bot 71 MB (techo 256); memoria pub 5 % de 1024 MB,
HUB 26 % de 768, bot 18 % de 768; los tres con rotación de log de Docker. Host: `/` 49 %,
`/srv/oasis` 27 %, imágenes 5 GB, 3 restos de rollback (los de este ciclo), cadena de ecoind 65 MB.

## Desviaciones

1. **Render de la config del bot**: `render-wallet-bot-config.sh` falló en un `chmod` («Operation not
   permitted»). Parada; el fichero no se había tocado (mismo contenido y fecha del 1 de octubre). Es
   la trampa ya registrada (WP-O114, ECOIN §5.2): en el host el destino es de otro uid y está a 400,
   y el render se hace con `sudo`. Repetido con `sudo`: `OK`, mismo inodo y dueño, sin marcadores
   sin rellenar, `language` conservado en `en`. El bot estaba parado; no arrancó nada con la config a
   medias. **Corrección**: el paso 9 del protocolo dice ya «render con `sudo` en el host».
2. Ninguna otra salida inesperada.

## Hallazgos

- **`/public/status` devuelve un invite con su semilla**, y es público. Es comportamiento previo de
  la instancia; al consultarlo, ese invite quedó en la salida de la sesión. Seguimiento: decidir si
  ese endpoint debe dar invites.
- **`logging` de panel-api y del edge**: está en el compose pero no aplicado; esos contenedores no
  se han recreado (el edge no se reinicia sin motivo). Entra en su próxima recreación.
- **Layout del host**: la carpeta del compose es `OASIS_PUB/` y las herramientas quedan en la imagen
  en `/app/OASIS_PUB/tools/`. `test-invite.sh` asume `/app/pub/tools/`: el invite se probó llamando a
  `ssb-admin.js` por su ruta real.
- **No se retiraron** los `*.bak-o106-*.tgz` de `/srv/oasis`: el GO-1 se pidió para los restos de
  1.1.4, no para ellos.
- La migración real duró segundos (logs de 4 MB) y los nodos en 1.1.10 siguieron replicando con el
  pub ya en 1.2.1 mientras duró el ciclo.

## Paso 9b · Snapshot del pub (GO-5)

```
$ pub-snapshot.sh status          → snapshot: no hay (el pub responde not available)
$ pub-snapshot.sh build           → {"ok":true,…,"messages":4562,"feeds":77,"boxed":697,"bytes":1747010,"ms":1080}
$ pub-snapshot.sh status          → snapshot: 1747010 bytes · hace 0 h · {"version":1,"kind":"snapshot",…,"messages":4562,"feeds":77,…}
$ upgrade-gates.sh --remote check post-o123 --expect 'bot:pubAvailability=+0..1'
  pub  v1.2.1 · Δseq=0 · sin publicaciones → ok      (hub y bot, igual)      GATE OK
```

El pub ofrece ya su snapshot: 4 562 mensajes de 77 feeds en 1,7 MB, construido en un segundo y sin
publicar nada. La orden que llamará el temporizador (el script dentro de la imagen, en
`/app/OASIS_PUB/tools/`) se probó a mano: mismo resultado.

**Desviación, con parada: el temporizador no está instalado.** El host no tiene `cron`
(`crontab: command not found`; ni `cron` ni `systemd-cron` instalados): lo que hay son temporizadores
de systemd. La lectura del paso 0 dio «crontab vacío» porque la orden fallaba en silencio.
Instalar una unidad de systemd es otro cambio en el host y pide su propio GO. Hasta entonces el
snapshot **no se refresca solo**: los clientes nuevos reciben el del 2026-10-04 y replican el resto.

## Rollback

No hay: los tres nodos han migrado. Quedan, para corregir hacia delante o para `RECOVERY-PROTOCOL.md`
§4: las tres copias en frío `/srv/oasis/oasis-{pub,hub,wallet-bot}.cold-o123-2026-10-04.tgz`, la
imagen `:1.1.10`, `src.old-1.1.10` y `src-1.1.10.tgz`. Se retiran cuando el ciclo siguiente los
sustituya.

## Pendiente

- **Temporizador del snapshot**: el host no tiene `cron`; decidir entre una unidad de systemd o
  instalar `cron`, y que `pub-snapshot.sh` imprima lo que corresponda.
- **A las 24 h**: `check post-o123` (esperado: `pubAvailability` +1 o +2, cifrados 0), memoria de
  los tres nodos, `capacity.sh`; fijar los presupuestos con esa medida.
- **Cliente**: drill y `client:test-ai` con `OASIS_AI=full`, y GO aparte si la identidad es real.
- Backups de hoy (`devops/backups/{oasis-pub,ecoin}/20261004T*`, con `secret` y `wallet.dat`) a
  almacenamiento cifrado fuera de la máquina.
- Push y merge a `main` de las dos ramas.
