#!/usr/bin/env python3
# formulario.py · genera FORMULARIO-BRANDING-CONTENIDOS.md: lo que vamos a crear en el pub de Acampada26S, en
# lenguaje llano, para que la gente de branding y de contenidos marque GO, conteste lo pendiente o escriba
# textos alternativos. Se genera desde lo asentado en la rama (organigrama v2, plantilla derivada,
# procedencia.json, assets/); no se edita a mano: se regenera tras cada respuesta incorporada.
#   python -X utf8 ARCHIVO/DISCO/26sm-exported/entrada/formulario.py
import hashlib, json, struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
DOSIER = 'ARCHIVO/DISCO/26sm-exported'
RAMA = 'dev/26sm-exported'   # rama de trabajo donde viven estos ficheros (ojo: no están en main)
D = ROOT / DOSIER
ORG = json.loads((D / 'entrada/acampada26s_organigrama.json').read_text(encoding='utf-8'))
T = json.loads((ROOT / 'pub/templates/acampada26s.json').read_text(encoding='utf-8'))
PROC = json.loads((D / 'entrada/procedencia.json').read_text(encoding='utf-8'))
OUT = D / 'FORMULARIO-BRANDING-CONTENIDOS.md'
inst, doc = ORG['instancia'], ORG['documento']

NOMBRE = {}   # id de órgano → nombre legible
def _idx(n):
    if isinstance(n, list):
        for v in n: _idx(v)
    elif isinstance(n, dict):
        if isinstance(n.get('id'), str): NOMBRE[n['id']] = n['nombre']
        for v in n.values(): _idx(v)
_idx(ORG['organos']); _idx(ORG['metodos_y_conceptos']); NOMBRE['documento'] = 'Todo el colectivo'

CHK, SI, NO = '[ ]', 'sí', 'no'
def pend(s): return isinstance(s, str) and s.startswith('<')
def cel(s): return str(s).replace('|', '\\|').replace('\n', ' ')
def estado(oid, campo='description'):
    f = PROC.get(oid, {}).get(campo)
    return 'USAMOS' if f == 'organigrama' else 'DUDA'
def organo(oid):
    if pend(oid): return 'pendiente'
    n = NOMBRE.get(oid, oid)
    return f'Comisión de {n}' if oid.startswith('comision_') and not oid.startswith('comision_de_') else n
def png_dims(p: Path):
    b = p.read_bytes()
    w, h = struct.unpack('>II', b[16:24]); return f'{w}×{h}', len(b)

L = []
def w(*lines): L.extend(lines)
def tabla(cab, filas):
    w('| ' + ' | '.join(cab) + ' |', '|' + '---|' * len(cab))
    for f in filas: w('| ' + ' | '.join(cel(c) for c in f) + ' |')
    w('')

n_grupos = len(T['tribes']); n_img = sum(1 for s in ('tribes', 'rooms', 'maps', 'events', 'wiki') for x in T[s] if x.get('image'))

# ---------------- cabecera ----------------
w(f'# Formulario · lo que vamos a crear en el espacio digital de {doc["titulo"]}', '',
  '**Para:** equipo de branding (bloque A) y equipo de contenidos (bloques B, C, D, E). Se puede contestar por separado.', '',
  f'**De dónde sale esto:** de los materiales que ya tenemos guardados en la rama `{RAMA}` del repositorio, carpeta '
  f'`{DOSIER}/`. Cada fila cita el fichero real. Este formulario lo genera un script a partir de esos ficheros; cuando nos '
  'devolváis respuestas, las incorporamos y lo regeneramos: no hace falta que cuidéis el formato.', '',
  '**Cómo responder:** marcad `[x]` donde pone `[ ]`, escribid en las columnas «Respuesta» o «Cambios», o contestad en un '
  'correo citando el número de fila (A1, B3, C-G12…). Si una fila no os dice nada, dejadla: lo que no se conteste va **por defecto**.', '',
  '**Leyenda de la columna «Estado»:**', '',
  '- **USAMOS** · el texto sale tal cual de vuestro organigrama publicado. Solo hay que dar el visto bueno.',
  '- **DUDA** · lo hemos redactado nosotros a partir del organigrama. Confirmadlo o cambiadlo.',
  '- **POR DEFECTO** · lo hemos decidido nosotros por una regla general (quién puede entrar, qué se ve desde fuera). Cambiadlo si no encaja.', '',
  '**Qué es cada cosa (en la aplicación tienen otros nombres, entre paréntesis):**', '',
  '- **Grupo** («tribu»): un espacio con su muro, su foro, sus tareas y su calendario. Puede ser abierto (se entra con un código o un QR) o cerrado (solo entra quien invite el responsable; lo que se escribe va cifrado).',
  '- **Subgrupo**: un grupo dentro de otro; hereda si es abierto o cerrado.',
  '- **Sala**: voz y texto en directo, para quien no está en la plaza. Va siempre dentro de un grupo.',
  '- **Calendario**: las convocatorias periódicas. **Evento**: una convocatoria concreta que se anuncia también hacia fuera.',
  '- **Lista de correo**: mensajes de uno a muchos. Abierta (cualquiera se suscribe) o cerrada (solo miembros, cifrada).',
  '- **Página** («wiki»): texto fijo que se puede editar. **Mapa**: un punto, o un mapa colaborativo donde cada nodo marca el suyo.',
  '- **Visible en la web**: lo que puede ver cualquiera desde el navegador, sin cuenta, en `' + inst['visor_publico'] + '`.', '',
  f'**Recuento de lo que se creará:** {n_grupos} grupos (incluidos {sum(1 for x in T["tribes"] if x.get("parent"))} subgrupos), '
  f'{len(T["rooms"])} salas, {len(T["calendars"])} calendarios, {len(T["events"])} evento, {len(T["mailing"])} listas de correo, '
  f'{len(T["wiki"])} páginas, {len(T["maps"])} mapas; {n_img} imágenes de tarjeta.', '')

