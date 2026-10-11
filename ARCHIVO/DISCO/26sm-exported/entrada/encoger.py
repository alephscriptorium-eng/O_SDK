#!/usr/bin/env python3
# encoger.py · recorta el fondo sobrante y reduce las capturas de vista-previa/ a 1024 px de ancho (PNG; JPEG q82 si pasa
# de --max-kb); actualiza bytes y sha256 en cada manifest-*.json. Determinista.
#   python -X utf8 ARCHIVO/DISCO/26sm-exported/entrada/encoger.py [--max-kb 250]
import argparse, hashlib, json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[4]
V = ROOT / 'ARCHIVO/DISCO/26sm-exported/vista-previa'


def recortar_fondo(im, minimo=400):
    w, h = im.size; px = im.load(); bg = px[5, h - 5]; y = h - 1
    while y > minimo and all(abs(px[x, y][i] - bg[i]) < 6 for x in range(0, w, 64) for i in range(3)): y -= 1
    return im.crop((0, 0, w, min(h, y + 40)))


def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--max-kb', type=int, default=250); a = ap.parse_args()
    for man in sorted(V.glob('manifest-*.json')):
        m = json.loads(man.read_text(encoding='utf-8')); tot = 0
        for it in m['items']:
            f = V / it['file']
            if not f.exists(): continue
            im = recortar_fondo(Image.open(f).convert('RGB'))
            w, h = im.size
            if w > 1024: im = im.resize((1024, int(h * 1024 / w)), Image.LANCZOS)
            im.save(f, optimize=True)
            if f.stat().st_size > a.max_kb * 1024 and f.suffix == '.png':
                j = f.with_suffix('.jpg'); im.save(j, quality=82, optimize=True); f.unlink(); f = j; it['file'] = f'img/{j.name}'
            b = f.read_bytes(); it['bytes'] = len(b); it['sha256'] = hashlib.sha256(b).hexdigest(); tot += len(b)
        man.write_text(json.dumps(m, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        print(f'{man.name}: {len(m["items"])} capturas, {tot // 1024} KB, máx {max((i["bytes"] for i in m["items"]), default=0) // 1024} KB')


if __name__ == '__main__':
    main()
