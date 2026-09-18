#!/usr/bin/env python3
"""Genera el sitio estático y sin JavaScript de una obra del Teatro.

Entrada: corpus normalizado + stores de voces y enlaces + perfil del export primario.
Salida: `volumes-dev/teatro/<obra>/` (o `--out`). Copia junto al HTML la media de los posts
VISIBLES, la media local de terceros y el «segundo cerebro». No publica nada más del export.
"""

from __future__ import annotations

import html
import re
import shutil
import sys
from collections import defaultdict
from pathlib import Path
from urllib.parse import quote

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lib import links as links_lib  # noqa: E402
from lib import normalize, voices, ytd  # noqa: E402
from lib.guards import BRAIN_DATA  # noqa: E402
from lib.obra import Obra, read_manifest, sidecar_dir  # noqa: E402
from tools.build_corpus import level2_refs, voice_refs, write_text  # noqa: E402

KIND_LABEL = {"original": "original", "self_reply": "hilo", "reply_to_other": "réplica", "retweet": "RT"}
REAL_LANGS = {"es", "en", "ca", "eu", "gl", "it", "pt", "fr", "de", "fi", "sv", "tr", "zh", "lt", "tl", "ht", "ja", "ru"}
LANG_ALIASES = {"in": "id"}
MES = {1: "enero", 2: "febrero", 3: "marzo", 4: "abril", 5: "mayo", 6: "junio", 7: "julio",
       8: "agosto", 9: "septiembre", 10: "octubre", 11: "noviembre", 12: "diciembre"}
FAMILY_LABEL = {"agent": "Conversaciones con agentes", "github": "Código (GitHub)", "own": "Dominio propio",
                "video": "Vídeo", "generic": "Otras páginas"}
STATUS_LABEL = {"link_only": "se queda como enlace", "gone": "ya no existe", "pending": "pendiente",
                "pending_browser": "pendiente de navegador", "error": "no recuperado", "blocked": "no público"}
INFRA_COPY = ("sidecar.py", "lib", "tools", "templates", "patches", "README.md")


# ── helpers ──────────────────────────────────────────────────────────────────

def esc(value: str) -> str:
    return html.escape(value or "", quote=True)


def linkify(text: str) -> str:
    """Escapa, convierte URLs en <a> y saltos en <br>. El cuerpo queda verbatim."""
    out: list[str] = []
    for i, line in enumerate(text.split("\n")):
        if i:
            out.append("<br>")
        for j, chunk in enumerate(line.split(" ")):
            if j:
                out.append(" ")
            if chunk.startswith(("http://", "https://")):
                out.append(f'<a href="{esc(chunk)}">{esc(chunk)}</a>')
            else:
                out.append(esc(chunk))
    return "".join(out)


def fmt_dt(created_at: str) -> str:
    return f"{created_at[:10]} · {created_at[11:16]} UTC"


def mes_nombre(month: str) -> str:
    year, mm = month.split("-")
    return f"{MES[int(mm)].capitalize()} {year}"


def excerpt(text: str, limit: int = 110) -> str:
    flat = " ".join(text.split())
    return flat[: limit - 1].rstrip() + "…" if len(flat) > limit else flat


def lang_attr(lang: str) -> str:
    code = LANG_ALIASES.get(lang, lang)
    return f' lang="{code}"' if code in REAL_LANGS else ""


def slugify(tag: str, used: set[str]) -> str:
    raw = "".join(ch if ch.isalnum() else "-" for ch in tag.casefold())
    raw = re.sub(r"-{2,}", "-", raw).strip("-") or "tag"
    slug, n = raw, 2
    while slug in used:
        slug, n = f"{raw}-{n}", n + 1
    used.add(slug)
    return slug


def sync_file(src: Path, dst: Path) -> int:
    if dst.is_file() and dst.stat().st_size == src.stat().st_size:
        return 0
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
    return 1


def sync_tree(src: Path, dst: Path) -> int:
    copied = 0
    for path in sorted(src.rglob("*")):
        if not path.is_file() or path.name == ".DS_Store" or "__pycache__" in path.parts or path.suffix == ".pyc":
            continue
        copied += sync_file(path, dst / path.relative_to(src))
    return copied


# ── markdown → HTML estático (subconjunto que emite html2md; todo escapado) ───

INLINE = re.compile(r"(`[^`]+`|\[[^\]]*\]\([^)\s]+\)|\*\*[^*]+\*\*|\*[^*\s][^*]*\*)")


