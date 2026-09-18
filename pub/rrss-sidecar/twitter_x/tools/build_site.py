#!/usr/bin/env python3
"""Build the static, zero-JS site "Aleph Cero" (Teatro · pub.escrivivir.co).

Canonical source: data/tweets.js (same as build_corpus.py, whose helpers we reuse).
Copies media and the Markdown second brain verbatim next to the generated HTML.
Publishes NOTHING else from data/ (the raw archive stays private).

Usage: python3 tools/build_site.py [--out DIR]
"""

from __future__ import annotations

import argparse
import html
import json
import shutil
import sys
from collections import defaultdict
from pathlib import Path
from urllib.parse import quote

from build_corpus import (
    OWN_ID,
    EXPECTED_POSTS,
    classify,
    index_media,
    load_external,
    lookup_external,
    parse_tweets_js,
    parse_twitter_date,
    repo_root,
    thread_root_of,
    write_text,
)

BASE = "/teatro/aleph-cero"
HANDLE = "_dev_aleph_1"

KIND_LABEL = {
    "original": "original",
    "self_reply": "hilo",
    "reply_to_other": "réplica",
    "retweet": "RT",
}

# Real ISO language codes observed in the corpus (pseudo-codes like zxx/qme/und
# and qst/art must not reach the HTML lang attribute).
REAL_LANGS = {
    "es", "en", "ca", "eu", "it", "pt", "fr", "de", "fi", "sv",
    "tr", "zh", "lt", "tl", "ht",
}
LANG_ALIASES = {"in": "id"}

MES = {
    1: "enero", 2: "febrero", 3: "marzo", 4: "abril", 5: "mayo", 6: "junio",
    7: "julio", 8: "agosto", 9: "septiembre", 10: "octubre", 11: "noviembre",
    12: "diciembre",
}

# Verbatim second brain payload (also the contents of the downloadable zip).
BRAIN_DIRS = ("corpus", "indexes", "tools")
BRAIN_FILES = ("AGENTS.md", "second-brain.md")
BRAIN_DATA = ("external_tweets.json", "external_worklist.json")
MEDIA_DIRS = ("tweets_media", "profile_media")

# data/ que el navegador anexo (build_viewer.py) puede publicar. Nada más.
VIEWER_DATA = (
    "manifest.js",
    "README.txt",
    "tweets.js",
    "tweet-headers.js",
    "account.js",
    "profile.js",
    "verified.js",
    "verified-organization.js",
    "screen-name-change.js",
)


# ── helpers ──────────────────────────────────────────────────────────────────

def esc(value: str) -> str:
    return html.escape(value, quote=True)


def linkify(text: str) -> str:
    """Escape, turn URLs into <a> and newlines into <br>. Body stays verbatim."""
    out: list[str] = []
    for i, line in enumerate(text.split("\n")):
        if i:
            out.append("<br>")
        for j, chunk in enumerate(line.split(" ")):
            if j:
                out.append(" ")
            if chunk.startswith("http://") or chunk.startswith("https://"):
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
    if len(flat) > limit:
        flat = flat[: limit - 1].rstrip() + "…"
    return flat


def lang_attr(lang: str) -> str:
    code = LANG_ALIASES.get(lang, lang)
    return f' lang="{code}"' if code in REAL_LANGS else ""


def slugify(tag: str, used: set[str]) -> str:
    raw = "".join(ch if ch.isalnum() else "-" for ch in tag.casefold())
    while "--" in raw:
        raw = raw.replace("--", "-")
    base = raw.strip("-") or "tag"
    slug, n = base, 2
    while slug in used:
        slug = f"{base}-{n}"
        n += 1
    used.add(slug)
    return slug


def parse_ytd(path: Path, name: str):
    prefix = f"window.YTD.{name}.part0 ="
    text = path.read_text(encoding="utf-8")
    if text.startswith("﻿"):
        text = text[1:]
    idx = text.find(prefix)
    if idx < 0:
        raise SystemExit(f"missing `{prefix}` wrapper in {path}")
    payload = text[idx + len(prefix):].strip().rstrip(";")
    return json.loads(payload)


