"""Capa editorial de una obra: la puerta semántica, declarada por el custodio en el lore.

Fuente: `ARCHIVO/LORE/<fuente>/<obra>/editorial/obra-semantica.json` más los `.md` que referencia.
Si el fichero no existe la obra se construye igual, solo con las puertas mecánicas.

Dos capas que nunca se mezclan:
  - curada:   `post_ids`, `thread_roots`, `link_hashes` — la elige el custodio;
  - mecánica: `terms` (regex) — lo que además menciona el constructo, listado aparte.

En los `.md` editoriales, `[[<id>]]` enlaza un post y `«cita» [[<id>]]` es una cita verificable:
`check` exige que el texto entre comillas esté literalmente en ese post.
"""

from __future__ import annotations

import re
from pathlib import Path

from .obra import Obra, read_json

FILENAME = "obra-semantica.json"
SCHEMA_VERSION = 1
SLUG_RE = re.compile(r"^[a-z0-9][a-z0-9-]{0,63}$")
POST_REF = re.compile(r"\[\[(\d{1,25})\]\]")
QUOTE_REF = re.compile(r"«([^«»]+)»\s*\[\[(\d{1,25})\]\]")
COMMENT = re.compile(r"<!--.*?-->", re.S)
ELLIPSIS = re.compile(r"\s*(?:\(…\)|\[…\]|\(\.\.\.\)|\[\.\.\.\]|…)\s*")
SVG_FORBIDDEN = re.compile(r"<script|\bon[a-z]+\s*=|<image\b|<foreignObject\b|href\s*=\s*[\"']?\s*(?:https?:|//|data:)|@import|url\(", re.I)


def flat(text: str) -> str:
    return " ".join((text or "").split())


