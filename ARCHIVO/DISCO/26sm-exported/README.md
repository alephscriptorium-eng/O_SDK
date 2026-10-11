# 26sm-exported · la 26S de verdad: materiales, identidad visual y entrada para su pub

Carpeta de **plan + evidencia** (rama `dev/26sm-exported`, homóloga de
[`scriptorium-exported/`](../scriptorium-exported/README.md)) para hacer con **Acampada26S** lo que
allí se ensayó con la plantilla genérica Campamento: reunir sus materiales reales (identidad visual,
organigrama, plantilla) y dejarlos listos para la activación de su pub. Aquí ya no se neutraliza
nada: los nombres propios son los del colectivo. Lo que se mantiene en el tiempo es la doc viva
(`docs/PUB/TEMPLATE-PROTOCOL.md`); esto queda como rastro.

| Qué | Dónde | Estado |
|---|---|---|
| **Doc viva** (leer primero): método, vías de activación, kit visual, secretaría, reparto | `docs/PUB/TEMPLATE-PROTOCOL.md` | al día 2026-10-10 |
| **Entrada**: organigrama transcrito y su imagen original | `entrada/acampada26s_organigrama.json` · `entrada/esquema.jpg` | copia 1:1 de `../retro-exporter/entrada/` (transcripción del 2026-10-07); el correcto de momento |
| **Plantilla** de la 26S (no se duplica: vive en el repo) | `pub/templates/acampada26s.json` · contrato `pub/templates/SCHEMA.md` | 16 tribus + 9 sub-tribus, 7 salas, 7 calendarios, 1 evento, 4 listas, 4 wikis, 2 mapas; 8 pendientes del colectivo |
| Mapeo organigrama → Oasis (trazable por `id`) | `../retro-exporter/MAPEO.md` | cerrado 2026-10-07 |
| **Logos** del colectivo (6 variantes, 1021×1134 PNG) | `assets/` · inventario `assets/MANIFEST.md` | recibidos 2026-10-11 |
| **Canva**: kit visual, post, recursos gráficos | `canva/` · índice `canva/README.md` | ⬜ **pendiente de descarga** (enlaces de edición: piden sesión) |
| Kit visual 512×512 para la plantilla (tribus, salas…) | `pub/templates/assets/acampada26s/` (generador `pub/tools/template-kit.py`) | ⬜ no generado; decidir antes si se parte de los logos o del kit de Canva |
| Guion / guía de reparto / mensaje de entrada | `../retro-exporter/guion-acampada26s.md` hoy · aquí cuando se regeneren con los materiales reales | ⬜ |

## Cómo se trabaja esta carpeta

1. **Materiales primero, ejecución después.** Nada de esta carpeta publica nada: se recopila, se ordena
   y se deja regenerable. La activación (vía fría o caliente) sigue `docs/PUB/TEMPLATE-PROTOCOL.md` y
   pide GO del custodio paso a paso, como en `../scriptorium-exported/runbook-*.md`.
2. **La entrada no se edita a mano.** Si el colectivo corrige el organigrama, se corrige
   `entrada/acampada26s_organigrama.json` y se anota en `metadatos.notas_de_transcripcion`; la
   plantilla y el guion se regeneran:

   ```sh
   node pub/tools/template-seed.js \
     --template pub/templates/acampada26s.json \
     --organigrama ARCHIVO/DISCO/26sm-exported/entrada/acampada26s_organigrama.json \
     --out ARCHIVO/DISCO/26sm-exported/guion-acampada26s.md --guion
   ```

3. **Los binarios de Canva** van a `canva/<carpeta>/` tal cual se exportan, más un `MANIFEST.md` por
   carpeta (fichero, px, bytes, sha256, para qué sirve), regenerado con `canva/manifest.py`. Lo
   derivado (recortes, 512×512) va a `pub/templates/assets/acampada26s/` por el generador, nunca a mano.
4. **Secretos, ninguno.** Aquí no hay invites, `secret` ni credenciales; los enlaces de Canva son de
   edición compartida y se tratan como material del colectivo, no como credencial.

## Pendientes (2026-10-11)

- [ ] Descargar las tres piezas de Canva (ver `canva/README.md`) y rellenar sus manifiestos.
- [ ] Decidir con el colectivo cuál de las 6 variantes del logo es la **oficial** para el `about` del pub / bot.
- [ ] Rellenar los 8 `<pendiente>` de `pub/templates/acampada26s.json` (plaza, mesa técnica, autoría…).
- [ ] Generar el kit 512×512 y la guía de reparto con los materiales reales.
