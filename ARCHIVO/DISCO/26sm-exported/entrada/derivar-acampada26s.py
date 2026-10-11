#!/usr/bin/env python3
# derivar-acampada26s.py · construye la plantilla pub/templates/acampada26s.json desde el organigrama v2.
# «El JSON manda»: todo hecho (nombres, funciones, horas, lugares, apertura, pendientes) sale de
#   ARCHIVO/DISCO/26sm-exported/entrada/acampada26s_organigrama.json
# y las reglas de mapeo (MAPEO R1-R5, docs/PUB/TEMPLATE-PROTOCOL.md §2) viven aquí. Reproducible: misma
# entrada → mismos bytes. Lo que este script redacta por su cuenta (descripciones que no están literales en
# el organigrama) queda apuntado en entrada/procedencia.json, que lee formulario.py para marcarlo como DUDA.
#   python -X utf8 ARCHIVO/DISCO/26sm-exported/entrada/derivar-acampada26s.py
import json, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
DOSIER = 'ARCHIVO/DISCO/26sm-exported'
SRC = ROOT / DOSIER / 'entrada/acampada26s_organigrama.json'
DST = ROOT / 'pub/templates/acampada26s.json'
PROC = ROOT / DOSIER / 'entrada/procedencia.json'
GUIA = f'{DOSIER}/guia-reparto-acampada26s.md'
ONBOARDING = 'ARCHIVO/DISCO/retro-exporter/onboarding-nodo.md'

o = json.loads(SRC.read_text(encoding='utf-8'))
inst, doc = o['instancia'], o['documento']
LUGAR = {l['id']: l for l in o['lugares']}
ORG = {}          # id → nodo (órganos, miembros, subgrupos)
PADRE = {}        # id de miembro/subgrupo → id del órgano que lo agrupa


def indexar(n, padre=None):
    if isinstance(n, list):
        for v in n: indexar(v, padre)
    elif isinstance(n, dict):
        if isinstance(n.get('id'), str):
            ORG[n['id']] = n
            if padre: PADRE[n['id']] = padre
            padre = n['id']
        for v in n.values(): indexar(v, padre)


indexar(o['organos']); indexar(o['metodos_y_conceptos'])
IDS = set(ORG) | {'documento'}
proc = {}  # id de objeto → {campo: 'organigrama' | 'derivador'}


def marca(oid, campo, fuente):
    proc.setdefault(oid, {})[campo] = fuente


def es_pendiente(s):
    return isinstance(s, str) and s.startswith('<')


def img(kind, oid):
    return f'{kind}-{oid}.png'


