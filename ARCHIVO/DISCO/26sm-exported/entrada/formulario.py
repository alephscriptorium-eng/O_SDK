#!/usr/bin/env python3
# formulario.py · genera FORMULARIO-BRANDING-CONTENIDOS.md: lo que vamos a crear en el pub de Acampada26S, en
# lenguaje llano, para que la gente de branding y de contenidos marque GO, conteste lo pendiente o escriba
# textos alternativos. Se genera desde lo asentado en la rama (organigrama v2.1, plantilla derivada,
# procedencia.json, assets/, kit visual); no se edita a mano: se regenera tras cada respuesta incorporada.
#   python -X utf8 ARCHIVO/DISCO/26sm-exported/entrada/formulario.py
import json, struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
DOSIER = 'ARCHIVO/DISCO/26sm-exported'
RAMA = 'dev/26sm-exported'   # rama de trabajo donde viven estos ficheros (ojo: no están en main)
D = ROOT / DOSIER
ORG = json.loads((D / 'entrada/acampada26s_organigrama.json').read_text(encoding='utf-8'))
T = json.loads((ROOT / 'pub/templates/acampada26s.json').read_text(encoding='utf-8'))
PROC = json.loads((D / 'entrada/procedencia.json').read_text(encoding='utf-8'))
OUT = D / 'FORMULARIO-BRANDING-CONTENIDOS.md'
PRUEBAS = D / 'pruebas'
inst, doc, marca = ORG['instancia'], ORG['documento'], ORG['instancia']['marca']
LUGAR = {l['id']: l for l in ORG['lugares']}

NOMBRE = {}   # id de órgano → nombre legible
def _idx(n):
    if isinstance(n, list):
        for v in n: _idx(v)
    elif isinstance(n, dict):
        if isinstance(n.get('id'), str) and n.get('nombre'): NOMBRE[n['id']] = n['nombre']
        for v in n.values(): _idx(v)
_idx(ORG['organos']); _idx(ORG['metodos_y_conceptos']); NOMBRE['documento'] = 'Todo el colectivo'

CHK, SI, NO = '[ ]', 'sí', 'no'
def pend(s): return isinstance(s, str) and s.startswith('<')
def cel(s): return str(s).replace('|', '\\|').replace('\n', ' ')
def estado(oid, campo='description'):
    f = PROC.get(oid, {}).get(campo)
    return {'organigrama': 'USAMOS', 'mixto': 'DUDA la primera frase · USAMOS los barrios'}.get(f, 'DUDA')
def organo(oid):
    if pend(oid): return 'pendiente'
    n = NOMBRE.get(oid, oid)
    return f'Comisión de {n}' if oid.startswith('comision_') and not oid.startswith('comision_de_') else n
def lugar(lid): return LUGAR[lid]['nombre'] if lid in LUGAR else lid
def png_dims(p: Path):
    b = p.read_bytes()
    w, h = struct.unpack('>II', b[16:24]); return f'{w}×{h}', len(b)
def kb(p: Path): return f'{p.stat().st_size // 1024} KB'

L = []
def w(*lines): L.extend(lines)
def tabla(cab, filas):
    w('| ' + ' | '.join(cab) + ' |', '|' + '---|' * len(cab))
    for f in filas: w('| ' + ' | '.join(cel(c) for c in f) + ' |')
    w('')

n_grupos = len(T['tribes']); n_img = sum(1 for s in ('tribes', 'rooms', 'maps', 'events', 'wiki') for x in T[s] if x.get('image'))
pal = marca['paleta']; tipo = marca['tipografia']

