# WP-O121 · Capacidad: inventario único de lo que crece y sus límites

Rama `upgrade/oasis-1.2.1` · 2026-10-04 · asiento D-O27 (punto 6). **Solo local: los límites no
están aplicados en el host.**

## Por qué

Al decidir el upgrade a 1.2.1 el custodio pidió una visión global: qué puede crecer demasiado y
cómo se limita. Había un script por pieza (`hub-disk.sh`, `ecoin-disk.sh`) y nadie miraba el
conjunto. 1.2.1 añade además un recolector de blobs que en un backend público viene apagado,
snapshots y un log con otro formato.

## Qué se entregó (`8aa4a80e`)

- `devops/scripts/capacity.sh` (`npm run devops:capacity`): solo lectura, local o por SSH. Por nodo:
  log, índices, blobs, snapshots, `/app/logs`, log de Docker, capa del contenedor, memoria. Del
  host: discos, imágenes, restos de rollback, cadena de ecoind, caché HTTP. Estado por fila; sale
  con 0, 1 (avisos), 2 (disco sobre el umbral duro) o 3 (no medible). `deploy-status.sh` enseña sus
  avisos.
- `docs/PUB/CAPACIDAD.md`: la tabla (qué crece · dónde · quién · límite · qué hacer), lo que hace
  solo un nodo en 1.2 y los picos.
- Límites: `mem_limit` y `logging` del pub, `logging` de panel-api y web
  (`pub/docker-compose.pub.yml`); `blobCache` en las configs de HUB (2048 MB) y bot (256 MB) por
  `regen-node-configs.js`; `hub-disk.sh prune-blobs --node pub`.

## Evidencia

**Antes de poner los límites**, `capacity.sh --local` señalaba justo los huecos:

```
  pub   AVISO   log de Docker       0 MB   · SIN ROTACIÓN
  pub   AVISO   memoria       51.94MiB     · SIN LÍMITE
  hub   AVISO   blobs               0 MB   (aviso > 2048) · SIN LÍMITE (pubMaxMB=0)
  bot   AVISO   blobs               0 MB   (aviso > 256) · SIN LÍMITE (pubMaxMB=0)
capacity: 6 avisos · 0 sin medir · 0 por encima del umbral duro
```

**Aplicarlos no publica nada.** Foto `c121`, recrear pub, HUB y bot con el compose y las configs
nuevas (misma versión), `check c121`:

```
  pub  v1.2.1 · Δseq=0 · sin publicaciones → ok
  hub  v1.2.1 · Δseq=0 · sin publicaciones → ok
  bot  v1.2.1 · Δseq=0 · sin publicaciones → ok
GATE OK
oasis-pub-hub: "blobCache":{"maxMB":2048,"pubMaxMB":2048}
oasis-pub-wallet-bot: "blobCache":{"maxMB":256,"pubMaxMB":256}
pub: mem_limit 1073741824 · logging max-file:5 max-size:20m
```

**Después**, los cuatro avisos de nodo desaparecen; quedan dos de la máquina de ensayo:

```
  pub   ok   log de Docker   0 MB · 20m×5
  pub   ok   memoria         4 % del límite (aviso > 80) · mem_limit=1024 MB
  hub   ok   blobs           0 MB (aviso > 2048) · blobCache.pubMaxMB=2048 MB
  bot   ok   blobs           0 MB (aviso > 256) · blobCache.pubMaxMB=256 MB
  host  AVISO imágenes de Docker (cota superior) 36 GB (aviso > 12)
  host  AVISO restos de rollback (src.old*, tgz, tags) 6 (aviso > 3)
capacity: 2 avisos · 0 sin medir · 0 por encima del umbral duro
```

Portal: `npm run docs:verificar` en verde (enlaces, anclas, ceguera: 0 menciones a la demo en el
ámbito ciego, trinquete en 52).

## Lo que no se ha medido

- **Nada contra el host.** Los presupuestos (`CAP_*`) y los valores (1024 MB de memoria para el pub,
  2048 y 256 MB de blobs) son provisionales: se fijan con `capacity.sh` sobre el VPS y el pico de
  memoria del pub tras 24 h. El compose del host deriva del repo: los límites entran al converger.
- **El recolector de blobs actuando**: en local no hay blobs. Con el techo puesto, el HUB pasará a
  borrar solo los blobs ajenos menos usados de más de 24 h; antes era una poda manual.
- `/c/blob` no anota el uso del blob (`touch` solo se llama desde `/blob` e `/image`): en el HUB el
  recolector decide por la fecha del fichero, no por las visitas del visor.

## Hallazgos

- `docker system df` tardó **5 minutos** y `docker ps -s` 52 s en la máquina de ensayo: el script
  hace una sola llamada de cada tipo y no usa `system df`. Las imágenes se dan como cota superior.
- Un `du` sin rutas mide el directorio actual: la función de tamaño devuelve 0 si no recibe nada.
- El bot corre como backend público: el «límite de 2 GB» que se temía al principio no existía; lo
  que había era ningún límite.

## Seguimiento

- WP-O123: `capacity.sh` contra el host en el paso 0 y en el cierre; ajustar presupuestos.
- Rotación de `/app/logs` y de los backups de la máquina operadora: quedan como fila con aviso, sin
  mecanismo.
- A upstream: `/c/blob` debería anotar el uso del blob.
