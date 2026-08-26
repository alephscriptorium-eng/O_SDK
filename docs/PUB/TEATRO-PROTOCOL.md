# Protocolo del Teatro (obras estáticas con zip certificado)

> **Este repo es el sitio del Teatro** (`C:\S_LAB\o-sdk`,
> `https://github.com/alephscriptorium-eng/O_SDK.git`). La sala vive en
> `https://pub.escrivivir.co/teatro/` como Sala 03 del Scriptorium.

Checklist operativo para publicar una **obra** nueva en el Teatro. Deriva de la
Obra Nº 1 ("Aleph Cero", 2026-08-26): el archivo X de `@_dev_aleph_1` como sitio
estático de 1495 páginas con 719 MB de media.

> **Modelo mental.** El Teatro separa **catálogo** de **contenido**: la portada
> (`/teatro/`) es una plantilla versionada en `pub/site-templates/teatro/`; las
> obras son árboles pesados que NO viajan en git — viven en el volumen de datos
> Gandi (`/srv/oasis/teatro/<obra>/`) y `pub-web` (Caddy) los monta read-only en
> `/srv/site/teatro` sobre el mountpoint vacío `pub/site/teatro/`. Publicar una
> obra = generar árbol → rsync al volumen → zip + certificado en el VPS. No se
> toca Caddyfile, DNS ni UFW.

## 0. Invariantes de una obra

Toda obra del Teatro cumple:

- **Cero JavaScript.** HTML + un CSS propio, autocontenido. El vídeo se sirve con
  `<video controls preload="metadata">` (nativo, sin JS). `grep -r "<script" → 0`.
- **Cero recursos externos.** Ni CDNs, ni fuentes remotas, ni imágenes de
  terceros. Todo asset se sirve desde el propio árbol de la obra.
- **Texto verbatim, citado por id.** Nada se resume en lugar de la fuente; el
  texto ajeno no recuperado no se completa ni se inventa (protocolo del corpus,
  `AGENTS.md` de la obra).
- **Nada sensible.** Si la fuente es un archivo de plataforma (X u otra), quedan
  fuera IPs, teléfonos, device tokens, DMs, bloqueos/mutes, likes/follows, chats
  de IA y contenido borrado. La obra publica solo: media propia, HTML generado,
  corpus Markdown y el zip.
- **Zip certificado con letrero.** El corpus descargable lleva SHA-256 visible en
  la página y firma ed25519 (ver §4).
- Las páginas que muestran el hash usan el placeholder literal `__ZIP_SHA256__`;
  el deploy lo estampa (§3).

## 1. Generar el árbol de la obra

Cada obra tiene su generador; el contrato es el árbol staged:

```
C:\S_META\LORE\deploy\teatro\           ← raíz local que se sube tal cual
  index.html                            ← portada Teatro (la copia el deploy desde el repo)
  <obra>/
    index.html                          ← portada de la obra (con __ZIP_SHA256__)
    ... páginas, assets/, media ...
    corpus fuente (verbatim, si aplica)
```

Referencia (Obra Nº 1): `tools/build_site.py` del segundo cerebro TWITTER_FILM
(`C:\S_META\LORE\TWITTER_FILM\TWITTER_FILM`). Ejecuta `python tools/build_site.py`
y valida en el mismo build: whitelist de `data/` (aborta si se cuela un `.js` del
archivo crudo), cero `<script>`, y conviene pasarle después un link-checker a los
`href/src` internos. Vista previa local con las mismas rutas absolutas:
`python -m http.server 8137 --directory C:\S_META\LORE\deploy` →
`http://localhost:8137/teatro/<obra>/`.

## 2. Alta en el catálogo

- Añadir la tarjeta de la obra en `pub/site-templates/teatro/index.html`
  (título, copy, meta con cifras, `door-link` a `/teatro/<obra>/` y al zip, y el
  bloque `SHA-256 DEL ZIP: __ZIP_SHA256__` con enlaces a `.sha256` y `.sig`).
- Commit en `main`. El deploy copia esta portada al árbol staged antes de subir.

## 3. Deploy (subida + zip + checksum + firma)

```bash
# Desde Windows (rsync no viene en Git Bash; el script corre en WSL):
wsl -d Ubuntu -- bash /mnt/c/S_LAB/o-sdk/devops/scripts/deploy-teatro.sh
```

Qué hace, en orden:

1. Copia la portada del Teatro del repo al árbol staged.
2. `rsync -a --partial --info=progress2` (sin `-z`, la media ya está comprimida)
   → `debian@92.243.24.163:/srv/oasis/teatro/`. **Reanudable**: si se corta,
   relanzar. (Referencia: 754 MB subieron en ~50 s a 14 MB/s.)
