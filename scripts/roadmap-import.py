"""Importa los dosieres de trabajo a docs/ROADMAP como copia saneada. El origen no se modifica.

Uso: python scripts/roadmap-import.py <carpeta-con-los-dosier-*>   (luego: npm run docs:build)
Sanea: rutas de disco locales, Google Fonts, enlaces a artifacts privados y datos de conexión del pub.
"""
import re
import shutil
import sys
from pathlib import Path

F4 = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else sys.exit(__doc__)
REPO = Path(__file__).resolve().parents[1]
MD_OUT = REPO / "docs" / "ROADMAP"
PUB_OUT = REPO / "docs" / "public" / "dosieres"

DOSSIERS = {
    "dosier-aleph-net": "aleph-net",
    "dosier-relacional": "relacional",
    "dosier-colectivizaciones": "colectivizaciones",
    "dosier-res-publica": "res-publica",
    "dosier-oasis-faircoin": "oasis-faircoin",
    "dosier-publicidad-rrss": "publicidad-rrss",
}
STATUS_URL = "https://pub.escrivivir.co/public/status"

PATH_TOKEN = re.compile(r"C:[\\/](?:S_LAB|S_META|S)\b[^\s`|)\]»,;<>\"']*")
PREFIXES = [
    (re.compile(r"^C:[\\/]S_LAB[\\/]([a-z]-sdk)", re.I), r"\1"),
    (re.compile(r"^C:[\\/]S[\\/]scriptorium", re.I), "scriptorium"),
    (re.compile(r"^C:[\\/]S_META[\\/]F4", re.I), "F4"),
    (re.compile(r"^C:[\\/]S_META[\\/]LORE", re.I), "LORE"),
    (re.compile(r"^C:[\\/]S_META", re.I), "S_META"),
    (re.compile(r"^C:[\\/]S_LAB", re.I), "S_LAB"),
    (re.compile(r"^C:[\\/]S\b", re.I), "S"),
]


def clean_path(match: re.Match) -> str:
    token = match.group(0)
    for rx, repl in PREFIXES:
        if rx.search(token):
            token = rx.sub(repl, token, count=1)
            break
    return token.replace("\\", "/")


def sanitize_text(text: str) -> str:
    text = PATH_TOKEN.sub(clean_path, text)
    text = re.sub(r"[ \t]*<link[^>]+fonts\.(?:googleapis|gstatic)\.com[^>]*>\r?\n?", "", text)
    text = re.sub(r'<a href="https://claude\.ai/code/artifact/[^"]+"[^>]*>(.*?)</a>', r"\1", text, flags=re.S)
    return text


