# Kit visual de las plantillas de organización

Imágenes que `pub/tools/template-seed.js --hot` sube como blobs al crear cada objeto (tribu, sala, mapa,
evento, portada de wiki). Un directorio por plantilla (`<assets>/<meta.id>/`), referenciado desde el
campo `image` de cada entrada (`pub/templates/SCHEMA.md`, «Imágenes»).

- **Formato: PNG** (jpg/webp también valen). **SVG no**: `/c/blob/:id` no lo reconoce y el blob se
  sirve como adjunto (`src/backend/blobHandler.js:305-313`). Techo 50 MB; recomendado ≤ 1 MB.
- **Generado, no dibujado a mano**: `pub/tools/template-kit.py` (Python + PIL, determinista; la fuente se
  pasa con `--font`, no se usan fuentes del sistema). `manifest.json` lista cada fichero con su sha256 y el
  **blob id previsto** (`&<base64(sha256)>.sha256`): el dosier lo cita antes de subir nada y los gates comparan.
- **No viaja en la imagen Docker**: `.dockerignore` excluye `*.png`. El bot lo monta por bind
  (`OASIS_RETRO_BOT_ASSETS_DIR`, `pub/docker-compose.pub.yml`); en el VPS se copia a `/srv/oasis/oasis-retro-bot/assets`.
- `wiki/<id>.md`: copia de cada `file:` de `wiki[]` que hace el generador del kit, porque el repo no está en
  el contenedor. La fuente sigue siendo el fichero original.

Regenerar: `npm run pub:template:kit` (plantilla Campamento). Dos ejecuciones dan los mismos bytes.

## Con la marca del colectivo (`--brand <marca.json>`, desde 2026-10-11)

`marca.json` lo escribe el derivador del dosier desde el organigrama (`instancia.marca`): paleta, fuentes (rutas), fondos (fotos de lona con
sha256), logo por versión, etiquetas por tipo y patrón de avatar. Con él, `template-kit.py` pinta foto de lona de fondo, caja de color con el
nombre en mayúsculas (tamaño ajustado, ≤ 3 líneas, en la banda central que sobrevive al recorte 280×140 del hub), etiqueta por tipo, logo con
aire; sin iconos ni sombras. `--avatar-brand` hace el avatar según el patrón del kit. El `manifest.json` añade `brand` con los sha256 de
`marca.json`, fuentes, logo y fondos. **Sin `--brand` el generador es byte a byte el de antes** (medido: 40/40 PNG de Campamento iguales).

**Fuentes**: solo se vendorizan fuentes libres (OFL, DejaVu); una tipografía propietaria (p. ej. Gill Sans) se pasa por ruta externa al repo
y nunca se commitea. Demo: `pub/templates/assets/acampada26s/` (`npm run pub:template:kit:26s`), 40 PNG de 200-410 KB.
