"""Tests del sidecar sobre un export SINTÉTICO generado en un directorio temporal.

No hay datos reales ni fixtures en git. `python -m unittest discover -s pub/rrss-sidecar/twitter_x/tests`
"""

from __future__ import annotations

import json
import os
import sys
import tempfile
import unittest
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

OWN = "1000"
OTHER = "2000"


def tweet(tid, text, date="Wed Jul 08 08:11:30 +0000 2026", reply_to=None, reply_user=None, urls=(), tags=()):
    data = {
        "id_str": tid, "full_text": text, "created_at": date, "lang": "es",
        "entities": {"urls": [{"expanded_url": u} for u in urls], "hashtags": [{"text": t} for t in tags]},
    }
    if reply_to:
        data.update({"in_reply_to_status_id_str": reply_to, "in_reply_to_user_id_str": reply_user,
                     "in_reply_to_screen_name": "alguien"})
    return {"tweet": data}


def write_export(root: Path, generation: str, parts: list[list[dict]], deleted=()):
    data = root / "data"
    (data / "tweets_media").mkdir(parents=True)
    (data / "profile_media").mkdir()
    files = []
    for index, part in enumerate(parts):
        name = "tweets.js" if index == 0 else f"tweets-part{index}.js"
        (data / name).write_text(f"window.YTD.tweets.part{index} = " + json.dumps(part), encoding="utf-8")
        files.append({"fileName": f"data/{name}", "globalName": f"YTD.tweets.part{index}", "count": str(len(part))})
    if deleted:
        (data / "deleted-tweets.js").write_text("window.YTD.deleted_tweets.part0 = " + json.dumps(list(deleted)), encoding="utf-8")
    (data / "account.js").write_text("window.YTD.account.part0 = " + json.dumps(
        [{"account": {"accountId": OWN, "username": "prueba", "accountDisplayName": "Prueba",
                      "email": "secreto@example.org", "createdAt": "2024-01-01T00:00:00.000Z"}}]), encoding="utf-8")
    (data / "profile.js").write_text("window.YTD.profile.part0 = " + json.dumps(
        [{"profile": {"description": {"bio": "bio de prueba", "location": ""}}}]), encoding="utf-8")
    manifest = {"userInfo": {"accountId": OWN, "userName": "prueba", "displayName": "Prueba"},
                "archiveInfo": {"generationDate": f"{generation}T00:00:00.000Z", "isPartialArchive": False, "sizeBytes": "1"},
                "dataTypes": {"tweets": {"files": files, "mediaDirectory": "data/tweets_media"}}}
    (data / "manifest.js").write_text("window.__THAR_CONFIG = " + json.dumps(manifest), encoding="utf-8")
    (data / "tweets_media" / "101-abc.jpg").write_bytes(b"\xff\xd8\xff fake")


