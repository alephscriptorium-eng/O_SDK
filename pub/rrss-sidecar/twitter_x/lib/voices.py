"""Protocolo (a): voces ajenas a 1-2 niveles.

El export de X trunca los RT y no incluye ni el padre de una réplica ni el tuit citado (la cita
solo existe como URL de status en `entities.urls`). Este módulo los recupera de fuera:

  nivel 1  original de cada RT · padre de cada réplica a terceros · cada tuit citado
  nivel 2  el padre y el citado DEL tuit de nivel 1 (llegan embebidos en la misma respuesta)

Fuente primaria: `cdn.syndication.twimg.com/tweet-result` (sin auth, no documentada).
Segunda opinión / fallback: `api.fxtwitter.com`. El crudo se cachea en `cache/voices/<id>.json`
para poder re-derivar sin volver a pedir. Lo no recuperable se marca `unavailable`: jamás se
inventa texto. El store es aditivo: un texto ya recuperado nunca se pierde.

  store/external_tweets.v2.json   {schema: 2, tweets: {<id>: nodo}}
  store/external_worklist.json    {retweets: [...], parents: [...], quotes: [...]}
"""

from __future__ import annotations

import json
import random
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from pathlib import Path

from . import normalize
from .obra import Obra, read_json, write_json_atomic

SYNDICATION = "https://cdn.syndication.twimg.com/tweet-result?id={id}&lang=en&token=a"
FXTWITTER = "https://api.fxtwitter.com/status/{id}"
UA = "rrss-sidecar/1.0 (archivo estatico; +https://github.com/alephscriptorium-eng/O_SDK)"
WORKERS = 4
MAX_ATTEMPTS = 4
MEDIA_MAX_BYTES = 600 * 1024
TERMINAL = {"ok", "unavailable"}


def now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def store_path(obra: Obra) -> Path:
    return obra.store_dir / "external_tweets.v2.json"


def load(obra: Obra) -> dict:
    data = read_json(store_path(obra), {"schema": 2, "tweets": {}})
    data.setdefault("tweets", {})
    return data


# ── worklist ─────────────────────────────────────────────────────────────────

def plan(obra: Obra) -> dict:
    """Recalcula la worklist desde el corpus normalizado. Devuelve contadores."""
    recs = normalize.records(obra)
    work: dict[str, dict[str, list[str]]] = {"retweets": {}, "parents": {}, "quotes": {}}
    for rec in recs:
        if rec["kind"] == "retweet":
            work["retweets"].setdefault(rec["id"], []).append(rec["id"])
        elif rec["kind"] == "reply_to_other" and rec["parent_id"]:
            work["parents"].setdefault(rec["parent_id"], []).append(rec["id"])
        for qid in rec["quotes"]:
            work["quotes"].setdefault(qid, []).append(rec["id"])
    write_json_atomic(obra.store_dir / "external_worklist.json", work)
    tweets = load(obra)["tweets"]
    wanted = set().union(*[set(branch) for branch in work.values()])
    pending = sorted(t for t in wanted if (tweets.get(t) or {}).get("status") not in TERMINAL)
    return {
        "retweets": len(work["retweets"]),
        "parents": len(work["parents"]),
        "quotes": len(work["quotes"]),
        "level1": len(wanted),
        "pending": len(pending),
        "pending_ids": pending,
        "work": work,
    }


# ── migración del store v1 (pipeline antiguo) ────────────────────────────────

def migrate_legacy(obra: Obra) -> int:
    legacy = read_json(obra.legacy_dir / "external_tweets.json", None)
    if not legacy:
        return 0
    data = load(obra)
    tweets, added = data["tweets"], 0
    for tid, item in (legacy.get("tweets") or {}).items():
        if tid in tweets or not isinstance(item, dict):
            continue
        status = item.get("status")
        tweets[tid] = {
            "id": item.get("final_id") or tid,
            "requested_id": tid,
            "status": "unavailable" if status == "unavailable" else "legacy",
            "level": 1,
            "via": [],
            "user": item.get("user"),
            "name": item.get("name"),
            "text": item.get("text") if status == "ok" else None,
            "url": item.get("url"),
            "created_at": None,
            "parent_id": None,
            "quoted_id": None,
            "media": [],
            "source": "legacy-v1",
            "fetched_at": legacy.get("fetched_at"),
            "attempts": 0,
        }
        added += 1
    write_json_atomic(store_path(obra), data)
    return added


# ── red ──────────────────────────────────────────────────────────────────────

def http_json(url: str, timeout: int = 20) -> tuple[int, dict | None]:
    request = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            body = response.read().decode("utf-8", "replace")
            return response.status, (json.loads(body) if body.strip() else None)
    except urllib.error.HTTPError as err:
        return err.code, None
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, ConnectionError):
        return 0, None