# ---------- R1 · órgano → tribu ----------
# apertura (hecho de la imagen) → privacidad (regla): abierto = pública con invitación abierta y QR;
# portavocias = privada y estricta (solo el autor invita); externo = tribu de enlace pública y estricta.
APERTURA = {
    'abierto': dict(private=False, inviteMode='open', openInvite=True),
    'portavocias': dict(private=True, inviteMode='strict', openInvite=False),
    'externo': dict(private=False, inviteMode='strict', openInvite=False),
}
# Descripciones que redacta el derivador (no están literales en el organigrama) → DUDA en el formulario.
DESC = {
    'asamblea_general': 'Órgano mayor de representación. Ratifica consensos (semáforo), espacio informativo, exposición de nodos y comisiones, lectura de comunicados.',
    'asamblea_internodos': 'Portavocías rotativas de los nodos territoriales. Pone en común las propuestas de los nodos y aglutina consensos para la Asamblea General. Sin poder de decisión.',
    'comision_comunicacion': 'Comunicación interna y externa, redes, medios, diseño. Coordina con nodos, comisiones y Asamblea General.',
    'comision_dinamizacion': 'Facilita las asambleas y los procesos de decisión.',
    'com_general': 'Grupo general de la comisión (antes: grupo de Telegram).',
    'com_redes': 'Redes sociales y contenido digital.',
    'com_interna': 'Comunicación interna de la acampada.',
    'com_audiovisual': 'Foto y vídeo. Lo publicado va a Images, Videos, Audios y Podcasts.',
    'com_diseno': 'Diseño gráfico e identidad visual. Lo publicado va a Images y Docs.',
    'com_cultura': 'Programación cultural. Los actos se publican como Events.',
    'com_piar': 'Relación con medios y entidades. Los comunicados salen por Blogs y la lista «Comunicados».',
    'com_crisis': 'Coordinación y respuesta rápida. Los avisos urgentes van a Emergencies.',
    'com_correccion': 'Revisión de textos antes de publicar. Se trabaja en Pads.',
}
PUNTO = {'norte': 'norte', 'oeste': 'oeste', 'centro': 'centro', 'este': 'este', 'sur': 'sur'}
CONTENT = {  # qué pestañas usa cada tipo de grupo (regla; va al guion)
    'asamblea_general': ['feed', 'forum'], 'asamblea_internodos': ['feed', 'forum'],
    'nodo': ['feed', 'forum', 'event'], 'comision': ['feed', 'forum', 'task'], 'externo': ['feed', 'forum'],
    'com_general': ['feed', 'forum'], 'com_redes': ['feed', 'forum', 'task'], 'com_interna': ['feed', 'forum'],
    'com_audiovisual': ['feed', 'media'], 'com_diseno': ['feed', 'media'], 'com_cultura': ['feed', 'event'],
    'com_piar': ['feed', 'forum'], 'com_crisis': ['feed', 'forum'], 'com_correccion': ['feed'],
}
TAGS = {
    'asamblea_general': ['asamblea', 'acampada26s'], 'asamblea_internodos': ['internodos', 'portavocias'],
    'comision_urbanismo': ['comision', 'urbanismo', 'vivienda'], 'intercsos': ['articulacion', 'intercsos'],
    'asamblea_de_colectivos': ['articulacion', 'colectivos'],
    'com_general': ['comunicacion'], 'com_redes': ['comunicacion', 'redes'], 'com_interna': ['comunicacion', 'interna'],
    'com_audiovisual': ['comunicacion', 'audiovisual'], 'com_diseno': ['comunicacion', 'diseno'],
    'com_cultura': ['comunicacion', 'cultura'], 'com_piar': ['comunicacion', 'prensa'],
    'com_crisis': ['comunicacion', 'crisis'], 'com_correccion': ['comunicacion', 'textos'],
}


def descripcion(oid, nodo, por_defecto=None):
    if oid in DESC:
        marca(oid, 'description', 'derivador'); return DESC[oid]
    if nodo.get('descripcion'):
        marca(oid, 'description', 'organigrama'); return nodo['descripcion']
    marca(oid, 'description', 'derivador'); return por_defecto or ''


def tribu(oid, origen, title, desc, apertura, tags, content, responsable, **extra):
    t = dict(id=oid, origen=origen, title=title, description=desc, tags=tags)
    t.update(APERTURA[apertura]); t['content'] = content
    t.update(extra); t['responsable'] = responsable; t['image'] = img('tribu', oid)
    return t


tribes = []
ag, inter, nodos = ORG['asamblea_general'], ORG['asamblea_internodos'], ORG['nodos_territoriales']
tribes.append(tribu('asamblea_general', 'asamblea_general', ag['nombre'], descripcion('asamblea_general', ag),
                    ag['apertura'], TAGS['asamblea_general'], CONTENT['asamblea_general'], ag['responsable_reparto']))
tribes.append(tribu('asamblea_internodos', 'asamblea_internodos', inter['nombre'], descripcion('asamblea_internodos', inter),
                    inter['apertura'], TAGS['asamblea_internodos'], CONTENT['asamblea_internodos'], inter['responsable_reparto'],
                    nota='La membresía son las portavocías vigentes: rotar = salir + invitar (la clave de la tribu rota en cada salida).'))
for m in nodos['miembros']:
    punto = m['id'].split('_', 1)[1]
    d = f'Asamblea abierta de barrios y territorios del {PUNTO[punto]}. Debate los temas de la Asamblea General, elabora propuestas y elige 2-3 portavoces rotativos.'
    if m.get('barrios'):   # literal de los posts del colectivo (v2.1)
        d += f' Barrios: {m["barrios"]}'
        marca(m['id'], 'description', 'mixto')   # frase inicial del derivador + barrios literales
    else:
        marca(m['id'], 'description', 'derivador')
    tribes.append(tribu(m['id'], m['id'], m['nombre'], d, m['apertura'], ['nodo', punto], CONTENT['nodo'], m['responsable_reparto']))
