#!/usr/bin/env python3
# derivar-campamento.py · deriva la plantilla y el organigrama «Campamento» de los de Acampada26S.
# Reproducible: misma entrada → misma salida. Lo que ata a la instancia (nombre, plaza, ciudad)
# pasa a genérico o a <pendiente>; lo que es estructura se conserva. Añade los campos de WP-O131:
# image (kit visual), clearnetPublic, responsable, meta.reparto y la wiki de reparto.
#   python -X utf8 ARCHIVO/DISCO/scriptorium-exported/entrada/derivar-campamento.py
import json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
SRC_T = ROOT / 'pub/templates/acampada26s.json'
SRC_O = ROOT / 'ARCHIVO/DISCO/retro-exporter/entrada/acampada26s_organigrama.json'
DST_T = ROOT / 'pub/templates/campamento.json'
DST_O = ROOT / 'ARCHIVO/DISCO/scriptorium-exported/entrada/campamento_organigrama.json'
GUIA = 'ARCHIVO/DISCO/scriptorium-exported/guia-reparto-campamento.md'

PLAZA = '<pendiente: plaza o lugar de la Asamblea General>'
SUBS = [
    (r'Acampada26S', 'Campamento'),
    (r'acampada26s\.net', '<pendiente: pub del colectivo>'),
    (r'acampada26s', 'campamento'),
    (r'Puerta del Sol nº 14, Madrid', PLAZA),
    (r'Puerta del Sol nº 14', PLAZA),
    (r'Puerta del Sol', 'la plaza'),
    (r'\ben Sol\b', 'en la plaza'),
    (r'la acampada', 'el campamento'),
]

def sub(s):
    for a, b in SUBS:
        s = re.sub(a, b, s)
    return s

def walk(x):
    if isinstance(x, str): return sub(x)
    if isinstance(x, list): return [walk(v) for v in x]
    if isinstance(x, dict): return {k: walk(v) for k, v in x.items()}
    return x

t = walk(json.loads(SRC_T.read_text(encoding='utf-8')))
o = walk(json.loads(SRC_O.read_text(encoding='utf-8')))

# ---- organigrama ----
o['documento']['titulo'] = 'Campamento'
o['documento']['descripcion'] = 'Estructura asamblearia, horizontal y en red (plantilla genérica para una acampada)'
o['documento']['objetivo_del_movimiento'] = '<pendiente: objetivo del movimiento, redactado por el colectivo>'
o['metadatos'] = {
    'derivado_de': 'ARCHIVO/DISCO/retro-exporter/entrada/acampada26s_organigrama.json',
    'como': 'ARCHIVO/DISCO/scriptorium-exported/entrada/derivar-campamento.py (sustituciones de nombre y lugar; la estructura no cambia)',
    'notas': ['Ningún órgano, relación o método se ha inventado: todo sale del organigrama de origen con los nombres propios neutralizados.']
}

# ---- plantilla ----
m = t['meta']
m['id'] = 'campamento'
m['nombre'] = 'Campamento'
m['descripcion'] = 'Estructura asamblearia, horizontal y en red, expresada en objetos de Oasis 1.2.3. Plantilla genérica (showcase) para cualquier acampada.'
m['pub'] = '<pendiente: pub del colectivo>'
m['organigrama'] = 'ARCHIVO/DISCO/scriptorium-exported/entrada/campamento_organigrama.json'
m['derivada_de'] = 'pub/templates/acampada26s.json'
m['reparto'] = {
    'mesa_tecnica': '<pendiente: quién es la mesa técnica (la secretaría del pub ejecuta; la mesa entrega)>',
    'entrega': 'Cada órgano nombra a quién de los suyos le llega el acceso. Tribus abiertas: QR impreso o botón en la tarjeta. Tribus estrictas y listas cerradas: el autor invita en mano. Nunca por un canal que quede escrito.'
}

# responsable = órgano del organigrama (factual: el origen); quién dentro del órgano es DECISIÓN del colectivo
RESP = {'com_': 'comision_de_comunicacion'}
def responsable(x):
    if x['id'].startswith('com_'): return 'comision_de_comunicacion'
    return x['origen']

def img(kind, x): return f'{kind}-{x["id"]}.png'

for x in t['tribes']:
    x['responsable'] = responsable(x)
    x['image'] = img('tribu', x)
    x['tags'] = [('campamento' if g == 'campamento' else g) for g in x['tags']]
for x in t['rooms']:
    x['responsable'] = x['origen']
    x['image'] = img('sala', x)
    x['clearnetPublic'] = False          # todas llevan tribe: nunca salen en /c (backend.js:655-751)
for x in t['calendars']:
    x['responsable'] = x['origen']
    x['clearnetPublic'] = x['tribe'] is None
for x in t['events']:
    x['image'] = img('evento', x)
    x['responsable'] = x['origen']
    x['tags'] = [('plaza' if g == 'sol' else g) for g in x['tags']]
    x['title'] = 'Asamblea General · en la plaza'
for x in t['mailing']:
    x['responsable'] = x['origen']
for x in t['maps']:
    x['responsable'] = x['origen']
    x['image'] = img('mapa', x)
    x['clearnetPublic'] = True
    x['lat'] = 0.0; x['lng'] = 0.0
    x['nota'] = (x.get('nota', '') + ' ' if x.get('nota') else '') + '<pendiente: coordenadas de la plaza; 0,0 es el valor sin decidir, no una ubicación>'
    x['tags'] = [('plaza' if g == 'sol' else g) for g in x['tags']]
    if x['id'] == 'mapa_sol':
        x['id'] = 'mapa_plaza'; x['title'] = 'La plaza'; x['image'] = img('mapa', x)
for x in t['wiki']:
    x['image'] = img('wiki', x)
    x['clearnetPublic'] = True
    x['responsable'] = x['origen']
t['wiki'].append({
    'id': 'wiki_reparto', 'origen': 'documento', 'title': 'Guía de reparto de accesos',
    'file': GUIA, 'editPolicy': 'author', 'tags': ['manual', 'reparto'],
    'image': 'wiki-wiki_reparto.png', 'clearnetPublic': True, 'responsable': 'documento',
    'nota': 'La genera template-seed.js --reparto: libro del operador, sin códigos. Misma fuente que la página de la Sala 02 del sitio.'
})

DST_T.write_text(json.dumps(t, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
DST_O.write_text(json.dumps(o, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(f'plantilla → {DST_T.relative_to(ROOT)}\norganigrama → {DST_O.relative_to(ROOT)}')
