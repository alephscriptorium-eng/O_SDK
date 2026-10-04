# Capacidad · lo que crece en una instancia y cómo se limita

> **Para qué.** Un pub no se llena de golpe: se llena por una pieza que nadie miraba. Esta página es
> el inventario único de todo lo que crece en disco y en memoria, quién lo hace crecer, qué límite
> tiene y cómo se mide. Las piezas tienen además su detalle propio (`HUB-PROTOCOL.md` §6,
> `ECOIN-PROTOCOL.md` §6); aquí está la vista de conjunto.
>
> **Regla.** Si añades una pieza que escribe en disco, añade su fila y su medida. Una pieza sin fila
> es la que llenará el disco.

## 1. Medir

```bash
bash devops/scripts/capacity.sh            # el host de la instancia, por SSH · solo lectura
bash devops/scripts/capacity.sh --local    # el stack local
bash devops/scripts/capacity.sh --json     # una línea para un journal
```

Cada fila sale con un estado: `ok`, `AVISO` (pasa su presupuesto, o no tiene límite donde debería
tenerlo) o `?` (no se pudo medir). Sale con `0` si todo está bien, `1` con avisos, `2` si un disco
pasa el umbral duro y `3` si algo no se pudo medir. `deploy-status.sh` lo resume.

Los **presupuestos** son umbrales de aviso, no límites: se ajustan por entorno (`CAP_*`, ver la
cabecera del script) y se fijan con la medida del host, no a ojo. El **límite**, cuando existe, lo
pone la pieza: el compose, la config del nodo o nginx.

## 2. Inventario

### Por nodo de Oasis (pub, HUB, bots)

| Qué crece | Dónde | Quién lo hace crecer | Límite | Al pasar el presupuesto |
|---|---|---|---|---|
| Log | `ssb-data/db2/log.bipf` (Oasis ≥ 1.2) o `flume/log.offset` | la replicación: todo feed a `hops` saltos | `friends.hops` y `friends.dunbar` del `ssb-config` del nodo. No se poda | bajar `hops` o `dunbar` es una decisión de red: cambia a quién se replica |
| Índices | `ssb-data/db2/indexes`, `db2/jit` | el log | ninguno; son derivables (se regeneran borrándolos, con el nodo parado) | crecen con el log: se actúa sobre el log |
| Blobs | `ssb-data/blobs` | la replicación y lo que pide el visor | **backend** (HUB, bots): `blobCache.pubMaxMB` en su `oasis-config.json`; lo fija `pub/scripts/regen-node-configs.js`. **pub** (solo sbot, sin recolector): `hub-disk.sh prune-blobs --node pub` | subir el techo o podar. Un blob borrado se vuelve a pedir a la red si alguien lo solicita |
| Snapshots | `ssb-data/oasis/content/snapshot*.oasissn` | **pub**: `pub-snapshot.sh` (temporizador de systemd en el host). **HUB y bots**: nadie, con `OASIS_SNAPSHOT=off` | techo `SNAPSHOT_MAX_MB` (por encima no se publica y queda el anterior). Crece con el log | subir el techo o retirar el servicio: `pub-snapshot.sh off` |
| Logs de la aplicación | bind de `/app/logs` | el nodo | ninguno | vaciar con el nodo parado |
| Log de Docker | `/var/lib/docker/containers/…` | la salida del contenedor | `logging` del compose (`max-size` × `max-file`) en **todos** los servicios | un servicio sin `logging` es un aviso: no tiene techo |
| Capa del contenedor | `/tmp` (subidas, descarga de un snapshot) y `/app/src/maps/cache` | el backend | ninguno; se vacía al recrear el contenedor | recrear el nodo en la misma versión no publica nada |
| Memoria | — | el nodo; en el pub, también la construcción del snapshot | `mem_limit` del compose en **todos** los nodos | subir el límite solo tras medir el pico; un nodo que llega al límite se reinicia |

### Del host

| Qué crece | Dónde | Límite | Al pasar el presupuesto |
|---|---|---|---|
| Disco de datos y disco raíz | — | umbral blando 75 %, duro 90 % | por encima del duro no se construye ni se despliega |
| Imágenes y caché de build | `/var/lib/docker` | se podan en cada deploy (`UPGRADE-PROTOCOL.md` §4, paso 2) | `docker image prune -f` · `docker builder prune -f` |
| Restos de rollback | `src.old-*`, `src-*.tgz`, tags de imagen | uno por ciclo; se retiran al sustituirlos el siguiente | `UPGRADE-PROTOCOL.md` §4, paso 2 |
| Caché HTTP del visor | bind de `/var/cache/hub` | `max_size` e `inactive` de nginx | `hub-disk.sh prune-cache` |
| Cadena de ecoind | datos de ecoind | ninguno: no se puede podar | proyectar su crecimiento; es el dato que decide el tamaño del disco |
| Backups | en el host y en la máquina operadora | en el host, `ECOIN_BACKUP_KEEP`; en la máquina operadora, a mano | moverlos a almacenamiento cifrado fuera de la máquina (`AGENTES.md` §2.7) |

## 3. Lo que hace solo un nodo (Oasis ≥ 1.2)

Un backend trae temporizadores que tocan el disco sin que nadie lo pida:

| Temporizador | Cuándo | Qué hace | En esta arquitectura |
|---|---|---|---|
| Recolector de blobs | a los 5 min y cada 6 h | por encima del techo, borra los blobs ajenos menos usados de más de 24 h. Protege los propios, los fijados y los recientes | activo en HUB y bots con el techo de su config. Con el valor de upstream (`pubMaxMB = 0`) no haría nada |
| Construcción de snapshots | a los 2 min y cada 6 h, en un backend público | carga el log **entero** en memoria, dos veces, y escribe dos ficheros | apagado con `OASIS_SNAPSHOT=off`. El del pub lo construye `pub-snapshot.sh`, con memoria constante |
| Limpieza de envíos de ficheros | a los 2 min y cada 12 h | borra los trozos de los envíos **propios** caducados | no hace nada en un nodo de soporte: no envía ficheros |

Ninguno publica en SSB.

## 4. Picos

- **Migración del log** (primer arranque en Oasis 1.2): conviven el log viejo y el nuevo. Hace falta
  libre el doble del log de cada nodo, además de la copia en frío previa.
- **Build de la imagen**: cada reconstrucción deja capas viejas hasta la poda.
- **Construcción del snapshot**: escribe un `.tmp` junto al fichero vigente antes de sustituirlo.