def sync_tree(src: Path, dst: Path) -> int:
    """Copy src into dst, skipping files whose size already matches."""
    copied = 0
    for path in sorted(src.rglob("*")):
        if not path.is_file() or path.name == ".DS_Store":
            continue
        rel = path.relative_to(src)
        target = dst / rel
        if target.is_file() and target.stat().st_size == path.stat().st_size:
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, target)
        copied += 1
    return copied


# ── page skeleton ────────────────────────────────────────────────────────────

NAV = (
    f'<div class="nav-top"><a href="/teatro/">← Teatro</a>'
    f' · <a href="{BASE}/">Aleph Cero</a>'
    f' · <a href="{BASE}/cronologia/">Cronología</a>'
    f' · <a href="{BASE}/hilos/">Hilos</a>'
    f' · <a href="{BASE}/hashtags/">Hashtags</a>'
    f' · <a href="{BASE}/tipos.html">Tipos</a>'
    f' · <a href="{BASE}/externos.html">Externos</a>'
    f' · <a href="{BASE}/aleph-cero.zip">ZIP ↓</a></div>'
)

FOOTER = (
    '<footer class="footer">Aleph Cero · Teatro del Scriptorium · '
    'archivo oficial X 2026-08-21 · texto verbatim · citar por id · '
    f'<a href="{BASE}/AGENTS.md">protocolo</a></footer>'
)


def page(title: str, body: str, description: str = "") -> str:
    desc = f'\n<meta name="description" content="{esc(description)}">' if description else ""
    return (
        "<!doctype html>\n"
        '<html lang="es">\n<head>\n<meta charset="utf-8">\n'
        '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
        f"<title>{esc(title)}</title>{desc}\n"
        '<link rel="icon" type="image/png" sizes="32x32" href="/ico.png">\n'
        f'<link rel="stylesheet" href="{BASE}/assets/obra.css">\n'
        f"</head>\n<body>\n{NAV}\n{body}\n{FOOTER}\n</body>\n</html>\n"
    )


# ── post rendering ───────────────────────────────────────────────────────────

def media_html(paths: list[str]) -> str:
    if not paths:
        return ""
    cells = []
    for rel in paths:
        src = f"{BASE}/{quote(rel)}"
        if rel.lower().endswith(".mp4"):
            cells.append(
                f'<figure><video controls preload="metadata" src="{src}"></video></figure>'
            )
        else:
            cells.append(f'<figure><img src="{src}" alt="" loading="lazy"></figure>')
    return f'<div class="media">{"".join(cells)}</div>'


def ctx_quote(kind: str, fetched: dict) -> str:
    """Third-party voice (Padre/Original). Never invent missing text."""
    label = "Padre" if kind == "reply_to_other" else "Original"
    tid = fetched.get("final_id") or fetched.get("requested_id") or ""
    who = " ".join(
        part
        for part in (fetched.get("name"), f"@{fetched['user']}" if fetched.get("user") else "")
        if part
    )
    head = f"{label} · <code>{esc(tid)}</code>" + (f" · {esc(who)}" if who else "")
    status = fetched.get("status")
    text = fetched.get("text")
    if status == "ok" and text:
        body = f"<p{lang_attr('')}>{linkify(text)}</p>"
    elif status == "ok":
        body = '<p class="no-dispo">Sin texto (solo media).</p>'
    elif status == "unavailable":
        body = '<p class="no-dispo">No disponible en X (borrado, protegido o cuenta ausente).</p>'
    else:
        body = f'<p class="no-dispo">No recuperado (<code>{esc(status or "missing")}</code>).</p>'
    return (
        f'<blockquote class="ctx"><div class="ctx-who">{head}</div>{body}</blockquote>'
    )


