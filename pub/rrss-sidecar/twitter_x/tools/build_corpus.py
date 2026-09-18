#!/usr/bin/env python3
"""Build corpus/posts and indexes/ from the official X archive.

Canonical source: data/tweets.js (do not modify).
Does not copy media; only records relative paths under data/tweets_media/.
"""

from __future__ import annotations

import html
import json
import sys
from collections import defaultdict
from datetime import datetime, timedelta, timezone
from pathlib import Path


OWN_ID = "1807003571025592320"
EXPECTED_POSTS = 1454
PREFIX = "window.YTD.tweets.part0 ="

MONTHS = {
    "Jan": 1,
    "Feb": 2,
    "Mar": 3,
    "Apr": 4,
    "May": 5,
    "Jun": 6,
    "Jul": 7,
    "Aug": 8,
    "Sep": 9,
    "Oct": 10,
    "Nov": 11,
    "Dec": 12,
}

YAML_BARE_SAFE = frozenset(
    {
        "y",
        "n",
        "yes",
        "no",
        "true",
        "false",
        "on",
        "off",
        "null",
        "none",
    }
)


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def parse_tweets_js(path: Path) -> list[dict]:
    text = path.read_text(encoding="utf-8")
    if text.startswith("\ufeff"):
        text = text[1:]
    idx = text.find(PREFIX)
    if idx < 0:
        raise SystemExit(f"missing `{PREFIX}` wrapper in {path}")
    payload = text[idx + len(PREFIX) :].strip()
    if payload.endswith(";"):
        payload = payload[:-1].rstrip()
    data = json.loads(payload)
    if not isinstance(data, list):
        raise SystemExit(f"expected a JSON array in {path}")
    tweets = []
    for entry in data:
        if not isinstance(entry, dict) or "tweet" not in entry:
            raise SystemExit("unexpected tweets.js entry shape")
        tweets.append(entry["tweet"])
    return tweets


def parse_twitter_date(value: str) -> str:
    """Parse 'Wed Jul 08 08:11:30 +0000 2026' → ISO 8601 (locale-independent)."""
    weekday, mon, day, hms, tz, year = value.split()
    del weekday
    hour, minute, second = (int(part) for part in hms.split(":"))
    sign = 1 if tz[0] == "+" else -1
    offset = timezone(sign * timedelta(hours=int(tz[1:3]), minutes=int(tz[3:5])))
    dt = datetime(
        int(year),
        MONTHS[mon],
        int(day),
        hour,
        minute,
        second,
        tzinfo=offset,
    )
    return dt.isoformat()


def classify(tweet: dict) -> str:
    text = tweet.get("full_text") or ""
    if text.startswith("RT @"):
        return "retweet"
    if tweet.get("in_reply_to_user_id_str") == OWN_ID:
        return "self_reply"
    if tweet.get("in_reply_to_status_id_str"):
        return "reply_to_other"
    return "original"


def thread_root_of(tweet_id: str, tweets_by_id: dict[str, dict]) -> str:
    seen: set[str] = set()
    current = tweet_id
    while current not in seen:
        seen.add(current)
        tweet = tweets_by_id.get(current)
        if tweet is None:
            break
        parent_user = tweet.get("in_reply_to_user_id_str")
        parent_id = tweet.get("in_reply_to_status_id_str")
        if parent_user != OWN_ID or not parent_id:
            break
        if parent_id not in tweets_by_id:
            break
        current = parent_id
    return current


def index_media(media_dir: Path) -> dict[str, list[str]]:
    by_id: dict[str, list[str]] = defaultdict(list)
    if not media_dir.is_dir():
        raise SystemExit(f"missing media directory: {media_dir}")
    for path in media_dir.iterdir():
        if not path.is_file():
            continue
        tweet_id = path.name.split("-", 1)[0]
        by_id[tweet_id].append(f"data/tweets_media/{path.name}")
    for paths in by_id.values():
        paths.sort()
    return dict(by_id)


