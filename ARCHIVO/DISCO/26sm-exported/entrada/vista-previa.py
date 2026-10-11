#!/usr/bin/env python3
# vista-previa.py · empaqueta las capturas del drill (manifest-c.json, manifest-app.json) en una página estática
# vista-previa/index.html (sin JS, rutas relativas) para adjuntar al formulario de branding y contenidos.
#   python -X utf8 ARCHIVO/DISCO/26sm-exported/entrada/vista-previa.py
import json, html
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
D = ROOT / 'ARCHIVO/DISCO/26sm-exported'
V = D / 'vista-previa'
T = json.loads((ROOT / 'pub/templates/acampada26s.json').read_text(encoding='utf-8'))
TITULO = {x['id']: x['title'] for s in ('tribes', 'rooms', 'calendars', 'events', 'mailing', 'wiki', 'maps') for x in T[s]}
FILA = {}  # id de objeto → fila del formulario
for i, x in enumerate(T['tribes'], 1): FILA[x['id']] = f'C-G{i}'
for i, x in enumerate(T['rooms'], 1): FILA[x['id']] = f'C-S{i}'
for i, x in enumerate(T['calendars'], 1): FILA[x['id']] = f'C-C{i}'
for i, x in enumerate(T['events'], 1): FILA[x['id']] = f'C-E{i}'
for i, x in enumerate(T['mailing'], 1): FILA[x['id']] = f'C-L{i}'
for i, x in enumerate(T['wiki'], 1): FILA[x['id']] = f'C-P{i}'
for i, x in enumerate(T['maps'], 1): FILA[x['id']] = f'C-M{i}'
PUB = 'https://acampada26s.net'

QUE_C = {'/c': 'Portada pública: todo lo que se ve desde fuera (sin cuenta)', '/c/inhabitant/': 'Perfil público de la cuenta de secretaría (avatar del kit)'}
QUE_APP = {'/': 'Actividad: lo último publicado', '/tribes': 'Grupos: todos los de la 26S con su tarjeta', '/tribe/': 'Un grupo por dentro (muro, foro, tareas)',
           '/wiki': 'Páginas: las 5 con su portada', '/wiki/': 'Una página abierta', '/calendars': 'Calendarios', '/calendars/': 'El calendario de la Asamblea General',
           '/rooms': 'Salas: vacío porque cada sala va dentro de su grupo (solo la ven sus miembros)', '/maps': 'Mapas', '/events': 'Eventos: la Asamblea General diaria',
           '/mailing': 'Listas de correo', '/author/': 'La cuenta de secretaría vista desde dentro'}


def que(url, tabla):
    for k in sorted(tabla, key=len, reverse=True):
        if url.startswith(k) and (k.endswith('/') or url == k): return tabla[k]
    return ''


def tarjeta(it, tabla, base_real):
    oid = (it.get('id') or '').split('#')[0]
    titulo = it.get('title') or TITULO.get(oid) or que(it['url'], tabla) or it['url']
    fila = FILA.get(oid, '')
    url_real = f'{base_real}{it["url"].split("?")[0]}' if base_real else ''
    meta = ' · '.join(x for x in [f'fila {fila} del formulario' if fila else '', que(it['url'], tabla) if it.get('title') else '', f'{it["bytes"] // 1024} KB'] if x)
    return (f'<figure><a href="{html.escape(it["file"])}"><img loading="lazy" src="{html.escape(it["file"])}" alt="{html.escape(titulo)}"></a>'
            f'<figcaption><strong>{html.escape(titulo)}</strong><br><small>{html.escape(meta)}</small>'
            + (f'<br><small>Será: <code>{html.escape(url_real)}</code></small>' if url_real else '') + '</figcaption></figure>')


