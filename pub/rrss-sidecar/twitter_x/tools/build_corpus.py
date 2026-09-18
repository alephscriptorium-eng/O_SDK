#!/usr/bin/env python3
"""Genera el «segundo cerebro» de una obra: corpus/ e indexes/ en Markdown plano.

Entrada: el corpus normalizado (`lib/normalize.records`) + los stores de voces ajenas y enlaces.
Salida (dentro del árbol de la obra, regenerable):
  corpus/posts/{id}.md      un post propio, texto verbatim + contexto recuperado
  corpus/external/{id}.md   una voz ajena (nivel 1 o 2)
  corpus/links/{hash}.md    el contenido íntegro de un enlace externo
  indexes/*.md              hilos, cronología, hashtags, media, tipos, externos, enlaces

No conoce el formato de X: eso es cosa de `lib/normalize.py` (la costura B.O.E.).
"""

from __future__ import annotations

import json
import re
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lib import links as links_lib  # noqa: E402
from lib import normalize, voices  # noqa: E402
from lib.obra import Obra  # noqa: E402

YAML_BARE_SAFE = frozenset({"y", "n", "yes", "no", "true", "false", "on", "off", "null", "none"})
UNAVAILABLE = "_No disponible en X (borrado, protegido o cuenta ausente)._"


def yaml_dquote(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def yaml_lang(value: str) -> str:
    if value.casefold() in YAML_BARE_SAFE or not value.isascii() or not value.isalpha():
        return yaml_dquote(value)
    return value


def yaml_id_or_null(value: str | None) -> str:
    return "null" if value is None else yaml_dquote(value)


def write_text(path: Path, content: str) -> None:
    if not content.endswith("\n"):
        content += "\n"
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="\n") as handle:
        handle.write(content)


def md_link(tweet_id: str) -> str:
    return f"[`{tweet_id}`](../corpus/posts/{tweet_id}.md)"


# ── voces ajenas ─────────────────────────────────────────────────────────────

def voice_refs(record: dict) -> list[tuple[str, str]]:
    """→ [(rótulo, id)] de las voces de nivel 1 que corresponden a un post."""
    refs: list[tuple[str, str]] = []
    if record["kind"] == "retweet":
        refs.append(("Original", record["id"]))
    elif record["kind"] == "reply_to_other" and record["parent_id"]:
        refs.append(("Padre", record["parent_id"]))
    refs += [("Cita", qid) for qid in record["quotes"]]
    return refs


def level2_refs(node: dict) -> list[tuple[str, str]]:
    refs = []
    if node.get("parent_id"):
        refs.append(("En respuesta a", str(node["parent_id"])))
    if node.get("quoted_id"):
        refs.append(("Citaba a", str(node["quoted_id"])))
    return refs


def voice_body(node: dict | None) -> str:
    if not node:
        return "_No recuperado (`missing`)._"
    status, text = node.get("status"), node.get("text")
    if text:
        return text
    if status in ("ok", "legacy"):
        return "_Sin texto (solo media)._"
    if status == "unavailable":
        return UNAVAILABLE
    return f"_No recuperado (`{status or 'missing'}`)._"


def voice_who(node: dict | None, tid: str) -> str:
    node = node or {}
    who = " ".join(p for p in (node.get("name"), f"@{node['user']}" if node.get("user") else "") if p)
    when = (node.get("created_at") or "")[:10]
    return " ".join(p for p in (f"`{node.get('id') or tid}`", who, when) if p)


def context_block(record: dict, tweets: dict) -> str | None:
    blocks = []
    for label, tid in voice_refs(record):
        node = tweets.get(tid)
        lines = [f"### {label} {voice_who(node, tid)}", "", voice_body(node)]
        for sub_label, sub_id in level2_refs(node or {}):
            sub = tweets.get(sub_id)
            if sub is None:
                continue
            lines += ["", f"#### {sub_label} {voice_who(sub, sub_id)}", "", voice_body(sub)]
        blocks.append("\n".join(lines))
    return "\n\n".join(blocks) if blocks else None


def render_post(record: dict, context: str | None, link_keys: list[str]) -> str:
    lines = [
        "---",
        f"id: {yaml_dquote(record['id'])}",
        f"created_at: {yaml_dquote(record['created_at'])}",
        f"lang: {yaml_lang(record['lang'])}",
        f"in_reply_to: {yaml_id_or_null(record['parent_id'])}",
        f"in_reply_to_user: {yaml_id_or_null(record['parent_user_id'])}",
        f"thread_root: {yaml_dquote(record['thread_root'])}",
        f"kind: {record['kind']}",
    ]
    if record["quotes"]:
        lines.append("quotes:")
        lines += [f"  - {yaml_dquote(q)}" for q in record["quotes"]]
    if record["media"]:
        lines.append("media:")
        lines += [f"  - {path}" for path in record["media"]]
    if record["urls"]:
        lines.append("urls:")
        lines += [f"  - expanded: {yaml_dquote(url)}" for url in record["urls"]]
    if link_keys:
        lines.append("links:")
        lines += [f"  - ../links/{key}.md" for key in link_keys]
    lines += ["---", "", record["text"]]
    if context:
        lines += ["", "---", "", context]
    return "\n".join(lines) + "\n"