def node_from_syndication(raw: dict) -> dict | None:
    if not isinstance(raw, dict) or raw.get("__typename") not in (None, "Tweet") or not raw.get("user"):
        return None
    user = raw.get("user") or {}
    note = raw.get("note_tweet")
    text = note.get("text") if isinstance(note, dict) and note.get("text") else raw.get("text")
    media = []
    for item in raw.get("mediaDetails") or []:
        media.append(
            {
                "type": item.get("type"),
                "remote_url": item.get("media_url_https"),
                "alt": item.get("ext_alt_text"),
                "local": None,
            }
        )
    tid = raw.get("id_str")
    return {
        "id": tid,
        "user": user.get("screen_name"),
        "name": user.get("name"),
        "user_id": user.get("id_str"),
        "created_at": raw.get("created_at"),
        "text": text,
        "lang": raw.get("lang"),
        "url": f"https://x.com/{user.get('screen_name')}/status/{tid}",
        "parent_id": raw.get("in_reply_to_status_id_str"),
        "quoted_id": (raw.get("quoted_tweet") or {}).get("id_str"),
        "media": media,
        "source": "tweet-result",
    }


def node_from_fxtwitter(raw: dict) -> dict | None:
    tweet = (raw or {}).get("tweet")
    if not isinstance(tweet, dict):
        return None
    author = tweet.get("author") or {}
    media = []
    for item in ((tweet.get("media") or {}).get("all")) or []:
        media.append(
            {
                "type": item.get("type"),
                "remote_url": item.get("thumbnail_url") or item.get("url"),
                "alt": item.get("altText"),
                "local": None,
            }
        )
    created = tweet.get("created_timestamp")
    return {
        "id": str(tweet.get("id")),
        "user": author.get("screen_name"),
        "name": author.get("name"),
        "user_id": str(author.get("id")) if author.get("id") else None,
        "created_at": datetime.fromtimestamp(created, timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000Z")
        if created else None,
        "text": tweet.get("text"),
        "lang": tweet.get("lang"),
        "url": tweet.get("url"),
        "parent_id": tweet.get("replying_to_status"),
        "quoted_id": str((tweet.get("quote") or {}).get("id")) if tweet.get("quote") else None,
        "media": media,
        "source": "fxtwitter",
    }


def fetch_one(obra: Obra, tid: str) -> tuple[str, dict | None, list[dict]]:
    """→ (status, nodo nivel 1, nodos nivel 2 embebidos). Reintenta con backoff."""
    cache = obra.cache_dir / "voices"
    cache.mkdir(parents=True, exist_ok=True)
    delay = 8.0
    for _attempt in range(MAX_ATTEMPTS):
        time.sleep(random.uniform(0.3, 0.8))
        code, raw = http_json(SYNDICATION.format(id=tid))
        if code == 200 and raw is not None:
            (cache / f"{tid}.json").write_text(json.dumps(raw, ensure_ascii=False), encoding="utf-8")
            node = node_from_syndication(raw)
            if node:
                level2 = []
                for key in ("parent", "quoted_tweet"):
                    child = node_from_syndication(raw.get(key) or {})
                    if child:
                        level2.append(child)
                return "ok", node, level2
        if code in (429,) or code >= 500 or code == 0:
            time.sleep(delay)
            delay = min(delay * 2, 64.0)
            continue
        break  # 200 sin tuit, 404, tombstone → segunda opinión
    code, raw = http_json(FXTWITTER.format(id=tid))
    if code == 200 and raw is not None:
        (cache / f"{tid}.fx.json").write_text(json.dumps(raw, ensure_ascii=False), encoding="utf-8")
        node = node_from_fxtwitter(raw)
        if node:
            level2 = []
            quote = node_from_fxtwitter({"tweet": (raw.get("tweet") or {}).get("quote")})
            if quote:
                level2.append(quote)
            return "ok", node, level2
    if code in (401, 403, 404, 410) or (code == 200 and raw is not None):
        return "unavailable", None, []
    return "error", None, []


def run(obra: Obra, refetch_legacy: bool = False, retry_unavailable: bool = False, limit: int = 0) -> dict:
    info = plan(obra)
    work = info["work"]
    data = load(obra)
    tweets = data["tweets"]

    targets = list(info["pending_ids"])
    wanted = set().union(*[set(branch) for branch in work.values()])
    if refetch_legacy:
        targets += sorted(t for t in wanted if (tweets.get(t) or {}).get("status") == "legacy" and t not in targets)
    if retry_unavailable:
        targets += sorted(t for t in wanted if (tweets.get(t) or {}).get("status") == "unavailable" and t not in targets)
    else:
        targets = [t for t in targets if (tweets.get(t) or {}).get("status") != "unavailable"]
    if limit:
        targets = targets[:limit]

    rel_of = {}
    for rel, branch in (("retweet", "retweets"), ("parent", "parents"), ("quote", "quotes")):
        for tid, sources in work[branch].items():
            rel_of.setdefault(tid, []).extend({"rel": rel, "from": src} for src in sources)

    counts = {"ok": 0, "unavailable": 0, "error": 0, "level2": 0}
    done = 0
    with ThreadPoolExecutor(max_workers=WORKERS) as pool:
        futures = {pool.submit(fetch_one, obra, tid): tid for tid in targets}
        for future in as_completed(futures):
            tid = futures[future]
            status, node, level2 = future.result()
            previous = tweets.get(tid) or {}
            entry = {
                "requested_id": tid,
                "level": 1,
                "via": rel_of.get(tid, []),
                "fetched_at": now_iso(),
                "attempts": int(previous.get("attempts") or 0) + 1,
            }
            if status == "ok" and node:
                entry.update(node)
                entry["status"] = "ok"
            elif previous.get("text"):
                # verbatim ya recuperado: se conserva aunque hoy no esté disponible
                entry = {**previous, **entry, "status": previous.get("status") or "legacy", "now": status}
            else:
                entry.update({"id": tid, "status": status, "text": None, "media": []})
            tweets[tid] = entry
            counts[status] += 1
            for child in level2:
                cid = child["id"]
                existing = tweets.get(cid)
                link = {"rel": "level2", "from": tid}
                if existing and existing.get("status") == "ok":
                    if link not in existing.setdefault("via", []):
                        existing["via"].append(link)
                    continue
                child.update({"requested_id": cid, "status": "ok", "level": 2 if cid not in wanted else 1,
                              "via": [link], "fetched_at": now_iso(), "attempts": 0})
                tweets[cid] = child
                counts["level2"] += 1
            done += 1
            if done % 25 == 0:
                write_json_atomic(store_path(obra), data)
                print(f"  … {done}/{len(targets)} {counts}", flush=True)
    write_json_atomic(store_path(obra), data)
    counts["requested"] = len(targets)
    return counts


# ── media de terceros (solo foto / póster, en local) ─────────────────────────

def fetch_media(obra: Obra) -> dict:
    if obra.publish["external_media"] != "local":
        return {"skipped": True}
    data = load(obra)
    dest = obra.cache_dir / "media_ext"
    dest.mkdir(parents=True, exist_ok=True)
    got = skipped = failed = 0
    for tid, node in data["tweets"].items():
        for index, item in enumerate(node.get("media") or []):
            url = item.get("remote_url")
            if not url or item.get("local"):
                continue
            ext = Path(url.split("?")[0]).suffix.lower() or ".jpg"
            if ext not in (".jpg", ".jpeg", ".png", ".webp", ".gif"):
                skipped += 1
                continue
            target = dest / f"{node.get('id') or tid}-{index}{ext}"
            small = url + ("&" if "?" in url else "?") + "name=small" if "pbs.twimg.com/media" in url else url
            try:
                request = urllib.request.Request(small, headers={"User-Agent": UA})
                with urllib.request.urlopen(request, timeout=30) as response:
                    blob = response.read(MEDIA_MAX_BYTES + 1)
                if len(blob) > MEDIA_MAX_BYTES:
                    skipped += 1
                    continue
                target.write_bytes(blob)
                item["local"] = f"data/external_media/{target.name}"
                got += 1
                time.sleep(0.15)
            except (urllib.error.URLError, TimeoutError, ConnectionError, OSError):
                failed += 1
    write_json_atomic(store_path(obra), data)
    return {"downloaded": got, "skipped": skipped, "failed": failed}


def published(obra: Obra) -> dict:
    """Las voces que el visor publica: las alcanzables desde los posts VISIBLES.

    Nivel 1 = ids de la worklist actual; nivel 2 = el padre o el citado de una de ellas. Quedan fuera
    (pero siguen en el store) los duplicados de stores antiguos y las voces de posts ya borrados.
    """
    tweets = load(obra)["tweets"]
    work = read_json(obra.store_dir / "external_worklist.json", {})
    wanted = set().union(*[set(branch) for branch in work.values()]) if work else set()
    keep = {tid: node for tid, node in tweets.items() if tid in wanted}
    for node in list(keep.values()):
        for key in ("parent_id", "quoted_id"):
            child = str(node.get(key) or "")
            if child and child in tweets and child not in keep:
                keep[child] = tweets[child]
    return keep


def summary(obra: Obra) -> dict:
    tweets = load(obra)["tweets"]
    out: dict[str, int] = {}
    for node in tweets.values():
        key = f"{node.get('status')}/L{node.get('level')}"
        out[key] = out.get(key, 0) + 1
    out["total"] = len(tweets)
    return out
