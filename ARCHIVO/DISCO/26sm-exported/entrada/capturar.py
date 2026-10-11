#!/usr/bin/env python3
# capturar.py · capturas del visor público (/c) y, si se indica, del cliente, con Chrome headless (stdlib + chrome.exe).
# Lee el sitemap del HUB del drill, añade las portadas de módulo y guarda un PNG por URL (ancho fijo, alto completo) en
# <out>/img/, con manifest.json (url, fichero, bytes, sha256, objeto de la plantilla al que corresponde).
#   python -X utf8 ARCHIVO/DISCO/26sm-exported/entrada/capturar.py --base http://localhost:8188 --out ARCHIVO/DISCO/26sm-exported/vista-previa
#   python -X utf8 … --base http://localhost:3100 --prefix app --urls /tribes,/wiki,/calendars  (vista interna, lista explícita)
import argparse, hashlib, json, re, subprocess, sys, time, urllib.request
from pathlib import Path

CHROME = r'C:\Program Files\Google\Chrome\Application\chrome.exe'
ROOT = Path(__file__).resolve().parents[4]
T = json.loads((ROOT / 'pub/templates/acampada26s.json').read_text(encoding='utf-8'))
PORTADAS = ['/c', '/c/tribes', '/c/wiki', '/c/calendars', '/c/events', '/c/maps', '/c/rooms']


def fetch(url, timeout=30):
    with urllib.request.urlopen(url, timeout=timeout) as r: return r.read().decode('utf-8', 'replace')


def shot(url, out, width=1280, height=2400, profile=None):
    args = [CHROME, '--headless=new', '--disable-gpu', '--no-sandbox', '--hide-scrollbars', f'--window-size={width},{height}',
            '--default-background-color=ffffffff', f'--screenshot={out}']
    if profile: args.append(f'--user-data-dir={profile}')
    args.append(url)
    subprocess.run(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=90)
    return out.exists()


def slug(path):
    """Nombre legible: una URL con clave (%25…=.sha256 / %40…=.ed25519) se reduce a <ruta>-<8 chars de la clave>."""
    p = urllib.request.unquote(path.split('?')[0])
    m = re.match(r'^(.*?/)([%@][A-Za-z0-9+/]+=\.(?:sha256|ed25519))$', p)
    if m: p = m.group(1) + m.group(2)[1:9]
    s = re.sub(r'[^A-Za-z0-9]+', '-', p.strip('/')).strip('-').lower()
    return s or 'portada'