def yaml_dquote(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def yaml_lang(value: str) -> str:
    if value.casefold() in YAML_BARE_SAFE or not value.isascii() or not value.isalpha():
        return yaml_dquote(value)
    return value


def yaml_id_or_null(value: str | None) -> str:
    if value is None:
        return "null"
    return yaml_dquote(value)


def load_external(path: Path) -> dict:
    if not path.is_file():
        return {"tweets": {}}
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        return {"tweets": {}}
    data.setdefault("tweets", {})
    return data


def lookup_external(external: dict, tweet_id: str | None) -> dict | None:
    if not tweet_id:
        return None
    item = (external.get("tweets") or {}).get(tweet_id)
    return item if isinstance(item, dict) else None


def context_block(kind: str, fetched: dict) -> str:
    heading = "### Padre" if kind == "reply_to_other" else "### Original"
    tid = fetched.get("final_id") or fetched.get("requested_id") or ""
    user = fetched.get("user")
    name = fetched.get("name")
    who = " ".join(part for part in (name, f"@{user}" if user else "") if part)
    lines = [f"{heading} `{tid}` {who}".rstrip(), ""]
    status = fetched.get("status")
    text = fetched.get("text")
    if status == "ok" and text:
        lines.append(text)
    elif status == "ok":
        lines.append("_Sin texto (solo media)._")
    elif status == "unavailable":
        lines.append("_No disponible en X (borrado, protegido o cuenta ausente)._")
    else:
        lines.append(f"_No recuperado (`{status or 'missing'}`)._")
    return "\n".join(lines)


def render_post(record: dict) -> str:
    lines = [
        "---",
        f"id: {yaml_dquote(record['id'])}",
        f"created_at: {yaml_dquote(record['created_at'])}",
        f"lang: {yaml_lang(record['lang'])}",
        f"in_reply_to: {yaml_id_or_null(record['in_reply_to'])}",
        f"in_reply_to_user: {yaml_id_or_null(record['in_reply_to_user'])}",
        f"thread_root: {yaml_dquote(record['thread_root'])}",
        f"kind: {record['kind']}",
    ]
    if record.get("original_id"):
        lines.append(f"original_id: {yaml_dquote(record['original_id'])}")
    if record.get("external_status"):
        lines.append(f"external_status: {record['external_status']}")
    if record["media"]:
        lines.append("media:")
        for path in record["media"]:
            lines.append(f"  - {path}")
    if record["urls"]:
        lines.append("urls:")
        for url in record["urls"]:
            lines.append(f"  - expanded: {yaml_dquote(url)}")
    lines.append("---")
    lines.append("")
    lines.append(record["full_text"])
    if record.get("context"):
        lines.append("")
        lines.append("---")
        lines.append("")
        lines.append(record["context"])
    body = "\n".join(lines)
    if not body.endswith("\n"):
        body += "\n"
    return body


def md_link(tweet_id: str) -> str:
    return f"[`{tweet_id}`](../corpus/posts/{tweet_id}.md)"


def write_text(path: Path, content: str) -> None:
    if not content.endswith("\n"):
        content += "\n"
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="\n") as handle:
        handle.write(content)


def month_range(start: str, end: str) -> list[str]:
    start_y, start_m = (int(part) for part in start.split("-"))
    end_y, end_m = (int(part) for part in end.split("-"))
    months: list[str] = []
    year, month = start_y, start_m
    while (year, month) <= (end_y, end_m):
        months.append(f"{year:04d}-{month:02d}")
        month += 1
        if month == 13:
            month = 1
            year += 1
    return months