def write_external(out: Path, tweets: dict) -> int:
    external_dir = out / "corpus" / "external"
    external_dir.mkdir(parents=True, exist_ok=True)
    for stale in external_dir.glob("*.md"):
        stale.unlink()
    items = sorted(tweets.items())
    for tid, node in items:
        lines = [
            "---",
            f"id: {yaml_dquote(str(node.get('id') or tid))}",
            f"requested_id: {yaml_dquote(tid)}",
            f"status: {node.get('status') or 'unknown'}",
            f"level: {node.get('level') or 1}",
            f"user: {yaml_id_or_null(node.get('user'))}",
            f"name: {yaml_dquote(node['name']) if node.get('name') else 'null'}",
            f"created_at: {yaml_id_or_null(node.get('created_at'))}",
            f"in_reply_to: {yaml_id_or_null(str(node['parent_id']) if node.get('parent_id') else None)}",
            f"quoted: {yaml_id_or_null(str(node['quoted_id']) if node.get('quoted_id') else None)}",
            f"source: {node.get('source') or 'unknown'}",
        ]
        if node.get("url"):
            lines.append(f"url: {yaml_dquote(node['url'])}")
        if node.get("via"):
            lines.append("via:")
            lines += [f"  - {v.get('rel')}: {yaml_dquote(str(v.get('from')))}" for v in node["via"]]
        media = [m["local"] for m in node.get("media") or [] if m.get("local")]
        if media:
            lines.append("media:")
            lines += [f"  - {path}" for path in media]
        lines += ["---", "", voice_body(node)]
        write_text(external_dir / f"{tid}.md", "\n".join(lines))

    index = [
        "# Externos",
        "",
        f"{len(items)} voces ajenas: originales de RT, padres de réplicas, tuits citados (nivel 1) y"
        " el padre o el citado de estos (nivel 2).",
        "Texto canónico de terceros: `corpus/external/{id}.md`. Lo no recuperado no se completa.",
        "",
    ]
    for tid, node in items:
        index.append(
            f"- [`{tid}`](../corpus/external/{tid}.md) @{node.get('user') or '?'} · "
            f"{node.get('status') or 'unknown'} · L{node.get('level') or 1}"
        )
    write_text(out / "indexes" / "externos.md", "\n".join(index))
    return len(items)


def write_links(obra: Obra, out: Path, store: dict) -> int:
    links_dir = out / "corpus" / "links"
    links_dir.mkdir(parents=True, exist_ok=True)
    for stale in links_dir.glob("*.md"):
        stale.unlink()
    written = 0
    by_family: dict[str, list[tuple[str, dict]]] = defaultdict(list)
    for key, entry in sorted(store.items()):
        by_family[entry.get("family") or "generic"].append((key, entry))
        source = links_lib.md_path(obra, key)
        if entry.get("status") != "ok" or not source.is_file():
            continue
        front = [
            "---",
            f"hash: {key}",
            f"url: {yaml_dquote(entry['url'])}",
            f"final_url: {yaml_dquote(entry.get('final_url') or entry['url'])}",
            f"family: {entry.get('family')}",
            f"title: {yaml_dquote(entry.get('title') or '')}",
            f"method: {entry.get('method')}",
            f"fetched_at: {yaml_dquote(entry.get('fetched_at') or '')}",
            f"sha256_md: {entry.get('sha256_md')}",
            "cited_by:",
            *[f"  - {yaml_dquote(t)}" for t in entry.get("cited_by") or []],
            "---",
            "",
        ]
        write_text(links_dir / f"{key}.md", "\n".join(front) + source.read_text(encoding="utf-8"))
        written += 1

    index = ["# Enlaces", "", f"{len(store)} enlaces externos citados en los posts propios.",
             "Contenido íntegro recuperado: `corpus/links/{hash}.md`. Lo no recuperado se lista sin texto.", ""]
    for family in sorted(by_family, key=lambda f: (not f.startswith("agent:"), f)):
        index += [f"## {family} ({len(by_family[family])})", ""]
        for key, entry in by_family[family]:
            label = entry.get("title") or entry["url"]
            target = f"[{label}](../corpus/links/{key}.md)" if entry.get("status") == "ok" else label
            index.append(f"- {target} · {entry.get('status')} · <{entry['url']}>")
        index.append("")
    write_text(out / "indexes" / "enlaces.md", "\n".join(index))
    return written


