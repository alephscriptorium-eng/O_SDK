"""Configuración de una obra y rutas de su lore.

Una *obra* es un árbol estático que el visor del Teatro sirve bajo `/teatro/<obra>/`.
Su *lore* (exports del usuario + stores no regenerables) vive en
`ARCHIVO/LORE/<fuente>/<obra>/` dentro del repo, ignorado por git. `obra.json` está en la raíz
de ese directorio y solo contiene rutas RELATIVAS a él: el lore es portable.

Nada aquí conoce el formato de X salvo `read_manifest`/`read_account`, que se usan únicamente
para inicializar `obra.json` desde un export.
"""

from __future__ import annotations

import json
import os
import re
from pathlib import Path

SOURCE = "twitter_x"
OBRA_RE = re.compile(r"^[a-z0-9][a-z0-9-]*$")
MANIFEST_PREFIX = "window.__THAR_CONFIG = "


def repo_root() -> Path:
    # pub/rrss-sidecar/twitter_x/lib/obra.py → 4 niveles hasta la raíz del repo
    return Path(__file__).resolve().parents[4]


def sidecar_dir() -> Path:
    return Path(__file__).resolve().parents[1]


def lore_root() -> Path:
    env = os.environ.get("TEATRO_LORE_ROOT")
    return Path(env) if env else repo_root() / "ARCHIVO" / "LORE" / SOURCE


def out_root() -> Path:
    env = os.environ.get("TEATRO_OUT_ROOT")
    return Path(env) if env else repo_root() / "volumes-dev" / "teatro"


def read_manifest(export_dir: Path) -> dict:
    path = export_dir / "data" / "manifest.js"
    text = path.read_text(encoding="utf-8").lstrip("﻿")
    if not text.startswith(MANIFEST_PREFIX):
        raise SystemExit(f"manifest inesperado (falta `{MANIFEST_PREFIX}`): {path}")
    return json.loads(text[len(MANIFEST_PREFIX):])


def generation_of(manifest: dict) -> str:
    return (manifest.get("archiveInfo") or {}).get("generationDate", "")[:10]


class Obra:
    """Vista de `obra.json` con las rutas ya resueltas."""

    def __init__(self, name: str, lore_dir: Path | None = None):
        if not OBRA_RE.match(name):
            raise SystemExit(f"nombre de obra inválido: {name!r} (usa [a-z0-9-])")
        self.name = name
        self.lore = (lore_dir or lore_root() / name).resolve()
        self.config_path = self.lore / "obra.json"
        self.cfg: dict = {}
        if self.config_path.is_file():
            self.cfg = json.loads(self.config_path.read_text(encoding="utf-8"))

    # ── rutas del lore ──
    @property
    def exports_dir(self) -> Path:
        return self.lore / "exports"

    @property
    def store_dir(self) -> Path:
        return self.lore / "store"

    @property
    def cache_dir(self) -> Path:
        return self.lore / "cache"

    @property
    def legacy_dir(self) -> Path:
        return self.lore / "legacy"

    @property
    def out(self) -> Path:
        return out_root() / self.name

    # ── configuración ──
    def require(self) -> "Obra":
        if not self.cfg:
            raise SystemExit(
                f"no existe {self.config_path}. Crea la obra con:\n"
                f"  sidecar.py lore-import --from <export> --obra {self.name}\n"
                f"  sidecar.py init --obra {self.name}"
            )
        return self

    @property
    def base(self) -> str:
        return self.cfg.get("base") or f"/teatro/{self.name}"

    @property
    def title(self) -> str:
        return self.cfg.get("title") or self.name

    @property
    def account(self) -> dict:
        return self.cfg.get("account") or {}

    @property
    def own_id(self) -> str:
        return str(self.account.get("id") or "")

    @property
    def handle(self) -> str:
        return str(self.account.get("handle") or "")

    @property
    def publish(self) -> dict:
        defaults = {"deleted_posts": "hidden", "external_media": "local", "viewer": True}
        defaults.update(self.cfg.get("publish") or {})
        return defaults

    def generations(self) -> list[dict]:
        """Generaciones declaradas, ordenadas por fecha, con `dir` absoluto."""
        items = []
        for src in self.cfg.get("sources") or []:
            item = dict(src)
            item["dir"] = (self.lore / src["path"]).resolve()
            items.append(item)
        items.sort(key=lambda s: s["generation"])
        return items

    def primary(self) -> dict:
        gens = self.generations()
        if not gens:
            raise SystemExit("obra.json sin `sources`: importa un export con `lore-import`")
        marked = [g for g in gens if g.get("primary")]
        return marked[-1] if marked else gens[-1]

    def save(self) -> None:
        self.lore.mkdir(parents=True, exist_ok=True)
        tmp = self.config_path.with_suffix(".json.tmp")
        tmp.write_text(json.dumps(self.cfg, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        tmp.replace(self.config_path)


def write_json_atomic(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(json.dumps(data, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    tmp.replace(path)


def read_json(path: Path, default):
    if not path.is_file():
        return default
    return json.loads(path.read_text(encoding="utf-8"))