# ---------------- A · marca ----------------
w('## A · Marca (branding)', '',
  '### A1 · Logo oficial', '',
  f'Tenemos seis variantes en `{DOSIER}/assets/`. **Elegid una**: será el avatar de la cuenta que crea todo (la «secretaría») '
  'y la base de las imágenes de tarjeta de cada grupo, sala, página y mapa. Si queréis otra distinta a estas seis, decidlo en la última fila.', '')
filas = []
for i, ruta in enumerate(inst['marca']['logos'], 1):
    p = ROOT / ruta; px, bytes_ = png_dims(p)
    filas.append((f'A1.{i}', f'`{ruta}`', px, f'{bytes_ // 1024} KB', CHK))
filas.append((f'A1.{len(filas) + 1}', 'Otro (decidnos cuál y dónde está)', '', '', CHK))
tabla(('#', 'Fichero', 'Tamaño', 'Peso', 'Oficial'), filas)
w('### A2 · Piezas de Canva', '',
  'Nos pasasteis tres enlaces. Son enlaces de edición y no se pueden descargar sin vuestra sesión, así que **o nos los exportáis** '
  '(Compartir → Descargar, en PNG o PDF) **o nos dais acceso** para bajarlos nosotros. Marcad una opción por pieza.', '')
filas = []
for i, c in enumerate(inst['marca']['canva'], 1):
    filas.append((f'A2.{i}', c['pieza'], c['enlace'], f'`{c["carpeta"]}`', c['estado'], f'{CHK} lo exportáis vosotros y nos lo pasáis · {CHK} nos dais acceso y lo bajamos nosotros'))
tabla(('#', 'Pieza', 'Enlace', 'Dónde lo guardaremos', 'Estado hoy', 'Opción'), filas)
w('### A3 · Imágenes de tarjeta y colores', '',
  f'Generaremos **{n_img} imágenes** (una por grupo, sala, mapa, evento y página; cuadradas, 512 píxeles) con un mismo estilo: '
  'el logo oficial, el nombre del espacio y un icono por tipo. Hoy el generador usa una paleta nuestra. Decidnos:', '',
  f'- A3.1 {CHK} Usad los colores del logo oficial · {CHK} Usad estos colores (escribid códigos o describidlos): ____________',
  f'- A3.2 {CHK} Tipografía: la del kit visual de Canva (cuando lo tengamos) · {CHK} Nos da igual, usad una libre',
  f'- A3.3 {CHK} Queremos ver una prueba de 3-4 tarjetas antes de generar las {n_img}', '')

# ---------------- B · datos pendientes ----------------
w('## B · Datos que solo vosotros sabéis (contenidos)', '',
  'Sin estas respuestas lo creamos igual, pero con huecos. Cada fila dice dónde se usa.', '')
filas = [
    ('B1', '¿Es correcto el objetivo del movimiento tal como lo leímos?', 'Cabecera de la página «Organigrama y funcionamiento»',
     f'«{doc["objetivo_del_movimiento"]}» → {CHK} correcto · cambios: ______'),
    ('B2', '¿Quién crea los espacios? Una sola cuenta de «secretaría» para todo, o cada órgano la suya. Importante: solo quien crea un grupo puede borrarlo o reorganizarlo.',
     'Autoría de todos los grupos (no se puede cambiar después)', f'{CHK} una cuenta de secretaría · {CHK} cada órgano la suya · otra: ______'),
    ('B3', '¿Quién es la mesa técnica? (las personas que recibirán los códigos de acceso y los repartirán a cada órgano)',
     'Guía de reparto de accesos', 'Nombres o cargos: ______'),
]
nodos = next(x for x in ORG['organos'] if x['id'] == 'nodos_territoriales')
for i, m in enumerate(nodos['miembros'], 4):
    filas.append((f'B{i}', f'Hora y periodicidad de la asamblea del {m["nombre"]}', f'Calendario «{m["nombre"]}»', 'Día(s) y hora: ______'))
