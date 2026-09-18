#!/usr/bin/env python3
"""Fetch remaining RT originals via the public FixTweet/fxtwitter API."""

from __future__ import annotations

import json
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

PAUSE = 1.1
BACKOFF = 8.0
UA = "TWITTER_FILM-corpus-recover/1.0"


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def remaining_rts(root: Path) -> list[str]:
    dest = root / "data" / "external_tweets.json"
    wl = json.loads((root / "data" / "external_worklist.json").read_text(encoding="utf-8"))
    done = set()
    if dest.exists():
        tweets = json.loads(dest.read_text(encoding="utf-8")).get("tweets", {})
        done = {
            tid
            for tid, item in tweets.items()
            if isinstance(item, dict) and item.get("status") in {"ok", "unavailable"}
        }
    return [row["rt_id"] for row in wl["retweets"] if row["rt_id"] not in done]


def load_store(root: Path) -> dict:
    dest = root / "data" / "external_tweets.json"
    if dest.exists():
        return json.loads(dest.read_text(encoding="utf-8"))
    return {"tweets": {}, "parent_of_reply": {}, "original_of_rt": {}}


def save_store(root: Path, data: dict) -> None:
    dest = root / "data" / "external_tweets.json"
    data["fetched_at"] = datetime.now(timezone.utc).isoformat()
    dest.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def fetch_one(rt_id: str) -> dict:
    url = f"https://api.fxtwitter.com/_dev_aleph_1/status/{rt_id}"
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            payload = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        if exc.code in {404, 403}:
            return {
                "requested_id": rt_id,
                "status": "unavailable",
                "final_id": rt_id,
                "user": None,
                "name": None,
                "text": None,
                "url": f"https://x.com/_dev_aleph_1/status/{rt_id}",
                "source": "fxtwitter",
                "http_status": exc.code,
            }
        return {"requested_id": rt_id, "status": "error", "error": f"HTTP {exc.code}"}
    except Exception as exc:
        return {"requested_id": rt_id, "status": "error", "error": str(exc)}

    tweet = payload.get("tweet") or {}
    code = payload.get("code")
    text = (tweet.get("text") or "").strip()
    author = tweet.get("author") or {}
    user = author.get("screen_name")
    name = author.get("name")
    final_id = tweet.get("id") or rt_id
    tweet_url = tweet.get("url") or (f"https://x.com/{user}/status/{final_id}" if user else None)

    if code == 200 and (text or (user and final_id and final_id != rt_id)):
        return {
            "requested_id": rt_id,
            "status": "ok",
            "final_id": str(final_id),
            "user": user,
            "name": name,
            "text": tweet.get("text") or "",
            "url": tweet_url,
            "source": "fxtwitter",
        }
    if code in {404, 401, 403} or not tweet:
        return {
            "requested_id": rt_id,
            "status": "unavailable",
            "final_id": rt_id,
            "user": user,
            "name": name,
            "text": None,
            "url": f"https://x.com/_dev_aleph_1/status/{rt_id}",
            "source": "fxtwitter",
            "api_code": code,
            "message": payload.get("message"),
        }
    return {
        "requested_id": rt_id,
        "status": "error",
        "error": f"unexpected code={code} message={payload.get('message')}",
        "api_code": code,
    }


def main() -> int:
    root = repo_root()
    ids = remaining_rts(root)
    print(f"remaining rts: {len(ids)}")
    data = load_store(root)
    tweets = data.setdefault("tweets", {})
    ok = unav = err = 0
    for i, rt_id in enumerate(ids, 1):
        item = fetch_one(rt_id)
        status = item.get("status")
        print(f"[{i}/{len(ids)}] {rt_id} {status} user={item.get('user')} final={item.get('final_id')}")
        if status in {"ok", "unavailable"}:
            tweets[rt_id] = item
            final_id = item.get("final_id")
            if final_id and final_id != rt_id:
                tweets[str(final_id)] = {**item, "requested_id": str(final_id)}
            if status == "ok":
                ok += 1
            else:
                unav += 1
            if i % 5 == 0 or i == len(ids):
                save_store(root, data)
        else:
            err += 1
            time.sleep(BACKOFF)
        time.sleep(PAUSE)
    save_store(root, data)
    print(f"done ok={ok} unavailable={unav} error={err}")
    print(f"remaining after: {len(remaining_rts(root))}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