class Editorial:
    """Vista resuelta contra los registros visibles. `problems` = errores; `warnings` = avisos."""

    def __init__(self, obra: Obra, records: list[dict], threads: dict[str, list[dict]], links: dict | None = None):
        self.dir = obra.editorial_dir
        self.raw: dict = read_json(self.dir / FILENAME, {}) or {}
        self.present = bool(self.raw)
        self.by_id = {r["id"]: r for r in records}
        self.records, self.threads, self.links = records, threads, links or {}
        self.problems: list[str] = []
        self.warnings: list[str] = []
        self.territories: list[dict] = []
        self.constructs: dict[str, dict] = {}
        self.post_constructs: dict[str, list[str]] = {}
        self.tracks: list[dict] = []
        if self.present:
            self._resolve()

    # ── ficheros ──
    def path(self, rel: str | None) -> Path | None:
        if not rel:
            return None
        target = (self.dir / rel).resolve()
        if self.dir.resolve() not in target.parents:
            self.problems.append(f"ruta fuera de editorial/: {rel}")
            return None
        return target

    def text(self, rel: str | None) -> str:
        target = self.path(rel)
        if not target:
            return ""
        if not target.is_file():
            self.problems.append(f"falta el fichero editorial: {rel}")
            return ""
        return target.read_text(encoding="utf-8")

    def cover_svg(self) -> str:
        """SVG de portada, listo para ir inline. Vacío si no hay o si no es seguro."""
        rel = self.raw.get("cover")
        svg = self.text(rel) if rel else ""
        if not svg:
            return ""
        svg = re.sub(r"<\?xml[^>]*\?>|<!DOCTYPE[^>]*>|<!--.*?-->", "", svg, flags=re.S).strip()
        if not svg.startswith("<svg") or SVG_FORBIDDEN.search(svg):
            self.problems.append(f"portada no admitida (solo vector puro, sin script, eventos, <image> ni recursos): {rel}")
            return ""
        return svg

    # ── resolución ──
    def _ids(self, where: str, ids, pool, what: str) -> list[str]:
        out = []
        for raw_id in ids or []:
            key = str(raw_id)
            if key in pool:
                if key not in out:
                    out.append(key)
            else:
                self.warnings.append(f"{where}: {what} {key} no está entre lo publicado (se omite)")
        return out

    def _resolve(self) -> None:
        if self.raw.get("version") != SCHEMA_VERSION:
            self.problems.append(f"version {self.raw.get('version')!r}: este sidecar entiende la {SCHEMA_VERSION}")
        for t in self.raw.get("territories") or []:
            tslug = str(t.get("slug") or "")
            if not SLUG_RE.match(tslug):
                self.problems.append(f"territorio con slug inválido: {tslug!r}")
                continue
            territory = {"slug": tslug, "title": t.get("title") or tslug, "copy": t.get("copy") or "", "constructs": []}
            for c in t.get("constructs") or []:
                slug = str(c.get("slug") or "")
                if not SLUG_RE.match(slug) or slug in self.constructs or slug == "index":
                    self.problems.append(f"constructo con slug inválido o repetido: {slug!r}")
                    continue
                where = f"constructo {slug}"
                post_ids = self._ids(where, c.get("post_ids"), self.by_id, "post")
                roots = self._ids(where, c.get("thread_roots"), self.threads, "hilo")
                link_keys = self._ids(where, c.get("link_hashes"), self.links, "enlace")
                first = str(c.get("first_id") or "")
                if first and first not in self.by_id:
                    self.warnings.append(f"{where}: first_id {first} no está entre lo publicado")
                    first = ""
                curated = set(post_ids) | {m["id"] for root in roots for m in self.threads[root]}
                if first:
                    curated.add(first)
                patterns = []
                for term in c.get("terms") or []:
                    try:
                        patterns.append(re.compile(term, re.I))
                    except re.error as exc:
                        self.problems.append(f"{where}: regex inválida {term!r}: {exc}")
                mechanical = [r["id"] for r in self.records
                              if r["id"] not in curated and r["kind"] != "retweet" and any(p.search(r["text"]) for p in patterns)]
                construct = {
                    "slug": slug, "title": c.get("title") or slug, "copy": c.get("copy") or "", "text": c.get("text"),
                    "territory": tslug, "first_id": first, "post_ids": post_ids, "thread_roots": roots,
                    "link_hashes": link_keys, "terms": list(c.get("terms") or []), "curated": curated, "mechanical": mechanical,
                }
                if not curated:
                    self.warnings.append(f"{where}: sin ningún post curado")
                self.constructs[slug] = construct
                territory["constructs"].append(construct)
                for pid in sorted(curated):
                    self.post_constructs.setdefault(pid, []).append(slug)
            self.territories.append(territory)

        album = self.raw.get("album") or {}
        for track in album.get("tracks") or []:
            try:
                n = int(track.get("n"))
            except (TypeError, ValueError):
                self.problems.append(f"corte sin número: {track.get('title')!r}")
                continue
            where = f"corte {n:02d}"
            video = str(track.get("video") or "")
            if video and not re.match(r"^https://[^\s\"'<>]+$", video):
                self.problems.append(f"{where}: `video` debe ser una URL https")
                video = ""
            slugs = [s for s in track.get("constructs") or [] if s in self.constructs]
            for missing in set(track.get("constructs") or []) - set(slugs):
                self.warnings.append(f"{where}: constructo desconocido {missing!r}")
            self.tracks.append({
                "n": n, "title": track.get("title") or f"Corte {n}", "side": track.get("side") or "", "video": video,
                "duration": track.get("duration") or "", "lyrics": track.get("lyrics"), "note": track.get("note") or "",
                "constructs": slugs, "post_ids": self._ids(where, track.get("post_ids"), self.by_id, "post"),
            })
        self.tracks.sort(key=lambda t: t["n"])

    @property
    def album(self) -> dict:
        return self.raw.get("album") or {}

    # ── comprobación ──
    def editorial_files(self) -> list[tuple[str, str]]:
        """(etiqueta, ruta relativa) de cada `.md` referenciado."""
        files = [("concepto", self.raw.get("concept")), ("álbum", self.album.get("text"))]
        files += [(f"constructo {c['slug']}", c["text"]) for c in self.constructs.values()]
        files += [(f"corte {t['n']:02d}", t["lyrics"]) for t in self.tracks]
        return [(label, rel) for label, rel in files if rel]

    def check(self) -> dict:
        """Verifica ficheros, referencias `[[id]]` y citas literales. Devuelve el informe de cobertura."""
        n_quotes = 0
        for label, rel in self.editorial_files():
            body = COMMENT.sub('', self.text(rel))
            for pid in POST_REF.findall(body):
                if pid not in self.by_id:
                    self.problems.append(f"{label}: [[{pid}]] no está entre lo publicado")
            if label.startswith("corte"):
                continue  # una letra no cita posts
            for quote, pid in QUOTE_REF.findall(body):
                n_quotes += 1
                source = flat((self.by_id.get(pid) or {}).get("text", ""))
                for fragment in ELLIPSIS.split(flat(quote)):
                    if fragment and fragment not in source:
                        self.problems.append(f"{label}: cita no literal en [[{pid}]]: «{fragment[:70]}»")
                        break
        self.cover_svg()
        own = [r for r in self.records if r["kind"] != "retweet"]
        curated = set(self.post_constructs)
        touched = curated | {i for c in self.constructs.values() for i in c["mechanical"]}
        return {
            "territories": len(self.territories), "constructs": len(self.constructs), "tracks": len(self.tracks),
            "lyrics": sum(1 for t in self.tracks if t["lyrics"]), "quotes_checked": n_quotes,
            "curated_posts": len(curated), "mechanical_posts": len(touched - curated),
            "own_posts": len(own), "coverage_pct": round(100 * len(touched & {r["id"] for r in own}) / max(len(own), 1), 1),
        }

    def delta(self, since: str) -> dict:
        """Posts propios posteriores a `since` (ISO) que ningún constructo recoge como curados."""
        fresh = [r for r in self.records if r["created_at"] >= since and r["kind"] != "retweet"]
        uncurated = [r for r in fresh if r["id"] not in self.post_constructs]
        suggestions = {}
        for c in self.constructs.values():
            hits = [i for i in c["mechanical"] if self.by_id[i]["created_at"] >= since]
            if hits:
                suggestions[c["slug"]] = hits
        suggested = {i for hits in suggestions.values() for i in hits}
        return {"fresh": fresh, "uncurated": uncurated, "suggestions": suggestions,
                "orphans": [r for r in uncurated if r["id"] not in suggested]}


def link_posts(markdown: str, href) -> str:
    """`[[id]]` → enlace Markdown. `href(id)` devuelve la URL o None si el post no está publicado."""
    def repl(match):
        url = href(match.group(1))
        return f"[{match.group(1)}]({url})" if url else f"`{match.group(1)}`"
    return POST_REF.sub(repl, markdown)