k = 4 + len(nodos['miembros'])
lug = ORG['lugares'][0]
filas.append((f'B{k}', f'¿Son correctas las coordenadas de {lug["nombre"]}? Hoy: {lug["lat"]}, {lug["lng"]} (aproximadas)', 'Mapa de la Asamblea General',
              f'{CHK} correctas · otras: ______'))
ext = next(x for x in ORG['organos'] if x['id'] == 'otros_espacios_de_articulacion')
for j, m in enumerate(ext['miembros'], k + 1):
    filas.append((f'B{j}', f'¿{m["nombre"]} tiene (o tendrá) un espacio Oasis propio con el que conectar? Si sí, su dirección.',
                  'Conexión entre espacios y lista cerrada', f'{CHK} no · {CHK} sí: ______'))
tabla(('#', 'Pregunta', 'Dónde se usa', 'Respuesta'), filas)

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
    filas.append((f'C-G{i}', nombre, x['description'], estado(x['id']), entrada_grupo(x), SI if not x['private'] else NO,
                  organo(x['responsable']), CHK, ''))
tabla(('#', 'Grupo', 'Descripción que usaremos', 'Estado', 'Cómo se entra', 'Visible en la web', 'Responsable del reparto', 'GO', 'Cambios'), filas)

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
    cuando = f'{d["recurrencia"]}' + (f' a las {d["hora"]}' if not pend(d['hora']) else ' (hora pendiente, ver bloque B)')
    filas.append((f'C-C{i}', x['title'], cuando, d.get('nota', ''), 'USAMOS' if not pend(d['hora']) else 'DUDA',
                  SI if x['clearnetPublic'] else NO + ' (va dentro de un grupo)', organo(x['responsable']), CHK, ''))
tabla(('#', 'Calendario', 'Cuándo', 'Nota que usaremos', 'Estado', 'Visible en la web', 'Responsable del reparto', 'GO', 'Cambios'), filas)

w('### C-E · Evento', '')
filas = []
for i, x in enumerate(T['events'], 1):
    filas.append((f'C-E{i}', x['title'], x['description'], f'{x["recurrencia"]} a las {x["hora"]}, {x["location"]}', estado(x['id']),
                  SI if x['clearnetPublic'] else NO, organo(x['responsable']), CHK, ''))
tabla(('#', 'Evento', 'Descripción que usaremos', 'Cuándo y dónde', 'Estado', 'Visible en la web', 'Responsable del reparto', 'GO', 'Cambios'), filas)

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
                  SI if x['clearnetPublic'] else NO, organo(x['responsable']), CHK, ''))
tabla(('#', 'Página', 'Quién la edita', 'Visible en la web', 'Responsable', 'GO', 'Cambios'), filas)

w('### C-M · Mapas', '')
filas = []
for i, x in enumerate(T['maps'], 1):
    tipo = 'un solo punto' if x['mapType'] == 'SINGLE' else 'colaborativo: cada nodo añade su punto'
    filas.append((f'C-M{i}', x['title'], x['description'], estado(x['id']), tipo, SI if x['clearnetPublic'] else NO + ' (solo dentro)',
                  organo(x['responsable']), CHK, ''))
tabla(('#', 'Mapa', 'Descripción que usaremos', 'Estado', 'Tipo', 'Visible en la web', 'Responsable del reparto', 'GO', 'Cambios'), filas)

# ---------------- D · páginas largas ----------------
w('## D · Páginas completas para revisar (contenidos)', '',
  'Leedlas enteras. Marcad «revisada» y anotad cambios con el número de página. Las dos primeras las generamos nosotros a partir '
  'del organigrama; el manual de bienvenida ya existía; la guía de reparto se genera sola y no lleva códigos.', '')
for i, x in enumerate(T['wiki'], 1):
    w(f'### D{i} · {x["title"]}', '')
    if x.get('file'):
        p = ROOT / x['file']
        w(f'Fichero: `{x["file"]}` ({p.stat().st_size // 1024} KB). {CHK} revisada · cambios: ______', '')
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
print(f'formulario → {OUT.relative_to(ROOT).as_posix()}  objetos: {total} · logos: {len(inst["marca"]["logos"])} · canva: {len(inst["marca"]["canva"])} · preguntas B: {k + len(ext["miembros"])}')