for m in ORG['comisiones_de_trabajo']['miembros']:
    tema = m['id'].split('_', 1)[1]
    tribes.append(tribu(m['id'], m['id'], f'Comisión de {m["nombre"]}', descripcion(m['id'], m),
                        m['apertura'], TAGS.get(m['id'], ['comision', tema]), CONTENT['comision'], m['responsable_reparto']))
com = ORG['comision_de_comunicacion']
TITULO_SUB = {  # título de cada sub-tribu (el nombre del subgrupo, normalizado; lo escribe el derivador)
    'com_general': 'General', 'com_redes': 'Redes y contenido digital', 'com_interna': 'Interna', 'com_audiovisual': 'Audiovisual',
    'com_diseno': 'Diseño y branding', 'com_cultura': 'Cultura y eventos', 'com_piar': 'Relaciones públicas (PIAR)',
    'com_crisis': 'Coordinación y gabinete de crisis', 'com_correccion': 'Corrección de textos',
}
for s in com['subgrupos']['lista']:
    tribes.append(tribu(s['id'], s['id'], f'Comunicación · {TITULO_SUB[s["id"]]}', descripcion(s['id'], s), s['apertura'],
                        TAGS[s['id']], CONTENT[s['id']], s['responsable_reparto'], parent='comision_comunicacion'))
EXT_ID = {'intercsos': 'intercsos', 'asamblea_de_colectivos': 'asamblea_colectivos'}
for m in ORG['otros_espacios_de_articulacion']['miembros']:
    oid = EXT_ID[m['id']]
    marca(oid, 'description', 'derivador')   # el organigrama da la descripción; «Tribu de enlace» lo añade el derivador
    tribes.append(tribu(oid, m['id'], m['nombre'], m['descripcion'] + ' Tribu de enlace.', m['apertura'],
                        TAGS[m['id']], CONTENT['externo'], m['responsable_reparto']))

# ---------- R2 · reunión → sala + calendario (+ evento público de la AG) ----------
rooms, calendars = [], []
lugar_ag = LUGAR[ag['reunion']['lugar_id']]


def sala(oid, origen, title, desc, status, tribe, tags, responsable):
    marca(oid, 'description', 'derivador')
    return dict(id=oid, origen=origen, title=title, description=desc, status=status, tribe=tribe, tags=tags,
                responsable=responsable, image=img('sala', oid), clearnetPublic=False)  # con tribu: nunca en /c


rooms.append(sala('sala_asamblea_general', 'asamblea_general', 'Sala · Asamblea General',
                  f'Sala abierta de la Asamblea General (voz y texto). Para quien no puede estar en Sol a las {ag["reunion"]["hora"]}.',
                  'OPEN', 'asamblea_general', ['asamblea'], ag['responsable_reparto']))
rooms.append(sala('sala_internodos', 'asamblea_internodos', 'Sala · Internodos', 'Sala de las portavocías, solo por invitación.',
                  'INVITE-ONLY', 'asamblea_internodos', ['internodos'], inter['responsable_reparto']))
for m in nodos['miembros']:
    rooms.append(sala(f'sala_{m["id"]}', m['id'], f'Sala · {m["nombre"]}', 'Sala abierta del nodo.', 'OPEN', m['id'], ['nodo'], m['responsable_reparto']))


def calendario(oid, origen, title, tribe, tags, fecha, responsable):
    return dict(id=oid, origen=origen, title=title, status='OPEN', tribe=tribe, tags=tags, dates=[fecha],
                responsable=responsable, clearnetPublic=tribe is None)


calendars.append(calendario('cal_asamblea_general', 'asamblea_general', ag['nombre'], None, ['asamblea'],
                            dict(label=ag['nombre'], hora=ag['reunion']['hora'], recurrencia=ag['reunion']['periodicidad'], offsetDays=1,
                                 nota=f'{lugar_ag["nombre"]}. Ratifica consensos con la técnica del semáforo.'), ag['responsable_reparto']))
calendars.append(calendario('cal_internodos', 'asamblea_internodos', inter['nombre'], 'asamblea_internodos', ['internodos'],
                            dict(label=inter['nombre'], hora=inter['reunion']['hora'], recurrencia=inter['reunion']['periodicidad'], offsetDays=1,
                                 nota=inter['reunion']['nota'][0].upper() + inter['reunion']['nota'][1:] + '.'), inter['responsable_reparto']))