# ---------------- cabecera ----------------
w(f'# Formulario · lo que vamos a crear en el espacio digital de {doc["titulo"]}', '',
  '**Para:** equipo de branding (bloque A) y equipo de contenidos (bloques B, C, D, E). Se puede contestar por separado.', '',
  f'**De dónde sale esto:** de los materiales que ya tenemos guardados en la rama `{RAMA}` del repositorio, carpeta '
  f'`{DOSIER}/`. Cada fila cita el fichero real. Este formulario lo genera un script a partir de esos ficheros; cuando nos '
  'devolváis respuestas, las incorporamos y lo regeneramos: no hace falta que cuidéis el formato.', '',
  '**Lo que ya nos habéis dado (gracias):** la guía visual («ACAMPADA BRAND KIT», 19 páginas) y 32 plantillas de post. '
  'Con eso hemos cerrado colores, logos, tipografía, fondos y composición: ya no os lo preguntamos, os lo enseñamos (bloque A3).', '',
  '**Lo que falta:** ' + ' · '.join(marca['faltan']) + '.', '',
  '**Cómo responder:** marcad `[x]` donde pone `[ ]`, escribid en las columnas «Respuesta» o «Cambios», o contestad en un '
  'correo citando el número de fila (A1, B3, C-G12…). Si una fila no os dice nada, dejadla: lo que no se conteste va **por defecto**.', '',
  '**Leyenda de la columna «Estado»:**', '',
  '- **USAMOS** · el texto sale tal cual de vuestro organigrama, vuestra guía visual o vuestros posts. Solo hay que dar el visto bueno.',
  '- **DUDA** · lo hemos redactado nosotros a partir de vuestros materiales. Confirmadlo o cambiadlo.',
  '- **POR DEFECTO** · lo hemos decidido nosotros por una regla general (quién puede entrar, qué se ve desde fuera). Cambiadlo si no encaja.', '',
  '**Qué es cada cosa (en la aplicación tienen otros nombres, entre paréntesis):**', '',
  '- **Grupo** («tribu»): un espacio con su muro, su foro, sus tareas y su calendario. Puede ser abierto (se entra con un código o un QR) o cerrado (solo entra quien invite el responsable; lo que se escribe va cifrado).',
  '- **Subgrupo**: un grupo dentro de otro; hereda si es abierto o cerrado.',
  '- **Sala**: voz y texto en directo, para quien no está en la plaza. Va siempre dentro de un grupo y solo la ven sus miembros.',
  '- **Calendario**: las convocatorias periódicas. **Evento**: una convocatoria concreta que se anuncia también hacia fuera.',
  '- **Lista de correo**: mensajes de uno a muchos. Abierta (cualquiera se suscribe) o cerrada (solo miembros, cifrada).',
  '- **Página** («wiki»): texto fijo que se puede editar. **Mapa**: un punto, o un mapa colaborativo donde cada nodo marca el suyo.',
  '- **Visible en la web**: lo que puede ver cualquiera desde el navegador, sin cuenta, en `' + inst['visor_publico'] + '`.', '',
  f'**Recuento de lo que se creará:** {n_grupos} grupos (incluidos {sum(1 for x in T["tribes"] if x.get("parent"))} subgrupos), '
  f'{len(T["rooms"])} salas, {len(T["calendars"])} calendarios, {len(T["events"])} evento, {len(T["mailing"])} listas de correo, '
  f'{len(T["wiki"])} páginas, {len(T["maps"])} mapas; {n_img} imágenes de tarjeta. Más {len(ORG["candidatos"])} candidatos que solo se crean si decís «crear» (bloque C-X).', '')

# ---------------- A · marca ----------------
w('## A · Marca (branding)', '',
  '### A1 · Logo oficial y avatar', '',
  f'Tenemos las seis versiones de vuestra guía (pág. 3) en `{DOSIER}/assets/`. **Elegid la del avatar** de la cuenta que crea todo (la '
  f'«secretaría»). Vuestra guía ya trae un patrón de avatar (pág. {marca["avatar"]["pagina"]}): {marca["avatar"]["patron"]}; y una identidad '
  f'para un bot (pág. {marca["bot"]["pagina"]}): {marca["bot"]["patron"]}. Marcad una opción en la última fila.', '')
filas = []
for i, l in enumerate(marca['logos'], 1):
    p = ROOT / l['fichero']; px, bytes_ = png_dims(p)
    filas.append((f'A1.{i}', l['version'], f'`{l["fichero"]}`', px, f'{bytes_ // 1024} KB', CHK))
tabla(('#', 'Versión (guía pág. 3)', 'Fichero', 'Tamaño', 'Peso', 'Para el avatar'), filas)
w(f'- A1.{len(filas) + 1} Avatar de la secretaría: {CHK} patrón de la guía (logo blanco sobre lona + «26S» naranja) · '
  f'{CHK} el archivador del bot (pág. {marca["bot"]["pagina"]}) · {CHK} otro: ______', '')

