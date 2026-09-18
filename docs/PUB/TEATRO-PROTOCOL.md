# Protocolo del Teatro (obras estáticas con zip certificado)

> **Este repo es el sitio del Teatro** (`C:\S_LAB\o-sdk`,
> `https://github.com/alephscriptorium-eng/O_SDK.git`). La sala vive en
> `https://pub.escrivivir.co/teatro/` como Sala 03 del Scriptorium.

> **Estado · WP-O99 (2026-09-18).** El Teatro es ya **autocontenido en o-sdk**: el generador está en
> git (`pub/rrss-sidecar/`), el lore del usuario vive en `ARCHIVO/LORE/` (ignorado por git) y la
> obra se genera en `volumes-dev/teatro/<obra>/`. Obra Nº 1 «Aleph Cero»: generación 2026-09-18,
> 1940 posts. Cómo se hace una obra desde un export de X: [`RRSS-SIDECAR-PROTOCOL.md`](./RRSS-SIDECAR-PROTOCOL.md).

Checklist operativo para **publicar** una obra en el Teatro: invariantes, alta en el catálogo,
deploy, certificación, verificación y realidad del VPS.

> **Modelo mental.** El Teatro separa **catálogo** de **contenido**. La portada (`/teatro/`) es una
> plantilla versionada en `pub/site-templates/teatro/`. Las obras son árboles pesados que NO viajan
> en git: se **generan** desde un lore con un sidecar, viven en el **volumen de datos** del VPS
> (`/srv/oasis/teatro/<obra>/`) y `pub-web` (Caddy) los monta read-only en `/srv/site/teatro`
> sobre el mountpoint vacío `pub/site/teatro/` (**el visor**).
>
> ```
> ARCHIVO/LORE/<fuente>/<obra>/ → pub/rrss-sidecar/<fuente>/ → volumes-dev/teatro/<obra>/ → /srv/oasis/teatro/<obra>/
>      lore (privado)               sidecar (git)               visor local (:8088)         visor en producción
> ```

## 0. Invariantes de una obra

Toda obra del Teatro cumple (la definición ejecutable es `pub/rrss-sidecar/twitter_x/lib/guards.py`;
la corre el build, `npm run teatro:check` y el pre-vuelo del deploy):

- **Cero JavaScript** en las páginas generadas: HTML + un CSS propio. El vídeo se sirve con
  `<video controls preload="metadata">`.
  **Excepción declarada:** `navegador.html`, el visor oficial del export de X, limpiado (whitelist de
  datos, manifest podado, sin CDNs). Es la única página con `<script>` y los únicos `.js` están en
  `assets/js/` y en la whitelist de `data/`. Se desactiva con `publish.viewer: false`.
- **Cero recursos externos cargados.** Ni CDNs, ni fuentes remotas, ni imágenes de terceros en
  caliente: la foto de un tuit ajeno se descarga a `data/external_media/` o no se muestra. Los
  enlaces `<a href>` externos sí están permitidos.
- **Texto verbatim, citado por id.** Nada se resume en lugar de la fuente; el texto ajeno no
  recuperado no se completa ni se inventa (`AGENTS.md` de la obra).
- **Nada sensible.** Fuera IPs, teléfonos, device tokens, DMs, bloqueos/mutes, likes/follows, chats
  de IA del export y **posts borrados por el autor** (se conservan solo en el lore). La obra publica:
  media propia de los posts visibles, HTML generado, corpus Markdown, stores públicos y los zips.
- **Descarga certificada con letrero.** SHA-256 visible en la página y firma ed25519 (§4). Las
  páginas que muestran el hash usan el placeholder literal `__ZIP_SHA256__`; el deploy lo estampa.

## 1. Generar el árbol de la obra

```bash
npm run teatro:build -- --obra <obra>       # → volumes-dev/teatro/<obra>/  (+ volumes-dev/teatro/index.html)
npm run teatro:check -- --obra <obra>       # invariantes
npm run pub:local:up                        # vista previa: http://localhost:8088/teatro/<obra>/
```

El árbol lo produce un sidecar (`RRSS-SIDECAR-PROTOCOL.md`). El contrato con el Teatro es solo el
árbol: `index.html` con `__ZIP_SHA256__`, páginas, `assets/`, `data/` (whitelist), `corpus/`,
`indexes/`, `tools/`, `AGENTS.md`. El pub local ya monta `volumes-dev/teatro` en `/teatro/`
(`OASIS_PUB_TEATRO_DIR`, default `../volumes-dev/teatro`).

## 2. Alta en el catálogo

- Añadir o actualizar la tarjeta de la obra en `pub/site-templates/teatro/index.html` (título,
  copy, cifras, `door-link` a `/teatro/<obra>/`). **El zip completo es la descarga destacada**; el
  zip ligero y el manifiesto se rotulan «para inspección». Bloque `SHA-256 DEL ZIP: __ZIP_SHA256__`
  con enlaces a `.sha256` y `.sig`.
- Commit en `main`. El build y el deploy copian esta portada al árbol antes de subir.

## 3. Deploy (subida + zips + checksums + firma + verificación)

```bash
TEATRO_OBRA=<obra> TEATRO_DRY_RUN=1 npm run devops:teatro:deploy   # qué subiría (y qué borraría)
TEATRO_OBRA=<obra> npm run devops:teatro:deploy                    # en Windows corre dentro de WSL (rsync, python3)
```

Qué hace `devops/scripts/deploy-teatro.sh`, en orden:

1. **Pre-vuelo local**: `sidecar.py check` (invariantes) y `sidecar.py manifest` → `MANIFEST.sha256`
   (hash de cada fichero servido; excluye la portada, que se estampa después, y los artefactos).
