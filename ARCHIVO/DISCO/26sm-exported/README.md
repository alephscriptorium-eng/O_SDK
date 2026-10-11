# 26sm-exported · la 26S de verdad: materiales, identidad visual y entrada para su pub

Carpeta de **plan + evidencia** (rama `dev/26sm-exported`, homóloga de
[`scriptorium-exported/`](../scriptorium-exported/README.md)) para hacer con **Acampada26S** lo que
allí se ensayó con la plantilla genérica Campamento: reunir sus materiales reales (identidad visual,
organigrama, plantilla) y dejarlos listos para la activación de su pub. Aquí ya no se neutraliza
nada: los nombres propios son los del colectivo. Lo que se mantiene en el tiempo es la doc viva
(`docs/PUB/TEMPLATE-PROTOCOL.md`); esto queda como rastro.

| Qué | Dónde | Estado |
|---|---|---|
| **Doc viva** (leer primero): método, vías de activación, kit visual, secretaría, reparto; contrato de entrada v2 en §1 | `docs/PUB/TEMPLATE-PROTOCOL.md` | al día 2026-10-11 |
| **Entrada v2 · el JSON manda**: organigrama transcrito de la imagen + hechos de instancia (fuente, pub, lugares, apertura, reuniones, canales con id, marca, reparto) | `entrada/acampada26s_organigrama.json` · imagen original `entrada/esquema.jpg` | v2 2026-10-11; 33 ids; los 24 de la v1 intactos |
| **Derivador**: construye la plantilla desde el organigrama con las reglas R1-R5 y el contrato WP-O131 (`image`, `clearnetPublic`, `responsable`, `wiki_reparto`, `meta.reparto`); apunta en `procedencia.json` qué textos redactó él | `entrada/derivar-acampada26s.py` → `pub/templates/acampada26s.json` · `entrada/procedencia.json` | determinista (dos ejecuciones, mismos bytes); 38 textos del derivador |
| **Plantilla** derivada (no se edita a mano) | `pub/templates/acampada26s.json` · contrato `pub/templates/SCHEMA.md` | 16 tribus + 9 sub-tribus, 7 salas, 7 calendarios, 1 evento, 4 listas, 5 wikis, 2 mapas; 9 pendientes, todos del colectivo |
| **Formulario para branding y contenidos**: todo lo que se creará, en lenguaje llano, con USAMOS / DUDA / POR DEFECTO, casillas GO y campos de respuesta | `entrada/formulario.py` → `FORMULARIO-BRANDING-CONTENIDOS.md` | generado 2026-10-11; 51 objetos, 6 logos, 3 piezas Canva, 11 preguntas; ⏳ sin enviar |
| Guion de activación humana · guía de reparto (libro del operador, sin códigos) | `guion-acampada26s.md` (`--guion`) · `guia-reparto-acampada26s.md` (`--reparto`) | regenerados 2026-10-11, exit 0 |
| Mapeo organigrama → Oasis (trazable por `id`) | `../retro-exporter/MAPEO.md` | cerrado 2026-10-07 |
| **Logos** del colectivo (6 variantes, 1021×1134 PNG) | `assets/` · inventario `assets/MANIFEST.md` | recibidos 2026-10-11; oficial sin elegir (formulario A1) |
| **Canva**: kit visual, post, recursos gráficos | `canva/` · índice `canva/README.md` · manifiestos por pieza | ✓ kit visual (PDF 19 págs) y post (32 PNG 1080×1350) recibidos 2026-10-11, exportados por el equipo · ⬜ recursos gráficos y 2 páginas del post |
| Kit visual 512×512 para la plantilla | `pub/templates/assets/acampada26s/` (generador `pub/tools/template-kit.py`) | ⬜ no generado (PIL ausente en el Python base; marca sin decidir) |

## Cómo se trabaja esta carpeta

1. **Materiales primero, ejecución después.** Nada de esta carpeta publica nada: se recopila, se ordena
   y se deja regenerable. La activación (vía fría o caliente) sigue `docs/PUB/TEMPLATE-PROTOCOL.md` y
   pide GO del custodio paso a paso, como en `../scriptorium-exported/runbook-*.md`.