w('### A2 · Piezas de Canva', '',
  'Dos ya las tenemos exportadas. Falta la tercera (la vista pública sale en blanco: hay que exportarla con sesión) y dos páginas del post.', '')
filas = []
for i, c in enumerate(marca['canva'], 1):
    filas.append((f'A2.{i}', c['pieza'], c['enlace'], f'`{c["carpeta"]}`', c['estado'], '' if c['estado'].startswith('recibido') else f'{CHK} lo exportáis vosotros y nos lo pasáis · {CHK} nos dais acceso y lo bajamos nosotros'))
tabla(('#', 'Pieza', 'Enlace', 'Dónde está / estará', 'Estado hoy', 'Opción'), filas)
w(f'- A2.{len(filas) + 1} También nos vendría bien: {CHK} el doc maestro «identidad visual y discursiva» · {CHK} el logo descargable en vectorial (SVG) · '
  f'{CHK} las 2 páginas que faltan del POST (hay 32 de 34)', '')

w('### A3 · Así aplicaremos vuestro kit (USAMOS: sale de vuestra guía visual)', '',
  f'Generaremos **{n_img} imágenes** (una por grupo, sala, mapa, evento y página; cuadradas, 512 píxeles) con vuestras reglas. '
  'Lo que sigue no es una pregunta: es cómo lo vamos a hacer. Decidnos solo si algo no encaja.', '')
tabla(('#', 'Regla', 'Cómo la aplicamos', 'Fuente'), [
    ('A3.1', 'Colores', f'azul lona `{pal["azul_lona"]["hex"]}` para cajas y fondos de identidad · naranja inquilina `{pal["naranja_inquilina"]["hex"]}` solo para etiquetas y señalar · blanco `{pal["blanco"]["hex"]}` para el texto · negro `{pal["negro"]["hex"]}` no se usa en pantalla', f'guía págs. 6-7'),
    ('A3.2', 'Fondo', 'siempre una foto de lona azul (las que vienen en el PDF de la guía), sin filtros que cambien el azul; una lona distinta por tarjeta, elegida de forma fija (misma tarjeta → misma lona)', 'guía págs. 10-11'),
    ('A3.3', 'Composición', 'caja azul sólida con el nombre en blanco y mayúsculas; etiqueta naranja con el tipo (GRUPO, SALA, MAPA, EVENTO, PÁGINA); logo blanco pequeño abajo con aire; nada de sombras ni iconos', 'guía págs. 4, 12-13'),
    ('A3.4', 'Tipografía', f'vuestra guía pide {tipo["titulares"]} (titulares) y {tipo["cuerpos"]} (cuerpos); son de pago y no podemos incluirlas en el proyecto. Mientras tanto usamos **{tipo["sustituto_libre"]["nombre"]}** ({tipo["sustituto_libre"]["licencia"]}), {tipo["sustituto_libre"]["por_que"]}', 'guía págs. 8-9'),
    ('A3.5', 'Nombres', 'el nombre de cada espacio va en mayúsculas y se ajusta solo (hasta 3 líneas); los nombres muy largos («Comunicación · Coordinación y gabinete de crisis») se verán más pequeños', 'guía pág. 9'),
])
w('Decisiones que sí os pedimos:', '',
  f'- A3.6 Tipografía: {CHK} vale {tipo["sustituto_libre"]["nombre"]} · {CHK} os pasamos los ficheros de {tipo["titulares"]} y {tipo["cuerpos"]} (los usaremos sin subirlos al proyecto)',
  f'- A3.7 Fondos de lona: {CHK} usad las fotos que trae el PDF de la guía · {CHK} os pasamos las originales a más resolución',
  f'- A3.8 {CHK} Queremos ver la prueba (A4) antes de dar el visto bueno a las {n_img}', '')