mc = json.loads((V / 'manifest-c.json').read_text(encoding='utf-8'))
ma = json.loads((V / 'manifest-app.json').read_text(encoding='utf-8'))
mg = json.loads((V / 'manifest-guia.json').read_text(encoding='utf-8')) if (V / 'manifest-guia.json').exists() else {'items': []}
css = ('body{font-family:system-ui,sans-serif;max-width:1100px;margin:0 auto;padding:16px;color:#1a1a1a;background:#f4f4f4}'
       'h1{font-size:1.5rem}h2{margin-top:2.5rem;border-bottom:3px solid #0452C5;padding-bottom:4px}'
       '.aviso{background:#FF981F;color:#fff;padding:12px 16px;border-radius:6px;font-weight:600}'
       '.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(320px,1fr));gap:20px}'
       'figure{margin:0;background:#fff;border:1px solid #ddd;border-radius:6px;overflow:hidden}'
       'figure img{width:100%;display:block;max-height:420px;object-fit:cover;object-position:top}'
       '.guias{grid-template-columns:1fr}.guias figure img{max-height:none}'
       'figcaption{padding:10px 12px;font-size:.9rem}code{font-size:.75rem;word-break:break-all}'
       '.nota{background:#fff;border-left:4px solid #0452C5;padding:10px 14px;margin:12px 0}')
partes = [f'<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
          f'<title>Vista previa real · Acampada26S</title><style>{css}</style></head><body>',
          '<h1>Así va a quedar · vista previa real del espacio digital de Acampada26S</h1>',
          '<p class="aviso">Capturas reales de un pub de prueba en un ordenador local, hecho con vuestros materiales y vuestro kit visual. '
          'Nada de esto se ha publicado en acampada26s.net. Es para que veáis exactamente cómo quedará y nos digáis qué cambiar (formulario, bloque A5).</p>',
          f'<p>Generado el {html.escape(mc.get("at", ""))}. Dos vistas: lo que ve <strong>cualquiera desde la web</strong> sin cuenta, y lo que ve '
          '<strong>una persona dentro de la aplicación</strong>. Cada captura dice a qué fila del formulario corresponde y qué dirección tendrá cuando esté en vuestro pub.</p>',
          '<h2>1 · Desde la web, sin cuenta (acampada26s.net/c)</h2>',
          '<div class="nota">Aquí solo sale lo marcado como «visible en la web»: calendario, evento, mapa colaborativo y páginas. '
          '<strong>Los grupos no aparecen en la web hasta que publican algo expuesto</strong> (lo hemos medido: recién creados, su dirección pública responde «no accesible»). '
          'Las salas, listas y el mapa de un solo punto nunca salen fuera.</div>',
          '<div class="grid">', *[tarjeta(it, QUE_C, PUB) for it in mc['items']], '</div>',
          '<h2>2 · Dentro de la aplicación (con cuenta)</h2>',
          '<div class="nota">Vista de una persona recién llegada, conectada al pub pero sin pertenecer aún a ningún grupo: ve los grupos abiertos con su tarjeta, '
          'las páginas, calendarios, mapas, eventos y listas. Las salas solo aparecen cuando se entra en el grupo que las tiene.</div>',
          '<div class="grid">', *[tarjeta(it, QUE_APP, '') for it in ma['items']], '</div>',
          *(['<h2>3 · Guías para validar (páginas enteras)</h2>',
             '<div class="nota">Las páginas largas que explican el procedimiento, tal como se leen en la web pública: organigrama y funcionamiento, '
             'manual de bienvenida (en dos partes) y guía de reparto de accesos. Leedlas enteras y decidnos si se entiende (formulario, bloque D). '
             'Se muestran sin tablas a propósito: el visor de Oasis no las dibuja.</div>',
             '<div class="grid guias">', *[tarjeta(it, QUE_C, PUB) for it in mg['items']], '</div>'] if mg['items'] else []),
          f'<p><small>{len(mc["items"])} capturas públicas + {len(ma["items"])} internas + {len(mg["items"])} guías enteras · fuente: <code>ARCHIVO/DISCO/26sm-exported/vista-previa/</code> (rama dev/26sm-exported) · '
          'generado por <code>entrada/vista-previa.py</code> desde <code>entrada/capturar.py</code>.</small></p></body></html>']
(V / 'index.html').write_text('\n'.join(partes), encoding='utf-8')
tot = sum(p.stat().st_size for p in V.rglob('*') if p.is_file() and '.chrome-profile' not in p.parts)
print(f'vista-previa/index.html · {len(mc["items"])} + {len(ma["items"])} capturas · {tot // 1024} KB en total')