def post_html(r: dict, threads: dict[str, list[dict]], full: bool = True) -> str:
    """One post as an article. Text verbatim; RT shows the Original as main voice."""
    kind = r["kind"]
    parts = [
        '<article class="post">',
        '<div class="post-head">',
        f'<span class="kind kind-{kind}">{esc(KIND_LABEL[kind])}</span>',
        f'<a class="pid" href="{BASE}/posts/{r["id"]}.html"><code>{r["id"]}</code></a>',
        f"<time>{fmt_dt(r['created_at'])}</time>",
    ]
    members = threads.get(r["thread_root"])
    if members:
        pos = next(i for i, m in enumerate(members, start=1) if m["id"] == r["id"])
        parts.append(
            f'<span class="en-hilo"><a href="{BASE}/hilos/{r["thread_root"]}.html">'
            f"hilo {pos}/{len(members)}</a></span>"
        )
    parts.append("</div>")

    if kind == "retweet":
        if r["fetched"]:
            parts.append(ctx_quote(kind, r["fetched"]))
            parts.append(f'<p class="rt-caption">{linkify(r["full_text"])}</p>')
        else:
            parts.append(f'<p class="cuerpo"{lang_attr(r["lang"])}>{linkify(r["full_text"])}</p>')
    else:
        if kind == "reply_to_other" and r["fetched"]:
            parts.append(ctx_quote(kind, r["fetched"]))
        elif kind == "self_reply" and r["in_reply_to"]:
            if r["parent_in_archive"]:
                parts.append(
                    f'<div class="ficha">En respuesta a '
                    f'<a href="{BASE}/posts/{r["in_reply_to"]}.html"><code>{r["in_reply_to"]}</code></a></div>'
                )
            else:
                parts.append(
                    f'<div class="ficha">En respuesta a <code>{r["in_reply_to"]}</code>'
                    " (no está en el archivo)</div>"
                )
        parts.append(f'<p class="cuerpo"{lang_attr(r["lang"])}>{linkify(r["full_text"])}</p>')

    parts.append(media_html(r["media"]))

    if full and r["urls"]:
        links = "<br>".join(f'→ <a href="{esc(u)}">{esc(u)}</a>' for u in r["urls"])
        parts.append(f'<div class="links">{links}</div>')
    if r["hashtags"]:
        tags = "".join(
            f'<a href="{BASE}/hashtags/{quote(r["tag_slugs"][t])}.html">#{esc(t)}</a>'
            for t in r["hashtags"]
        )
        parts.append(f'<div class="tags">{tags}</div>')
    parts.append("</article>")
    return "\n".join(parts)


def fila(r: dict) -> str:
    return (
        f'<div class="fila"><time>{r["created_at"][:10]}</time> '
        f'<span class="k">{esc(KIND_LABEL[r["kind"]])}</span> '
        f'<a href="{BASE}/posts/{r["id"]}.html">{esc(excerpt(r["full_text"]) or r["id"])}</a></div>'
    )


# ── main build ───────────────────────────────────────────────────────────────