w('### A4 · Prueba visual', '')
pruebas = sorted(PRUEBAS.glob('*.png')) if PRUEBAS.exists() else []
if pruebas:
    w('Hemos hecho estas de muestra con vuestras reglas. Abridlas y decidnos:', '')
    TITULO = {x['id']: (sec, x['title']) for sec in ('tribes', 'rooms', 'maps', 'events', 'wiki') for x in T[sec]}
    TIPO = {'tribes': 'Grupo', 'rooms': 'Sala', 'maps': 'Mapa', 'events': 'Evento', 'wiki': 'Página'}
    def que_es(p):
        if p.name == '_contacto.png': return 'Hoja de contacto: todas juntas + cómo se ve recortada en la lista de grupos'
        if p.name.startswith('avatar'): return 'Avatar de la cuenta de secretaría (patrón de la guía, pág. 18)'
        oid = p.stem.split('-', 1)[1] if '-' in p.stem else p.stem
        sec, t = TITULO.get(oid, (None, oid)); return f'{TIPO.get(sec, "")} «{t}»'.strip()
    tabla(('#', 'Fichero', 'Qué es', 'Nos gusta', 'Cambios'),
          [(f'A4.{i}', f'`{DOSIER}/pruebas/{p.name}`', que_es(p), CHK, '') for i, p in enumerate(pruebas, 1)])
else:
    w(f'Las tarjetas de muestra se generan en `{DOSIER}/pruebas/` en la siguiente ronda; esta fila se rellenará sola.', '')

w('### A5 · Vista previa real', '')
VP = D / 'vista-previa'
if (VP / 'index.html').exists():
    mc = json.loads((VP / 'manifest-c.json').read_text(encoding='utf-8')) if (VP / 'manifest-c.json').exists() else {'items': []}
    ma = json.loads((VP / 'manifest-app.json').read_text(encoding='utf-8')) if (VP / 'manifest-app.json').exists() else {'items': []}
    w(f'Hemos montado un pub de prueba en un ordenador local con vuestros materiales y hemos sembrado todo lo de este formulario. '
      f'Estas son **capturas reales** de cómo queda: abrid `{DOSIER}/vista-previa/index.html` (o el zip `vista-previa.zip`). '
      f'{len(mc["items"])} capturas de la web pública y {len(ma["items"])} de dentro de la aplicación. Si algo os lía, es así exactamente como va a quedar. Decidnos:', '',
      f'- A5.1 {CHK} Así nos vale · {CHK} cambios: ______',
      f'- A5.2 Lo que hemos visto al sembrar: los **grupos no salen en la web** hasta que publican algo expuesto (recién creados, su dirección pública responde «no accesible»); '
      f'las **salas** solo las ve quien está dentro de su grupo. {CHK} entendido · {CHK} queremos hablarlo', '')
else:
    w(f'La vista previa se genera en `{DOSIER}/vista-previa/` tras el drill local; esta fila se rellenará sola.', '')
CAPTURA = {}
for mf in (D / 'vista-previa/manifest-c.json', D / 'vista-previa/manifest-app.json'):
    if mf.exists():
        for it in json.loads(mf.read_text(encoding='utf-8'))['items']:
            if it.get('id'): CAPTURA.setdefault(it['id'].split('#')[0], it['file'])
def captura(oid):
    f = CAPTURA.get(oid); return f'`vista-previa/{f}`' if f else ''

# ---------------- B · datos pendientes ----------------
w('## B · Datos que solo vosotros sabéis (contenidos)', '',
  'Sin estas respuestas lo creamos igual, pero con huecos. Cada fila dice dónde se usa.', '')
