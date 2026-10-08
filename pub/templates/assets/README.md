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