for m in nodos['miembros']:
    calendars.append(calendario(f'cal_{m["id"]}', m['id'], m['nombre'], m['id'], ['nodo'],
                                dict(label='Asamblea del nodo', hora=m['reunion']['hora'], recurrencia=m['reunion']['periodicidad'], offsetDays=2,
                                     nota='Periodicidad según cada nodo.'), m['responsable_reparto']))

marca('evento_asamblea_general', 'description', 'derivador')
events = [dict(id='evento_asamblea_general', origen='asamblea_general', title='Asamblea General · Puerta del Sol',
               description=f'Cada día a las {ag["reunion"]["hora"]} en {lugar_ag["nombre"]}. Espacio informativo y de consenso; ratificación con la técnica del semáforo.',
               offsetDays=1, hora=ag['reunion']['hora'], location=f'{lugar_ag["nombre"]}, {lugar_ag["ciudad"]}', isPublic=True, clearnetPublic=True,
               recurrencia=ag['reunion']['periodicidad'], tags=['asamblea', 'sol'], responsable=ag['responsable_reparto'],
               image=img('evento', 'evento_asamblea_general'))]

# ---------- R4 · canales → listas · R5 · externos → listas cifradas + federación ----------
mailing = []
for oid, origen, title, desc, tipo, tags, resp in [
    ('lista_acuerdos', 'asamblea_general', 'Acuerdos de la Asamblea General',
     'Flujo descendente: temas y acuerdos para trabajar en los nodos. Solo publica quien la Asamblea decida; cualquiera se suscribe.', 'OPEN', ['acuerdos'], ag['responsable_reparto']),
    ('lista_comunicados', 'comision_de_comunicacion', 'Comunicados', 'Comunicados oficiales de la acampada hacia dentro y hacia fuera.', 'OPEN', ['comunicados'], com['responsable_reparto']),
    ('lista_colectivos', 'asamblea_de_colectivos', 'Asamblea de Colectivos', 'Coordinación con otros colectivos. Cifrada: solo miembros.', 'CLOSED', ['articulacion'], 'asamblea_de_colectivos'),
    ('lista_intercsos', 'intercsos', 'InterCSOs', 'Relación con entidades de la sociedad civil. Cifrada: solo miembros.', 'CLOSED', ['articulacion'], 'intercsos'),
]:
    marca(oid, 'description', 'derivador')
    mailing.append(dict(id=oid, origen=origen, title=title, description=desc, listType=tipo, tags=tags, responsable=resp))

federation = []
for m in ORG['otros_espacios_de_articulacion']['miembros']:
    nota = ('Cada entidad con pub propio: follow mutuo entre pubs y announce. Sin pub: tribu de enlace + lista CLOSED.' if m['id'] == 'intercsos'
            else 'Una federación de pubs es la forma nativa de «asamblea de colectivos» en SSB.')
    federation.append(dict(id=f'fed_{EXT_ID[m["id"]].replace("asamblea_", "")}', origen=m['id'], nombre=m['nombre'], pub=m['pub'], nota=nota))

# ---------- Mapas ----------
maps = [
    dict(id='mapa_sol', origen='asamblea_general', title=lugar_ag['nombre'],
         description=f'Lugar de la Asamblea General, cada día a las {ag["reunion"]["hora"]}' + (f' ({lugar_ag["nota"]})' if lugar_ag.get('nota') else '') + '.',
         lat=lugar_ag['lat'], lng=lugar_ag['lng'], mapType='SINGLE', tags=['asamblea', 'sol'], markers=[],
         nota=lugar_ag['precision'], responsable=ag['responsable_reparto'], image=img('mapa', 'mapa_sol'), clearnetPublic=False),
    dict(id='mapa_nodos', origen='nodos_territoriales', title=nodos['nombre'], description='Mapa colaborativo: cada nodo marca dónde se reúne.',
         lat=lugar_ag['lat'], lng=lugar_ag['lng'], mapType='OPEN', tags=['nodos'], markers=[],
         nota='Los marcadores los pone cada nodo; no se inventan coordenadas.', responsable=nodos['responsable_reparto'],
         image=img('mapa', 'mapa_nodos'), clearnetPublic=True),
]
for x in maps: marca(x['id'], 'description', 'derivador')