nodos = next(x for x in ORG['organos'] if x['id'] == 'nodos_territoriales')
agr = ORG['agrupacion_observada']
grupos_txt = ' · '.join(' + '.join(NOMBRE[n] for n in g) for g in agr['grupos'])
filas = [
    ('B1', '¿Es correcto el objetivo del movimiento tal como lo leímos?', 'Cabecera de la página «Organigrama y funcionamiento»',
     f'«{doc["objetivo_del_movimiento"]}» → {CHK} correcto · cambios: ______'),
    ('B2', '¿Quién crea los espacios? Una sola cuenta de «secretaría» para todo, o cada órgano la suya. Importante: solo quien crea un grupo puede borrarlo o reorganizarlo.',
     'Autoría de todos los grupos (no se puede cambiar después)', f'{CHK} una cuenta de secretaría · {CHK} cada órgano la suya · otra: ______'),
    ('B3', '¿Quién es la mesa técnica? (las personas que recibirán los códigos de acceso y los repartirán a cada órgano)',
     'Guía de reparto de accesos', 'Nombres o cargos: ______'),
    ('B4', f'En vuestros posts los nodos se reúnen agrupados ({grupos_txt}). ¿Creamos los calendarios y las salas por nodo (5, como el organigrama) o por agrupación (3)? Los grupos de cada nodo (con sus barrios) seguirán siendo 5.',
     'Calendarios y salas de los nodos', f'{CHK} 5, por nodo · {CHK} 3, por agrupación · otra: ______'),
]
obs = [r for r in ORG['reuniones_observadas'] if r.get('organo') == 'nodos_territoriales' and r.get('items')]
muestra = ' / '.join(f'{r["fecha"][8:]}/{r["fecha"][5:7]}: ' + ', '.join(f'{" + ".join(NOMBRE[n] for n in it["nodos"])} {it["hora"]} {lugar(it["lugar_id"])}' for it in r['items']) for r in obs)
filas.append(('B5', f'Las horas y lugares de los nodos cambian cada día («se publican a diario»). Lo que hemos leído en los posts: {muestra}. ¿Es correcto como muestra? ¿Seguiréis anunciándolo a diario? Entonces el calendario de cada nodo se rellena fecha a fecha, sin hora fija.',
              'Calendarios de los nodos', f'{CHK} correcto como muestra · {CHK} seguimos anunciando a diario · cambios: ______'))
lug = LUGAR['sol_14']
filas.append(('B6', f'¿Son correctas las coordenadas de {lug["nombre"]} ({lug.get("nota", "")})? Hoy: {lug["lat"]}, {lug["lng"]} (aproximadas)', 'Mapa de la Asamblea General', f'{CHK} correctas · otras: ______'))
otros = [l for l in ORG['lugares'] if l['id'] != 'sol_14']
filas.append(('B7', 'Lugares que salen en vuestros posts y de los que no tenemos coordenadas: ' + ', '.join(l['nombre'] for l in otros) + '. ¿Nos dais dirección exacta o coordenadas de los que vayan a repetirse?',
              'Mapa colaborativo de los nodos y calendario Programa', 'Direcciones: ______'))
ext = next(x for x in ORG['organos'] if x['id'] == 'otros_espacios_de_articulacion')
k = 8
for j, m in enumerate(ext['miembros'], k):
    filas.append((f'B{j}', f'¿{m["nombre"]} tiene (o tendrá) un espacio Oasis propio con el que conectar? Si sí, su dirección.',
                  'Conexión entre espacios y lista cerrada', f'{CHK} no · {CHK} sí: ______'))
k += len(ext['miembros'])
filas.append((f'B{k}', 'Vuestra guía enlaza un «doc maestro: identidad visual y discursiva». ¿Nos lo pasáis? De ahí saldrían el tono y los lemas de las páginas.', 'Páginas y textos de bienvenida', f'{CHK} os lo pasamos · {CHK} no existe aún'))
tabla(('#', 'Pregunta', 'Dónde se usa', 'Respuesta'), filas)
n_preguntas_b = len(filas)

# ---------------- C · textos por objeto ----------------
w('## C · Textos y ajustes de cada espacio (contenidos)', '',
  'Una tabla por tipo. La columna **Estado** va sobre el texto; las columnas **Cómo se entra** y **Visible en la web** son siempre '
  '**POR DEFECTO** (reglas generales: lo «abierto a toda la población» es abierto; las portavocías, cerrado; los espacios con otros '
  'colectivos, por invitación). Marcad **GO** si vale tal cual, o escribid los cambios.', '')

def entrada_grupo(x):
    if x['private']: return 'cerrado y cifrado; invita el responsable'
    if x['inviteMode'] == 'strict': return 'solo por invitación del responsable'
    return 'cualquiera, con código o QR de la tarjeta'

