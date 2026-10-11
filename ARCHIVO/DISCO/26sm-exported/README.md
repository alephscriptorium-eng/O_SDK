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
| **Entrada v2.1 · el JSON manda**: organigrama transcrito de la imagen + hechos de instancia (fuente, pub, lugares, apertura, reuniones, canales con id, reparto) + **marca completa** desde el kit visual (paleta, tipografía, logos por versión, fondos, reglas, avatar) + hechos de los posts (barrios por nodo, reuniones observadas, agrupación real, canal Telegram) + `candidatos[]` (no se siembran) | `entrada/acampada26s_organigrama.json` · imagen original `entrada/esquema.jpg` | v2.1 2026-10-11; 33 ids de órgano; los 24 de la v1 intactos |
| **Derivador**: construye la plantilla desde el organigrama con las reglas R1-R5 y el contrato WP-O131 (`image`, `clearnetPublic`, `responsable`, `wiki_reparto`, `meta.reparto`); apunta en `procedencia.json` qué textos redactó él; escribe `marca.json` para el generador de tarjetas | `entrada/derivar-acampada26s.py` → `pub/templates/acampada26s.json` · `entrada/procedencia.json` · `entrada/marca.json` | determinista; 33 textos del derivador + 5 mixtos (nodos: frase nuestra + barrios literales) |
| **Plantilla** derivada (no se edita a mano) | `pub/templates/acampada26s.json` · contrato `pub/templates/SCHEMA.md` | 16 tribus + 9 sub-tribus, 7 salas, 7 calendarios, 1 evento, 4 listas, 5 wikis, 2 mapas; 9 pendientes, todos del colectivo |
| **Formulario v2 para branding y contenidos**: todo lo que se creará, en lenguaje llano, con USAMOS / DUDA / POR DEFECTO, casillas GO y campos de respuesta; A3 «así aplicaremos vuestro kit», B4-B5 (5 nodos o 3 agrupaciones; reuniones observadas), C-X candidatos | `entrada/formulario.py` → `FORMULARIO-BRANDING-CONTENIDOS.md` | v2 2026-10-11; 51 objetos + 4 candidatos, 85 filas, 10 preguntas B; ⏳ sin enviar |
| **Vista previa real** (drill local en entorno separado, bot desechable; 16 capturas de la web pública + 12 del cliente; para adjuntar al formulario) | `runbook-drill-26s.md` · `vista-previa/index.html` (+ `vista-previa.zip`, gitignored) · `entrada/capturar.py`, `entrada/vista-previa.py` · `drill/ledger-drill-26s.json`, `drill/guia-reparto-drill-26s.md` · método: `pub/docker-compose.drill.yml`, `pub/scripts/drill-26s.sh` | ✅ 2026-10-11: G-1…G10 en verde, 145 mensajes sembrados en el pub del drill, real intacto |
| Guion de activación humana · guía de reparto (libro del operador, sin códigos) | `guion-acampada26s.md` (`--guion`) · `guia-reparto-acampada26s.md` (`--reparto`) | regenerados 2026-10-11, exit 0 |
| Mapeo organigrama → Oasis (trazable por `id`) | `../retro-exporter/MAPEO.md` | cerrado 2026-10-07 |
| **Logos** del colectivo (6 variantes, 1021×1134 PNG) | `assets/` · inventario `assets/MANIFEST.md` | recibidos 2026-10-11; oficial sin elegir (formulario A1) |
| **Canva**: kit visual, post, recursos gráficos | `canva/` · índice `canva/README.md` · manifiestos por pieza · **`canva/kit-visual/BRANDKIT.md`** (resumen citado por página) · `canva/kit-visual/extraido/` (40 imágenes embebidas del PDF: 17 lonas, logos con alfa, avatar, banner; `entrada/extraer-brandkit.py`) | ✓ kit visual (PDF 19 págs) y post (32 PNG 1080×1350) recibidos 2026-10-11 · ⬜ recursos gráficos y 2 páginas del post |
| **Kit visual 512×512 con la marca** (lona, caja azul, etiqueta naranja, logo; Cabin Condensed como sustituto libre de Gill Sans) | `pub/templates/assets/acampada26s/` (`npm run pub:template:kit:26s`; generador `pub/tools/template-kit.py --brand entrada/marca.json`) · fuentes `assets/fonts/` (OFL) · avatar candidato `assets/avatar-secretaria-512.png` · muestras `pruebas/` | ✓ generado 2026-10-11: 40 PNG (200-410 KB), determinista; pendiente del GO de branding (formulario A3-A4) |

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
python -X utf8 ARCHIVO/DISCO/26sm-exported/entrada/extraer-brandkit.py           # lonas, logos, avatar del PDF del kit → canva/kit-visual/extraido/
python -X utf8 ARCHIVO/DISCO/26sm-exported/entrada/derivar-acampada26s.py        # plantilla + procedencia.json + marca.json
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