2. **El JSON manda.** Si el colectivo corrige algo (una hora, un nombre, un texto), se corrige en
   `entrada/acampada26s_organigrama.json` (nunca en la plantilla ni en el formulario) y se regenera todo
   con los comandos de abajo. Lo que el derivador redacta por su cuenta está en `DESC`/`TITULO_SUB` de
   `derivar-acampada26s.py`; cuando el colectivo lo confirme, pasa al JSON como `descripcion`.
3. **Los binarios de Canva** van a `canva/<carpeta>/` tal cual se exportan, más un `MANIFEST.md` por
   carpeta regenerado con `canva/manifest.py`. Lo derivado (512×512) va a `pub/templates/assets/acampada26s/`
   por el generador, nunca a mano.
4. **Secretos, ninguno.** Aquí no hay invites, `secret` ni credenciales; los enlaces de Canva son de
   edición compartida y se tratan como material del colectivo, no como credencial.

## Comandos que regeneran todo (en este orden)

```sh
python -X utf8 ARCHIVO/DISCO/26sm-exported/entrada/derivar-acampada26s.py        # plantilla + procedencia.json
node pub/tools/template-seed.js --template pub/templates/acampada26s.json \
  --organigrama ARCHIVO/DISCO/26sm-exported/entrada/acampada26s_organigrama.json \
  --out ARCHIVO/DISCO/26sm-exported/guion-acampada26s.md --guion                # guion (exit 0, 33 ids)
node pub/tools/template-seed.js --template pub/templates/acampada26s.json \
  --organigrama ARCHIVO/DISCO/26sm-exported/entrada/acampada26s_organigrama.json \
  --out ARCHIVO/DISCO/26sm-exported/guia-reparto-acampada26s.md --reparto       # guía de reparto
python -X utf8 ARCHIVO/DISCO/26sm-exported/entrada/formulario.py                  # formulario
python -X utf8 ARCHIVO/DISCO/26sm-exported/canva/manifest.py                      # manifiestos de canva/
```

## Evidencia de la ronda «el JSON manda» (2026-10-11)

| Comprobación | Comando | Salida |
|---|---|---|
| Derivador determinista | `derivar-acampada26s.py` ×2 + `sha256sum` de plantilla y procedencia | mismos bytes |
| Guion | `template-seed.js --guion` | `origen comprobado contra organigrama: sí (33 ids)` · `9 pendientes` · exit 0 |
| Reparto | `template-seed.js --reparto` | `9 pendientes` · exit 0 |
| Pendientes restantes (todos del colectivo) | §14 del guion | `meta.autoria` · 5 horas de nodo · coordenadas de Sol 14 · 2 pubs aliados |
| Diff semántico contra la plantilla a mano (`git show 030c1012:pub/templates/acampada26s.json`) | script de comparación por `id` (title, private, inviteMode, status, listType, mapType, description…) | mismos 51 objetos + `wiki_reparto`; ningún título ni privacidad cambia; solo campos añadidos (`image`, `clearnetPublic`, `responsable`, `nota`), `origen` de las 9 sub-tribus (ahora su subgrupo) y `meta.organigrama` |
| No regresión de Campamento | `template-seed.js --guion` sobre `pub/templates/campamento.json` | `24 ids` · `11 pendientes` · exit 0 |
| Formulario sin jerga | `grep -iE '\b(sbot|blob|clearnet|feed|ssb|sha256|json|bipf|docker)\b'` sobre el `.md` | 0 líneas; 78 filas numeradas |

## Pendientes (2026-10-11)

- [ ] Enviar `FORMULARIO-BRANDING-CONTENIDOS.md` a branding y contenidos; incorporar respuestas al JSON v2 y regenerar.
- [ ] Canva: conseguir RECURSOS GRÁFICOS y las 2 páginas que faltan del POST; rellenar la columna «Para qué» de los manifiestos.
- [ ] Decidir si los 96 MB de Canva se versionan o van a `.gitignore` (queda el manifiesto).
- [ ] Logo oficial (formulario A1) → avatar de la secretaría y kit 512×512 con la marca.
- [ ] Medir `oasisVersion` del pub `acampada26s.net` (`instancia.oasis_version.observada`).
- [ ] Paquete «congelado» para el operador de la 26S (runbook externo + compose aislado): siguiente micro-tarea.