w('### C-G · Grupos', '')
filas = []
for i, x in enumerate(T['tribes'], 1):
    nombre = x['title'] + (' *(subgrupo de Comisión de Comunicación)*' if x.get('parent') else '')
    filas.append((f'C-G{i}', nombre, x['description'], estado(x['id']), entrada_grupo(x), ('sí, cuando publique algo expuesto' if not x['private'] else NO),
                  organo(x['responsable']), captura(x['id']), CHK, ''))
tabla(('#', 'Grupo', 'Descripción que usaremos', 'Estado', 'Cómo se entra', 'Visible en la web', 'Responsable del reparto', 'Captura', 'GO', 'Cambios'), filas)

w('### C-S · Salas de voz y texto', '')
filas = []
for i, x in enumerate(T['rooms'], 1):
    filas.append((f'C-S{i}', x['title'], x['description'], estado(x['id']), 'cualquiera del grupo' if x['status'] == 'OPEN' else 'solo por invitación',
                  NO + ' (va dentro de un grupo)', organo(x['responsable']), CHK, ''))
tabla(('#', 'Sala', 'Descripción que usaremos', 'Estado', 'Quién entra', 'Visible en la web', 'Responsable del reparto', 'GO', 'Cambios'), filas)

w('### C-C · Calendarios', '')
filas = []
for i, x in enumerate(T['calendars'], 1):
    d = x['dates'][0]
    cuando = f'{d["recurrencia"]}' + (f' a las {d["hora"]}' if not pend(d['hora']) else ' (se rellena fecha a fecha, ver B5)')
    filas.append((f'C-C{i}', x['title'], cuando, d.get('nota', ''), 'USAMOS' if not pend(d['hora']) else 'DUDA',
                  SI if x['clearnetPublic'] else NO + ' (va dentro de un grupo)', organo(x['responsable']), captura(x['id']), CHK, ''))
tabla(('#', 'Calendario', 'Cuándo', 'Nota que usaremos', 'Estado', 'Visible en la web', 'Responsable del reparto', 'Captura', 'GO', 'Cambios'), filas)

w('### C-E · Evento', '')
filas = []
for i, x in enumerate(T['events'], 1):
    filas.append((f'C-E{i}', x['title'], x['description'], f'{x["recurrencia"]} a las {x["hora"]}, {x["location"]}', estado(x['id']),
                  SI if x['clearnetPublic'] else NO, organo(x['responsable']), captura(x['id']), CHK, ''))
tabla(('#', 'Evento', 'Descripción que usaremos', 'Cuándo y dónde', 'Estado', 'Visible en la web', 'Responsable del reparto', 'Captura', 'GO', 'Cambios'), filas)

w('### C-L · Listas de correo', '')
filas = []
for i, x in enumerate(T['mailing'], 1):
    filas.append((f'C-L{i}', x['title'], x['description'], estado(x['id']), 'cualquiera se suscribe' if x['listType'] == 'OPEN' else 'solo miembros; cifrada',
                  organo(x['responsable']), CHK, ''))
tabla(('#', 'Lista', 'Descripción que usaremos', 'Estado', 'Quién la recibe', 'Responsable del reparto', 'GO', 'Cambios'), filas)

w('### C-P · Páginas', '', 'El texto completo de cada página está en el bloque D; aquí solo el título y los ajustes.', '')
filas = []
for i, x in enumerate(T['wiki'], 1):
    filas.append((f'C-P{i}', x['title'], 'cualquiera la edita' if x['editPolicy'] == 'open' else 'solo quien la crea',
                  SI if x['clearnetPublic'] else NO, organo(x['responsable']), captura(x['id']), CHK, ''))
tabla(('#', 'Página', 'Quién la edita', 'Visible en la web', 'Responsable', 'Captura', 'GO', 'Cambios'), filas)

w('### C-M · Mapas', '')
filas = []
for i, x in enumerate(T['maps'], 1):
    tipo_m = 'un solo punto' if x['mapType'] == 'SINGLE' else 'colaborativo: cada nodo añade su punto'
    filas.append((f'C-M{i}', x['title'], x['description'], estado(x['id']), tipo_m, SI if x['clearnetPublic'] else NO + ' (solo dentro)',
                  organo(x['responsable']), captura(x['id']), CHK, ''))