def build_records(root: Path):
    tweets = parse_tweets_js(root / "data" / "tweets.js")
    if len(tweets) != EXPECTED_POSTS:
        raise SystemExit(f"expected {EXPECTED_POSTS} tweets, got {len(tweets)}")
    tweets_by_id = {t["id_str"]: t for t in tweets}
    media_by_id = index_media(root / "data" / "tweets_media")
    external = load_external(root / "data" / "external_tweets.json")

    records = []
    for tweet in tweets:
        tweet_id = tweet["id_str"]
        parent_id = tweet.get("in_reply_to_status_id_str") or None
        kind = classify(tweet)
        fetched_id = parent_id if kind == "reply_to_other" else (
            tweet_id if kind == "retweet" else None
        )
        urls, seen_urls = [], set()
        for url_obj in (tweet.get("entities") or {}).get("urls") or []:
            expanded = url_obj.get("expanded_url")
            if expanded and expanded not in seen_urls:
                seen_urls.add(expanded)
                urls.append(expanded)
        hashtags, seen_tags = [], set()
        for tag_obj in (tweet.get("entities") or {}).get("hashtags") or []:
            text = tag_obj.get("text")
            if text and text not in seen_tags:
                seen_tags.add(text)
                hashtags.append(text)
        records.append(
            {
                "id": tweet_id,
                "created_at": parse_twitter_date(tweet["created_at"]),
                "lang": tweet.get("lang") or "und",
                "in_reply_to": parent_id,
                "parent_in_archive": bool(parent_id) and parent_id in tweets_by_id,
                "thread_root": thread_root_of(tweet_id, tweets_by_id),
                "kind": kind,
                "media": list(media_by_id.get(tweet_id, [])),
                "urls": urls,
                "hashtags": hashtags,
                "full_text": html.unescape(tweet["full_text"]),
                "fetched": lookup_external(external, fetched_id),
            }
        )
    records.sort(key=lambda r: (r["created_at"], r["id"]))
    return records, external


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    default_out = repo_root().parent.parent / "deploy" / "teatro" / "aleph-cero"
    parser.add_argument("--out", type=Path, default=default_out)
    args = parser.parse_args()

    root = repo_root()
    out: Path = args.out
    records, external = build_records(root)
    by_id = {r["id"]: r for r in records}

    threads = defaultdict(list)
    for r in records:
        threads[r["thread_root"]].append(r)
    threads = {k: v for k, v in threads.items() if len(v) >= 2}
    for members in threads.values():
        members.sort(key=lambda r: (r["created_at"], r["id"]))

    by_month = defaultdict(list)
    for r in records:
        by_month[r["created_at"][:7]].append(r)
    months = sorted(by_month)

    tag_ids = defaultdict(list)
    for r in records:
        for tag in r["hashtags"]:
            tag_ids[tag].append(r["id"])
    used_slugs: set[str] = set()
    tag_slugs = {
        tag: slugify(tag, used_slugs)
        for tag in sorted(tag_ids, key=lambda t: (t.casefold(), t))
    }
    for r in records:
        r["tag_slugs"] = tag_slugs

    profile = parse_ytd(root / "data" / "profile.js", "profile")[0]["profile"]
    account = parse_ytd(root / "data" / "account.js", "account")[0]["account"]
    profile_media = sorted((root / "data" / "profile_media").glob("*"))
    avatar = next((p for p in profile_media if "boVLdbGq" in p.name), None)
    banner = next((p for p in profile_media if p != avatar), None)

    n_media = sum(len(r["media"]) for r in records)

    # ── portada ──
    stats = (
        f'<div class="stats-bar">'
        f'<div class="stat"><span class="val">{len(records)}</span><span class="lbl">posts</span></div>'
        f'<div class="stat"><span class="val">{n_media}</span><span class="lbl">media</span></div>'
        f'<div class="stat"><span class="val">{len(threads)}</span><span class="lbl">hilos</span></div>'
        f'<div class="stat"><span class="val">{len(tag_ids)}</span><span class="lbl">hashtags</span></div>'
        f'<div class="stat"><span class="val">{len((external.get("tweets") or {}))}</span><span class="lbl">voces ajenas</span></div>'
        f"</div>"
    )
    bio = profile.get("description", {}).get("bio", "")
    puertas = [
        ("Cronología", "Los actos: la obra mes a mes, de 2024-06 a 2026-07, texto y media completos.", f"{BASE}/cronologia/"),
        ("Hilos", f"{len(threads)} escenas: cadenas de dos o más posts propios, en orden.", f"{BASE}/hilos/"),
        ("Hashtags", f"{len(tag_ids)} etiquetas del archivo. Solo estas; ninguna inferida.", f"{BASE}/hashtags/"),
        ("Tipos", "Partición mecánica: original, hilo, réplica, RT.", f"{BASE}/tipos.html"),
        ("Externos", "Las voces ajenas recuperadas: padres de réplicas y originales de RT.", f"{BASE}/externos.html"),
        ("Navegador", "El visor del archivo, limpio y sin CDNs: línea de tiempo con búsqueda. Requiere JavaScript.", f"{BASE}/navegador.html"),
        ("Segundo cerebro", "El corpus Markdown crudo: protocolo, posts e índices, tal cual.", f"{BASE}/AGENTS.md"),
        ("Descargar", "La obra completa en un zip: corpus, índices y media.", f"{BASE}/aleph-cero.zip"),
    ]
    puertas_html = "".join(
        f'<div class="puerta"><div class="p-title">{esc(t)}</div>'
        f'<div class="p-copy">{esc(c)}</div><a class="door-link" href="{u}">Entrar →</a></div>'
        for t, c, u in puertas
    )
    portada = (
        '<header class="header"><div class="stamp">Obra Nº 1</div>'
        "<h1>Aleph Cero</h1>"
        '<div class="sub">Teatro del Scriptorium</div>'
        '<div class="sub2">El archivo de una cuenta como pieza en actos, escenas y apartes.</div>'
        f'<div class="issue">PUB.ESCRIVIVIR.CO · TEATRO · 2026</div></header>'
        '<div class="washi"></div>'
        + (f'<div class="banner"><img src="{BASE}/data/profile_media/{quote(banner.name)}" alt="Cabecera del perfil"></div>' if banner else "")
        + '<div class="perfil">'
        + (f'<img class="avatar" src="{BASE}/data/profile_media/{quote(avatar.name)}" alt="Avatar">' if avatar else "")
        + f'<div class="quien"><div class="nombre">αlephillΩ</div>'
        f'<div class="arroba">@{esc(account["username"])} · en X desde {account["createdAt"][:10]}</div>'
        f'<div class="bio">{linkify(bio)}</div>'
        f'<div class="meta">{esc(profile.get("location") or "")}</div></div></div>'
        + stats
        + '<div class="callout">Texto verbatim · citar por id · nada inventado</div>'
        + f'<div class="puertas">{puertas_html}</div>'
        # __ZIP_SHA256__ lo sustituye deploy-teatro.sh tras generar el zip en el VPS.
        + '<div class="ficha"><b>Descarga íntegra.</b> '
        'SHA-256 de <code>aleph-cero.zip</code>:<br><code>__ZIP_SHA256__</code><br>'
        f'Comprobar: <code>sha256sum -c aleph-cero.zip.sha256</code> junto a '
        f'<a href="{BASE}/aleph-cero.zip.sha256">aleph-cero.zip.sha256</a><br>'
        f'Firmado con la clave ed25519 del VPS: '
        f'<a href="{BASE}/aleph-cero.zip.sha256.sig">firma</a> · '
        f'<a href="{BASE}/allowed_signers">allowed_signers</a><br>'
        'Verificar: <code>ssh-keygen -Y verify -f allowed_signers -I teatro@escrivivir.co '
        '-n file -s aleph-cero.zip.sha256.sig &lt; aleph-cero.zip.sha256</code></div>'
    )
    write_text(out / "index.html", page(
        "Aleph Cero · Teatro del Scriptorium", portada,
        f"Aleph Cero: el archivo de @_dev_aleph_1 como obra estática. "
        f"{len(records)} posts, hilos, hashtags y media.",
    ))

    # ── cronología ──
    filas = []
    for month in months:
        items = by_month[month]
        filas.append(
            f'<tr><td><a href="{BASE}/cronologia/{month}.html">{esc(mes_nombre(month))}</a></td>'
            f'<td class="num">{len(items)}</td></tr>'
        )
    crono_index = (
        '<h2 class="acto">Cronología · los actos</h2>'
        '<div class="acto-sub">Un acto por mes con posts. Texto y media completos, en orden.</div>'
        f'<table class="tbl"><tr><th>Acto</th><th>Posts</th></tr>{"".join(filas)}</table>'
    )
    write_text(out / "cronologia" / "index.html", page("Cronología · Aleph Cero", crono_index))

    for i, month in enumerate(months):
        items = by_month[month]
        nav_prev = (
            f'<a href="{BASE}/cronologia/{months[i-1]}.html">← {esc(mes_nombre(months[i-1]))}</a>'
            if i else "<span></span>"
        )
        nav_next = (
            f'<a href="{BASE}/cronologia/{months[i+1]}.html">{esc(mes_nombre(months[i+1]))} →</a>'
            if i + 1 < len(months) else "<span></span>"
        )
        pn = f'<div class="pn">{nav_prev}{nav_next}</div>'
        body = (
            f'<h2 class="acto">{esc(mes_nombre(month))}</h2>'
            f'<div class="acto-sub">{len(items)} posts · <a href="{BASE}/cronologia/">todos los actos</a></div>'
            + pn
            + "\n".join(post_html(r, threads) for r in items)
            + pn
        )
        write_text(out / "cronologia" / f"{month}.html",
                   page(f"{mes_nombre(month)} · Aleph Cero", body))

    # ── hilos ──
    thread_items = sorted(
        ((members[0]["created_at"], root_id, members) for root_id, members in threads.items()),
    )
    filas = []
    for created_at, root_id, members in thread_items:
        first = by_id[root_id]
        filas.append(
            f'<div class="fila"><time>{created_at[:10]}</time> '
            f'<span class="k">{len(members)} posts</span> '
            f'<a href="{BASE}/hilos/{root_id}.html">{esc(excerpt(first["full_text"]) or root_id)}</a></div>'
        )
    hilos_index = (
        '<h2 class="acto">Hilos · las escenas</h2>'
        f'<div class="acto-sub">{len(threads)} cadenas de dos o más posts propios.</div>'
        f'<div class="listado">{"".join(filas)}</div>'
    )
    write_text(out / "hilos" / "index.html", page("Hilos · Aleph Cero", hilos_index))

    for created_at, root_id, members in thread_items:
        body = (
            f'<h2 class="acto">Hilo · {created_at[:10]}</h2>'
            f'<div class="acto-sub">{len(members)} posts · raíz <code>{root_id}</code> · '
            f'<a href="{BASE}/hilos/">todas las escenas</a></div>'
            + "\n".join(post_html(r, threads) for r in members)
        )
        write_text(out / "hilos" / f"{root_id}.html",
                   page(f"Hilo {root_id} · Aleph Cero", body))

    # ── hashtags ──
    filas = [
        f'<tr><td><a href="{BASE}/hashtags/{quote(tag_slugs[tag])}.html">#{esc(tag)}</a></td>'
        f'<td class="num">{len(tag_ids[tag])}</td></tr>'
        for tag in tag_slugs
    ]
    write_text(out / "hashtags" / "index.html", page(
        "Hashtags · Aleph Cero",
        '<h2 class="acto">Hashtags</h2>'
        '<div class="acto-sub">Solo las etiquetas del archivo; ninguna inferida.</div>'
        f'<table class="tbl"><tr><th>Etiqueta</th><th>Posts</th></tr>{"".join(filas)}</table>',
    ))
    for tag, slug in tag_slugs.items():
        items = sorted((by_id[i] for i in set(tag_ids[tag])),
                       key=lambda r: (r["created_at"], r["id"]))
        body = (
            f'<h2 class="acto">#{esc(tag)}</h2>'
            f'<div class="acto-sub">{len(items)} posts · <a href="{BASE}/hashtags/">todas las etiquetas</a></div>'
            f'<div class="listado">{"".join(fila(r) for r in items)}</div>'
        )
        write_text(out / "hashtags" / f"{slug}.html", page(f"#{tag} · Aleph Cero", body))

    # ── tipos ──
    secciones = []
    for kind in ("original", "self_reply", "reply_to_other", "retweet"):
        items = [r for r in records if r["kind"] == kind]
        secciones.append(
            f'<h2 class="acto">{esc(KIND_LABEL[kind])} · {kind} ({len(items)})</h2>'
            f'<div class="listado">{"".join(fila(r) for r in items)}</div>'
        )
    write_text(out / "tipos.html", page(
        "Tipos · Aleph Cero",
        '<div class="acto-sub">Partición mecánica por campos, no por juicio.</div>'
        + "".join(secciones),
    ))

    # ── externos ──
    ext_items = sorted(
        (tid, item) for tid, item in (external.get("tweets") or {}).items()
        if isinstance(item, dict)
    )
    filas = []
    for tid, item in ext_items:
        user = item.get("user") or "?"
        status = item.get("status") or "unknown"
        filas.append(
            f'<div class="fila"><code>{tid}</code> @{esc(user)} · {esc(status)} · '
            f'<a href="{BASE}/corpus/external/{tid}.md">md</a></div>'
        )
    write_text(out / "externos.html", page(
        "Externos · Aleph Cero",
        '<h2 class="acto">Voces ajenas</h2>'
        '<div class="acto-sub">Padres de réplicas y originales de RT, tal como se recuperaron. '
        'Lo no recuperado no se completa.</div>'
        f'<div class="listado">{"".join(filas)}</div>',
    ))

    # ── permalinks ──
    for r in records:
        members = threads.get(r["thread_root"])
        extra = [f'<div class="ficha">']
        extra.append(
            f'Fuente verbatim: <a href="{BASE}/corpus/posts/{r["id"]}.md">corpus/posts/{r["id"]}.md</a>'
            f' · <a href="https://x.com/{HANDLE}/status/{r["id"]}">en X</a>'
            f' · acto <a href="{BASE}/cronologia/{r["created_at"][:7]}.html">{esc(mes_nombre(r["created_at"][:7]))}</a>'
        )
        if members:
            idx = next(i for i, m in enumerate(members) if m["id"] == r["id"])
            nav = [f'<br>Escena: <a href="{BASE}/hilos/{r["thread_root"]}.html">hilo completo</a>']
            if idx:
                nav.append(f' · <a href="{BASE}/posts/{members[idx-1]["id"]}.html">← anterior</a>')
            if idx + 1 < len(members):
                nav.append(f' · <a href="{BASE}/posts/{members[idx+1]["id"]}.html">siguiente →</a>')
            extra.append("".join(nav))
        extra.append("</div>")
        body = post_html(r, threads) + "".join(extra)
        write_text(out / "posts" / f"{r['id']}.html",
                   page(f"{r['id']} · Aleph Cero", body, excerpt(r["full_text"], 150)))

    # ── css + verbatim payload ──
    (out / "assets").mkdir(parents=True, exist_ok=True)
    shutil.copy2(root / "tools" / "obra.css", out / "assets" / "obra.css")

    copied = 0
    for name in MEDIA_DIRS:
        copied += sync_tree(root / "data" / name, out / "data" / name)
    for name in BRAIN_DIRS:
        copied += sync_tree(root / name, out / name)
    for name in BRAIN_FILES:
        src, dst = root / name, out / name
        if not dst.is_file() or dst.stat().st_size != src.stat().st_size:
            shutil.copy2(src, dst)
            copied += 1
    for name in BRAIN_DATA:
        src, dst = root / "data" / name, out / "data" / name
        dst.parent.mkdir(parents=True, exist_ok=True)
        if not dst.is_file() or dst.stat().st_size != src.stat().st_size:
            shutil.copy2(src, dst)
            copied += 1

    # ── guards: nothing sensitive, nothing scripted ──
    allowed_data = set(MEDIA_DIRS) | set(BRAIN_DATA) | set(VIEWER_DATA)
    extra_entries = [
        p.name for p in (out / "data").iterdir() if p.name not in allowed_data
    ]
    if extra_entries:
        raise SystemExit(f"unexpected entries in staged data/: {extra_entries}")
    js_files = [
        p for p in (out / "data").rglob("*.js") if p.name not in VIEWER_DATA
    ]
    if js_files:
        raise SystemExit(f"raw archive .js leaked into staging: {js_files[:3]}")
    # navegador.html es la excepción declarada: el visor anexo requiere JS
    # (autocontenido, sin CDNs); las páginas generadas siguen siendo 0-JS.
    scripted = [
        p for p in out.rglob("*.html")
        if "corpus" not in p.parts and p.name != "navegador.html"
        and "<script" in p.read_text(encoding="utf-8")
    ]
    if scripted:
        raise SystemExit(f"<script> found in generated pages: {scripted[:3]}")

    n_pages = sum(1 for _ in out.rglob("*.html"))
    print("site build ok")
    print(f"out: {out}")
    print(f"html pages: {n_pages}")
    print(f"posts: {len(records)} · months: {len(months)} · threads: {len(threads)}"
          f" · tags: {len(tag_slugs)} · externos: {len(ext_items)}")
    print(f"files copied this run: {copied}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
