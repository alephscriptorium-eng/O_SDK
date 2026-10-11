# canva/ · las tres piezas de identidad de Acampada26S

Enlaces entregados por el custodio el 2026-10-11 (acortadores `canva.link`), resueltos con
`curl -sIL` el mismo día. Los tres son enlaces **de edición** (`/edit`): sin sesión de Canva devuelven
`403`, así que la descarga se hace a mano desde el navegador con sesión y se deposita aquí.

| Pieza | Acortador | Diseño (resuelto) | Carpeta destino | Estado |
|---|---|---|---|---|
| KIT VISUAL | `https://canva.link/82o6d2lwolcctsw` | `https://www.canva.com/design/DAHXCGOgH2E/1lIYrVroTYfzQt8tZDZXyA/edit` | `kit-visual/` | ✓ 2026-10-11: `ACAMPADA BRAND KIT .pdf` (19 págs, 24,5 MB), exportado por el equipo |
| POST | `https://canva.link/4qk1xlcplw2fa65` | `https://www.canva.com/design/DAHXEHpvYUY/u85j_5kJNWXNBBhGR-30UA/edit` | `post/` | ✓ 2026-10-11: 32 PNG 1080×1350 (de 34 páginas del diseño; sin duplicados por sha256), exportado por el equipo |
| RECURSOS GRÁFICOS | `https://canva.link/tatovgme5p4ty6v` | `https://www.canva.com/design/DAHXEFmMbQg/kJsQnfXnGSAv1v0VndVo3g/edit` | `recursos-graficos/` | ⬜ (la vista pública sale en blanco: hace falta exportarlo con sesión) |

## Cómo exportar (Canva → aquí)

Para cada diseño, en Canva: **Compartir → Descargar**.

- Páginas con texto o varias piezas (kit, post): **PDF estándar** una vez (conserva todo) **y PNG** por
  página (tamaño 1×, fondo transparente si el diseño lo permite). Nombre: `<pieza>-pNN.png`.
- Elementos sueltos (recursos gráficos): **PNG con fondo transparente** página a página, o
  **SVG** si Canva lo ofrece (recordar: `/c/blob/:id` del pub no sirve SVG; el kit final es PNG).
- Dejar el fichero exactamente como lo entrega Canva; no renombrar más allá del prefijo de pieza.

Después, el manifiesto de cada carpeta se regenera con:

```sh
python -X utf8 ARCHIVO/DISCO/26sm-exported/canva/manifest.py
```

La columna «Para qué» de cada `MANIFEST.md` se rellena a mano y se conserva entre ejecuciones mientras
el sha256 del fichero no cambie.

## Cómo llegaron (2026-10-11)

- La extensión Claude in Chrome no estaba conectada: los `/edit` dan 403 sin sesión. La variante `/view` de cada
  diseño es pública (HTTP 200) y expone miniaturas firmadas y caducas (`disableexport=T`): sirven para ver, no para usar.
  Medido con ellas: KIT VISUAL «ACAMPADA BRAND KIT» 19 páginas 16:9; POST «POST ACAMPADA26S» 34 páginas 4:5;
  RECURSOS GRÁFICOS 1 página que sale en blanco.
- Dos piezas las exportó el equipo desde su sesión y las dejó en la carpeta del dosier; se movieron aquí sin renombrar
  (el PDF conserva el espacio antes de `.pdf` tal como salió de Canva). Faltan 2 páginas del POST y toda la pieza de
  recursos gráficos.
- Del PDF del kit se extraen las imágenes embebidas con `entrada/extraer-brandkit.py` → `kit-visual/extraido/` (binarios
  fuera de git; `manifest.json` dentro) y el texto se resume citado por página en `kit-visual/BRANDKIT.md`.
- Peso: 96 MB de binarios. Si se decide no versionarlos, van a `.gitignore` y queda solo el `MANIFEST.md` (sha256) como
  prueba de qué había.
