#!/usr/bin/env python3
# extraer-brandkit.py · saca del PDF del kit visual («ACAMPADA BRAND KIT .pdf») las imágenes embebidas:
#   - JPEG (DCTDecode): fotos de lona y ejemplos, tal cual (bytes del PDF, sin recodificar);
#   - PNG con transparencia (FlateDecode RGB + SMask gris): logos, avatar, banner.
# Salida: canva/kit-visual/extraido/ + manifest.json (objeto del PDF, px, bytes, sha256, uso previsto).
# Reproducible y sin dependencias fuera de PIL (que ya hace falta para el kit). No altera el PDF.
#   python -X utf8 ARCHIVO/DISCO/26sm-exported/entrada/extraer-brandkit.py
import hashlib, json, re, sys, zlib
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    sys.exit('PIL no disponible: pip install pillow')

ROOT = Path(__file__).resolve().parents[4]
DOSIER = ROOT / 'ARCHIVO/DISCO/26sm-exported'
PDF = DOSIER / 'canva/kit-visual/ACAMPADA BRAND KIT .pdf'
OUT = DOSIER / 'canva/kit-visual/extraido'

# Uso previsto por objeto del PDF (visto a mano el 2026-10-11; lo que no está aquí se marca «ejemplo»).
USO = {
    '36': 'lona', '63': 'lona', '66': 'lona', '70': 'lona', '71': 'lona', '115': 'lona', '116': 'lona', '117': 'lona',
    '118': 'lona', '119': 'lona', '120': 'lona', '121': 'lona', '122': 'lona', '123': 'lona', '124': 'lona', '128': 'lona',
    '177': 'lona',
    '104': 'ejemplo-placa', '105': 'ejemplo-placa', '110': 'ejemplo-post', '149': 'ejemplo-post',
    '50': 'logo', '51': 'logo', '52': 'logo', '55': 'logo', '64': 'logo', '65': 'logo', '72': 'logo', '73': 'logo',
    '74': 'logo-medio', '75': 'logo', '54': 'ejemplo-placa', '129': 'ejemplo', '142': 'avatar-ejemplo', '150': 'ejemplo',
    '165': 'ejemplo-post', '166': 'ejemplo-post', '173': 'avatar-ejemplo', '178': 'avatar-ejemplo', '481': 'banner',
}


def sha(b): return hashlib.sha256(b).hexdigest()


def main():
    b = PDF.read_bytes()
    OUT.mkdir(parents=True, exist_ok=True)
    objs = {n.decode(): body for n, body in re.findall(rb'(\d+) 0 obj(.*?)endobj', b, re.S)}

    def stream(body):
        m = re.search(rb'stream\r?\n(.*?)\r?\nendstream', body, re.S)
        return m.group(1) if m else None

    def num(body, key):
        m = re.search(rb'/' + key + rb' (\d+)', body); return int(m.group(1)) if m else None

    items, skipped = [], []
    for n, body in objs.items():
        head = body.split(b'stream', 1)[0]
        if b'/Subtype /Image' not in head and b'/Subtype/Image' not in head: continue
        if b'/SMask' not in head and b'/DeviceGray' in head: continue   # es una máscara: se usa desde su imagen
        w, h = num(head, b'Width'), num(head, b'Height'); data = stream(body)
        if data is None: skipped.append((n, 'sin stream')); continue
        flt = re.search(rb'/Filter\s*/(\w+)', head); flt = flt.group(1).decode() if flt else '?'
        uso = USO.get(n, 'ejemplo')
        if flt == 'DCTDecode':
            name = f'{uso}-{int(n):03d}.jpg'; (OUT / name).write_bytes(data)
        elif flt == 'FlateDecode':
            if b'/DecodeParms' in head: skipped.append((n, 'FlateDecode con predictor: no soportado')); continue
            raw = zlib.decompress(data)
            if len(raw) != w * h * 3: skipped.append((n, f'tamaño inesperado {len(raw)} para {w}x{h} RGB')); continue
            im = Image.frombytes('RGB', (w, h), raw)
            sm = re.search(rb'/SMask (\d+) 0 R', head)
            if sm:
                mb = objs[sm.group(1).decode()]; mraw = zlib.decompress(stream(mb))
                if len(mraw) == w * h:
                    im = im.convert('RGBA'); im.putalpha(Image.frombytes('L', (w, h), mraw))
            name = f'{uso}-{int(n):03d}.png'; im.save(OUT / name, format='PNG', optimize=True)
        else:
            skipped.append((n, f'filtro {flt}')); continue
        fb = (OUT / name).read_bytes()
        items.append({'obj': int(n), 'file': name, 'px': f'{w}x{h}', 'bytes': len(fb), 'sha256': sha(fb), 'uso': uso, 'filtro': flt})
    items.sort(key=lambda x: x['obj'])
    manifest = {'pdf': PDF.name, 'pdf_sha256': sha(b), 'items': items,
                'no_extraidos': [{'obj': int(n), 'por_que': why} for n, why in skipped]}
    (OUT / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    por_uso = {}
    for it in items: por_uso[it['uso']] = por_uso.get(it['uso'], 0) + 1
    print(f'extraídos {len(items)} → {OUT.relative_to(ROOT).as_posix()}/  {json.dumps(por_uso, ensure_ascii=False)}  no extraídos: {len(skipped)}')


if __name__ == '__main__':
    main()
