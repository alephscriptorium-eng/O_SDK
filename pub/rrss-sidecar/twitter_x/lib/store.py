"""Store aditivo multi-generación de los posts propios.

Cada export completo de X es una *generación*. Entre generaciones el autor puede borrar posts:
esos ids desaparecen del export nuevo y «solo existen en la capa histórica». El store nunca
borra: hace upsert por id y anota en qué generaciones se vio cada post.

  store/posts.json        {id: {tweet, generations[], first_seen, last_seen, deleted, origin}}
  store/generations.json  [{generation, path, count, tweets_sha256, is_partial}]

`deleted` = el id no está en la generación primaria (la más reciente). Un post `deleted` se
conserva aquí pero NO se publica (`publish.deleted_posts: hidden`).
"""

from __future__ import annotations

import hashlib
from pathlib import Path

from . import ytd
from .obra import Obra, read_json, read_manifest, write_json_atomic


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def ingest(obra: Obra) -> dict:
    posts: dict[str, dict] = read_json(obra.store_dir / "posts.json", {})
    generations = []
    primary = obra.primary()
    primary_ids: set[str] = set()

    for gen in obra.generations():
        data_dir = gen["dir"] / "data"
        manifest = read_manifest(gen["dir"])
        tweets = ytd.tweets_of(data_dir)
        expected = sum(
            int(f.get("count", 0))
            for f in ((manifest.get("dataTypes") or {}).get("tweets") or {}).get("files") or []
        )
        if expected and expected != len(tweets):
            raise SystemExit(
                f"{gen['generation']}: el manifest declara {expected} tweets y hay {len(tweets)}"
            )
        name = gen["generation"]
        for tweet in tweets:
            _upsert(posts, tweet, name, "tweets.js")
        for tweet in ytd.tweets_of(data_dir, "deleted-tweets", required=False):
            _upsert(posts, tweet, name, "deleted-tweets.js", authoritative=False)
        if gen is primary or gen["generation"] == primary["generation"]:
            primary_ids = {t["id_str"] for t in tweets}
        generations.append(
            {
                "generation": name,
                "path": gen["path"],
                "count": len(tweets),
                "tweets_sha256": sha256_file(ytd.part_files(data_dir, "tweets")[0]),
                "is_partial": bool((manifest.get("archiveInfo") or {}).get("isPartialArchive")),
            }
        )

    for tweet_id, entry in posts.items():
        entry["deleted"] = tweet_id not in primary_ids

    write_json_atomic(obra.store_dir / "posts.json", posts)
    write_json_atomic(obra.store_dir / "generations.json", generations)
    visible = sum(1 for e in posts.values() if not e["deleted"])
    return {
        "generations": len(generations),
        "store": len(posts),
        "visible": visible,
        "deleted": len(posts) - visible,
        "primary": primary["generation"],
    }


def _upsert(posts: dict, tweet: dict, generation: str, origin: str, authoritative: bool = True) -> None:
    tweet_id = tweet["id_str"]
    entry = posts.get(tweet_id)
    if entry is None:
        posts[tweet_id] = {
            "tweet": tweet,
            "generations": [generation],
            "first_seen": generation,
            "last_seen": generation,
            "deleted": False,
            "origin": origin,
        }
        return
    if generation not in entry["generations"]:
        entry["generations"].append(generation)
        entry["generations"].sort()
    # El contenido es el de la generación más reciente que lo trae en tweets.js.
    if authoritative and generation >= entry["last_seen"]:
        entry["tweet"] = tweet
        entry["origin"] = origin
    entry["first_seen"] = min(entry["first_seen"], generation)
    entry["last_seen"] = max(entry["last_seen"], generation)


def load_posts(obra: Obra) -> dict[str, dict]:
    posts = read_json(obra.store_dir / "posts.json", None)
    if posts is None:
        raise SystemExit("store vacío: ejecuta `sidecar.py ingest --obra <obra>`")
    return posts


def visible_tweets(obra: Obra) -> list[dict]:
    hidden = obra.publish["deleted_posts"] == "hidden"
    return [e["tweet"] for e in load_posts(obra).values() if not (hidden and e["deleted"])]
