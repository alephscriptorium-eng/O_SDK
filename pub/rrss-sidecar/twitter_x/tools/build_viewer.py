#!/usr/bin/env python3
"""Stage the customized X archive viewer ("ver-web") into the Aleph Cero site.

Not verbatim: the stock viewer is cleaned before publishing.
- data/ whitelist only (no IPs, tokens, DMs, Grok, blocks, likes...) with the
  manifest pruned to match, so removed sections disappear cleanly.
- De-CDN: the two abs.twimg.com references (Chirp fonts, default avatar) are
  rewritten to local paths — zero external requests.
- Keeps our multi-video patch (assets/js/ondemand.App.*.js) — same bundles in
  the 2026-07-08 and 2026-08-21 generations, verified.

Anchored at the obra root so it reuses the already-published media
(data/tweets_media/, data/profile_media/): the viewer costs ~23 MB, not 750.

Usage: python3 tools/build_viewer.py [--out DIR]   (same --out as build_site.py)
"""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path

from build_corpus import repo_root
from build_site import BRAIN_DATA, MEDIA_DIRS, VIEWER_DATA, sync_tree

DEAD_FONTS = "https://abs.twimg.com/fonts/"
DEFAULT_AVATAR = (
    "https://abs.twimg.com/sticky/default_profile_images/default_profile_normal.png"
)


def prune_manifest(src: Path, dst: Path, available: set[str]) -> tuple[int, int]:
    prefix = "window.__THAR_CONFIG = "
    text = src.read_text(encoding="utf-8")
    if not text.startswith(prefix):
        raise SystemExit(f"unexpected manifest wrapper in {src}")
    config = json.loads(text[len(prefix):])
    data_types = config.get("dataTypes") or {}
    kept, dropped = {}, 0
    for name, spec in data_types.items():
        files = (spec or {}).get("files") or []
        names = {Path(f.get("fileName", "")).name for f in files}
        media_dir = (spec or {}).get("mediaDirectory")
        media_ok = media_dir is None or Path(media_dir).name in MEDIA_DIRS
        if names and names <= available and media_ok:
            kept[name] = spec
        else:
            dropped += 1
    config["dataTypes"] = kept
    dst.write_text(prefix + json.dumps(config, ensure_ascii=False, indent=2) + "\n",
                   encoding="utf-8")
    return len(kept), dropped


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    default_out = repo_root().parent.parent / "deploy" / "teatro" / "aleph-cero"
    parser.add_argument("--out", type=Path, default=default_out)
    args = parser.parse_args()
    root = repo_root()
    out: Path = args.out

    # 1) chrome del visor (con el parche multi-vídeo), junto a assets/obra.css
    copied = sync_tree(root / "assets", out / "assets")

    # 2) des-CDN sobre la copia staged (nunca sobre la fuente)
    modules = next((out / "assets" / "js").glob("modules.*.js"))
    text = modules.read_text(encoding="utf-8")
    n_fonts = text.count(DEAD_FONTS)
    n_avatar = text.count(DEFAULT_AVATAR)
    text = text.replace(DEFAULT_AVATAR, "assets/images/defaultAvatar.svg")
    text = text.replace(DEAD_FONTS, "assets/fonts/")
    modules.write_text(text, encoding="utf-8")

    # 3) datos whitelisted de la generación actual
    available = set(VIEWER_DATA)
    for name in VIEWER_DATA:
        if name == "manifest.js":
            continue
        src, dst = root / "data" / name, out / "data" / name
        if not dst.is_file() or dst.stat().st_size != src.stat().st_size:
            shutil.copy2(src, dst)
            copied += 1
    kept, dropped = prune_manifest(root / "data" / "manifest.js",
                                   out / "data" / "manifest.js", available)

    # 4) la página: el stub oficial, renombrado
    shutil.copy2(root / "Your archive.html", out / "navegador.html")

    # 5) guardas — vetamos cargas externas reales; la lista cdnDomains del visor
    # (dominios sin protocolo, usada para MAPEAR urls de tweets a media local)
    # debe sobrevivir o la resolución de media se rompe.
    for path in (out / "assets" / "js").glob("*.js"):
        body = path.read_text(encoding="utf-8")
        for bad in ("abs.twimg.com/fonts", "abs.twimg.com/sticky"):
            if bad in body:
                raise SystemExit(f"external load reference survived in {path.name}: {bad}")
    allowed = set(VIEWER_DATA) | set(BRAIN_DATA) | set(MEDIA_DIRS)
    extra = [p.name for p in (out / "data").iterdir() if p.name not in allowed]
    if extra:
        raise SystemExit(f"unexpected entries in staged data/: {extra}")

    print("viewer build ok")
    print(f"manifest dataTypes: kept {kept}, dropped {dropped}")
    print(f"des-CDN: fonts x{n_fonts}, avatar x{n_avatar} reescritos")
    print(f"files copied this run: {copied}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