def special(slug: str, rel: str, text: str) -> str:
    if slug == "aleph-net" and rel == "02-pub-scriptorium.md":
        # la fila del panel se publica sin el detalle de su exposición: eso vive en MAPA.md y en WP-O52
        text, n = re.subn(r"(\| `pub-panel-api` \|[^|]*\|)[^|]*\|[^|]*\|",
                          r"\1 `127.0.0.1:${PUB_PANEL_PORT:-8787}` | activo; endurecimiento en backlog (WP-O52) |", text, count=1)
        assert n == 1, "fila del panel no encontrada"
    if slug == "aleph-net":
        text = text.replace("../modelador-redes/docs/informe-tutoria-plasticidad.md",
                            "modelador-redes/docs/informe-tutoria-plasticidad.md (https://github.com/alephscriptorium-eng/modelador-redes)")
    if slug == "relacional" and rel == "00-dictamen.md":
        note = ("\n> **Nota de publicación (2026-09-18).** El ensayo es público: está registrado en la red Oasis como\n"
                "> documento (2026-09-16) y se sirve desde el hub del pub:\n"
                "> <https://pub.escrivivir.co/c/documents/%25mJW4WynqLsOwoYwBvSTuV7SUlzBerZ0lOgviqm7MrBU%3D.sha256>.\n"
                "> Ese registro es la **identificación del modelo** que la casa quiere clonar o forkear; cuál de las dos\n"
                "> se decide en el dosier [aleph-net](../aleph-net/00-indice.md). Las menciones de este dosier a «permiso\n"
                "> pendiente» o «palimpsesto privado» son anteriores a esa publicación y quedan superadas por ella.\n")
        head, sep, rest = text.partition("\n")
        text = head + sep + note + rest
    if slug == "publicidad-rrss" and rel == "03-call4obras.md":
        start = text.index("Datos públicos, servidos por")
        end = text.index("En Oasis:")
        text = (text[:start] +
                f"Los datos de conexión **no se copian aquí**: cambian, y una copia se desfasa. La fuente única es el propio pub:\n\n"
                f"- <{STATUS_URL}> — `host`, `port`, `feedId`, `connect` (multiserver), `capsShs` (las caps de la red) y versión de Oasis, en JSON;\n"
                f"- <https://pub.escrivivir.co> — los mismos datos con botón COPY, y el **invite vivo**;\n"
                f"- <https://pub.escrivivir.co/c> — el navegador en claro del pub.\n\n" + text[end:])
    if slug == "publicidad-rrss" and rel == "banners/make_banners.py":
        old = re.search(r'SIGIL = Path\("[^"]+"\)\.read_text\(encoding="utf-8"\)', text).group(0)
        text = text.replace("import re\n", "import os\nimport re\n", 1).replace(
            old, '# Sigilo de la obra: el SVG de portada de su capa curada (editorial/portada.svg en el lore).\n'
                 'SIGIL = Path(os.environ.get("TEATRO_SIGIL") or Path(__file__).with_name("sigilo.svg")).read_text(encoding="utf-8")')
    if slug == "publicidad-rrss" and rel == "banners/make_banners.py":
        # DRY: los datos de conexión del pub no se duplican; se remite a la fuente viva
        text = re.sub(r'\s*connect="[^"]+",\s*caps="[^"]+",', "", text)
        box_old = text[text.index('<div class="p" style="word-break:break-all"><b>connect</b>'):text.index("(COPY)</div>") + len("(COPY)</div>")]
        text = text.replace(box_old, '<div class="p">Los datos no se imprimen: cambian.<br><b>connect · caps · versión</b> pub.escrivivir.co/public/status<br><b>invite vivo</b> pub.escrivivir.co (COPY)</div>')
    return text


def main() -> None:
    for out in (MD_OUT, PUB_OUT):
        if out.exists():
            shutil.rmtree(out)
    report = {}
    for src_name, slug in DOSSIERS.items():
        src = F4 / src_name
        n_md = n_pub = 0
        for path in sorted(src.rglob("*")):
            if not path.is_file() or "__pycache__" in path.parts:
                continue
            rel = path.relative_to(src).as_posix()
            is_md = path.suffix == ".md"
            is_fig = path.suffix == ".svg" and "figuras" in path.parts  # imágenes citadas en relativo desde un .md
            target = (MD_OUT if (is_md or is_fig) else PUB_OUT) / slug / rel
            target.parent.mkdir(parents=True, exist_ok=True)
            if path.suffix in (".md", ".html", ".py", ".sh", ".svg"):
                text = special(slug, rel, sanitize_text(path.read_text(encoding="utf-8")))
                target.write_text(text, encoding="utf-8", newline="\n")
            else:
                shutil.copy2(path, target)
            n_md += is_md
            n_pub += not (is_md or is_fig)
        report[slug] = (n_md, n_pub)
    # el sigilo viaja junto al generador de banners
    sig = REPO / "ARCHIVO/LORE/twitter_x/aleph-cero/editorial/portada.svg"
    if sig.is_file():
        shutil.copy2(sig, PUB_OUT / "publicidad-rrss" / "banners" / "sigilo.svg")
    for slug, (a, b) in report.items():
        print(f"{slug:<20} md: {a:>2} · anexos: {b:>2}")


main()
