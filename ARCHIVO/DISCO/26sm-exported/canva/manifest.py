#!/usr/bin/env python3
# manifest.py · inventario de lo descargado de Canva: un MANIFEST.md por subcarpeta (fichero, px, bytes, sha256).
# Reproducible y sin dependencias: lee la cabecera PNG/JPEG a mano. La columna «Para qué» se rellena a mano
# y se conserva entre ejecuciones mientras el sha256 del fichero no cambie.
#   python -X utf8 ARCHIVO/DISCO/26sm-exported/canva/manifest.py
import hashlib, struct
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[3]
PIEZAS = {'kit-visual': 'KIT VISUAL', 'post': 'POST', 'recursos-graficos': 'RECURSOS GRÁFICOS'}
PENDIENTE = '<pendiente>'


def dims(b: bytes) -> str:
    if b[:8] == b'\x89PNG\r\n\x1a\n':
        w, h = struct.unpack('>II', b[16:24])
        return f'{w}×{h}'
    if b[:2] == b'\xff\xd8':
        i = 2
        while i < len(b) - 9:
            if b[i] != 0xFF:
                i += 1
                continue
            marker = b[i + 1]
            if marker in (0xC0, 0xC1, 0xC2):
                h, w = struct.unpack('>HH', b[i + 5:i + 9])
                return f'{w}×{h}'
            i += 2 + struct.unpack('>H', b[i + 2:i + 4])[0]
    return '—'


def previos(mf: Path) -> dict:
    """sha256 → «Para qué» ya escrito en el manifiesto anterior."""
    out = {}
    if not mf.exists():
        return out
    for line in mf.read_text(encoding='utf-8').splitlines():
        c = [x.strip() for x in line.strip().strip('|').split('|')]
        if len(c) == 5 and c[3].startswith('`') and c[3].endswith('`'):
            out[c[3].strip('`')] = c[4]
    return out


def main():
    for carpeta, nombre in PIEZAS.items():
        d = HERE / carpeta
        d.mkdir(exist_ok=True)
        mf = d / 'MANIFEST.md'
        prev = previos(mf)
        ficheros = sorted(p for p in d.iterdir() if p.is_file() and p.name != 'MANIFEST.md')
        filas = ['| Fichero | px | bytes | sha256 | Para qué |', '|---|---|---|---|---|']
        for p in ficheros:
            b = p.read_bytes()
            sha = hashlib.sha256(b).hexdigest()
            filas.append(f'| `{p.name}` | {dims(b)} | {len(b)} | `{sha}` | {prev.get(sha, PENDIENTE)} |')
        if not ficheros:
            filas.append('| *(vacío: nada descargado todavía)* | | | | |')
        cab = [
            f'# {nombre} · manifiesto',
            '',
            'Origen: ver `../README.md`. Generado por `../manifest.py`; la columna «Para qué» se rellena a mano '
            'y se conserva en la siguiente ejecución si el sha256 no cambia.',
            '',
        ]
        mf.write_text('\n'.join(cab + filas) + '\n', encoding='utf-8')
        print(f'{carpeta}: {len(ficheros)} fichero(s) → {mf.relative_to(REPO).as_posix()}')


if __name__ == '__main__':
    main()