# ---------- R3 · métodos → convención de voto + wikis; wiki del organigrama generada ----------
def wiki_organigrama():
    L = [f'# {doc["titulo"]} · {doc["subtitulo"]}', '',
         f'> Página generada desde el organigrama publicado por el colectivo el {doc["fuente"]["fecha_publicacion"]} '
         f'({doc["fuente"]["blog"]}). El colectivo la revisa y la corrige; la fuente es la imagen, no esta página.', '',
         f'**{doc["descripcion"]}.** Objetivo del movimiento: {doc["objetivo_del_movimiento"]}', '']
    for org in o['organos']:
        L.append(f'## {org["nombre"]}')
        if org.get('descripcion'): L.append(org['descripcion'] + ('' if org['descripcion'].endswith('.') else '.'))
        r = org.get('reunion')
        if r:
            lugar = LUGAR[r['lugar_id']]['nombre'] if r.get('lugar_id') else None
            L.append('Se reúne: ' + r['periodicidad'] + (f' a las {r["hora"]}' if r.get('hora') and not es_pendiente(r['hora']) else '')
                     + (f', en {lugar}' if lugar else '') + (f' ({r["nota"]})' if r.get('nota') else '') + '.')
        if org.get('acceso'): L.append(org['acceso'] + '.')
        for f in org.get('funciones', []): L.append(f'- {f}')
        for f in org.get('formas_de_participacion', []): L.append(f'- {f}')
        if org.get('miembros'):
            L.append('')
            for m in org['miembros']:
                L.append(f'- **{m["nombre"]}**' + (f': {m["descripcion"]}' if m.get('descripcion') else ''))
        if org.get('subgrupos'):
            L.append(''); L.append(f'Subgrupos (hoy en {org["subgrupos"]["plataforma"]}):')
            for s in org['subgrupos']['lista']: L.append(f'- {s["nombre"]}')
        L.append('')
    fd = o['flujo_de_decision']
    L += ['## Flujo de decisión', '',
          '- Ascendente: ' + ' → '.join(ORG[i]['nombre'] for i in fd['ascendente']),
          '- Descendente: ' + ' → '.join(ORG[i]['nombre'] for i in fd['descendente']),
          '- Cada día: ' + ' · '.join(f'{s["hora"]} {ORG[s["organo"]]["nombre"]}' for s in fd['secuencia_diaria']), '']
    for m in o['metodos_y_conceptos']:
        L.append(f'## {m["nombre"]}')
        if m.get('descripcion'): L.append(m['descripcion'])
        for v in m.get('valores', []): L.append(f'- {v["color"].capitalize()}: {v["significado"]}')
        for c in m.get('caracteristicas', []): L.append(f'- {c}')
        L.append('')
    return '\n'.join(L).rstrip() + '\n'


sem, port = ORG['tecnica_semaforo'], ORG['portavocias_rotativas']
wiki = [
    dict(id='wiki_organigrama', origen='documento', title=doc['subtitulo'], body=wiki_organigrama(), editPolicy='open', tags=['organigrama'],
         image=img('wiki', 'wiki_organigrama'), clearnetPublic=True, responsable='documento',
         nota='Cuerpo generado desde el organigrama por derivar-acampada26s.py; el colectivo lo revisa en el formulario.'),
    dict(id='wiki_semaforo', origen='tecnica_semaforo', title=sem['nombre'],
         body=sem['descripcion'] + ' ' + ' '.join(f'{v["color"].capitalize()}: {v["significado"].lower()}.' for v in sem['valores'])
              + ' En Oasis: una votación (Votes) con las tres opciones VERDE, AMARILLO, ROJO por cada propuesta.',
         editPolicy='author', tags=['metodo'], image=img('wiki', 'wiki_semaforo'), clearnetPublic=True, responsable='asamblea_general'),
    dict(id='wiki_portavocias', origen='portavocias_rotativas', title=port['nombre'],
         body='2-3 portavoces por nodo, rotativas, sin poder de decisión: transmiten las propuestas de su nodo a la Asamblea Internodos. '
              'En Oasis: ser portavoz = ser miembro de la tribu Asamblea Internodos durante el turno; al terminar, se sale de la tribu y entra la siguiente portavocía.',
         editPolicy='author', tags=['metodo'], image=img('wiki', 'wiki_portavocias'), clearnetPublic=True, responsable='asamblea_internodos'),
    dict(id='wiki_onboarding', origen='personas', title='Oasis para el nodo · manual de bienvenida', file=ONBOARDING, editPolicy='open', tags=['manual'],
         image=img('wiki', 'wiki_onboarding'), clearnetPublic=True, responsable='personas'),
    dict(id='wiki_reparto', origen='documento', title='Guía de reparto de accesos', file=GUIA, editPolicy='author', tags=['manual', 'reparto'],
         image=img('wiki', 'wiki_reparto'), clearnetPublic=True, responsable='documento',
         nota='La genera template-seed.js --reparto: libro del operador, sin códigos.'),
]
for w in wiki: marca(w['id'], 'body', 'organigrama' if w['id'] == 'wiki_organigrama' else 'derivador')