2. Copia la portada del Teatro del repo al árbol.
3. `rsync -a --partial --chmod=D755,F644` de **solo esa obra** y de `index.html` →
   `/srv/oasis/teatro/`. Reanudable. `TEATRO_DELETE=1` hace espejo **dentro de `<obra>/`**, nunca
   fuera (así desaparecen del servidor las páginas de posts borrados).
4. **Integridad**: `sha256sum -c MANIFEST.sha256` en el VPS, antes de estampar nada.
5. **Dos zips en el VPS** (evita subir el peso dos veces):
   `<obra>.zip` = **todo** el árbol con la media, sin comprimir (`zip -0`), la descarga principal; y
   `<obra>-cerebro.zip` = corpus, índices, herramientas y stores, para inspección o gestión.
6. `sha256sum` de ambos y `sed` del hash del zip completo en los dos letreros.
7. Firma **en local** de `<obra>.zip.sha256`, `<obra>-cerebro.zip.sha256` y `MANIFEST.sha256`
   (`ssh-keygen -Y sign -n file` con la clave de acceso al VPS; la privada nunca viaja) y sube las
   `.sig` + `allowed_signers`.
8. **Verificación automática** (§5). Un fallo termina con código ≠ 0.

Variables: `TEATRO_OBRA` (obligatoria), `LOCAL_TEATRO_DIR`, `REMOTE_TEATRO_DIR`, `TEATRO_DRY_RUN`,
`TEATRO_DELETE`, `TEATRO_SKIP_ZIP`, `TEATRO_SKIP_VERIFY`.

## 4. Qué se certifica (y cómo lo comprueba un visitante)

- **Integridad**: `<obra>.zip.sha256` (visible además en el letrero), `<obra>-cerebro.zip.sha256` y
  `MANIFEST.sha256` (un hash por fichero servido: permite verificar un mirror sin bajar el zip).
- **Procedencia**: las tres `.sig`, firma ssh-ed25519 con la misma clave que abre el VPS. La pública
  está en `allowed_signers` (principal `teatro@escrivivir.co`, namespace `file`).

```bash
sha256sum -c <obra>.zip.sha256
ssh-keygen -Y verify -f allowed_signers -I teatro@escrivivir.co -n file -s <obra>.zip.sha256.sig < <obra>.zip.sha256
# mirror + verificación fichero a fichero:
wget -r -np -nH --cut-dirs=2 https://pub.escrivivir.co/teatro/<obra>/ && sha256sum -c MANIFEST.sha256
```

## 5. Verificación post-deploy

La ejecuta el propio deploy. Manualmente: `TEATRO_OBRA=<obra> npm run devops:teatro:verify`
(árbol remoto contra el manifiesto local, recuento, tamaño, permisos). Comprueba: `/teatro/`,
`/teatro/<obra>/`, `/enlaces/`, checksums y manifiesto → 200; un `.mp4` con `Range` → 206;
`data/ip-audit.js` y `data/direct-messages.js` → **404**; hash estampado; portada sin `<script>`;
nada world-writable; `/` y `/public/status` vivos; y avisa si `/teatro/no-existe/` no da 404 (§6).

Respaldo de lo no regenerable: `TEATRO_OBRA=<obra> npm run devops:teatro:backup` (portada estampada,
firmas, manifiesto y los **stores de voces y enlaces** del lore). El árbol servido no se respalda: se
regenera. Los exports son responsabilidad del usuario (`ARCHIVO/LORE/README.md`).

## 6. Realidad del VPS — leer antes de tocar

- El stack vivo corre desde **`/opt/oasis-scriptorium/OASIS_PUB`** (layout antiguo, **sin git**), no
  desde el checkout `pub/` que describe `devops/MIGRATION-2026-07.md`. La migración sigue pendiente;
  los ficheros se suben **in place** (`cat >`), nunca reemplazando el inode de un bind de fichero.
- El mount del Teatro se añadió al compose **vivo** a mano (backup `docker-compose.pub.yml.bak-teatro`);
  `OASIS_PUB_TEATRO_DIR=/srv/oasis/teatro` está en `.env` y `.env.prod` de ese directorio.
- **La obra vive en el volumen de datos** (`/dev/xvdb`, `/srv/oasis/teatro`), no en el disco de
  sistema. `verify-debian13-base.sh` lo comprueba (existe, permisos, nada world-writable) y
  `hub-disk.sh status` lo mide.
- **Bloque `@teatro` del Caddyfile** (`pub/caddy/Caddyfile`): 404 real bajo `/teatro/` (sin el
  fallback a la landing del `handle` genérico), `Cache-Control`, CSP estricta para las páginas
  generadas y CSP propia para `navegador.html`. El Caddyfile vivo es **compartido por más vhosts**:
  backup → subir → `docker exec oasis-pub-web caddy validate --config /etc/caddy/Caddyfile` →
  `caddy reload`. **Nunca `restart pub-web`.**
- `pub/site/scriptorium/index.html` del repo y el vivo **divergen a propósito** (token público de
  PUBLIC_ROOM). Al desplegar el vestíbulo hay que **fusionar**, no pisar. `deploy-site.sh` usa
  `rsync --delete` sin exclusiones: no apuntarlo a `OASIS_PUB/site` sin revisar los `*.bak-*`.
- Recrear solo el edge: `cd /opt/oasis-scriptorium/OASIS_PUB && docker compose --env-file .env.prod
  -f docker-compose.pub.yml up -d pub-web`. El project name coincide con el del repo: el día de la
  migración Docker **adopta** contenedores y red.
