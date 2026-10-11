#!/usr/bin/env python3
# md-sin-tablas.py · prepara un markdown para sembrarlo como wiki en Oasis sin tocar el código de upstream (D-O34):
#   1. sin tablas: cada fila → un ítem «- **col1** · col2 · col3» (el renderer de Oasis no tiene tablas ni <br>);
#   2. sin «## N.» en cabeceras (el renderer las vuelve ítem numerado) y sin «####» (el renderer no pasa de ###);
#   3. sin «# título» al principio: Oasis pinta el título de la página y saldría dos veces;
#   4. en páginas de como mucho --max bytes (por defecto 5600): el cuerpo de una wiki que pasa de 6000 B viaja en
#      un blob aparte que un cliente no pide solo (src/models/wiki_model.js:53-57) y la página se ve vacía. Por
#      debajo, el cuerpo va dentro del mensaje y se lee siempre. Se parte por cabeceras «##», equilibrado, con un
#      índice de páginas (wikilinks por título) al principio y al final de cada una.
# Salida: <dst>, <dst sin .wiki.md>-2.wiki.md, … y un índice <dst sin .md>.json [{file, title, bytes}] que leen los
# derivadores de plantilla para crear una entrada wiki[] por página. Determinista.
#   python -X utf8 pub/tools/md-sin-tablas.py <entrada.md> <salida.wiki.md> --titulo "Título" [--max 5600]
import argparse, json, re, sys
from pathlib import Path


def sin_tablas(md: str) -> str:
    out, i, lines = [], 0, md.replace('\r\n', '\n').split('\n')
    while i < len(lines):
        l = lines[i]
        if l.lstrip().startswith('|'):
            rows = []
            while i < len(lines) and lines[i].lstrip().startswith('|'):
                rows.append([c.strip() for c in lines[i].strip().strip('|').split('|')]); i += 1
            head = rows[0] if rows else []
            body = [r for r in rows[1:] if not all(re.fullmatch(r':?-{2,}:?', c or '---') for c in r)]
            if any(h for h in head):
                out.append('*' + ' · '.join(h for h in head if h) + '*')
            for r in body:
                cells = [c for c in r if c != '']
                if not cells: continue
                first = cells[0] if cells[0].startswith('**') else f'**{cells[0]}**'
                out.append('- ' + ' · '.join([first] + cells[1:]))
            out.append('')
            continue
        m = re.match(r'^(#{1,6})\s+(\d+[.)])\s+(.*)$', l)
        if m: l = f'{m.group(1)} {m.group(3)}'
        m = re.match(r'^(#{4,6})\s+(.*)$', l)
        if m: l = f'### {m.group(2)}'
        out.append(l); i += 1
    s = '\n'.join(out)
    s = re.sub(r'^# [^\n]*\n+', '', s, count=1)   # el título lo pone Oasis
    return re.sub(r'\n{3,}', '\n\n', s).strip() + '\n'


def partir(md: str, maxb: int, titulo: str):
    """Trozos por «## » (y por párrafos si una sección sola pasa de maxb), equilibrados, cada uno ≤ maxb con su índice."""
    secs = re.split(r'(?m)^(?=## )', md)
    piezas = []
    for sec in secs:
        if len(sec.encode('utf-8')) <= maxb: piezas.append(sec); continue
        for par in re.split(r'\n{2,}', sec):   # sección demasiado larga: por párrafos
            piezas.append(par.strip() + '\n\n')
    nav_reserva = 260   # «Parte k de n» arriba e índice de páginas abajo (crece con n; se comprueba al final)
    total = sum(len(p.encode('utf-8')) for p in piezas)
    n_obj = max(1, -(-total // (maxb - nav_reserva)))
    while True:
        objetivo = total / n_obj
        partes, cur = [], ''
        for p in piezas:
            if cur and len(partes) < n_obj - 1 and len(cur.encode('utf-8')) + len(p.encode('utf-8')) / 2 > objetivo:
                partes.append(cur); cur = p
            else:
                cur += p
        if cur: partes.append(cur)
        n = len(partes)
        titulos = [f'{titulo} · {k} de {n}' if n > 1 else titulo for k in range(1, n + 1)]
        indice = 'Páginas: ' + ' · '.join(f'[[{t}]]' for t in titulos) if n > 1 else ''
        res = []
        for k, cuerpo in enumerate(partes, 1):
            body = (f'*Parte {k} de {n}.*\n\n' if n > 1 else '') + cuerpo.strip() + (f'\n\n{indice}\n' if n > 1 else '\n')
            res.append((titulos[k - 1], body))
        if all(len(b.encode('utf-8')) <= maxb for _, b in res) or n_obj > 40: return res
        n_obj += 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('src'); ap.add_argument('dst'); ap.add_argument('--max', type=int, default=5600)
    ap.add_argument('--titulo', required=True)
    a = ap.parse_args()
    md = sin_tablas(Path(a.src).read_text(encoding='utf-8'))
    dst = Path(a.dst)
    base = dst.name[:-len('.wiki.md')] if dst.name.endswith('.wiki.md') else dst.stem
    partes = partir(md, a.max, a.titulo)
    indice = []
    for k, (t, body) in enumerate(partes, 1):
        f = dst if k == 1 else dst.with_name(f'{base}-{k}.wiki.md')
        f.write_text(body, encoding='utf-8')
        indice.append({'file': f.as_posix(), 'title': t, 'bytes': len(body.encode('utf-8'))})
    # páginas sobrantes de una ejecución anterior con más partes
    for viejo in dst.parent.glob(f'{base}-*.wiki.md'):
        if viejo.as_posix() not in {i['file'] for i in indice}: viejo.unlink()
    idx = dst.with_name(f'{base}.wiki.json')
    idx.write_text(json.dumps({'titulo': a.titulo, 'max': a.max, 'src': Path(a.src).as_posix(), 'paginas': indice}, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    bad = sum(1 for l in md.split('\n') if l.lstrip().startswith('|'))
    print(f'{len(partes)} página(s) ≤ {a.max} B · ' + ' · '.join(f'{i["bytes"]} B' for i in indice) + f' · líneas con |: {bad} · índice {idx.as_posix()}')
    sys.exit(1 if bad or any(i['bytes'] > a.max for i in indice) else 0)


if __name__ == '__main__':
    main()