# ---------- Convenciones, addenda y guion (método: MAPEO §2-§3) ----------
votes = dict(
    convencion=dict(id='semaforo', origen='tecnica_semaforo', options=[v['color'].upper() for v in sem['valores']], minDays=7,
                    nota='Una votación por propuesta que llega a la Asamblea General. El módulo Votes admite opciones libres; la votación interna de Parliament no (YES/NO/ABSTENTION).'),
    ejemplo=dict(id='voto_ejemplo', origen='asamblea_general', question='¿Ratifica la Asamblea General la propuesta «…» del Nodo …?', offsetDays=7, tags=['semaforo']))
emergencies = dict(convencion=[
    dict(origen='comision_cuidados', category='HEALTH', uso='Salud y primeros auxilios en la plaza.'),
    dict(origen='comision_de_comunicacion', category='SECURITY', uso='Gabinete de crisis: avisos de seguridad.'),
    dict(origen='comision_abastecimiento', category='INFRASTRUCTURE', uso='Cortes de suministro, materiales críticos.'),
    dict(origen='nodos_territoriales', category='NEIGHBORHOOD', uso='Avisos de barrio desde cada nodo.')])
courts = dict(convencion=dict(origen='comision_mediacion', method='MEDIATION', uso='Conflictos de convivencia: la Comisión de Mediación abre el caso con método MEDIATION.'))
addenda = [
    dict(modulo='housing', origen='comision_urbanismo', porQue='Vivienda es la demanda central del movimiento: Housing publica alquiler, venta y acogida (couchsurfing) con disponibilidad. Fuera del workflow activists; encenderlo es un clic por cliente.'),
    dict(modulo='market', origen='comision_abastecimiento', porQue='Dar, pedir e intercambiar bienes y servicios sin dinero (exchange) o con ECOin. Complementa a Logistics (ya dentro).'),
    dict(modulo='transfers', origen='comision_abastecimiento', porQue='Transferencias de TIEMPO y CONFIANZA entre habitantes, además de económicas: banco de tiempo de la plaza.'),
    dict(modulo='parliament', origen='asamblea_general', porQue='Ratificación formal con legislaturas, propuestas y leyes. Requiere abrir una legislatura; su votación interna es sí/no, por eso el semáforo vive en Votes.'),
    dict(modulo='school', origen='portavocias_rotativas', porQue='Ya dentro de activists: cursos y lecciones para formar portavocías y mesa técnica.'),
    dict(modulo='banking', origen='documento', porQue='ECOin: un pub con cartera paga renta básica a los habitantes activos. Economía interna opcional; protocolo ECOIN-PROTOCOL.md.'),
]
guion = dict(workflow=inst['workflow'],
             nota_workflow='El workflow es un ajuste local de cada cliente (Settings → Workflows → Activists). Ningún mensaje SSB lo transporta: el pub no puede imponerlo. Va en el guion y en el manual.',
             invite_asamblea=inst['invite_asamblea'])

meta = dict(id='acampada26s', nombre=doc['titulo'], descripcion=f'{doc["descripcion"]}, expresada en objetos de Oasis {inst["oasis_version"]["declarada"]}',
            pub=inst['pub'], workflow=inst['workflow'], idioma=inst['idioma'], version_oasis=inst['oasis_version']['declarada'],
            organigrama=str(SRC.relative_to(ROOT)).replace('\\', '/'), derivada_por=f'{DOSIER}/entrada/derivar-acampada26s.py',
            autoria=inst['autoria'], reparto=inst['reparto'])