class SidecarCase(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        base = Path(self.tmp.name)
        os.environ["TEATRO_LORE_ROOT"] = str(base / "lore")
        os.environ["TEATRO_OUT_ROOT"] = str(base / "out")
        from lib.obra import Obra
        self.obra = Obra("prueba")
        old = self.obra.exports_dir / "2026-01-01"
        new = self.obra.exports_dir / "2026-06-01"
        common = [
            tweet("101", "raíz del hilo #Etiqueta", tags=["Etiqueta"]),
            tweet("102", "segundo del hilo", reply_to="101", reply_user=OWN),
            tweet("103", "réplica a otro", reply_to="900", reply_user=OTHER),
            tweet("104", "RT @otro: texto truncado…"),
        ]
        write_export(old, "2026-01-01", [common + [tweet("199", "este lo borraré")]])
        write_export(new, "2026-06-01", [common, [
            tweet("105", "cito y enlazo", urls=["https://x.com/otro/status/901", "https://x.com/prueba/status/101",
                                                 "https://chatgpt.com/share/6a8bee78-7a54-83ea-8b6a-7aee17b36b46",
                                                 "https://example.org/articulo?utm_source=x"]),
        ]], deleted=[tweet("198", "borrado con registro")])
        self.obra.cfg = {"obra": "prueba", "title": "Prueba", "base": "/teatro/prueba",
                         "account": {"id": OWN, "handle": "prueba", "name": "Prueba"},
                         "own_hosts": [], "publish": {"deleted_posts": "hidden", "external_media": "local", "viewer": False},
                         "sources": [{"generation": "2026-01-01", "path": "exports/2026-01-01"},
                                     {"generation": "2026-06-01", "path": "exports/2026-06-01", "primary": True}]}
        self.obra.save()

    def tearDown(self):
        self.tmp.cleanup()
        os.environ.pop("TEATRO_LORE_ROOT", None)
        os.environ.pop("TEATRO_OUT_ROOT", None)

    def test_multipart_and_duplicates(self):
        from lib import ytd
        data = self.obra.exports_dir / "2026-06-01" / "data"
        self.assertEqual(len(ytd.tweets_of(data)), 5)
        (data / "tweets-part2.js").write_text("window.YTD.tweets.part2 = " + json.dumps([tweet("101", "dup")]), encoding="utf-8")
        with self.assertRaises(SystemExit):
            ytd.tweets_of(data)

    def test_additive_store_hides_deleted(self):
        from lib import normalize, store
        info = store.ingest(self.obra)
        self.assertEqual((info["store"], info["visible"], info["deleted"]), (7, 5, 2))
        ids = {r["id"] for r in normalize.records(self.obra)}
        self.assertNotIn("199", ids)
        self.assertNotIn("198", ids)
        self.assertEqual(store.ingest(self.obra)["store"], 7, "ingest debe ser idempotente")

    def test_normalize_contract(self):
        from lib import normalize, store
        store.ingest(self.obra)
        recs = {r["id"]: r for r in normalize.records(self.obra)}
        self.assertEqual([recs[i]["kind"] for i in ("101", "102", "103", "104")],
                         ["original", "self_reply", "reply_to_other", "retweet"])
        self.assertEqual(recs["102"]["thread_root"], "101")
        self.assertEqual(recs["105"]["quotes"], ["901"])
        self.assertEqual(recs["105"]["self_links"], ["101"])
        self.assertEqual(len(recs["105"]["links"]), 2)
        self.assertEqual(recs["101"]["media"], ["data/tweets_media/101-abc.jpg"])

    def test_link_families_and_keys(self):
        from lib import links
        cases = {
            "https://chatgpt.com/share/abc": "agent:chatgpt",
            "https://chat.deepseek.com/share/x1": "agent:deepseek",
            "https://x.com/i/grok/share/zz": "agent:grok",
            "https://claude.ai/code/artifact/3a5c": "agent:claude",
            "https://www.perplexity.ai/search/q": "agent:perplexity",
            "https://github.com/o/r": "github:repo",
            "https://github.com/o/r/blob/main/a.md": "github:blob",
            "https://gist.github.com/u/0123abcd": "github:gist",
            "https://youtu.be/xyz": "video:youtube",
            "https://docs.midominio.example/p": "own",
            "https://example.org/a": "generic",
        }
        for url, family in cases.items():
            self.assertEqual(links.classify(url, ["midominio.example"]), family, url)
        self.assertEqual(links.key_of("https://Example.org/a?utm_source=x&b=1#frag"), links.key_of("https://example.org/a?b=1"))

    def test_html2md(self):
        from lib import html2md
        title, md = html2md.convert(
            "<html><head><title>Hola</title><script>alert(1)</script></head><body><nav>menú</nav><main>"
            "<h1>Título</h1><p>Un <b>párrafo</b> con <a href='/x'>enlace</a>.</p><ul><li>uno<ul><li>dos</li></ul></li></ul>"
            "<pre><code class='language-py'>print(1)</code></pre></main></body></html>", "https://e.org/base/")
        self.assertEqual(title, "Hola")
        self.assertIn("# Título", md)
        self.assertIn("**párrafo**", md)
        self.assertIn("[enlace](https://e.org/x)", md)
        self.assertIn("```py\nprint(1)\n```", md)
        self.assertIn("  - dos", md)
        self.assertNotIn("alert", md)
        self.assertNotIn("menú", md)

    def test_markdown_render_is_escaped(self):
        from tools.build_site import md_to_html
        out = md_to_html("# T\n\n<script>alert(1)</script> y [x](javascript:alert(1))\n\n```\n<b>\n```")
        self.assertNotIn("<script", out)
        self.assertNotIn("javascript:", out)
        self.assertIn("&lt;b&gt;", out)

    def test_build_and_guards(self):
        from lib import guards, store
        from tools import build_corpus, build_site
        store.ingest(self.obra)
        out = self.obra.out
        build_corpus.build(self.obra, out)
        build_site.build(self.obra, out)
        self.assertEqual(guards.check(out, extra_needles=guards.personal_needles(self.obra.primary()["dir"])), [])
        self.assertTrue((out / "posts" / "105.html").is_file())
        self.assertFalse((out / "posts" / "199.html").exists(), "un post borrado no se publica")
        self.assertIn("/teatro/prueba/", (out / "index.html").read_text(encoding="utf-8"))
        # hostil: un fichero sensible del export y un <script> colado deben hacer fallar las guardas
        (out / "data" / "ip-audit.js").write_text("x", encoding="utf-8")
        (out / "posts" / "101.html").write_text("<script>1</script>", encoding="utf-8")
        problems = "\n".join(guards.check(out))
        self.assertIn("ip-audit.js", problems)
        self.assertIn("<script>", problems)

    def write_editorial(self, **override):
        ed = self.obra.editorial_dir
        (ed / "constructos").mkdir(parents=True)
        (ed / "concepto.md").write_text("<!-- nota privada -->\nLa obra dice «raíz del hilo» [[101]].", encoding="utf-8")
        (ed / "constructos" / "idea.md").write_text("Nace con «segundo (…) hilo» [[102]] y <b>no es HTML</b>.", encoding="utf-8")
        (ed / "letra.md").write_text("verso uno\nverso dos\n", encoding="utf-8")
        (ed / "portada.svg").write_text('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 9 9"><circle cx="4" cy="4" r="3"/></svg>',
                                        encoding="utf-8")
        data = {"version": 1, "curated_by": "custodio", "curated_at": "2026-06-02", "concept": "concepto.md",
                "cover": "portada.svg", "territories": [{"slug": "teoria", "title": "Teoría", "constructs": [
                    {"slug": "idea", "title": "La idea", "text": "constructos/idea.md", "first_id": "101",
                     "post_ids": ["105", "199", "7777"], "thread_roots": ["101"], "terms": ["réplica"]},
                    {"slug": "otra", "title": "Otra", "post_ids": ["103"]}]}],
                "album": {"title": "El cantar", "tracks": [{"n": 1, "title": "Corte", "lyrics": "letra.md",
                                                            "video": "https://example.org/v", "constructs": ["idea"]}]}}
        data.update(override)
        (ed / "obra-semantica.json").write_text(json.dumps(data), encoding="utf-8")

    def test_editorial_layer(self):
        from lib import editorial, guards, normalize, store
        from tools import build_corpus, build_site
        store.ingest(self.obra)
        out = self.obra.out
        build_corpus.build(self.obra, out)
        build_site.build(self.obra, out)
        self.assertFalse((out / "sistema").exists(), "sin capa editorial no hay puerta curada")
        self.assertFalse((out / "indexes" / "sistema.md").exists())
        self.assertTrue((out / "conversaciones.html").is_file())
        self.assertTrue((out / "interlocutores" / "index.html").is_file())

        self.write_editorial()
        records = normalize.records(self.obra)
        ed = editorial.Editorial(self.obra, records, normalize.threads_of(records))
        report = ed.check()
        self.assertEqual(ed.problems, [])
        self.assertEqual(report["quotes_checked"], 2)
        self.assertEqual(ed.constructs["idea"]["curated"], {"101", "102", "105"})
        self.assertEqual(ed.constructs["otra"]["mechanical"], [], "lo curado no se repite como mecánico")
        self.assertEqual(ed.constructs["idea"]["mechanical"], ["103"])
        warned = "\n".join(ed.warnings)
        self.assertIn("199", warned, "un post borrado se avisa y se omite")
        self.assertIn("7777", warned)

        build_corpus.build(self.obra, out)
        build_site.build(self.obra, out)
        self.assertEqual(guards.check(out), [])
        page = (out / "sistema" / "idea.html").read_text(encoding="utf-8")
        self.assertIn("/teatro/prueba/posts/102.html", page)
        self.assertIn("&lt;b&gt;no es HTML", page)
        portada = (out / "index.html").read_text(encoding="utf-8")
        self.assertIn("<svg", portada)
        self.assertNotIn("nota privada", portada)
        self.assertIn("Leer la obra", portada)
        self.assertIn("Recorrer el archivo", portada)
        self.assertIn("/teatro/prueba/sistema/idea.html", (out / "posts" / "105.html").read_text(encoding="utf-8"))
        self.assertIn("verso uno", (out / "cantar" / "01.html").read_text(encoding="utf-8"))
        self.assertIn("CAPA CURADA", (out / "indexes" / "sistema.md").read_text(encoding="utf-8"))

        # hostil: cita inventada, portada activa y ruta que se escapa del lore
        (self.obra.editorial_dir / "concepto.md").write_text("«esto no lo dijo» [[101]]", encoding="utf-8")
        (self.obra.editorial_dir / "portada.svg").write_text('<svg onload="x()"></svg>', encoding="utf-8")
        bad = editorial.Editorial(self.obra, records, normalize.threads_of(records))
        bad.raw["album"]["text"] = "../obra.json"
        bad.check()
        problems = "\n".join(bad.problems)
        self.assertIn("cita no literal", problems)
        self.assertIn("portada no admitida", problems)
        self.assertIn("fuera de editorial", problems)
        (out / "suelto.svg").write_text('<svg><script>1</script></svg>', encoding="utf-8")
        self.assertIn("SVG con contenido activo", "\n".join(guards.check(out)))

    def test_voices_plan_and_legacy_migration(self):
        from lib import store, voices
        store.ingest(self.obra)
        self.obra.legacy_dir.mkdir(parents=True)
        (self.obra.legacy_dir / "external_tweets.json").write_text(json.dumps({"fetched_at": "2026-01-02", "tweets": {
            "900": {"requested_id": "900", "status": "ok", "final_id": "900", "user": "otro", "name": "Otro", "text": "texto del padre"},
            "104": {"requested_id": "104", "status": "unavailable"}}}), encoding="utf-8")
        self.assertEqual(voices.migrate_legacy(self.obra), 2)
        info = voices.plan(self.obra)
        self.assertEqual((info["retweets"], info["parents"], info["quotes"]), (1, 1, 1))
        tweets = voices.load(self.obra)["tweets"]
        self.assertEqual(tweets["900"]["text"], "texto del padre")
        self.assertEqual(tweets["104"]["status"], "unavailable")
        self.assertIn("901", info["pending_ids"])
        self.assertNotIn("104", info["pending_ids"])


if __name__ == "__main__":
    unittest.main()
