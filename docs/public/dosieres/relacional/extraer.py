# SPDX-License-Identifier: GPL-3.0-or-later
"""extraer.py — RELACIONAL.pdf → markdown (dosier F4 · 2026-09-17).

Solo stdlib + `pdftotext` (xpdf 4.00, viene con Git for Windows en
mingw64/bin). Sin pymupdf, sin pandoc: no están en la casa.

Método: `pdftotext -enc UTF-8 -layout`. El modo `-layout` conserva la
sangría, única señal tipográfica que el PDF deja (citas a 2 espacios,
listas numeradas a 3, viñetas a 6); el modo crudo la pierde y además se
come los guiones de fin de línea («ser-singular-plural» → «sersingular-plural»).
Después se reconstruyen bloques (párrafos separados por línea en blanco),
se cosen los cortes de página y se etiquetan:

  I. / II. …           → ## (h2)
  n.n …                → ### (h3)
  Tesis n: …           → ### (h3)
  Abstract · Referencias Bibliográficas · Fin del documento → ##
  sangría 2            → cita (> …)
  sangría 3 (+6 cont.) → lista numerada
  sangría 6            → viñetas; ítem nuevo = empieza en mayúscula o «“»
  etiqueta corta + «:» → **negrita** (inferida: el PDF no expone fuentes)

Lo que NO hace: no OCR (no hay imágenes), no toca el texto salvo cosido
de líneas. Los guiones de fin de línea se conservan literalmente (el PDF
no tiene guiones blandos U+00AD, luego son guiones reales).

Uso:  python extraer.py [--pdf fuente/RELACIONAL.pdf] [--out 01-relacional.md] [--check]
"""

from __future__ import annotations

import argparse
import datetime as _dt
import hashlib
import os
import re
import shutil
import subprocess
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
PDF_DEF = os.path.join(AQUI, "fuente", "RELACIONAL.pdf")
OUT_DEF = os.path.join(AQUI, "01-relacional.md")

RE_H2 = re.compile(r"^(?:[IVX]+)\.\s+\S")
RE_H3 = re.compile(r"^\d\.\d\s+\S")
RE_TESIS = re.compile(r"^Tesis \d+:\s")
RE_NUM = re.compile(r"^\d+\.\s+")
H2_LITERAL = {"Abstract", "Referencias Bibliográficas", "Fin del documento"}
CIERRE = (".", "”", ":", "?", "!", ")")  # fin de párrafo plausible en corte de página
ETIQ = re.compile(r"^([^“”:]{2,60}?):\s+(?=\S)")


def pdftotext_bin() -> str:
    cand = shutil.which("pdftotext") or r"C:\Program Files\Git\mingw64\bin\pdftotext.exe"
    if not os.path.exists(cand):
        sys.exit("pdftotext no encontrado (Git for Windows lo trae en mingw64/bin)")
    return cand


def extraer_layout(pdf: str) -> tuple[str, str]:
    r = subprocess.run(
        [pdftotext_bin(), "-enc", "UTF-8", "-layout", pdf, "-"],
        capture_output=True,
    )
    if r.returncode != 0:
        sys.exit(f"pdftotext falló ({r.returncode}): {r.stderr.decode('utf-8', 'replace')}")
    avisos = r.stderr.decode("utf-8", "replace").strip()
    return r.stdout.decode("utf-8"), avisos


# ---------- bloques ----------

def es_titulo(b: list[str]) -> bool:
    s = b[0].strip()
    return bool(RE_H2.match(s) or RE_H3.match(s) or RE_TESIS.match(s) or s in H2_LITERAL)


def bloques(texto: str) -> list[list[str]]:
    """Lista de bloques; cada bloque = líneas crudas (con sangría). Cose cortes de página."""
    paginas = texto.replace("\r\n", "\n").split("\f")
    out: list[list[str]] = []
    actual: list[str] = []
    for pag in paginas:
        lineas = [l.rstrip() for l in pag.split("\n")]
        # el último bloque de la página anterior continúa si no cerró frase y no es título
        if out and lineas and lineas[0].strip():
            ult = out[-1][-1].strip()
            if not ult.endswith(CIERRE) and not es_titulo(out[-1]):
                actual = out.pop()
        for l in lineas:
            if l.strip():
                actual.append(l)
            elif actual:
                out.append(actual)
                actual = []
        if actual:
            out.append(actual)
            actual = []
    return out


def unir(lineas: list[str]) -> str:
    """Une líneas de un párrafo: guion final se conserva sin espacio."""
    s = ""
    for l in lineas:
        l = l.strip()
        if not s:
            s = l
        elif s.endswith("-"):
            s += l
        else:
            s += " " + l
    return s


def sangria(l: str) -> int:
    return len(l) - len(l.lstrip(" "))


def negrita_etiqueta(p: str) -> str:
    m = ETIQ.match(p)
    if not m:
        return p
    et = m.group(1)
    palabras = et.split()
    autor_anyo = re.search(r"\(\d{4}", et) is not None  # «Whitehead (1929/1978)»
    if et[:1].islower() or len(palabras[0]) == 1 or (len(palabras) > 4 and not autor_anyo):
        return p
    return f"**{et}:** {p[m.end():]}"


# ---------- render ----------