def md_inline(text: str) -> str:
    out = []
    for part in INLINE.split(text):
        if not part:
            continue
        if part.startswith("`") and part.endswith("`") and len(part) > 1:
            out.append(f"<code>{esc(part[1:-1])}</code>")
        elif part.startswith("[") and "](" in part:
            label, url = part[1:-1].split("](", 1)
            safe = url if url.startswith(("http://", "https://", "/", "mailto:")) else "#"
            out.append(f'<a href="{esc(safe)}">{esc(label) or esc(url)}</a>')
        elif part.startswith("**"):
            out.append(f"<strong>{esc(part[2:-2])}</strong>")
        elif part.startswith("*"):
            out.append(f"<em>{esc(part[1:-1])}</em>")
        else:
            out.append(esc(part))
    return "".join(out)


def md_to_html(markdown: str) -> str:
    out: list[str] = []
    lines = markdown.replace("\r\n", "\n").split("\n")
    i, para = 0, []

    def flush():
        if para:
            out.append("<p>" + "<br>".join(md_inline(p) for p in para) + "</p>")
            para.clear()

    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        fence = re.match(r"^(`{3,})(\S*)\s*$", stripped)
        if fence:
            flush()
            body, i = [], i + 1
            while i < len(lines) and not lines[i].strip().startswith(fence.group(1)):
                body.append(lines[i])
                i += 1
            out.append(f"<pre><code>{esc(chr(10).join(body))}</code></pre>")
            i += 1
            continue
        details = re.match(r"^<details><summary>(.*?)</summary>$", stripped)
        if details:
            flush()
            out.append(f"<details><summary>{esc(details.group(1))}</summary>")
        elif stripped == "</details>":
            flush()
            out.append("</details>")
        elif not stripped:
            flush()
        elif re.match(r"^#{1,6} ", stripped):
            flush()
            level = min(len(stripped) - len(stripped.lstrip("#")) + 1, 6)
            out.append(f"<h{level}>{md_inline(stripped.lstrip('#').strip())}</h{level}>")
        elif stripped in ("---", "***", "___"):
            flush()
            out.append("<hr>")
        elif stripped.startswith(">"):
            flush()
            quote_lines = []
            while i < len(lines) and lines[i].strip().startswith(">"):
                quote_lines.append(lines[i].strip()[1:].lstrip())
                i += 1
            out.append(f"<blockquote>{md_to_html(chr(10).join(quote_lines))}</blockquote>")
            continue
        elif stripped.startswith("|") and i + 1 < len(lines) and re.match(r"^\|?\s*:?-{3,}", lines[i + 1].strip()):
            flush()
            rows = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                rows.append([c.strip() for c in lines[i].strip().strip("|").split("|")])
                i += 1
            head, body = rows[0], rows[2:]
            table = "<tr>" + "".join(f"<th>{md_inline(c)}</th>" for c in head) + "</tr>"
            table += "".join("<tr>" + "".join(f"<td>{md_inline(c)}</td>" for c in r) + "</tr>" for r in body)
            out.append(f'<table class="tbl">{table}</table>')
            continue
        elif re.match(r"^\s*(?:[-*+]|\d+\.) ", line):
            flush()
            items = []
            while i < len(lines) and re.match(r"^\s*(?:[-*+]|\d+\.) ", lines[i]):
                indent = (len(lines[i]) - len(lines[i].lstrip())) // 2
                text = re.sub(r"^\s*(?:[-*+]|\d+\.) ", "", lines[i])
                items.append(f'<li class="li-{min(indent, 4)}">{md_inline(text)}</li>')
                i += 1
            out.append(f"<ul>{''.join(items)}</ul>")
            continue
        else:
            para.append(stripped)
        i += 1
    flush()
    return "\n".join(out)


# ── sitio ────────────────────────────────────────────────────────────────────

