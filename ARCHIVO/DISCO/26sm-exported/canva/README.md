# canva/ · las tres piezas de identidad de Acampada26S

Enlaces entregados por el custodio el 2026-10-11 (acortadores `canva.link`), resueltos con
`curl -sIL` el mismo día. Los tres son enlaces **de edición** (`/edit`): sin sesión de Canva devuelven
`403`, así que la descarga se hace a mano desde el navegador con sesión y se deposita aquí.

| Pieza | Acortador | Diseño (resuelto) | Carpeta destino | Estado |
|---|---|---|---|---|
| KIT VISUAL | `https://canva.link/82o6d2lwolcctsw` | `https://www.canva.com/design/DAHXCGOgH2E/1lIYrVroTYfzQt8tZDZXyA/edit` | `kit-visual/` | ⬜ |
| POST | `https://canva.link/4qk1xlcplw2fa65` | `https://www.canva.com/design/DAHXEHpvYUY/u85j_5kJNWXNBBhGR-30UA/edit` | `post/` | ⬜ |
| RECURSOS GRÁFICOS | `https://canva.link/tatovgme5p4ty6v` | `https://www.canva.com/design/DAHXEFmMbQg/kJsQnfXnGSAv1v0VndVo3g/edit` | `recursos-graficos/` | ⬜ |

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

## Lo que no se ha podido medir

La extensión Claude in Chrome no estaba conectada en la sesión del 2026-10-11, así que el contenido de
los tres diseños **no se ha visto**: no se sabe cuántas páginas tiene cada uno ni qué formatos ofrece.
Lo de arriba es el procedimiento genérico; se corrige al primer intento real.