tabla(('#', 'Mapa', 'Descripción que usaremos', 'Estado', 'Tipo', 'Visible en la web', 'Responsable del reparto', 'Captura', 'GO', 'Cambios'), filas)

w('### C-X · Candidatos: lo que vuestros posts sugieren y el organigrama no tiene', '',
  'No los creamos salvo que marquéis «crear». Si los marcáis, decidnos quién los lleva.', '')
filas = []
for i, c in enumerate(ORG['candidatos'], 1):
    fu = c['fuente'] if isinstance(c['fuente'], list) else [c['fuente']]
    filas.append((f'C-X{i}', c['nombre'], c['tipo'], c['por_que'], organo(c['origen']), ', '.join(f'`{f.rsplit("/", 1)[1]}`' for f in fu), f'{CHK} crear · {CHK} no', ''))
tabla(('#', 'Qué', 'Tipo', 'Por qué lo proponemos', 'Órgano', 'Visto en', 'Decisión', 'Quién lo lleva'), filas)

# ---------------- D · páginas largas ----------------
w('## D · Páginas completas para revisar (contenidos)', '',
  'Leedlas enteras. Marcad «revisada» y anotad cambios con el número de página. Las dos primeras las generamos nosotros a partir '
  f'del organigrama (la portada de la primera seguirá vuestra guía, pág. {marca["organigrama_maquetado"]["pagina"]}); el manual de '
  'bienvenida ya existía; la guía de reparto se genera sola y no lleva códigos.', '')
for i, x in enumerate(T['wiki'], 1):
    w(f'### D{i} · {x["title"]}', '')
    if x.get('file'):
        p = ROOT / x['file']
        w(f'Fichero: `{x["file"]}` ({kb(p)}). {CHK} revisada · cambios: ______', '')
    else:
        w(f'Texto que se publicará ({len(x["body"].encode("utf-8")) // 1024 + 1} KB). {CHK} revisada · cambios: ______', '', '> ' + x['body'].replace('\n', '\n> '), '')

# ---------------- E · lo que no creamos aún ----------------
w('## E · Lo que NO vamos a crear todavía', '',
  'La aplicación tiene más piezas que podrían servir. No las activamos ahora; marcad las que os interesen y lo hablamos.', '')
NOMBRE_MOD = {'housing': 'Vivienda: anuncios de alquiler, venta y acogida', 'market': 'Mercado: dar, pedir e intercambiar sin dinero',
              'transfers': 'Banco de tiempo y de confianza', 'parliament': 'Parlamento: ratificación formal con propuestas y leyes',
              'school': 'Escuela: cursos para formar portavocías', 'banking': 'Moneda interna: renta básica para quien participa'}
filas = [(f'E{i}', NOMBRE_MOD.get(a['modulo'], a['modulo']), organo(a['origen']), a['porQue'], CHK) for i, a in enumerate(T['addenda'], 1)]
tabla(('#', 'Pieza', 'A qué órgano serviría', 'Por qué la señalamos', 'Nos interesa'), filas)

# ---------------- F · cierre ----------------
w('## F · Cómo nos lo devolvéis', '',
  '- Este mismo fichero con las casillas marcadas y los textos escritos, o',
  '- un correo con las respuestas numeradas (A1.3, B2, C-G7…), o',
  f'- editándolo directamente en la rama `{RAMA}`.', '',
  'Con las respuestas regeneramos todo (textos, imágenes, guía de reparto) y os enseñamos el resultado antes de crear nada: '
  '**nada se publica hasta que deis el GO final**, y lo que se publica queda para siempre, por eso este formulario.', '')

OUT.write_text('\n'.join(L).rstrip() + '\n', encoding='utf-8')
total = sum(len(T[s]) for s in ('tribes', 'rooms', 'calendars', 'events', 'mailing', 'wiki', 'maps'))
print(f'formulario → {OUT.relative_to(ROOT).as_posix()}  objetos: {total} · candidatos: {len(ORG["candidatos"])} · logos: {len(marca["logos"])} · canva: {len(marca["canva"])} · preguntas B: {n_preguntas_b} · pruebas: {len(pruebas)}')