class Site:
    def __init__(self, obra: Obra, out: Path):
        self.obra, self.out = obra, out
        self.base, self.title = obra.base, obra.title
        self.records = normalize.records(obra)
        self.by_id = {r["id"]: r for r in self.records}
        self.threads = normalize.threads_of(self.records)
        self.tweets = voices.published(obra)
        self.links = links_lib.load(obra)
        primary = obra.primary()
        self.primary_dir = primary["dir"]
        self.generation = primary["generation"]
        self.n_generations = len(obra.generations())
        self.zip_name = f"{obra.name}.zip"
        self.brain_zip = f"{obra.name}-cerebro.zip"

    # esqueleto
    def nav(self) -> str:
        b = self.base
        return (
            f'<div class="nav-top"><a href="/teatro/">← Teatro</a> · <a href="{b}/">{esc(self.title)}</a>'
            f' · <a href="{b}/cronologia/">Cronología</a> · <a href="{b}/hilos/">Hilos</a>'
            f' · <a href="{b}/hashtags/">Hashtags</a> · <a href="{b}/tipos.html">Tipos</a>'
            f' · <a href="{b}/externos.html">Externos</a> · <a href="{b}/enlaces/">Enlaces</a>'
            f' · <a href="{b}/{self.zip_name}">ZIP ↓</a></div>'
        )

    def footer(self) -> str:
        capas = f" · {self.n_generations} generaciones" if self.n_generations > 1 else ""
        return (
            f'<footer class="footer">{esc(self.title)} · Teatro del Scriptorium · archivo oficial X '
            f"{self.generation}{capas} · texto verbatim · citar por id · "
            f'<a href="{self.base}/AGENTS.md">protocolo</a></footer>'
        )

    def page(self, title: str, body: str, description: str = "") -> str:
        desc = f'\n<meta name="description" content="{esc(description)}">' if description else ""
        return (
            '<!doctype html>\n<html lang="es">\n<head>\n<meta charset="utf-8">\n'
            '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
            f"<title>{esc(title)}</title>{desc}\n"
            '<link rel="icon" type="image/png" sizes="32x32" href="/ico.png">\n'
            f'<link rel="stylesheet" href="{self.base}/assets/obra.css">\n'
            f"</head>\n<body>\n{self.nav()}\n{body}\n{self.footer()}\n</body>\n</html>\n"
        )

    # piezas
    def media_html(self, paths: list[str]) -> str:
        if not paths:
            return ""
        cells = []
        for rel in paths:
            src = f"{self.base}/{quote(rel)}"
            if rel.lower().endswith(".mp4"):
                cells.append(f'<figure><video controls preload="metadata" src="{src}"></video></figure>')
            else:
                cells.append(f'<figure><img src="{src}" alt="" loading="lazy"></figure>')
        return f'<div class="media">{"".join(cells)}</div>'

    def ctx_block(self, label: str, tid: str, depth: int = 1) -> str:
        """Voz ajena. Nunca se inventa el texto que falta. `depth` 1 o 2."""
        node = self.tweets.get(tid) or {}
        who = " ".join(p for p in (node.get("name"), f"@{node['user']}" if node.get("user") else "") if p)
        when = (node.get("created_at") or "")[:10]
        head = f"{esc(label)} · <code>{esc(str(node.get('id') or tid))}</code>"
        head += f" · {esc(who)}" if who else ""
        head += f" · <time>{esc(when)}</time>" if when else ""
        if node.get("url"):
            head += f' · <a href="{esc(node["url"])}">en X</a>'
        status, text = node.get("status"), node.get("text")
        if text:
            body = f"<p>{linkify(text)}</p>"
        elif status in ("ok", "legacy"):
            body = '<p class="no-dispo">Sin texto (solo media).</p>'
        elif status == "unavailable":
            body = '<p class="no-dispo">No disponible en X (borrado, protegido o cuenta ausente).</p>'
        else:
            body = f'<p class="no-dispo">No recuperado (<code>{esc(status or "missing")}</code>).</p>'
        body += self.media_html([m["local"] for m in node.get("media") or [] if m.get("local")])
        inner = ""
        if depth == 1:
            inner = "".join(self.ctx_block(lbl, sub, 2) for lbl, sub in level2_refs(node) if sub in self.tweets)
        return f'<blockquote class="ctx ctx-{depth}"><div class="ctx-who">{head}</div>{inner}{body}</blockquote>'

    def links_block(self, record: dict) -> str:
        rows = []
        for url in record["links"]:
            entry = self.links.get(links_lib.key_of(url)) or {}
            if entry.get("status") == "ok":
                key = links_lib.key_of(url)
                rows.append(
                    f'→ <a href="{self.base}/enlaces/{key}.html">{esc(entry.get("title") or url)}</a>'
                    f' <span class="k">{esc(entry.get("family", ""))}</span> · <a href="{esc(url)}">original</a>'
                )
            else:
                rows.append(f'→ <a href="{esc(url)}">{esc(url)}</a>')
        for tid in record["self_links"]:
            if tid in self.by_id:
                rows.append(f'→ post propio <a href="{self.base}/posts/{tid}.html"><code>{tid}</code></a>')
        return f'<div class="links">{"<br>".join(rows)}</div>' if rows else ""

    def post_html(self, r: dict, full: bool = True) -> str:
        kind, b = r["kind"], self.base
        parts = [
            '<article class="post">', '<div class="post-head">',
            f'<span class="kind kind-{kind}">{esc(KIND_LABEL[kind])}</span>',
            f'<a class="pid" href="{b}/posts/{r["id"]}.html"><code>{r["id"]}</code></a>',
            f"<time>{fmt_dt(r['created_at'])}</time>",
        ]
        members = self.threads.get(r["thread_root"])
        if members:
            pos = next(i for i, m in enumerate(members, start=1) if m["id"] == r["id"])
            parts.append(f'<span class="en-hilo"><a href="{b}/hilos/{r["thread_root"]}.html">hilo {pos}/{len(members)}</a></span>')
        parts.append("</div>")

        refs = voice_refs(r)
        if kind == "retweet":
            if r["id"] in self.tweets:
                parts.append(self.ctx_block("Original", r["id"]))
                parts.append(f'<p class="rt-caption">{linkify(r["text"])}</p>')
            else:
                parts.append(f'<p class="cuerpo"{lang_attr(r["lang"])}>{linkify(r["text"])}</p>')
        else:
            for label, tid in refs:
                if label == "Padre":
                    parts.append(self.ctx_block(label, tid))
            if kind == "self_reply" and r["parent_id"]:
                if r["parent_in_archive"]:
                    parts.append(f'<div class="ficha">En respuesta a <a href="{b}/posts/{r["parent_id"]}.html"><code>{r["parent_id"]}</code></a></div>')
                else:
                    parts.append(f'<div class="ficha">En respuesta a <code>{r["parent_id"]}</code> (no está en el archivo)</div>')
            parts.append(f'<p class="cuerpo"{lang_attr(r["lang"])}>{linkify(r["text"])}</p>')
            for label, tid in refs:
                if label == "Cita":
                    parts.append(self.ctx_block(label, tid))

        parts.append(self.media_html(r["media"]))
        if full:
            parts.append(self.links_block(r))
        if r["hashtags"]:
            tags = "".join(f'<a href="{b}/hashtags/{quote(self.tag_slugs[t])}.html">#{esc(t)}</a>' for t in r["hashtags"])
            parts.append(f'<div class="tags">{tags}</div>')
        parts.append("</article>")
        return "\n".join(p for p in parts if p)

    def fila(self, r: dict) -> str:
        return (
            f'<div class="fila"><time>{r["created_at"][:10]}</time> <span class="k">{esc(KIND_LABEL[r["kind"]])}</span> '
            f'<a href="{self.base}/posts/{r["id"]}.html">{esc(excerpt(r["text"]) or r["id"])}</a></div>'
        )

    # build
    def build(self) -> dict:
        out, b, records, threads = self.out, self.base, self.records, self.threads
        by_month = defaultdict(list)
        for r in records:
            by_month[r["created_at"][:7]].append(r)
        months = sorted(by_month)
        tag_ids = defaultdict(list)
        for r in records:
            for tag in r["hashtags"]:
                tag_ids[tag].append(r["id"])
        used: set[str] = set()
        self.tag_slugs = {t: slugify(t, used) for t in sorted(tag_ids, key=lambda t: (t.casefold(), t))}

        self.portada(months, tag_ids)

        # cronología
        filas = "".join(
            f'<tr><td><a href="{b}/cronologia/{m}.html">{esc(mes_nombre(m))}</a></td><td class="num">{len(by_month[m])}</td></tr>'
            for m in months)
        write_text(out / "cronologia" / "index.html", self.page(
            f"Cronología · {self.title}",
            '<h2 class="acto">Cronología · los actos</h2>'
            '<div class="acto-sub">Un acto por mes con posts. Texto y media completos, en orden.</div>'
            f'<table class="tbl"><tr><th>Acto</th><th>Posts</th></tr>{filas}</table>'))
        for i, month in enumerate(months):
            items = by_month[month]
            prev_ = f'<a href="{b}/cronologia/{months[i-1]}.html">← {esc(mes_nombre(months[i-1]))}</a>' if i else "<span></span>"
            next_ = f'<a href="{b}/cronologia/{months[i+1]}.html">{esc(mes_nombre(months[i+1]))} →</a>' if i + 1 < len(months) else "<span></span>"
            pn = f'<div class="pn">{prev_}{next_}</div>'
            body = (f'<h2 class="acto">{esc(mes_nombre(month))}</h2>'
                    f'<div class="acto-sub">{len(items)} posts · <a href="{b}/cronologia/">todos los actos</a></div>'
                    + pn + "\n".join(self.post_html(r) for r in items) + pn)
            write_text(out / "cronologia" / f"{month}.html", self.page(f"{mes_nombre(month)} · {self.title}", body))

        # hilos
        thread_items = sorted((m[0]["created_at"], root, m) for root, m in threads.items())
        filas = "".join(
            f'<div class="fila"><time>{c[:10]}</time> <span class="k">{len(m)} posts</span> '
            f'<a href="{b}/hilos/{root}.html">{esc(excerpt(self.by_id[root]["text"]) or root)}</a></div>'
            for c, root, m in thread_items)
        write_text(out / "hilos" / "index.html", self.page(
            f"Hilos · {self.title}",
            f'<h2 class="acto">Hilos · las escenas</h2><div class="acto-sub">{len(threads)} cadenas de dos o más posts propios.</div>'
            f'<div class="listado">{filas}</div>'))
        for created_at, root, members in thread_items:
            body = (f'<h2 class="acto">Hilo · {created_at[:10]}</h2>'
                    f'<div class="acto-sub">{len(members)} posts · raíz <code>{root}</code> · <a href="{b}/hilos/">todas las escenas</a></div>'
                    + "\n".join(self.post_html(r) for r in members))
            write_text(out / "hilos" / f"{root}.html", self.page(f"Hilo {root} · {self.title}", body))

        # hashtags
        filas = "".join(
            f'<tr><td><a href="{b}/hashtags/{quote(s)}.html">#{esc(t)}</a></td><td class="num">{len(set(tag_ids[t]))}</td></tr>'
            for t, s in self.tag_slugs.items())
        write_text(out / "hashtags" / "index.html", self.page(
            f"Hashtags · {self.title}",
            '<h2 class="acto">Hashtags</h2><div class="acto-sub">Solo las etiquetas del archivo; ninguna inferida.</div>'
            f'<table class="tbl"><tr><th>Etiqueta</th><th>Posts</th></tr>{filas}</table>'))
        for tag, slug in self.tag_slugs.items():
            items = sorted((self.by_id[i] for i in set(tag_ids[tag])), key=lambda r: (r["created_at"], r["id"]))
            write_text(out / "hashtags" / f"{slug}.html", self.page(
                f"#{tag} · {self.title}",
                f'<h2 class="acto">#{esc(tag)}</h2><div class="acto-sub">{len(items)} posts · <a href="{b}/hashtags/">todas las etiquetas</a></div>'
                f'<div class="listado">{"".join(self.fila(r) for r in items)}</div>'))

        # tipos
        secciones = "".join(
            f'<h2 class="acto">{esc(KIND_LABEL[k])} · {k} ({sum(1 for r in records if r["kind"] == k)})</h2>'
            f'<div class="listado">{"".join(self.fila(r) for r in records if r["kind"] == k)}</div>'
            for k in normalize.KINDS)
        write_text(out / "tipos.html", self.page(
            f"Tipos · {self.title}", '<div class="acto-sub">Partición mecánica por campos, no por juicio.</div>' + secciones))

        self.externos()
        n_link_pages = self.enlaces()

        # permalinks
        for r in records:
            members = threads.get(r["thread_root"])
            extra = [
                f'<div class="ficha">Fuente verbatim: <a href="{b}/corpus/posts/{r["id"]}.md">corpus/posts/{r["id"]}.md</a>'
                f' · <a href="https://x.com/{esc(self.obra.handle)}/status/{r["id"]}">en X</a>'
                f' · acto <a href="{b}/cronologia/{r["created_at"][:7]}.html">{esc(mes_nombre(r["created_at"][:7]))}</a>'
            ]
            if members:
                idx = next(i for i, m in enumerate(members) if m["id"] == r["id"])
                extra.append(f'<br>Escena: <a href="{b}/hilos/{r["thread_root"]}.html">hilo completo</a>')
                if idx:
                    extra.append(f' · <a href="{b}/posts/{members[idx-1]["id"]}.html">← anterior</a>')
                if idx + 1 < len(members):
                    extra.append(f' · <a href="{b}/posts/{members[idx+1]["id"]}.html">siguiente →</a>')
            extra.append("</div>")
            write_text(out / "posts" / f"{r['id']}.html", self.page(
                f"{r['id']} · {self.title}", self.post_html(r) + "".join(extra), excerpt(r["text"], 150)))
        for stale in (out / "posts").glob("*.html"):
            if stale.stem not in self.by_id:
                stale.unlink()

        copied = self.payload()
        n_pages = sum(1 for _ in out.rglob("*.html"))
        stats = {"pages": n_pages, "posts": len(records), "months": len(months), "threads": len(threads),
                 "tags": len(self.tag_slugs), "voices": len(self.tweets), "link_pages": n_link_pages, "copied": copied}
        print("site build ok ·", " · ".join(f"{k}: {v}" for k, v in stats.items()))
        return stats

    def portada(self, months, tag_ids) -> None:
        b, records = self.base, self.records
        data_dir = self.primary_dir / "data"
        profile = (ytd.parse_ytd(data_dir, "profile", required=False) or [{}])[0].get("profile", {})
        account = (ytd.parse_ytd(data_dir, "account", required=False) or [{}])[0].get("account", {})
        media_files = sorted((data_dir / "profile_media").glob("*")) if (data_dir / "profile_media").is_dir() else []

        def pick(url: str | None):
            stem = Path((url or "").split("?")[0]).stem
            return next((p for p in media_files if stem and stem in p.name), None)

        avatar, banner = pick(profile.get("avatarMediaUrl")), pick(profile.get("headerMediaUrl"))
        n_media = sum(len(r["media"]) for r in records)
        n_conv = sum(1 for e in self.links.values() if e.get("status") == "ok" and (e.get("family") or "").startswith("agent:"))
        n_links = sum(1 for e in self.links.values() if e.get("status") == "ok")
        span = f"de {months[0]} a {months[-1]}" if months else ""
        stats = "".join(
            f'<div class="stat"><span class="val">{v}</span><span class="lbl">{lbl}</span></div>'
            for v, lbl in ((len(records), "posts"), (n_media, "media"), (len(self.threads), "hilos"),
                           (len(tag_ids), "hashtags"), (len(self.tweets), "voces ajenas"), (n_links, "enlaces")))
        puertas = [
            ("Cronología", f"Los actos: la obra mes a mes, {span}, texto y media completos.", f"{b}/cronologia/"),
            ("Hilos", f"{len(self.threads)} escenas: cadenas de dos o más posts propios, en orden.", f"{b}/hilos/"),
            ("Enlaces", f"{n_links} páginas enlazadas traídas a Markdown; {n_conv} son conversaciones con agentes.", f"{b}/enlaces/"),
            ("Externos", "Las voces ajenas: originales de RT, padres de réplicas y tuits citados, a dos niveles.", f"{b}/externos.html"),
            ("Hashtags", f"{len(tag_ids)} etiquetas del archivo. Solo estas; ninguna inferida.", f"{b}/hashtags/"),
            ("Tipos", "Partición mecánica: original, hilo, réplica, RT.", f"{b}/tipos.html"),
            ("Segundo cerebro", "El corpus Markdown crudo: protocolo, posts, voces, enlaces e índices, tal cual.", f"{b}/AGENTS.md"),
        ]
        if self.obra.publish["viewer"]:
            puertas.append(("Navegador", "El visor del archivo, limpio y sin CDNs: línea de tiempo con búsqueda. Requiere JavaScript.", f"{b}/navegador.html"))
        puertas_html = "".join(
            f'<div class="puerta"><div class="p-title">{esc(t)}</div><div class="p-copy">{esc(c)}</div>'
            f'<a class="door-link" href="{u}">Entrar →</a></div>' for t, c, u in puertas)
        z, c = self.zip_name, self.brain_zip
        descarga = (
            '<div class="descarga"><div class="descarga-main">'
            f'<div class="p-title">Descargar la obra completa</div>'
            f'<div class="p-copy">Todo en un zip: páginas, corpus, índices y <b>toda la media</b>. Es la copia íntegra de la obra.</div>'
            f'<a class="door-link door-main" href="{b}/{z}">Descargar {esc(z)} ↓</a>'
            f'<div class="ficha">SHA-256 de <code>{esc(z)}</code>:<br><code>__ZIP_SHA256__</code><br>'
            f'Comprobar: <code>sha256sum -c {esc(z)}.sha256</code> junto a <a href="{b}/{z}.sha256">{esc(z)}.sha256</a><br>'
            f'Firmado con la clave ed25519 del VPS: <a href="{b}/{z}.sha256.sig">firma</a> · <a href="{b}/allowed_signers">allowed_signers</a><br>'
            f'Verificar: <code>ssh-keygen -Y verify -f allowed_signers -I teatro@escrivivir.co -n file -s {esc(z)}.sha256.sig &lt; {esc(z)}.sha256</code></div>'
            '</div><div class="descarga-aux"><b>Para inspección o gestión</b> (no es la obra completa): '
            f'<a href="{b}/{c}">{esc(c)}</a> — solo texto, índices y herramientas, sin media · '
            f'<a href="{b}/{c}.sha256">sha256</a> · <a href="{b}/{c}.sha256.sig">firma</a><br>'
            f'<a href="{b}/MANIFEST.sha256">MANIFEST.sha256</a> — hash de cada fichero servido · <a href="{b}/MANIFEST.sha256.sig">firma</a></div></div>'
        )
        name = account.get("accountDisplayName") or self.obra.account.get("name") or self.obra.handle
        portada = (
            f'<header class="header"><div class="stamp">{esc(self.obra.cfg.get("stamp") or "Obra")}</div><h1>{esc(self.title)}</h1>'
            '<div class="sub">Teatro del Scriptorium</div>'
            f'<div class="sub2">{esc(self.obra.cfg.get("tagline") or "El archivo de una cuenta como pieza en actos, escenas y apartes.")}</div>'
            f'<div class="issue">TEATRO · {self.generation[:4]}</div></header><div class="washi"></div>'
            + (f'<div class="banner"><img src="{b}/data/profile_media/{quote(banner.name)}" alt="Cabecera del perfil"></div>' if banner else "")
            + '<div class="perfil">'
            + (f'<img class="avatar" src="{b}/data/profile_media/{quote(avatar.name)}" alt="Avatar">' if avatar else "")
            + f'<div class="quien"><div class="nombre">{esc(name)}</div>'
            f'<div class="arroba">@{esc(self.obra.handle)} · en X desde {esc((account.get("createdAt") or "")[:10])}</div>'
            f'<div class="bio">{linkify((profile.get("description") or {}).get("bio", ""))}</div>'
            f'<div class="meta">{esc((profile.get("description") or {}).get("location") or "")}</div></div></div>'
            + f'<div class="stats-bar">{stats}</div>'
            + '<div class="callout">Texto verbatim · citar por id · nada inventado</div>'
            + descarga
            + f'<div class="puertas">{puertas_html}</div>'
        )
        write_text(self.out / "index.html", self.page(
            f"{self.title} · Teatro del Scriptorium", portada,
            f"{self.title}: el archivo de @{self.obra.handle} como obra estática. {len(records)} posts, hilos, voces ajenas, enlaces y media."))

    def externos(self) -> None:
        b = self.base
        groups = {1: [], 2: []}
        for tid, node in sorted(self.tweets.items()):
            groups[2 if node.get("level") == 2 else 1].append((tid, node))
        secciones = []
        for level, label in ((1, "Nivel 1 · originales de RT, padres de réplicas y tuits citados"),
                             (2, "Nivel 2 · el padre o el citado de una voz de nivel 1")):
            filas = "".join(
                f'<div class="fila"><code>{tid}</code> @{esc(n.get("user") or "?")} · {esc(n.get("status") or "unknown")}'
                f' · <time>{esc((n.get("created_at") or "")[:10])}</time> · <a href="{b}/corpus/external/{tid}.md">md</a>'
                f' · {esc(excerpt(n.get("text") or "", 90))}</div>' for tid, n in groups[level])
            secciones.append(f'<h2 class="acto">{label} ({len(groups[level])})</h2><div class="listado">{filas}</div>')
        write_text(self.out / "externos.html", self.page(
            f"Externos · {self.title}",
            '<div class="acto-sub">Voces ajenas tal como se recuperaron. Lo no recuperado no se completa.</div>' + "".join(secciones)))

    def enlaces(self) -> int:
        b, out = self.base, self.out / "enlaces"
        groups: dict[str, list[tuple[str, dict]]] = defaultdict(list)
        for key, entry in self.links.items():
            groups[(entry.get("family") or "generic").split(":")[0]].append((key, entry))
        written = 0
        secciones = []
        for group in ("agent", "own", "github", "generic", "video"):
            items = sorted(groups.get(group, []), key=lambda kv: (kv[1].get("title") or kv[1]["url"]).casefold())
            if not items:
                continue
            filas = []
            for key, entry in items:
                cited = " ".join(f'<a href="{b}/posts/{t}.html"><code>{t}</code></a>' for t in (entry.get("cited_by") or [])[:4] if t in self.by_id)
                if entry.get("status") == "ok":
                    title = f'<a href="{b}/enlaces/{key}.html">{esc(entry.get("title") or entry["url"])}</a>'
                else:
                    label = STATUS_LABEL.get(entry.get("status") or "pending", entry.get("status") or "pendiente")
                    title = f'<a href="{esc(entry["url"])}">{esc(entry["url"])}</a> <span class="no-dispo">({esc(label)})</span>'
                filas.append(f'<div class="fila"><span class="k">{esc(entry.get("family", ""))}</span> {title} · citado en {cited}</div>')
            secciones.append(f'<h2 class="acto">{esc(FAMILY_LABEL[group])} ({len(items)})</h2><div class="listado">{"".join(filas)}</div>')
        write_text(out / "index.html", self.page(
            f"Enlaces · {self.title}",
            '<div class="acto-sub">Cada página enlazada desde un post propio, traída a Markdown tal como estaba el día de la recuperación.</div>'
            + "".join(secciones)))
        for key, entry in self.links.items():
            source = links_lib.md_path(self.obra, key)
            if entry.get("status") != "ok" or not source.is_file():
                continue
            cited = " · ".join(f'<a href="{b}/posts/{t}.html"><code>{t}</code></a>' for t in entry.get("cited_by") or [] if t in self.by_id)
            head = (
                f'<h2 class="acto">{esc(entry.get("title") or entry["url"])}</h2>'
                f'<div class="acto-sub">{esc(entry.get("family", ""))} · recuperado {esc((entry.get("fetched_at") or "")[:10])} '
                f'({esc(entry.get("method") or "")}) · <a href="{esc(entry["url"])}">original</a> · '
                + (f'<a href="{esc(entry["public_url"])}">enlace público</a> · ' if entry.get("public_url") else "") +
                f'<a href="{b}/corpus/links/{key}.md">md</a></div>'
                f'<div class="ficha">Citado en: {cited or "—"}</div>'
            )
            write_text(out / f"{key}.html", self.page(
                f"{entry.get('title') or 'Enlace'} · {self.title}",
                head + f'<article class="doc">{md_to_html(source.read_text(encoding="utf-8"))}</article>'))
            written += 1
        for stale in out.glob("*.html"):
            if stale.stem != "index" and (self.links.get(stale.stem) or {}).get("status") != "ok":
                stale.unlink()
        return written

    def payload(self) -> int:
        out, obra = self.out, self.obra
        copied = sync_file(sidecar_dir() / "templates" / "obra.css", out / "assets" / "obra.css")
        # media de los posts VISIBLES (de cualquier generación); lo demás se poda
        wanted: dict[str, Path] = {}
        for r in self.records:
            for rel, src in zip(r["media"], r["media_src"]):
                wanted[Path(rel).name] = Path(src)
        media_out = out / "data" / "tweets_media"
        media_out.mkdir(parents=True, exist_ok=True)
        for name, src in wanted.items():
            copied += sync_file(src, media_out / name)
        for stale in media_out.iterdir():
            if stale.is_file() and stale.name not in wanted:
                stale.unlink()
        profile_src = self.primary_dir / "data" / "profile_media"
        if profile_src.is_dir():
            copied += sync_tree(profile_src, out / "data" / "profile_media")
        ext_src = obra.cache_dir / "media_ext"
        if ext_src.is_dir() and obra.publish["external_media"] == "local":
            copied += sync_tree(ext_src, out / "data" / "external_media")
        # segundo cerebro: stores públicos + infra + protocolo de agentes
        for name in BRAIN_DATA:
            src = obra.store_dir / name
            if src.is_file():
                copied += sync_file(src, out / "data" / name)
        for name in INFRA_COPY:
            src = sidecar_dir() / name
            if src.is_dir():
                copied += sync_tree(src, out / "tools" / name)
            elif src.is_file():
                copied += sync_file(src, out / "tools" / name)
        manifest = read_manifest(self.primary_dir)
        agents = (sidecar_dir() / "AGENTS.md").read_text(encoding="utf-8")
        agents = (agents.replace("{handle}", obra.handle).replace("{title}", self.title)
                  .replace("{n_posts}", str(len(self.records))).replace("{generation}", self.generation)
                  .replace("{n_generations}", str(self.n_generations))
                  .replace("{archive_size}", str((manifest.get("archiveInfo") or {}).get("sizeBytes", ""))))
        write_text(out / "AGENTS.md", agents)
        return copied


def build(obra: Obra, out: Path) -> dict:
    return Site(obra, out).build()
