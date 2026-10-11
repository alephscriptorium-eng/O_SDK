#!/usr/bin/env python3
"""template-kit.py · kit visual de una plantilla de organización (WP-O131).

Genera un PNG 512×512 por objeto con `image` en la plantilla (tribus, salas, mapas, eventos, wikis), con
un branding propio de la plantilla (paleta + icono por tipo + título + orla pública/privada), y un
`manifest.json` con el sha256 y el **blob id previsto** (`&<base64(sha256)>.sha256`): así el dosier cita
el id antes de subir nada y los gates comparan. También copia los markdown que las wikis referencian
(`file:`) a `<out>/wiki/<id>.md`, para que el seeder (que corre en el contenedor) los encuentre.

Determinista: misma plantilla + misma fuente → mismos bytes. La fuente se pasa con `--font` y es
obligatoria (ni el repo ni PIL traen una TTF; no se cae a las del sistema, que cambian de máquina).

  python -X utf8 pub/tools/template-kit.py --template pub/templates/campamento.json \
      --font ARCHIVO/DISCO/scriptorium-exported/assets/fonts/DejaVuSans-Bold.ttf \
      --out pub/templates/assets/campamento
  python -X utf8 pub/tools/template-kit.py --avatar <png origen> --out <png 512> [--font …]

Con marca del colectivo (`--brand <marca.json>`, lo escribe el derivador del dosier desde el organigrama):
foto de lona de fondo, caja de color con el nombre en mayúsculas, etiqueta por tipo, logo con aire; fuentes,
paleta y fondos salen del JSON (las fuentes propietarias no se vendorizan: solo libres, o por ruta externa).
Sin `--brand` el generador es byte a byte el de antes.

  python -X utf8 pub/tools/template-kit.py --template pub/templates/acampada26s.json \
      --brand ARCHIVO/DISCO/26sm-exported/entrada/marca.json --out pub/templates/assets/acampada26s
  python -X utf8 pub/tools/template-kit.py --brand <marca.json> --avatar-brand --out <png 512>

Solo PNG: /c/blob no sirve SVG (docs/PUB/TEMPLATE-PROTOCOL.md §4.4).
"""
import argparse, base64, hashlib, json, math, shutil, sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    sys.exit('PIL no disponible: pip install pillow')

SIZE = 512
# Paleta «Campamento» (la de la presentación del dosier retro-exporter, para que dosier y objetos coincidan).
PALETTE = {
    'tribu':   ('#5d3b9c', '#b79ae6'),
    'subtribu': ('#5d3b9c', '#aba5bb'),
    'sala':    ('#ef6f61', '#ffd3c9'),
    'mapa':    ('#5fc27e', '#d8f3e0'),
    'evento':  ('#e2b04a', '#fff0c7'),
    'wiki':    ('#6cc9c2', '#dff6f4'),
}
PAPER = '#ece8f3'
INK = '#2b2340'