def write_indexes(indexes_dir: Path, records: list[dict], threads: dict[str, list[dict]]) -> None:
    by_id = {record["id"]: record for record in records}

    hilos_lines = [
        "# Hilos",
        "",
        f"{len(threads)} hilos propios (cadenas de 2 o más posts de la cuenta).",
        "Solo punteros; el texto está en `corpus/posts/{id}.md`.",
        "",
    ]
    thread_items = []
    for root_id, members in threads.items():
        root = by_id[root_id]
        thread_items.append((root["created_at"], root_id, members))
    thread_items.sort(key=lambda item: (item[0], item[1]))
    for created_at, root_id, members in thread_items:
        day = created_at[:10]
        hilos_lines.append(
            f"## {len(members)} posts · {day} · raíz {md_link(root_id)}"
        )
        hilos_lines.append("")
        for i, member in enumerate(members, start=1):
            hilos_lines.append(f"{i}. {md_link(member['id'])}")
        hilos_lines.append("")
    write_text(indexes_dir / "hilos.md", "\n".join(hilos_lines))

    by_month: dict[str, list[dict]] = defaultdict(list)
    for record in records:
        by_month[record["created_at"][:7]].append(record)
    crono_lines = [
        "# Cronología",
        "",
        "Posts por mes (`created_at`), de 2024-06 a 2026-08. Solo punteros.",
        "",
    ]
    for month in month_range("2024-06", "2026-08"):
        items = sorted(by_month.get(month, []), key=lambda r: (r["created_at"], r["id"]))
        crono_lines.append(f"## {month} ({len(items)})")
        crono_lines.append("")
        for record in items:
            crono_lines.append(f"- {md_link(record['id'])}")
        if items:
            crono_lines.append("")
        else:
            crono_lines.append("")
    write_text(indexes_dir / "cronologia.md", "\n".join(crono_lines))

    tag_to_ids: dict[str, list[str]] = defaultdict(list)
    seen_pair: set[tuple[str, str]] = set()
    for record in records:
        for tag in record["hashtags"]:
            pair = (tag, record["id"])
            if pair in seen_pair:
                continue
            seen_pair.add(pair)
            tag_to_ids[tag].append(record["id"])
    hashtag_lines = [
        "# Hashtags",
        "",
        f"{len(tag_to_ids)} etiquetas tomadas de `entities.hashtags`. Solo estas; no inferir otras.",
        "",
    ]
    for tag in sorted(tag_to_ids, key=lambda t: (t.casefold(), t)):
        ids = tag_to_ids[tag]
        ids_sorted = sorted(ids, key=lambda i: (by_id[i]["created_at"], i))
        hashtag_lines.append(f"## #{tag} ({len(ids_sorted)})")
        hashtag_lines.append("")
        for tweet_id in ids_sorted:
            hashtag_lines.append(f"- {md_link(tweet_id)}")
        hashtag_lines.append("")
    write_text(indexes_dir / "hashtags.md", "\n".join(hashtag_lines))

    media_records = [record for record in records if record["media"]]
    media_records.sort(key=lambda r: (r["created_at"], r["id"]))
    media_lines = [
        "# Media",
        "",
        f"{len(media_records)} posts con archivos locales en `data/tweets_media/`.",
        "Rutas relativas a la raíz del repo. Solo punteros.",
        "",
    ]
    for record in media_records:
        media_lines.append(f"## {md_link(record['id'])} ({len(record['media'])})")
        media_lines.append("")
        for path in record["media"]:
            media_lines.append(f"- `{path}`")
        media_lines.append("")
    write_text(indexes_dir / "media.md", "\n".join(media_lines))

    kinds = ("original", "self_reply", "reply_to_other", "retweet")
    tipo_lines = [
        "# Tipos",
        "",
        "Partición mecánica por campos (no por juicio):",
        "- `retweet` si `full_text` empieza por `RT @`",
        "- `self_reply` si `in_reply_to_user_id_str` es la cuenta propia",
        "- `reply_to_other` si hay `in_reply_to_status_id_str` y el usuario no es el propio",
        "- `original` en el resto",
        "",
    ]
    for kind in kinds:
        items = [r for r in records if r["kind"] == kind]
        items.sort(key=lambda r: (r["created_at"], r["id"]))
        tipo_lines.append(f"## {kind} ({len(items)})")
        tipo_lines.append("")
        for record in items:
            tipo_lines.append(f"- {md_link(record['id'])}")
        tipo_lines.append("")
    write_text(indexes_dir / "tipos.md", "\n".join(tipo_lines))


