"""Guardas de publicación: la única fuente de verdad de los invariantes de una obra.

Las usan `sidecar.py build` (al terminar), `sidecar.py check <dir>` y el deploy (pre-vuelo).
Una obra publicada:
  1. no contiene nada del export fuera de la whitelist de `data/`;
  2. no lleva `.js` salvo el visor anexo (`assets/js/`) y los datos whitelisted;
  3. no tiene `<script` salvo en `navegador.html` (EXCEPCIÓN DECLARADA: el visor oficial de X);
  4. no carga ningún recurso externo (los `<a href>` externos sí están permitidos);
  5. no incluye ningún fichero de nombre sensible, en el árbol ni en los zips;
  6. no deja placeholders ni rutas locales del operador.
"""

from __future__ import annotations

import re
import zipfile
from pathlib import Path

MEDIA_DIRS = ("tweets_media", "profile_media", "external_media")
VIEWER_DATA = (
    "manifest.js", "README.txt", "tweets.js", "tweet-headers.js", "account.js", "profile.js",
    "verified.js", "verified-organization.js", "screen-name-change.js",
)
BRAIN_DATA = ("external_tweets.v2.json", "external_worklist.json", "links_store.json")
VIEWER_PAGE = "navegador.html"

SENSITIVE = re.compile(
    r"(^|[/\\])(ip-audit|account-creation-ip|phone-number|email-address|device-token|key-registry|"
    r"connected-application|personalization|block|mute|like|follower|following|contact|"
    r"grok-chat|direct-message|ad-|ads-|ni-devices|saved-search|sso|app|branch-links|"
    r"periscope|protected-history|smartblock|user-link-clicks|deleted-tweet)[^/\\]*\.js$",
    re.I,
)
EXTERNAL_LOAD = re.compile(
    r"""(?:<(?:img|script|iframe|video|audio|source|embed|object)\b[^>]*?\bsrc\s*=\s*["']?https?://"""
    r"""|<link\b[^>]*?\bhref\s*=\s*["']?https?://|url\(\s*["']?https?://|@import\s+["']?https?://)""",
    re.I,
)
LOCAL_PATH = re.compile(r"(?<![\w/])(?:[A-Za-z]:[\\/]Users[\\/]|/Users/[^/\s\"'<]+/|/home/[^/\s\"'<]+/|/mnt/[a-z]/)", re.I)
PLACEHOLDER = re.compile(r"__[A-Z0-9_]*SHA256__")


def check(out: Path, allow_placeholders: bool = True, extra_needles: list[str] | None = None) -> list[str]:
    """Devuelve la lista de violaciones (vacía = verde)."""
    problems: list[str] = []
    if not (out / "index.html").is_file():
        return [f"no es una obra: falta {out / 'index.html'}"]

    data = out / "data"
    allowed = set(MEDIA_DIRS) | set(VIEWER_DATA) | set(BRAIN_DATA)
    if data.is_dir():
        for entry in data.iterdir():
            if entry.name not in allowed:
                problems.append(f"data/: entrada fuera de whitelist: {entry.name}")

    for path in out.rglob("*"):
        if not path.is_file():
            continue
        rel = path.relative_to(out).as_posix()
        if SENSITIVE.search(rel):
            problems.append(f"nombre sensible: {rel}")
        if path.suffix == ".js":
            ok = rel.startswith("assets/js/") or (rel.startswith("data/") and path.name in VIEWER_DATA)
            if not ok:
                problems.append(f".js fuera del visor: {rel}")
        if path.suffix in (".pyc",) or "__pycache__" in path.parts:
            problems.append(f"bytecode en la obra: {rel}")

    needles = [n for n in (extra_needles or []) if n and len(n) >= 6]
    for path in list(out.rglob("*.html")) + list(out.rglob("*.md")) + list(out.rglob("*.css")):
        rel = path.relative_to(out).as_posix()
        text = path.read_text(encoding="utf-8", errors="replace")
        published_md = rel.startswith("corpus/")
        if path.suffix == ".html" and path.name != VIEWER_PAGE and "<script" in text.lower():
            problems.append(f"<script> en página generada: {rel}")
        if path.name != VIEWER_PAGE and not published_md and EXTERNAL_LOAD.search(text):
            problems.append(f"recurso externo cargado: {rel}")
        if not published_md and LOCAL_PATH.search(text):
            problems.append(f"ruta local del operador: {rel}")
        if not allow_placeholders and PLACEHOLDER.search(text):
            problems.append(f"placeholder sin estampar: {rel}")
        for needle in needles:
            if needle in text:
                problems.append(f"dato personal del export en {rel}")
                break

    for archive in out.glob("*.zip"):
        with zipfile.ZipFile(archive) as handle:
            for name in handle.namelist():
                if SENSITIVE.search(name):
                    problems.append(f"{archive.name}: nombre sensible dentro del zip: {name}")
    return problems


def personal_needles(export_dir: Path) -> list[str]:
    """Email y teléfono del export: jamás pueden aparecer en la obra publicada."""
    needles: list[str] = []
    for name in ("account.js", "phone-number.js", "email-address-change.js"):
        path = export_dir / "data" / name
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        needles += re.findall(r"[\w.+-]+@[\w-]+\.[\w.-]+", text)
        needles += re.findall(r"\+\d{8,15}", text)
    return sorted(set(needles))
