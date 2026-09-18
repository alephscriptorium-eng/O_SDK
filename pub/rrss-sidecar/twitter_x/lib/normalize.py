"""Export de X → corpus normalizado. LA COSTURA.

Todo lo que el visor consume sale de `records(obra)`: una lista de dicts con el contrato de
`pub/rrss-sidecar/CORPUS-SCHEMA.md`. Un adaptador de otra fuente (p. ej. B.O.E./Arrakis) solo
tiene que producir estos mismos registros; los builders no conocen `window.YTD`.

Partición mecánica, por campos y no por juicio:
  retweet         full_text empieza por "RT @"
  self_reply      in_reply_to_user_id_str == cuenta propia
  reply_to_other  hay in_reply_to_status_id_str y el usuario no es el propio
  original        el resto
"""

from __future__ import annotations

import html
import re
from collections import defaultdict
from datetime import datetime, timedelta, timezone
from pathlib import Path
from urllib.parse import urlsplit

from .obra import Obra
from .store import load_posts

MONTHS = {m: i for i, m in enumerate(
    ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"], start=1)}

KINDS = ("original", "self_reply", "reply_to_other", "retweet")

# https://twitter.com/<user>/status/<id> · x.com · mobile. · /i/web/status/<id>
STATUS_URL = re.compile(
    r"^https?://(?:www\.|mobile\.)?(?:twitter|x)\.com/"
    r"(?:i/web/status|(?P<user>[A-Za-z0-9_]{1,20})/status(?:es)?)/(?P<id>\d+)",
    re.IGNORECASE,
)
X_HOSTS = re.compile(r"(^|\.)(twitter\.com|x\.com|t\.co|twimg\.com)$", re.IGNORECASE)
X_KEEP = re.compile(r"^https?://(?:www\.)?x\.com/i/grok/share/", re.IGNORECASE)


def parse_twitter_date(value: str) -> str:
    """'Wed Jul 08 08:11:30 +0000 2026' → ISO 8601 (independiente del locale)."""
    _weekday, mon, day, hms, tz, year = value.split()
    hour, minute, second = (int(part) for part in hms.split(":"))
    sign = 1 if tz[0] == "+" else -1
    offset = timezone(sign * timedelta(hours=int(tz[1:3]), minutes=int(tz[3:5])))
    return datetime(int(year), MONTHS[mon], int(day), hour, minute, second, tzinfo=offset).isoformat()


def classify(tweet: dict, own_id: str) -> str:
    if (tweet.get("full_text") or "").startswith("RT @"):
        return "retweet"
    if tweet.get("in_reply_to_user_id_str") == own_id:
        return "self_reply"
    if tweet.get("in_reply_to_status_id_str"):
        return "reply_to_other"
    return "original"


def thread_root_of(tweet_id: str, tweets_by_id: dict[str, dict], own_id: str) -> str:
    seen: set[str] = set()
    current = tweet_id
    while current not in seen:
        seen.add(current)
        tweet = tweets_by_id.get(current)
        if tweet is None:
            break
        parent_id = tweet.get("in_reply_to_status_id_str")
        if tweet.get("in_reply_to_user_id_str") != own_id or not parent_id:
            break
        if parent_id not in tweets_by_id:
            break
        current = parent_id
    return current


def index_media(obra: Obra) -> dict[str, list[Path]]:
    """id de tweet → ficheros de media (`<id>-<algo>.ext`), buscando en todas las generaciones.

    La generación más reciente gana; las antiguas solo aportan lo que falte.
    """
    by_id: dict[str, dict[str, Path]] = defaultdict(dict)
    for gen in reversed(obra.generations()):
        media_dir = gen["dir"] / "data" / "tweets_media"
        if not media_dir.is_dir():
            continue
        for path in media_dir.iterdir():
            if path.is_file():
                by_id[path.name.split("-", 1)[0]].setdefault(path.name, path)
    return {tid: [files[name] for name in sorted(files)] for tid, files in by_id.items()}


def expanded_urls(tweet: dict) -> list[str]:
    urls, seen = [], set()
    for obj in (tweet.get("entities") or {}).get("urls") or []:
        url = obj.get("expanded_url")
        if url and url not in seen:
            seen.add(url)
            urls.append(url)
    return urls


def split_urls(urls: list[str], own_ids: set[str], handle: str) -> tuple[list[str], list[str], list[str]]:
    """→ (ids citados de terceros, ids propios enlazados, enlaces externos)."""
    quotes, selfs, links = [], [], []
    for url in urls:
        match = STATUS_URL.match(url)
        if match and not X_KEEP.match(url):
            tid = match.group("id")
            user = (match.group("user") or "").lower()
            if tid in own_ids or (handle and user == handle.lower()):
                selfs.append(tid)
            else:
                quotes.append(tid)
            continue
        try:
            host = urlsplit(url).hostname or ""
        except ValueError:
            continue
        if X_HOSTS.search(host) and not X_KEEP.match(url):
            continue
        links.append(url)
    return quotes, selfs, links


def records(obra: Obra) -> list[dict]:
    """Registros normalizados de los posts VISIBLES, ordenados por (created_at, id)."""
    posts = load_posts(obra)
    hidden = obra.publish["deleted_posts"] == "hidden"
    entries = {tid: e for tid, e in posts.items() if not (hidden and e["deleted"])}
    tweets_by_id = {tid: e["tweet"] for tid, e in entries.items()}
    own_ids = set(posts)  # una auto-cita a un post borrado sigue siendo propia
    media = index_media(obra)
    own_id, handle = obra.own_id, obra.handle

    out: list[dict] = []
    for tid, entry in entries.items():
        tweet = entry["tweet"]
        if "full_text" not in tweet:
            raise SystemExit(f"tweet {tid} sin full_text")
        kind = classify(tweet, own_id)
        urls = expanded_urls(tweet)
        quotes, selfs, links = split_urls(urls, own_ids, handle)
        if kind == "retweet":
            quotes, links = [], []  # las URLs de un RT son del original, no nuestras
        hashtags, seen_tags = [], set()
        for tag in (tweet.get("entities") or {}).get("hashtags") or []:
            text = tag.get("text")
            if text and text not in seen_tags:
                seen_tags.add(text)
                hashtags.append(text)
        parent_id = tweet.get("in_reply_to_status_id_str") or None
        out.append(
            {
                "id": tid,
                "created_at": parse_twitter_date(tweet["created_at"]),
                "actor": handle,
                "lang": tweet.get("lang") or "und",
                "kind": kind,
                "text": html.unescape(tweet["full_text"]),
                "parent_id": parent_id,
                "parent_user_id": tweet.get("in_reply_to_user_id_str") or None,
                "parent_user": tweet.get("in_reply_to_screen_name") or None,
                "parent_in_archive": bool(parent_id) and parent_id in tweets_by_id,
                "thread_root": thread_root_of(tid, tweets_by_id, own_id),
                "urls": urls,
                "quotes": quotes,
                "self_links": selfs,
                "links": links,
                "hashtags": hashtags,
                "media": [f"data/tweets_media/{p.name}" for p in media.get(tid, [])],
                "media_src": [str(p) for p in media.get(tid, [])],
                "generations": entry["generations"],
                "deleted": entry["deleted"],
            }
        )
    out.sort(key=lambda r: (r["created_at"], r["id"]))
    return out


def threads_of(recs: list[dict]) -> dict[str, list[dict]]:
    threads: dict[str, list[dict]] = defaultdict(list)
    for rec in recs:
        threads[rec["thread_root"]].append(rec)
    return {root: members for root, members in threads.items() if len(members) >= 2}


def month_span(recs: list[dict]) -> list[str]:
    """Todos los meses entre el primero y el último post (incluidos los vacíos)."""
    if not recs:
        return []
    first, last = recs[0]["created_at"][:7], recs[-1]["created_at"][:7]
    year, month = (int(p) for p in first.split("-"))
    end = tuple(int(p) for p in last.split("-"))
    months = []
    while (year, month) <= end:
        months.append(f"{year:04d}-{month:02d}")
        month += 1
        if month == 13:
            year, month = year + 1, 1
    return months