def write_external(indexes_dir: Path, external_dir: Path, external: dict) -> int:
    tweets = external.get("tweets") or {}
    items = []
    for tweet_id, item in tweets.items():
        if not isinstance(item, dict):
            continue
        items.append((tweet_id, item))
    items.sort(key=lambda pair: pair[0])
    external_dir.mkdir(parents=True, exist_ok=True)
    for stale in external_dir.glob("*.md"):
        stale.unlink()
    for tweet_id, item in items:
        user = item.get("user")
        name = item.get("name")
        status = item.get("status") or "unknown"
        url = item.get("url") or ""
        text = item.get("text") or ""
        lines = [
            "---",
            f"id: {yaml_dquote(tweet_id)}",
            f"user: {yaml_id_or_null(user)}",
            f"name: {yaml_dquote(name) if name else 'null'}",
            f"status: {status}",
        ]
        if url:
            lines.append(f"url: {yaml_dquote(url)}")
        lines.append("---")
        lines.append("")
        if status == "ok" and text:
            lines.append(text)
        elif status == "unavailable":
            lines.append("_No disponible en X (borrado, protegido o cuenta ausente)._")
        else:
            lines.append(f"_No recuperado (`{status}`)._")
        write_text(external_dir / f"{tweet_id}.md", "\n".join(lines))
    lines = [
        "# Externos",
        "",
        f"{len(items)} tweets ajenos recuperados (padres de `reply_to_other` y originales de `retweet`).",
        "Texto canónico de terceros: `corpus/external/{id}.md`. También se copia al post propio bajo `### Padre` / `### Original`.",
        "",
    ]
    for tweet_id, item in items:
        user = item.get("user") or "?"
        status = item.get("status") or "unknown"
        lines.append(f"- [`{tweet_id}`](../corpus/external/{tweet_id}.md) @{user} · {status}")
    write_text(indexes_dir / "externos.md", "\n".join(lines))
    return len(items)