3. Genera `<obra>.zip` **en el VPS** (evita subir el peso dos veces): `zip -rq` o
   fallback `python3 -m zipfile`. El zip contiene el corpus verbatim, no el HTML.
4. `sha256sum` → `<obra>.zip.sha256`, y `sed` estampa el hash en los dos
   letreros (`__ZIP_SHA256__` en `/teatro/index.html` y `/teatro/<obra>/index.html`).
5. Firma **en local** el `.sha256` con la clave de acceso al VPS
   (`ssh-keygen -Y sign -n file` con `devops/.ssh/gandi_pub_ed25519` — la
   privada nunca viaja) y sube `<obra>.zip.sha256.sig` + `allowed_signers`.

Variables: `LOCAL_TEATRO_DIR`, `REMOTE_TEATRO_DIR`, `TEATRO_DELETE=1` (espejo
con `--delete`, cuidado), `TEATRO_SKIP_ZIP=1` (no regenerar zip).

> **TODO segunda obra:** la lista de contenidos del zip y las rutas `<obra>`
> están fijadas a `aleph-cero` dentro de `deploy-teatro.sh` — parametrizarlas
> cuando entre la Obra Nº 2.

## 4. Qué certifica el zip (y cómo lo comprueba un visitante)

- **Integridad**: `aleph-cero.zip.sha256` (SHA-256 del zip, visible además en el
  letrero de la página). Detecta zip corrupto o manipulado.
- **Procedencia**: `aleph-cero.zip.sha256.sig`, firma ssh-ed25519 del fichero
  `.sha256` hecha con la misma clave que abre el VPS. Publicamos la pública en
  `allowed_signers` (principal `teatro@escrivivir.co`, namespace `file`).

Verificación (los mismos comandos están en el letrero de la obra):

```bash
sha256sum -c aleph-cero.zip.sha256
ssh-keygen -Y verify -f allowed_signers -I teatro@escrivivir.co \
  -n file -s aleph-cero.zip.sha256.sig < aleph-cero.zip.sha256
# → Good "file" signature for teatro@escrivivir.co with ED25519 key SHA256:YGHof3kw…
```

## 5. Verificación post-deploy

```bash
curl -s -o /dev/null -w '%{http_code}\n' https://pub.escrivivir.co/teatro/            # 200
curl -s -o /dev/null -w '%{http_code}\n' https://pub.escrivivir.co/teatro/<obra>/     # 200
curl -s -o /dev/null -w '%{http_code}\n' -r 0-1023 https://pub.escrivivir.co/teatro/<obra>/<un-mp4>  # 206
curl -sI https://pub.escrivivir.co/teatro/<obra>/<obra>.zip | grep -i content-length  # tamaño esperado
curl -s https://pub.escrivivir.co/teatro/<obra>/ | grep -c "<script"                  # 0
curl -s https://pub.escrivivir.co/teatro/<obra>/ | grep <hash-esperado>               # letrero estampado
```

Y la verificación de firma "en frío" del §4 descargando los tres artefactos.
Comprobar también que el resto de vhosts siguen vivos (`/`, `/public/status`,
`scriptorium.escrivivir.co/healthz`).

## 6. Realidad del VPS (2026-08-26) — leer antes de tocar

- El stack vivo corre desde **`/opt/oasis-scriptorium/OASIS_PUB`** (layout
  antiguo, **sin git**), no desde el checkout `pub/` que describe
  `devops/MIGRATION-2026-07.md`. La migración sigue pendiente.
- El mount del Teatro se añadió al compose **vivo** a mano, con backup:
  `docker-compose.pub.yml.bak-teatro`. `OASIS_PUB_TEATRO_DIR=/srv/oasis/teatro`
  quedó añadida a `.env` y `.env.prod` de ese directorio.
- `pub/site/scriptorium/index.html` del repo y el vivo **divergen a propósito**:
  el vivo publica el token de PUBLIC_ROOM (aparece en la web, no es secreto) y la
  etiqueta del diagrama dice `BlockchainComPort/OASIS_PUB`. Al desplegar el
  vestíbulo hay que **fusionar**, no pisar (hay backups `*.bak-teatro` en
  `site/`).
- Recrear solo el edge: `cd /opt/oasis-scriptorium/OASIS_PUB &&
  docker compose --env-file .env.prod -f docker-compose.pub.yml up -d pub-web`.
  El project name (`oasis-pub-scriptorium`) coincide con el del compose del repo,
  así que el día de la migración Docker **adopta** los contenedores y la red al
  levantar desde el checkout nuevo — no hay que destruir nada.