def objeto_de(path, ledger):
    """Devuelve (sección, id, título) del objeto de la plantilla que corresponde a la URL, si el ledger lo conoce."""
    for sec in ('tribes', 'rooms', 'calendars', 'events', 'mailing', 'wiki', 'maps'):
        for oid, key in (ledger.get(sec) or {}).items():
            k = key if isinstance(key, str) else (key.get('key') or key.get('id') or '')
            short = k[1:9].lower() if k.startswith('%') else ''   # /c usa slug-<8 chars de la clave> (clearnetShortId)
            if k and (urllib.request.quote(k, safe='') in path or k in path or (short and path.rstrip('/').endswith('-' + short))):
                t = next((x['title'] for x in T.get(sec, []) if x['id'] == oid.split('#')[0]), oid)
                return sec, oid, t
    return None, None, None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--base', required=True); ap.add_argument('--out', required=True)
    ap.add_argument('--prefix', default='c'); ap.add_argument('--urls', default='')
    ap.add_argument('--ledger', default=str(ROOT / 'ARCHIVO/DISCO/26sm-exported/drill/ledger-drill-26s.json'))
    ap.add_argument('--profile', default=''); ap.add_argument('--max-kb', type=int, default=400)
    ap.add_argument('--height', type=int, default=2400, help='alto de la ventana (las páginas de guía enteras: 9000)')
    ap.add_argument('--relink', action='store_true', help='solo vuelve a asociar cada captura existente del manifest con su objeto (sin capturar)')
    a = ap.parse_args()
    out = Path(a.out).resolve(); img = out / 'img'; img.mkdir(parents=True, exist_ok=True)
    # perfil propio SIEMPRE: con un Chrome del usuario abierto, un chrome.exe sin --user-data-dir delega en esa instancia y no captura
    profile = Path(a.profile).resolve() if a.profile else (out / '.chrome-profile'); profile.mkdir(exist_ok=True)
    ledger = json.loads(Path(a.ledger).read_text(encoding='utf-8')) if Path(a.ledger).exists() else {}
    if a.relink:
        man = out / f'manifest-{a.prefix}.json'; m = json.loads(man.read_text(encoding='utf-8'))
        for it in m['items']:
            sec, oid, title = objeto_de(it['url'], ledger); it.update({'section': sec, 'id': oid, 'title': title})
            # nombre de fichero legible (sin claves ni sufijos .sha256/.ed25519): <prefijo>-<slug>.png|jpg
            nuevo = f'{a.prefix}-{slug(it["url"])}' + Path(it['file']).suffix
            if Path(it['file']).name != nuevo and (out / it['file']).exists():
                (out / it['file']).rename(img / nuevo); it['file'] = f'img/{nuevo}'
        man.write_text(json.dumps(m, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        print(f'relink: {sum(1 for i in m["items"] if i["id"])}/{len(m["items"])} con objeto'); return
    if a.urls:
        urls = [u.strip() for u in a.urls.split(',') if u.strip()]
    else:
        sm = fetch(f'{a.base}/c/sitemap.xml?nc={int(time.time())}')
        locs = re.findall(r'<loc>([^<]+)</loc>', sm)
        paths = [re.sub(r'^https?://[^/]+', '', l) for l in locs]
        urls = PORTADAS + [p for p in paths if p not in PORTADAS]
        # las tribus no salen en el sitemap (TEMPLATE §5): se añaden desde el ledger (/c/tribe/<clave del mensaje>)
        for sec in ('tribes', 'subtribes'):
            for oid, key in (ledger.get(sec) or {}).items():
                k = key if isinstance(key, str) else (key.get('key') or key.get('id') or '')
                if k: urls.append('/c/tribe/' + urllib.request.quote(k, safe=''))
    items = []
    for i, p in enumerate(urls, 1):
        name = f'{a.prefix}-{slug(p)}.png'[:120]
        f = img / name
        if not a.urls:   # del sitemap/ledger: saltar lo que el visor no sirve (índices de módulo, tribus sin contenido expuesto)
            try:
                if 'cn-notfound' in fetch(f'{a.base}{p}?nc={int(time.time())}'): print(f'  – {p[:60]} (no accesible)'); continue
            except Exception as e: print(f'  ✗ {p[:60]} ({e})'); continue
        ok = shot(f'{a.base}{p}', f, height=a.height, profile=str(profile))
        if not ok: print(f'  ✗ {p}'); continue
        sec, oid, title = objeto_de(p, ledger)
        b = f.read_bytes()
        items.append({'url': p, 'file': f'img/{name}', 'bytes': len(b), 'sha256': hashlib.sha256(b).hexdigest(), 'section': sec, 'id': oid, 'title': title})
        print(f'  {i:3d}/{len(urls)} {p[:60]:60s} {len(b)//1024:4d} KB  {title or ""}')
    man = out / f'manifest-{a.prefix}.json'
    man.write_text(json.dumps({'base': a.base, 'at': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()), 'items': items}, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    tot = sum(i['bytes'] for i in items)
    print(f'{len(items)} capturas → {man.relative_to(ROOT).as_posix() if man.is_relative_to(ROOT) else man} · {tot//1024} KB · máx {max((i["bytes"] for i in items), default=0)//1024} KB')


if __name__ == '__main__':
    main()