def hexrgb(h):
    h = h.lstrip('#'); return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def icon(draw, kind, cx, cy, r, color):
    """Icono geométrico por tipo (sin fuentes, sin aleatoriedad)."""
    c = hexrgb(color)
    if kind in ('tribu', 'subtribu'):
        # círculo de personas: n puntos alrededor
        n = 6 if kind == 'tribu' else 4
        for k in range(n):
            a = 2 * math.pi * k / n - math.pi / 2
            x, y = cx + r * 0.62 * math.cos(a), cy + r * 0.62 * math.sin(a)
            draw.ellipse([x - r * 0.18, y - r * 0.18, x + r * 0.18, y + r * 0.18], fill=c)
        draw.ellipse([cx - r * 0.2, cy - r * 0.2, cx + r * 0.2, cy + r * 0.2], outline=c, width=max(3, r // 14))
    elif kind == 'sala':
        # ondas de voz
        for k in range(3):
            rr = r * (0.3 + 0.25 * k)
            draw.arc([cx - rr, cy - rr, cx + rr, cy + rr], start=-40, end=40, fill=c, width=max(4, r // 12))
        draw.ellipse([cx - r * 0.12, cy - r * 0.12, cx + r * 0.12, cy + r * 0.12], fill=c)
    elif kind == 'mapa':
        # pin
        draw.ellipse([cx - r * 0.42, cy - r * 0.75, cx + r * 0.42, cy + r * 0.09], fill=c)
        draw.polygon([(cx - r * 0.3, cy - r * 0.15), (cx + r * 0.3, cy - r * 0.15), (cx, cy + r * 0.72)], fill=c)
        draw.ellipse([cx - r * 0.16, cy - r * 0.49, cx + r * 0.16, cy - r * 0.17], fill=hexrgb(PAPER))
    elif kind == 'evento':
        # calendario: marco + cabecera + dos anillas
        w, h = r * 0.9, r * 0.8
        draw.rounded_rectangle([cx - w, cy - h * 0.7, cx + w, cy + h], radius=r // 8, outline=c, width=max(4, r // 12))
        draw.rectangle([cx - w, cy - h * 0.7, cx + w, cy - h * 0.25], fill=c)
        for dx in (-w * 0.5, w * 0.5):
            draw.rectangle([cx + dx - r * 0.06, cy - h * 0.95, cx + dx + r * 0.06, cy - h * 0.45], fill=c)
        draw.ellipse([cx - r * 0.14, cy + r * 0.05, cx + r * 0.14, cy + r * 0.33], fill=c)
    elif kind == 'wiki':
        # página con líneas
        w, h = r * 0.7, r * 0.9
        draw.rounded_rectangle([cx - w, cy - h, cx + w, cy + h], radius=r // 10, outline=c, width=max(4, r // 12))
        for k in range(4):
            y = cy - h * 0.55 + k * h * 0.38
            draw.line([cx - w * 0.6, y, cx + w * (0.6 if k < 3 else 0.1), y], fill=c, width=max(4, r // 14))


def wrap(draw, text, font, maxw):
    words, lines, cur = text.split(), [], ''
    for w in words:
        t = (cur + ' ' + w).strip()
        if draw.textlength(t, font=font) <= maxw or not cur:
            cur = t
        else:
            lines.append(cur); cur = w
    if cur: lines.append(cur)
    return lines[:4]


def render(kind, title, subtitle, private, font_path, out_path):
    main, soft = PALETTE[kind]
    im = Image.new('RGB', (SIZE, SIZE), hexrgb(PAPER))
    d = ImageDraw.Draw(im)
    # orla: continua = pública, discontinua = privada
    m = 18
    if private:
        step = 26
        for k in range(0, 4 * (SIZE - 2 * m), step):
            pass
        # trazo discontinuo a mano (PIL no tiene dash): cuatro lados
        def dash(x0, y0, x1, y1):
            L = math.hypot(x1 - x0, y1 - y0); n = int(L // step)
            for k in range(0, n, 2):
                t0, t1 = k / n, min((k + 1) / n, 1)
                d.line([x0 + (x1 - x0) * t0, y0 + (y1 - y0) * t0, x0 + (x1 - x0) * t1, y0 + (y1 - y0) * t1], fill=hexrgb(main), width=8)
        dash(m, m, SIZE - m, m); dash(SIZE - m, m, SIZE - m, SIZE - m); dash(SIZE - m, SIZE - m, m, SIZE - m); dash(m, SIZE - m, m, m)
    else:
        d.rounded_rectangle([m, m, SIZE - m, SIZE - m], radius=28, outline=hexrgb(main), width=8)
    # medallón
    d.ellipse([SIZE // 2 - 118, 78, SIZE // 2 + 118, 314], fill=hexrgb(soft))
    icon(d, kind, SIZE // 2, 196, 100, main)
    # título
    f1 = ImageFont.truetype(font_path, 40)
    f2 = ImageFont.truetype(font_path, 22)
    lines = wrap(d, title, f1, SIZE - 2 * m - 40)
    y = 334
    for ln in lines:
        wdt = d.textlength(ln, font=f1)
        d.text(((SIZE - wdt) / 2, y), ln, font=f1, fill=hexrgb(INK)); y += 46
    sub = f'{subtitle} · {"privada" if private else "pública"}'
    wdt = d.textlength(sub, font=f2)
    d.text(((SIZE - wdt) / 2, SIZE - m - 50), sub, font=f2, fill=hexrgb(main))
    im.save(out_path, format='PNG', optimize=True)


def blob_id(path):
    h = hashlib.sha256(Path(path).read_bytes()).digest()
    return hashlib.sha256(Path(path).read_bytes()).hexdigest(), '&' + base64.b64encode(h).decode() + '.sha256'


# ---------------------------------------------------------------------------------------------------------
# Marca del colectivo (`--brand marca.json`). Reglas que aplica (kit visual de la 26S, BRANDKIT.md):
#   fondo = foto de lona (sin filtros), caja de color sólida con el nombre en blanco y mayúsculas, etiqueta
#   naranja con el tipo (el naranja «solo para señalar»), logo con aire, sin sombras ni iconos. El nombre vive
#   en la banda central vertical (y≈186-326), que es lo que sobrevive al recorte 280×140 de las tarjetas del hub.
# ---------------------------------------------------------------------------------------------------------
class Brand:
    def __init__(self, path):
        self.path = Path(path)
        self.d = json.loads(self.path.read_text(encoding='utf-8'))
        d = self.d
        self.pal = d['paleta']
        self.f_titular, self.f_cuerpo = Path(d['fuentes']['titular']), Path(d['fuentes']['cuerpo'])
        for f in (self.f_titular, self.f_cuerpo):
            if not f.exists(): sys.exit(f'fuente {f} no existe (marca.json → fuentes). Las propietarias van por ruta externa, nunca al repo.')
        self.lead = float(d.get('interlineado', 0.98))
        self.upper = bool(d.get('mayusculas', True))
        self.etq = d.get('etiquetas', {})
        self.logo_path = Path(d['logo']['blanco'])
        if not self.logo_path.exists(): sys.exit(f'logo {self.logo_path} no existe')
        self.logo = Image.open(self.logo_path).convert('RGBA')
        # lonas: solo las oscuras (el kit: «fondos blancos o naranjas puntuales», nunca para una serie de tarjetas)
        self.fondos = []
        for f in d['fondos']:
            p = Path(f)
            if not p.exists(): sys.exit(f'fondo {p} no existe (regenerar con extraer-brandkit.py)')
            im = Image.open(p).convert('L'); s = im.resize((8, 8), Image.BOX)
            lum = sum(s.tobytes()) / 64
            if lum <= 120: self.fondos.append(p)
        if not self.fondos: sys.exit('marca.json: ninguna lona oscura utilizable')
        self.portadas = d.get('portadas', {})
        self.cache = {}

    def color(self, k): return hexrgb(self.pal[k])

    def font(self, which, size):
        key = (which, size)
        if key not in self.cache:
            self.cache[key] = ImageFont.truetype(str(self.f_titular if which == 'titular' else self.f_cuerpo), size)
        return self.cache[key]

    def lona(self, seed, size=SIZE, zoom=0.6):
        """Recorte cuadrado de una lona elegida de forma fija por `seed` (misma tarjeta → misma lona)."""
        i = int(hashlib.sha256(seed.encode('utf-8')).hexdigest(), 16) % len(self.fondos)
        im = Image.open(self.fondos[i]).convert('RGB')
        w, h = im.size; side = int(min(w, h) * zoom)
        im = im.crop(((w - side) // 2, (h - side) // 2, (w - side) // 2 + side, (h - side) // 2 + side))
        return im.resize((size, size), Image.LANCZOS), self.fondos[i].name

    def sha_inputs(self):
        return {'marca_sha256': hashlib.sha256(self.path.read_bytes()).hexdigest(),
                'fonts': {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in (self.f_titular, self.f_cuerpo)},
                'logo': {self.logo_path.name: hashlib.sha256(self.logo_path.read_bytes()).hexdigest()},
                'fondos': {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in self.fondos}}


def fit_text(draw, text, brand, maxw, maxh, sizes=range(72, 33, -2), max_lines=3):
    """Mayor tamaño de titular con el que el texto cabe en maxw×maxh con ≤ max_lines líneas."""
    for s in sizes:
        f = brand.font('titular', s)
        lines = wrap(draw, text, f, maxw)
        lh = int(s * brand.lead)
        if len(lines) <= max_lines and all(draw.textlength(l, font=f) <= maxw for l in lines) and len(lines) * lh <= maxh:
            return f, lines, lh
    s = sizes[-1]; f = brand.font('titular', s)
    return f, wrap(draw, text, f, maxw)[:max_lines], int(s * brand.lead)


def paste_logo(im, brand, height, cx, cy):
    lg = brand.logo; w, h = lg.size
    lg = lg.resize((max(1, int(w * height / h)), height), Image.LANCZOS)
    im.paste(lg, (int(cx - lg.size[0] / 2), int(cy - height / 2)), lg)


def label_box(d, brand, text, cy, fill, size=24, pad=10):
    f = brand.font('titular', size)
    tw = d.textlength(text, font=f)
    x0, x1 = SIZE / 2 - tw / 2 - pad, SIZE / 2 + tw / 2 + pad
    d.rectangle([x0, cy - size / 2 - pad * 0.6, x1, cy + size / 2 + pad * 0.6], fill=fill)
    d.text((SIZE / 2 - tw / 2, cy - size * 0.62), text, font=f, fill=brand.color('blanco'))


def render_brand(kind, title, private, brand, out_path, seed, subtitle=None):
    im, lona_name = brand.lona(seed)
    d = ImageDraw.Draw(im)
    azul, naranja, blanco = brand.color('azul_lona'), brand.color('naranja_inquilina'), brand.color('blanco')
    # 1) etiqueta naranja con el tipo (y «CERRADO» si es privado): el naranja solo para señalar
    etiqueta = brand.etq.get(kind, kind.upper())
    if private: etiqueta += ' · ' + brand.etq.get('privado', 'CERRADO')
    label_box(d, brand, etiqueta, 132, naranja)
    # 2) caja azul sólida en la banda central con el nombre en blanco y mayúsculas
    bx0, by0, bx1, by1 = 32, 160, SIZE - 32, 352
    d.rectangle([bx0, by0, bx1, by1], fill=azul)
    text = title.upper() if brand.upper else title
    pad = 18
    sub_f = brand.font('cuerpo', 22) if subtitle else None
    sub_h = 34 if subtitle else 0
    f, lines, lh = fit_text(d, text, brand, (bx1 - bx0) - 2 * pad, (by1 - by0) - 2 * pad - sub_h)
    total = len(lines) * lh + sub_h
    y = by0 + ((by1 - by0) - total) / 2
    for ln in lines:
        tw = d.textlength(ln, font=f)
        d.text((SIZE / 2 - tw / 2, y - f.size * 0.12), ln, font=f, fill=blanco); y += lh
    if subtitle:
        tw = d.textlength(subtitle, font=sub_f)
        d.text((SIZE / 2 - tw / 2, y + 4), subtitle, font=sub_f, fill=blanco)
    # 3) logo blanco con aire, abajo y centrado
    paste_logo(im, brand, 80, SIZE / 2, 436)
    im.save(out_path, format='PNG', optimize=True)
    return lona_name


def avatar_brand(brand, out, size=512, texto=None):
    """Patrón del kit (pág. 18): logo blanco sobre lona, cuadrado, con el texto corto en naranja a la derecha."""
    im, _ = brand.lona('avatar', size, zoom=0.5)
    paste_logo(im, brand, int(size * 0.60), size * 0.40, size * 0.48)
    texto = texto if texto is not None else brand.d.get('avatar', {}).get('texto')
    if texto:
        d = ImageDraw.Draw(im); f = brand.font('titular', int(size * 0.24))
        tw = d.textlength(texto, font=f)
        d.text((size * 0.80 - tw / 2, size * 0.60), texto, font=f, fill=brand.color('naranja_inquilina'))
    im.save(out, format='PNG', optimize=True)
    sha, bid = blob_id(out)
    print(f'{out} {Path(out).stat().st_size} B sha256={sha} blob={bid}')


def build(template, font, out, brand=None):
    t = json.loads(Path(template).read_text(encoding='utf-8'))
    out = Path(out); out.mkdir(parents=True, exist_ok=True); (out / 'wiki').mkdir(exist_ok=True)
    for viejo in (out / 'wiki').glob('*.md'): viejo.unlink()   # sin restos de una partición anterior con más páginas
    label = {'tribes': 'tribu', 'rooms': 'sala', 'maps': 'mapa', 'events': 'evento', 'wiki': 'wiki'}
    manifest = {'template': t['meta']['id'], 'font_sha256': blob_id(font)[0] if font else None, 'items': []}
    if brand: manifest['brand'] = brand.sha_inputs()
    for section, kind in label.items():
        for x in t.get(section, []):
            if not x.get('image'):
                continue
            k = 'subtribu' if (section == 'tribes' and x.get('parent')) else kind
            private = bool(x.get('private')) if section == 'tribes' else (x.get('status') == 'INVITE-ONLY' if section == 'rooms' else (x.get('isPublic') is False if section == 'events' else bool(x.get('tribe'))))
            sub = {'tribu': 'Tribu', 'subtribu': 'Sub-tribu', 'sala': 'Sala', 'mapa': 'Mapa', 'evento': 'Evento', 'wiki': 'Wiki'}[k]
            path = out / x['image']
            item = {'id': x['id'], 'section': section, 'file': x['image']}
            if brand:
                portada = brand.portadas.get(x['id'], {})
                item['lona'] = render_brand(k, x['title'], private, brand, path, x['id'], subtitle=portada.get('subtitulo'))
            else:
                render(k, x['title'], f'{t["meta"]["nombre"]} · {sub}', private, font, path)
            sha, bid = blob_id(path)
            item.update({'bytes': path.stat().st_size, 'sha256': sha, 'blobId': bid})
            manifest['items'].append(item)
    for x in t.get('wiki', []):
        if x.get('file'):
            src = Path(x['file'])
            if not src.exists():
                sys.exit(f'wiki {x["id"]}: file {x["file"]} no existe')
            dst = out / 'wiki' / f'{x["id"]}.md'
            shutil.copyfile(src, dst)
            manifest['items'].append({'id': x['id'], 'section': 'wiki-file', 'file': f'wiki/{x["id"]}.md', 'from': x['file'], 'bytes': dst.stat().st_size, 'sha256': blob_id(dst)[0]})
    (out / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'{len(manifest["items"])} ficheros → {out} (manifest.json)')


def avatar(src, out, size=512):
    im = Image.open(src).convert('RGBA')
    w, h = im.size
    s = min(w, h)
    im = im.crop(((w - s) // 2, (h - s) // 2, (w - s) // 2 + s, (h - s) // 2 + s)).resize((size, size), Image.LANCZOS)
    bg = Image.new('RGB', (size, size), (255, 255, 255))
    bg.paste(im, mask=im.split()[3])
    bg.save(out, format='PNG', optimize=True)
    sha, bid = blob_id(out)
    print(f'{out} {Path(out).stat().st_size} B sha256={sha} blob={bid}')


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--template'); ap.add_argument('--font'); ap.add_argument('--out', required=True); ap.add_argument('--avatar')
    ap.add_argument('--brand', help='marca.json del colectivo (paleta, fuentes, fondos, logo); lo escribe el derivador del dosier')
    ap.add_argument('--avatar-brand', action='store_true', help='con --brand: avatar según el patrón del kit (logo sobre lona + texto corto)')
    ap.add_argument('--only', help='con --template: solo los ids indicados (coma), para pruebas')
    a = ap.parse_args()
    brand = Brand(a.brand) if a.brand else None
    if a.avatar_brand:
        if not brand: ap.error('--avatar-brand requiere --brand')
        avatar_brand(brand, a.out)
    elif a.avatar:
        avatar(a.avatar, a.out)
    elif a.template:
        if brand is None and (not a.font or not Path(a.font).exists()):
            sys.exit('--font <ttf> obligatorio y debe existir (no se usan fuentes del sistema)')
        if a.only:
            t = json.loads(Path(a.template).read_text(encoding='utf-8')); keep = set(a.only.split(','))
            for sec in ('tribes', 'rooms', 'maps', 'events', 'wiki'):
                t[sec] = [x for x in t.get(sec, []) if x['id'] in keep]
            tmp = Path(a.out) / '_solo.json'; Path(a.out).mkdir(parents=True, exist_ok=True)
            tmp.write_text(json.dumps(t, ensure_ascii=False), encoding='utf-8')
            build(tmp, a.font, a.out, brand); tmp.unlink()
        else:
            build(a.template, a.font, a.out, brand)
    else:
        ap.error('--template o --avatar')
