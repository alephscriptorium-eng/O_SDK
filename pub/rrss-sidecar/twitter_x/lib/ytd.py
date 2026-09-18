"""Lectura de los ficheros `data/*.js` del export oficial de X.

Formato: `window.YTD.<tipo>.part<N> = [ ... ]` (un array JSON tras el `=`). Un archivo grande
se parte en `tweets.js`, `tweets-part1.js`, `tweets-part2.js`…: se leen TODAS las partes.
Este módulo y `normalize.py` son los únicos que conocen el formato de X (la costura B.O.E.).
"""

from __future__ import annotations

import json
import re
from pathlib import Path

WRAPPER = re.compile(r"window\.YTD\.([A-Za-z0-9_]+)\.part(\d+)\s*=\s*")


def part_files(data_dir: Path, stem: str) -> list[Path]:
    """`tweets` → [tweets.js, tweets-part1.js, …] en orden de parte."""
    first = data_dir / f"{stem}.js"
    rest = sorted(
        data_dir.glob(f"{stem}-part*.js"),
        key=lambda p: int(re.search(r"-part(\d+)\.js$", p.name).group(1)),
    )
    return ([first] if first.is_file() else []) + rest


def parse_file(path: Path) -> list:
    text = path.read_text(encoding="utf-8").lstrip("﻿")
    match = WRAPPER.search(text)
    if not match:
        raise SystemExit(f"falta el envoltorio `window.YTD.<tipo>.partN =` en {path}")
    payload = text[match.end():].strip()
    if payload.endswith(";"):
        payload = payload[:-1].rstrip()
    data = json.loads(payload)
    if not isinstance(data, list):
        raise SystemExit(f"se esperaba un array JSON en {path}")
    return data


def parse_ytd(data_dir: Path, stem: str, required: bool = True) -> list:
    files = part_files(data_dir, stem)
    if not files:
        if required:
            raise SystemExit(f"no existe {data_dir / (stem + '.js')}")
        return []
    items: list = []
    for path in files:
        items.extend(parse_file(path))
    return items


def tweets_of(data_dir: Path, stem: str = "tweets", required: bool = True) -> list[dict]:
    """Devuelve los objetos tweet (desenvuelve `{"tweet": {...}}`). Ids duplicados = error."""
    tweets: list[dict] = []
    seen: set[str] = set()
    for entry in parse_ytd(data_dir, stem, required=required):
        tweet = entry.get("tweet") if isinstance(entry, dict) else None
        if not isinstance(tweet, dict) or not tweet.get("id_str"):
            raise SystemExit(f"entrada inesperada en {stem}.js (sin tweet.id_str)")
        if tweet["id_str"] in seen:
            raise SystemExit(f"id duplicado entre partes de {stem}.js: {tweet['id_str']}")
        seen.add(tweet["id_str"])
        tweets.append(tweet)
    return tweets