t = dict(meta=meta, tribes=tribes, rooms=rooms, calendars=calendars, events=events, mailing=mailing, wiki=wiki, maps=maps,
         votes=votes, emergencies=emergencies, courts=courts, federation=federation, addenda=addenda, guion=guion)

# ---------- comprobaciones (la misma que organigramaIds en template-seed.js) ----------
rotos = []
for sec in ('tribes', 'rooms', 'calendars', 'events', 'mailing', 'wiki', 'maps', 'federation', 'addenda'):
    for x in t[sec]:
        if x['origen'] not in IDS: rotos.append(f'{sec}:{x["id"] if "id" in x else x["modulo"]}:origen={x["origen"]}')
        r = x.get('responsable')
        if r and not es_pendiente(r) and r not in IDS: rotos.append(f'{sec}:{x["id"]}:responsable={r}')
if rotos:
    print('ORIGEN/RESPONSABLE fuera del organigrama:', *rotos, sep='\n  '); sys.exit(2)

# ---------- marca.json: lo que el generador de tarjetas necesita (el JSON manda también sobre la marca) ----------
MARCA = ROOT / DOSIER / 'entrada/marca.json'
mk = inst.get('marca', {})
if mk.get('paleta'):
    logos = {l['version']: l['fichero'] for l in mk['logos']}
    marca_json = {
        'id': 'acampada26s', 'fuente': mk.get('fuente'),
        'paleta': {k: v['hex'] for k, v in mk['paleta'].items()},
        'fuentes': {   # rutas relativas al repo; libres (OFL) vendorizadas en el dosier. Gill Sans no se vendoriza.
            'titular': f'{DOSIER}/assets/fonts/CabinCondensed-Bold.ttf',
            'cuerpo': f'{DOSIER}/assets/fonts/CabinCondensed-Regular.ttf',
            'nombre_oficial': {'titular': mk['tipografia']['titulares'], 'cuerpo': mk['tipografia']['cuerpos']},
            'sustituto': mk['tipografia']['sustituto_libre']['nombre'],
        },
        'interlineado': mk['tipografia']['interlineado'], 'mayusculas': mk['tipografia']['mayusculas_en_titulares'],
        'fondos': [l['fichero'] for l in mk['fondo']['lonas']],
        'fondos_sha256': {l['fichero'].rsplit('/', 1)[1]: l['sha256'] for l in mk['fondo']['lonas']},
        'logo': {'blanco': logos.get('blanco'), 'naranja': logos.get('naranja'), 'azul': logos.get('azul')},
        'etiquetas': {'tribu': 'GRUPO', 'subtribu': 'SUBGRUPO', 'sala': 'SALA', 'mapa': 'MAPA', 'evento': 'EVENTO', 'wiki': 'PÁGINA', 'privado': 'CERRADO'},
        'avatar': {'patron': mk['avatar']['patron'], 'texto': '26S'},
        'composicion': mk['composicion']['orden'],
        'portadas': {'wiki_organigrama': {'subtitulo': doc['descripcion'], 'referencia': f'kit pág. {mk["organigrama_maquetado"]["pagina"]}'}},
    }
    MARCA.write_text(json.dumps(marca_json, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

DST.write_text(json.dumps(t, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
PROC.write_text(json.dumps(proc, ensure_ascii=False, indent=2, sort_keys=True) + '\n', encoding='utf-8')
n = {k: len(v) for k, v in t.items() if isinstance(v, list)}
print(f'plantilla → {DST.relative_to(ROOT).as_posix()}  {json.dumps(n)}  ids del organigrama: {len(IDS)}  candidatos (no sembrados): {len(o.get("candidatos", []))}')
print(f'procedencia → {PROC.relative_to(ROOT).as_posix()}  ({sum(1 for v in proc.values() if "derivador" in v.values())} textos del derivador, {sum(1 for v in proc.values() if "mixto" in v.values())} mixtos)')
if mk.get('paleta'): print(f'marca → {MARCA.relative_to(ROOT).as_posix()}  ({len(marca_json["fondos"])} lonas, paleta {marca_json["paleta"]})')