def write_indexes(out: Path, records: list[dict], threads: dict[str, list[dict]]) -> None:
    indexes_dir = out / "indexes"
    by_id = {r["id"]: r for r in records}

    hilos = ["# Hilos", "", f"{len(threads)} hilos propios (cadenas de 2 o más posts de la cuenta).",
             "Solo punteros; el texto está en `corpus/posts/{id}.md`.", ""]
    for created_at, root_id, members in sorted(
            (by_id[root]["created_at"], root, m) for root, m in threads.items()):
        hilos += [f"## {len(members)} posts · {created_at[:10]} · raíz {md_link(root_id)}", ""]
        hilos += [f"{i}. {md_link(m['id'])}" for i, m in enumerate(members, start=1)]
        hilos.append("")
    write_text(indexes_dir / "hilos.md", "\n".join(hilos))

    months = normalize.month_span(records)
    by_month: dict[str, list[dict]] = defaultdict(list)
    for record in records:
        by_month[record["created_at"][:7]].append(record)
    span = f"de {months[0]} a {months[-1]}" if months else "sin posts"
    crono = ["# Cronología", "", f"Posts por mes (`created_at`), {span}. Solo punteros.", ""]
    for month in months:
        items = by_month.get(month, [])
        crono += [f"## {month} ({len(items)})", ""]
        crono += [f"- {md_link(r['id'])}" for r in items]
        crono.append("")
    write_text(indexes_dir / "cronologia.md", "\n".join(crono))

    tag_to_ids: dict[str, list[str]] = defaultdict(list)
    for record in records:
        for tag in record["hashtags"]:
            if record["id"] not in tag_to_ids[tag]:
                tag_to_ids[tag].append(record["id"])
    tags = ["# Hashtags", "",
            f"{len(tag_to_ids)} etiquetas tomadas de `entities.hashtags`. Solo estas; no inferir otras.", ""]
    for tag in sorted(tag_to_ids, key=lambda t: (t.casefold(), t)):
        ids = sorted(tag_to_ids[tag], key=lambda i: (by_id[i]["created_at"], i))
        tags += [f"## #{tag} ({len(ids)})", ""] + [f"- {md_link(i)}" for i in ids] + [""]
    write_text(indexes_dir / "hashtags.md", "\n".join(tags))

    with_media = [r for r in records if r["media"]]
    media = ["# Media", "", f"{len(with_media)} posts con archivos locales en `data/tweets_media/`.",
             "Rutas relativas a la raíz de la obra. Solo punteros.", ""]
    for record in with_media:
        media += [f"## {md_link(record['id'])} ({len(record['media'])})", ""]
        media += [f"- `{path}`" for path in record["media"]] + [""]
    write_text(indexes_dir / "media.md", "\n".join(media))

    tipos = ["# Tipos", "", "Partición mecánica por campos (no por juicio):",
             "- `retweet` si `full_text` empieza por `RT @`",
             "- `self_reply` si `in_reply_to_user_id_str` es la cuenta propia",
             "- `reply_to_other` si hay `in_reply_to_status_id_str` y el usuario no es el propio",
             "- `original` en el resto", ""]
    for kind in normalize.KINDS:
        items = [r for r in records if r["kind"] == kind]
        tipos += [f"## {kind} ({len(items)})", ""] + [f"- {md_link(r['id'])}" for r in items] + [""]
    write_text(indexes_dir / "tipos.md", "\n".join(tipos))


