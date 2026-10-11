#!/usr/bin/env python3
# md-sin-tablas.py · reexpresa un markdown para el renderer de wikis de Oasis (src/backend/renderStyledText.js), que no
# tiene tablas ni <br> y vuelve «## 2. X» un ítem numerado además de cabecera (D-O34). Conserva toda la información:
#   - cada fila de tabla → un ítem «- **col1** · col2 · col3» (la cabecera de la tabla se cita una vez en cursiva);
#   - «## N. Título» → «## Título»; «####» → «###» (el renderer no pasa de 3);
#   - las referencias «§N» se mantienen (son texto).
# Con --max N y --split, si el resultado pasa de N bytes se parte en trozos por cabeceras «##», cada uno con
# un enlace al siguiente/anterior (wikilink por título). Salida determinista.
#   python -X utf8 pub/tools/md-sin-tablas.py <entrada.md> <salida.md> [--max 20000 --split --titulo "Manual de bienvenida"]
import argparse, re, sys
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
    return re.sub(r'\n{3,}', '\n\n', s).strip() + '\n'


def partir(md: str, maxb: int, titulo: str):
    """Parte por «## » en trozos ≤ maxb bytes (mejor esfuerzo); devuelve [(título, cuerpo)]."""
    cab = re.match(r'^(# [^\n]*\n)', md)
    intro = cab.group(1) if cab else ''
    resto = md[len(intro):]
    secs = re.split(r'(?m)^(?=## )', resto)
    total = len(resto.encode('utf-8')); n_obj = -(-total // (maxb - 600))   # trozos equilibrados, no «todo y un resto»
    objetivo = total / n_obj
    partes, cur = [], ''
    for sec in secs:
        if cur and len(partes) < n_obj - 1 and len(cur.encode('utf-8')) + len(sec.encode('utf-8')) / 2 > objetivo:
            partes.append(cur); cur = sec
        else:
            cur += sec
    if cur: partes.append(cur)
    n = len(partes)
    res = []
    for k, cuerpo in enumerate(partes, 1):
        t = f'{titulo} · {k} de {n}' if n > 1 else titulo
        nav = []
        if k > 1: nav.append(f'Anterior: [[{titulo} · {k - 1} de {n}]]')
        if k < n: nav.append(f'Siguiente: [[{titulo} · {k + 1} de {n}]]')
        body = f'# {t}\n\n' + ('*Parte {k} de {n}.* ' if n > 1 else '') + cuerpo.strip() + ('\n\n' + ' · '.join(nav) if nav else '') + '\n'
        res.append((t, body))
    return res


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('src'); ap.add_argument('dst'); ap.add_argument('--max', type=int, default=0)
    ap.add_argument('--split', action='store_true'); ap.add_argument('--titulo', default='')
    a = ap.parse_args()
    md = sin_tablas(Path(a.src).read_text(encoding='utf-8'))
    bad = sum(1 for l in md.split('\n') if l.lstrip().startswith('|'))
    size = len(md.encode('utf-8'))
    dst = Path(a.dst)
    if a.max and size > a.max and a.split:
        partes = partir(md, a.max, a.titulo or dst.stem)
        for k, (t, body) in enumerate(partes, 1):
            f = dst if k == 1 else dst.with_name(dst.name.replace('.wiki.md', f'-{k}.wiki.md'))
            f.write_text(body, encoding='utf-8')
            print(f'{f.as_posix()}  {len(body.encode("utf-8"))} B  «{t}»')
        print(f'{len(partes)} partes (origen {size} B > {a.max}); líneas con |: {bad}')
    else:
        dst.write_text(md, encoding='utf-8')
        print(f'{dst.as_posix()}  {size} B  líneas con |: {bad}' + (f'  ⚠ > {a.max}' if a.max and size > a.max else ''))
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
