#!/usr/bin/env python3
"""Prepara el «navegador anexo»: el visor oficial del export de X, limpiado.

ESPECÍFICO DE twitter_x y opcional (`publish.viewer`). Es la única página con JavaScript de la
obra: excepción declarada al invariante «cero JS» (ver `lib/guards.py`).

- Parte SIEMPRE del visor stock del export primario (`assets/`, `Your archive.html`).
- `data/`: solo la whitelist `VIEWER_DATA`, con el manifest podado a juego: las secciones
  retiradas (DMs, likes, IPs, bloqueos, Grok…) desaparecen limpiamente.
- Des-CDN: las referencias a abs.twimg.com (fuentes, avatar por defecto) se reescriben a rutas
  locales sobre la copia; cero peticiones externas.
- Parches declarativos de `patches/*.json` (p. ej. multi-vídeo): se aplican solo si el sha256
  del bundle stock coincide; si X cambia el bundle, se avisa y se sigue sin parche.
"""

from __future__ import annotations

import hashlib
import json
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lib.guards import BRAIN_DATA, MEDIA_DIRS, VIEWER_DATA, VIEWER_PAGE  # noqa: E402
from lib.obra import MANIFEST_PREFIX, Obra, sidecar_dir  # noqa: E402
from tools.build_site import sync_file, sync_tree  # noqa: E402

DEAD_FONTS = "https://abs.twimg.com/fonts/"
DEFAULT_AVATAR = "https://abs.twimg.com/sticky/default_profile_images/default_profile_normal.png"
EXTERNAL_HELP = "https://help.twitter.com/"


def prune_manifest(src: Path, dst: Path, available: set[str]) -> tuple[int, int]:
    text = src.read_text(encoding="utf-8").lstrip("﻿")
    if not text.startswith(MANIFEST_PREFIX):
        raise SystemExit(f"manifest inesperado en {src}")
    config = json.loads(text[len(MANIFEST_PREFIX):])
    kept, dropped = {}, 0
    for name, spec in (config.get("dataTypes") or {}).items():
        files = (spec or {}).get("files") or []
        names = {Path(f.get("fileName", "")).name for f in files}
        media_dir = (spec or {}).get("mediaDirectory")
        media_ok = media_dir is None or Path(media_dir).name in MEDIA_DIRS
        if names and names <= available and media_ok:
            kept[name] = spec
        else:
            dropped += 1
    config["dataTypes"] = kept
    # datos personales del manifest que el visor no necesita
    for key in ("email",):
        (config.get("userInfo") or {}).pop(key, None)
    dst.write_text(MANIFEST_PREFIX + json.dumps(config, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return len(kept), dropped


def apply_patches(js_dir: Path) -> list[str]:
    notes = []
    for spec_path in sorted((sidecar_dir() / "patches").glob("*.json")):
        spec = json.loads(spec_path.read_text(encoding="utf-8"))
        targets = list(js_dir.glob(spec["file_glob"]))
        if not targets:
            notes.append(f"{spec_path.stem}: sin fichero {spec['file_glob']} (no aplicado)")
            continue
        target = targets[0]
        blob = target.read_bytes()
        digest = hashlib.sha256(blob).hexdigest()
        if digest == spec.get("patched_sha256"):
            notes.append(f"{spec_path.stem}: ya aplicado")
            continue
        if digest != spec["stock_sha256"]:
            notes.append(f"{spec_path.stem}: AVISO, el bundle cambió (sha {digest[:12]}…); se sirve sin parche")
            continue
        text = blob.decode("utf-8")
        if text.count(spec["find"]) != 1:
            notes.append(f"{spec_path.stem}: AVISO, el fragmento a sustituir no es único; no aplicado")
            continue
        patched = text.replace(spec["find"], spec["replace"]).encode("utf-8")
        if spec.get("patched_sha256") and hashlib.sha256(patched).hexdigest() != spec["patched_sha256"]:
            notes.append(f"{spec_path.stem}: AVISO, el resultado no coincide con patched_sha256; no aplicado")
            continue
        target.write_bytes(patched)
        notes.append(f"{spec_path.stem}: aplicado a {target.name}")
    return notes


def build(obra: Obra, out: Path) -> dict:
    if not obra.publish["viewer"]:
        for stale in (out / VIEWER_PAGE,):
            stale.unlink(missing_ok=True)
        return {"viewer": False}
    root = obra.primary()["dir"]
    data_src = root / "data"

    # 1) cromo stock del visor. Se recopia siempre el JS: los parches parten del stock.
    js_out = out / "assets" / "js"
    if js_out.is_dir():
        shutil.rmtree(js_out)
    copied = sync_tree(root / "assets", out / "assets")
    notes = apply_patches(js_out)

    # 2) des-CDN sobre la copia
    n_fonts = n_avatar = 0
    for bundle in js_out.glob("*.js"):
        text = bundle.read_text(encoding="utf-8")
        if DEAD_FONTS in text or DEFAULT_AVATAR in text:
            n_fonts += text.count(DEAD_FONTS)
            n_avatar += text.count(DEFAULT_AVATAR)
            text = text.replace(DEFAULT_AVATAR, "assets/images/defaultAvatar.svg").replace(DEAD_FONTS, "assets/fonts/")
            bundle.write_text(text, encoding="utf-8")

    # 3) datos whitelisted de la generación primaria
    available = set(VIEWER_DATA)
    for name in VIEWER_DATA:
        src = data_src / name
        if name == "manifest.js" or not src.is_file():
            continue
        copied += sync_file(src, out / "data" / name)
    kept, dropped = prune_manifest(data_src / "manifest.js", out / "data" / "manifest.js", available)

    # 4) la página: el stub oficial, renombrado
    shutil.copy2(root / "Your archive.html", out / VIEWER_PAGE)

    # 5) guardas propias del visor (las generales están en lib/guards.py)
    for path in js_out.glob("*.js"):
        body = path.read_text(encoding="utf-8")
        for bad in ("abs.twimg.com/fonts", "abs.twimg.com/sticky"):
            if bad in body:
                raise SystemExit(f"sobrevive una carga externa en {path.name}: {bad}")
    allowed = set(VIEWER_DATA) | set(BRAIN_DATA) | set(MEDIA_DIRS)
    extra = [p.name for p in (out / "data").iterdir() if p.name not in allowed]
    if extra:
        raise SystemExit(f"entradas inesperadas en data/: {extra}")

    print(f"viewer build ok · dataTypes: {kept} conservados, {dropped} retirados · "
          f"des-CDN: fuentes x{n_fonts}, avatar x{n_avatar} · copiados: {copied}")
    for note in notes:
        print(f"  parche {note}")
    return {"viewer": True, "kept": kept, "dropped": dropped, "patches": notes}