def write_editorial(obra: Obra, out: Path, records: list[dict], threads: dict, link_store: dict) -> int:
    """`indexes/sistema.md` y `indexes/cantar.md`: la capa curada, marcada como tal. Sin editorial, se retiran."""
    from lib import editorial as editorial_lib

    ed = editorial_lib.Editorial(obra, records, threads, link_store)
    indexes_dir = out / "indexes"
    for name in ("sistema.md", "cantar.md"):
        (indexes_dir / name).unlink(missing_ok=True)
    if not ed.present:
        return 0
    by_id = {r["id"]: r for r in records}
    href = lambda pid: f"../corpus/posts/{pid}.md" if pid in by_id else None  # noqa: E731
    clean = lambda md: editorial_lib.link_posts(re.sub(r"<!--.*?-->", "", md, flags=re.S), href).strip()  # noqa: E731
    firma = " · ".join(x for x in (ed.raw.get("curated_by"), ed.raw.get("curated_at")) if x)
    aviso = (f"> CAPA CURADA{' por ' + firma if firma else ''}. Es una lectura del editor, no un campo del archivo: "
             "la selección y la glosa son suyas; las citas son literales. Citar siempre el post por su id, no esta página.")
    if ed.territories:
        lines = [f"# {ed.raw.get('title') or 'El sistema'}", "", aviso, ""]
        concept = ed.text(ed.raw.get("concept")) if ed.raw.get("concept") else ""
        if concept:
            lines += [clean(concept), ""]
        for t in ed.territories:
            lines += [f"## {t['title']}", "", t["copy"], ""]
            for c in t["constructs"]:
                lines += [f"### {c['title']} (`{c['slug']}`)", ""]
                if c["text"]:
                    lines += [clean(ed.text(c["text"])), ""]
                if c["first_id"]:
                    lines += [f"- nace en: {md_link(c['first_id'])}"]
                lines += [f"- curado: {md_link(i)}" for i in c["post_ids"] if i != c["first_id"]]
                lines += [f"- hilo: [{root}](../corpus/posts/{root}.md) ({len(threads[root])} posts)" for root in c["thread_roots"]]
                lines += [f"- enlace: [{(link_store[k].get('title') or link_store[k]['url'])}](../corpus/links/{k}.md)"
                          for k in c["link_hashes"] if link_store[k].get("status") == "ok"]
                if c["mechanical"]:
                    lines += ["", f"Mención mecánica ({', '.join('`' + t + '`' for t in c['terms'])}): "
                              + " ".join(md_link(i) for i in c["mechanical"])]
                lines += [""]
        write_text(indexes_dir / "sistema.md", "\n".join(lines))
    if ed.tracks:
        album = ed.album
        lines = [f"# {album.get('title') or 'El cantar'}", "", aviso, "", album.get("copy") or "", ""]
        if album.get("text"):
            lines += [clean(ed.text(album["text"])), ""]
        for t in ed.tracks:
            lines += [f"## {t['n']:02d} · {t['title']}", "",
                      " · ".join(x for x in (t["side"], t["duration"], t["video"]) if x), ""]
            if t["constructs"]:
                lines += ["Recapitula: " + ", ".join(f"`{s}`" for s in t["constructs"]), ""]
            if t["lyrics"]:
                lines += [clean(ed.text(t["lyrics"])), ""]
        if album.get("lyrics"):
            lines += ["## Letra", "", "La letra se reparte por los cortes.", "", clean(ed.text(album["lyrics"])), ""]
        write_text(indexes_dir / "cantar.md", "\n".join(lines))
    if ed.voice_notes:
        for tid, note in ed.voice_notes.items():
            path = out / "corpus" / "external" / f"{tid}.md"
            if path.is_file():
                write_text(path, path.read_text(encoding="utf-8").rstrip("\n") + f"\n\n> Descripción del custodio (no es texto de la voz): {note}\n")
    return len(ed.constructs)


def write_interlocutores(out: Path, records: list[dict]) -> None:
    people: dict[str, list[str]] = {}
    names: dict[str, str] = {}
    for r in records:
        for handle in (r["mentions"][:1] if r["kind"] == "retweet" else r["mentions"]):
            names.setdefault(handle.lower(), handle)
            people.setdefault(handle.lower(), []).append(r["id"])
    lines = ["# Interlocutores", "", "Cuentas a las que la obra responde, menciona o retuitea. Recuento mecánico.", ""]
    for h in sorted(people, key=lambda h: (-len(people[h]), h)):
        lines += [f"## @{names[h]} ({len(people[h])})", ""] + [f"- {md_link(i)}" for i in people[h]] + [""]
    write_text(out / "indexes" / "interlocutores.md", "\n".join(lines))


def build(obra: Obra, out: Path) -> dict:
    records = normalize.records(obra)
    threads = normalize.threads_of(records)
    tweets = voices.published(obra)
    link_store = links_lib.load(obra)

    posts_dir = out / "corpus" / "posts"
    posts_dir.mkdir(parents=True, exist_ok=True)
    for stale in posts_dir.glob("*.md"):
        stale.unlink()
    for record in records:
        keys = [links_lib.key_of(u) for u in record["links"]]
        keys = [k for k in dict.fromkeys(keys) if (link_store.get(k) or {}).get("status") == "ok"]
        write_text(posts_dir / f"{record['id']}.md", render_post(record, context_block(record, tweets), keys))

    write_indexes(out, records, threads)
    write_interlocutores(out, records)
    n_ext = write_external(out, tweets)
    n_links = write_links(obra, out, link_store)
    n_constructs = write_editorial(obra, out, records, threads, link_store)

    files = {p.stem for p in posts_dir.glob("*.md")}
    if files != {r["id"] for r in records}:
        raise SystemExit("corpus/posts no coincide con los registros visibles")
    kinds = {k: sum(1 for r in records if r["kind"] == k) for k in normalize.KINDS}
    stats = {
        "posts": len(records), "threads": len(threads), "external": n_ext, "links_md": n_links,
        "with_context": sum(1 for r in records if voice_refs(r)), "constructs": n_constructs, **kinds,
    }
    print("corpus build ok ·", " · ".join(f"{k}: {v}" for k, v in stats.items()))
    return stats