## Evidencia de la ronda «marca real», fase 1 (2026-10-11)

| Comprobación | Comando | Salida |
|---|---|---|
| Extracción del PDF | `extraer-brandkit.py` | 40 imágenes (17 lona, 10 logo, 3 avatar-ejemplo, 1 banner, 9 ejemplos), 0 no extraídas; manifest con sha256 del PDF |
| Determinismo | extraer + derivar + formulario ×2, `sha256sum` de plantilla, procedencia, marca.json, formulario y manifest | mismos bytes |
| Guion / reparto | `template-seed.js --guion` / `--reparto` | `33 ids` · `9 pendientes` (autoría, 5 horas de nodo, coordenadas, 2 pubs) · exit 0 |
| Diff de la plantilla vs commit anterior | `git diff pub/templates/acampada26s.json` | 6 líneas: 5 nodos (+ «Barrios: …» literal de los posts) y `mapa_sol` (+ «junto a Goiko Grill») |
| Formulario | `formulario.py` + `grep` lista negra + hex ⊂ JSON | 85 filas, 4 candidatos, 0 jerga, 4 hex todos en el JSON |
| No regresión Campamento | `template-seed.js --guion` sobre `campamento.json` | `24 ids` · exit 0 |

## Evidencia de la ronda «marca real», fase 2 (2026-10-11)

| Comprobación | Comando | Salida |
|---|---|---|
| Fuentes libres | `curl` a `github.com/google/fonts/ofl/cabincondensed` (ok del custodio) · `sha256sum` | `CabinCondensed-Bold.ttf` 97876 B, `-Regular.ttf` 99468 B, `OFL.txt`; sha en `assets/MANIFEST.md` |
| No regresión del generador | `template-kit.py` sin `--brand` sobre Campamento, sha de los 40 PNG vs `pub/templates/assets/campamento/manifest.json` | 40/40 iguales (solo cambian las copias `wiki/*.md`, cuyas fuentes cambiaron en commits posteriores) |
| Kit 26S | `npm run pub:template:kit:26s` ×2 | 40 PNG 512×512 RGB, máx 410 KB, media 321 KB; `manifest.json` idéntico en las dos ejecuciones; 12 lonas distintas usadas |
| Paleta exacta | muestreo de píxeles en `tribu-asamblea_general.png` | caja `#0452c5` · etiqueta `#ff981f` · texto `#ffffff` |
| Revisión visual | `pruebas/_contacto.png` (hoja de contacto + simulación del recorte 280×140 del hub) | nombre legible en la banda central; logo con aire; sin sombras ni iconos |
| Formulario | `formulario.py` | A4 con las muestras; lista negra 0 |

## Evidencia de la vista previa real (2026-10-11)

Gate a gate con comando y salida: `runbook-drill-26s.md`. Resumen: entorno `oasis-drill-26s` separado del real (guard: ningún
contenedor monta `volumes-real/`); bootstrap del bot y del HUB por invite; `about` con el avatar (+1 medido); dry-run y 10 bloques
con delta = previsto (145 mensajes); HUB con el feed del bot en 10 s; sitemap 1 calendario, 7 eventos, 1 mapa, 5 wikis; cliente
desechable unido y replicando (seq 149); 28 capturas; pub Δ1 (contact del cliente), HUB Δ0; bot real con las mismas fechas que
antes. Hallazgos nuevos: las tribus no salen en `/c` hasta exponer contenido; las salas solo para miembros; el cliente de un drill
anterior tenía otro `caps.shs`; `/c/blob/<id>` directo con el id codificado entero responde 404 (las páginas sí sirven las imágenes).

## Pendientes (2026-10-11)

- [ ] Enviar `FORMULARIO-BRANDING-CONTENIDOS.md` + `vista-previa.zip` a branding y contenidos; incorporar respuestas al JSON y regenerar.
- [ ] Decidir `drill-26s.sh wipe` (43 MB en `volumes-dev/drill-26s/`) o conservarlo para repetir capturas.
- [ ] Canva: conseguir RECURSOS GRÁFICOS y las 2 páginas que faltan del POST; rellenar la columna «Para qué» de los manifiestos.
- [ ] Decidir si los 96 MB de Canva se versionan o van a `.gitignore` (queda el manifiesto).
- [ ] GO de branding al kit (formulario A3-A4) y al avatar (A1); si entregan Gill Sans, regenerar con `marca.json → fuentes` apuntando fuera del repo.
- [ ] Medir `oasisVersion` del pub `acampada26s.net` (`instancia.oasis_version.observada`).
- [ ] Paquete «congelado» para el operador de la 26S (runbook externo + compose aislado): siguiente micro-tarea.