def main() -> int:
    root = repo_root()
    tweets_js = root / "data" / "tweets.js"
    media_dir = root / "data" / "tweets_media"
    posts_dir = root / "corpus" / "posts"
    indexes_dir = root / "indexes"

    tweets = parse_tweets_js(tweets_js)
    if len(tweets) != EXPECTED_POSTS:
        raise SystemExit(f"expected {EXPECTED_POSTS} tweets, got {len(tweets)}")

    tweets_by_id: dict[str, dict] = {}
    for tweet in tweets:
        tweet_id = tweet.get("id_str")
        if not tweet_id:
            raise SystemExit("tweet missing id_str")
        if tweet_id in tweets_by_id:
            raise SystemExit(f"duplicate tweet id {tweet_id}")
        tweets_by_id[tweet_id] = tweet

    media_by_id = index_media(media_dir)
    external = load_external(root / "data" / "external_tweets.json")

    records: list[dict] = []
    missing_parents: list[tuple[str, str]] = []
    for tweet in tweets:
        tweet_id = tweet["id_str"]
        if "full_text" not in tweet:
            raise SystemExit(f"tweet {tweet_id} missing full_text")
        parent_id = tweet.get("in_reply_to_status_id_str") or None
        parent_user = tweet.get("in_reply_to_user_id_str") or None
        if parent_user == OWN_ID and parent_id and parent_id not in tweets_by_id:
            missing_parents.append((tweet_id, parent_id))
        urls: list[str] = []
        seen_urls: set[str] = set()
        for url_obj in (tweet.get("entities") or {}).get("urls") or []:
            expanded = url_obj.get("expanded_url")
            if expanded and expanded not in seen_urls:
                seen_urls.add(expanded)
                urls.append(expanded)
        hashtags = []
        seen_tags: set[str] = set()
        for tag_obj in (tweet.get("entities") or {}).get("hashtags") or []:
            text = tag_obj.get("text")
            if text and text not in seen_tags:
                seen_tags.add(text)
                hashtags.append(text)
        kind = classify(tweet)
        fetched_id = parent_id if kind == "reply_to_other" else (tweet_id if kind == "retweet" else None)
        fetched = lookup_external(external, fetched_id)
        original_id = None
        external_status = None
        context = None
        if fetched:
            external_status = fetched.get("status")
            if kind == "retweet":
                original_id = fetched.get("final_id") if fetched.get("final_id") != tweet_id else None
            context = context_block(kind, fetched)
        records.append(
            {
                "id": tweet_id,
                "created_at": parse_twitter_date(tweet["created_at"]),
                "lang": tweet.get("lang") or "und",
                "in_reply_to": parent_id,
                "in_reply_to_user": parent_user,
                "thread_root": thread_root_of(tweet_id, tweets_by_id),
                "kind": kind,
                "media": list(media_by_id.get(tweet_id, [])),
                "urls": urls,
                "hashtags": hashtags,
                "full_text": html.unescape(tweet["full_text"]),
                "original_id": original_id,
                "external_status": external_status,
                "context": context,
            }
        )

    records.sort(key=lambda r: (r["created_at"], r["id"]))

    threads: dict[str, list[dict]] = defaultdict(list)
    for record in records:
        threads[record["thread_root"]].append(record)
    threads = {
        root_id: members
        for root_id, members in threads.items()
        if len(members) >= 2
    }
    for members in threads.values():
        members.sort(key=lambda r: (r["created_at"], r["id"]))

    posts_dir.mkdir(parents=True, exist_ok=True)
    for stale in posts_dir.glob("*.md"):
        stale.unlink()
    for record in records:
        write_text(posts_dir / f"{record['id']}.md", render_post(record))

    write_indexes(indexes_dir, records, threads)
    external_count = write_external(indexes_dir, root / "corpus" / "external", external)

    post_files = sorted(posts_dir.glob("*.md"))
    if len(post_files) != EXPECTED_POSTS:
        raise SystemExit(f"expected {EXPECTED_POSTS} post files, got {len(post_files)}")
    file_ids = {path.stem for path in post_files}
    tweet_ids = set(tweets_by_id)
    if file_ids != tweet_ids:
        missing = tweet_ids - file_ids
        extra = file_ids - tweet_ids
        raise SystemExit(f"id mismatch: missing={sorted(missing)[:5]} extra={sorted(extra)[:5]}")

    media_refs = [path for record in records for path in record["media"]]
    for rel in media_refs:
        if not (root / rel).is_file():
            raise SystemExit(f"referenced media missing: {rel}")

    kinds_count = {kind: 0 for kind in ("original", "self_reply", "reply_to_other", "retweet")}
    for record in records:
        kinds_count[record["kind"]] += 1

    print("corpus build ok")
    print(f"posts: {len(records)}")
    print(f"posts with media: {sum(1 for r in records if r['media'])}")
    print(f"media files referenced: {len(media_refs)}")
    print(f"self-threads: {len(threads)}")
    print(f"posts in threads: {sum(len(m) for m in threads.values())}")
    print(f"original: {kinds_count['original']}")
    print(f"self_reply: {kinds_count['self_reply']}")
    print(f"reply_to_other: {kinds_count['reply_to_other']}")
    print(f"retweet: {kinds_count['retweet']}")
    print(f"hashtags: {len({tag for r in records for tag in r['hashtags']})}")
    print(f"external tweets: {external_count}")
    print(f"posts with recovered context: {sum(1 for r in records if r.get('context'))}")
    print(f"self-replies whose parent is missing: {len(missing_parents)}")
    for tweet_id, parent_id in missing_parents:
        print(f"  missing parent: {tweet_id} -> {parent_id}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
