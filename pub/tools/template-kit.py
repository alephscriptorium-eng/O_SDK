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


def build(template, font, out):
    t = json.loads(Path(template).read_text(encoding='utf-8'))
    out = Path(out); out.mkdir(parents=True, exist_ok=True); (out / 'wiki').mkdir(exist_ok=True)
    label = {'tribes': 'tribu', 'rooms': 'sala', 'maps': 'mapa', 'events': 'evento', 'wiki': 'wiki'}
    manifest = {'template': t['meta']['id'], 'font_sha256': blob_id(font)[0], 'items': []}
    for section, kind in label.items():
        for x in t.get(section, []):
            if not x.get('image'):
                continue
            k = 'subtribu' if (section == 'tribes' and x.get('parent')) else kind
            private = bool(x.get('private')) if section == 'tribes' else (x.get('status') == 'INVITE-ONLY' if section == 'rooms' else (x.get('isPublic') is False if section == 'events' else bool(x.get('tribe'))))
            sub = {'tribu': 'Tribu', 'subtribu': 'Sub-tribu', 'sala': 'Sala', 'mapa': 'Mapa', 'evento': 'Evento', 'wiki': 'Wiki'}[k]
            path = out / x['image']
            render(k, x['title'], f'{t["meta"]["nombre"]} · {sub}', private, font, path)
            sha, bid = blob_id(path)
            manifest['items'].append({'id': x['id'], 'section': section, 'file': x['image'], 'bytes': path.stat().st_size, 'sha256': sha, 'blobId': bid})
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
    a = ap.parse_args()
    if a.avatar:
        avatar(a.avatar, a.out)
    elif a.template:
        if not a.font or not Path(a.font).exists():
            sys.exit('--font <ttf> obligatorio y debe existir (no se usan fuentes del sistema)')
        build(a.template, a.font, a.out)
    else:
        ap.error('--template o --avatar')