def nota_extraccion(meta: dict) -> str:
    return (
        f"> **Nota de extracción ({meta['fecha']}, dosier F4 `dosier-relacional`).** "
        f"Markdown generado por `extraer.py` desde `fuente/RELACIONAL.pdf` "
        f"(sha256 `{meta['sha256'][:12]}…`, {meta['paginas']} págs., sin imágenes, "
        f"xref dañado y reconstruido por pdftotext {meta['pdftotext']}). "
        f"Negritas de etiqueta y niveles de encabezado son **inferidos** (el PDF no expone "
        f"fuentes); guiones de fin de línea conservados tal cual. Sin revisión humana: "
        f"cotejar contra el PDF antes de citar."
    )


def render(bl: list[list[str]], meta: dict) -> str:
    md: list[str] = []
    i = 0
    # título: bloques hasta «Subtítulo:»
    titulo: list[str] = []
    while i < len(bl) and not bl[i][0].strip().startswith("Subtítulo:"):
        titulo.append(unir(bl[i]))
        i += 1
    md += ["# " + " ".join(titulo), "", nota_extraccion(meta), ""]
    # metadatos: Subtítulo / Autor … Fecha … Disciplinas
    while i < len(bl) and bl[i][0].strip() != "Abstract":
        s = unir(bl[i])
        s = re.sub(r"\s+(Fecha:|Disciplinas:)", r"\n\1", s)
        for linea in s.split("\n"):
            k, _, v = linea.partition(":")
            md.append(f"- **{k.strip()}:** {v.strip()}")
        i += 1
    md.append("")

    en_refs = False
    while i < len(bl):
        b = bl[i]
        i += 1
        s0 = b[0].strip()
        ind = sangria(b[0])
        # --- encabezados
        if s0 in H2_LITERAL:
            en_refs = s0 == "Referencias Bibliográficas"
            if s0 == "Fin del documento":
                md += ["", "---", ""]
            md += ["## " + s0, ""]
            continue
        if RE_H2.match(s0) or RE_H3.match(s0) or RE_TESIS.match(s0):
            t = unir(b)
            # un título largo puede partirse en dos bloques (interlineado mayor):
            # se cose si el siguiente bloque es una sola línea corta sin cierre
            if i < len(bl) and len(bl[i]) == 1:
                cola = bl[i][0].strip()
                if len(cola) <= 45 and not cola.endswith(CIERRE) and not es_titulo(bl[i]) \
                        and sangria(bl[i][0]) == 0 and cola not in H2_LITERAL:
                    t += " " + cola
                    i += 1
            md += [("## " if RE_H2.match(s0) else "### ") + t, ""]
            continue
        # --- referencias: un bloque = una referencia
        if en_refs:
            md.append("- " + unir(b))
            continue
        # --- citas (sangría 2)
        if ind == 2:
            md += ["> " + unir(b), ""]
            continue
        # --- lista numerada (sangría 3, continuación a 6)
        if ind == 3 and RE_NUM.match(s0):
            md.append(RE_NUM.match(s0).group(0).strip() + " " + RE_NUM.sub("", unir(b)))
            if not (i < len(bl) and sangria(bl[i][0]) == 3):
                md.append("")
            continue
        # --- viñetas (sangría 6): ítem nuevo = mayúscula o comilla
        if ind >= 6:
            items: list[list[str]] = []
            for l in b:
                t = l.strip()
                if not items or t[:1].isupper() or t[:1] == "“":
                    items.append([t])
                else:
                    items[-1].append(t)
            md += ["- " + unir(it) for it in items]
            md.append("")
            continue
        # --- párrafo
        p = unir(b)
        if p.startswith("En ontología clásica:"):  # ajuste puntual: dos fórmulas en un bloque (§3.1)
            a, _, c = p.partition(" En ontología relacional:")
            md += [negrita_etiqueta(a) + "  ", negrita_etiqueta("En ontología relacional:" + c), ""]
            continue
        if p in ("Cita clave reinterpretada:", "Cita reinterpretada:"):
            md += [f"**{p}**", ""]
            continue
        md += [negrita_etiqueta(p), ""]
    txt = "\n".join(md).rstrip() + "\n"
    return re.sub(r"\n{3,}", "\n\n", txt)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--pdf", default=PDF_DEF)
    ap.add_argument("--out", default=OUT_DEF)
    ap.add_argument("--check", action="store_true", help="no escribe; exit 1 si el .md difiere")
    a = ap.parse_args()
    with open(a.pdf, "rb") as f:
        pdf_bytes = f.read()
    texto, avisos = extraer_layout(a.pdf)
    meta = {
        "fecha": _dt.date.today().isoformat(),
        "sha256": hashlib.sha256(pdf_bytes).hexdigest(),
        "paginas": texto.count("\f"),
        "pdftotext": "4.00",
    }
    if a.check:
        if not os.path.exists(a.out):
            print("no existe", a.out)
            return 1
        with open(a.out, encoding="utf-8") as f:
            previo = f.read()
        m = re.search(r"Nota de extracción \((\d{4}-\d{2}-\d{2})", previo)
        if m:
            meta["fecha"] = m.group(1)
        igual = previo == render(bloques(texto), meta)
        print("OK: sin cambios" if igual else "DIFIERE: regenerar con `python extraer.py`")
        return 0 if igual else 1
    md = render(bloques(texto), meta)
    with open(a.out, "w", encoding="utf-8", newline="\n") as f:
        f.write(md)
    print(f"{a.out}: {len(md.splitlines())} líneas · {len(md.split())} palabras · sha256 pdf {meta['sha256'][:12]}…")
    if avisos:
        print("avisos pdftotext:", avisos.replace("\n", " | ")[:300])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
