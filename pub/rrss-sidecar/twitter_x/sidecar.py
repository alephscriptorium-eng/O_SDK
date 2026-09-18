#!/usr/bin/env python3
"""rrss-sidecar · twitter_x — de un export de cuenta de X a una obra del Teatro.

  lore  (ARCHIVO/LORE/twitter_x/<obra>/)  →  corpus normalizado  →  visor (volumes-dev/teatro/<obra>/)

Flujo típico:
  sidecar.py lore-import --obra mi-obra --from "C:/ruta/al/export/descomprimido"
  sidecar.py init        --obra mi-obra [--title "Mi Obra"]
  sidecar.py ingest      --obra mi-obra
  sidecar.py fetch-voices --obra mi-obra --migrate --run      # voces ajenas a 1-2 niveles
  sidecar.py fetch-links  --obra mi-obra --run                # enlaces externos → markdown
  sidecar.py build       --obra mi-obra
  sidecar.py check       --obra mi-obra

Solo stdlib de Python ≥ 3.10. Guía completa: pub/rrss-sidecar/twitter_x/README.md
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
for _stream in (sys.stdout, sys.stderr):  # consolas Windows (cp1252) al lanzar desde npm
    try:
        _stream.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, ValueError):
        pass

from lib import guards, links, store, voices, ytd  # noqa: E402
from lib.obra import Obra, generation_of, read_manifest, repo_root  # noqa: E402

NOT_IN_MANIFEST = (".zip", ".sha256", ".sig")


def human(n: int) -> str:
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1024 or unit == "GB":
            return f"{n:.1f} {unit}" if unit != "B" else f"{n} B"
        n /= 1024
    return f"{n} B"


def tree_stats(root: Path) -> tuple[int, int]:
    files = size = 0
    for path in root.rglob("*"):
        if path.is_file():
            files, size = files + 1, size + path.stat().st_size
    return files, size


def sha256(path: Path) -> str:
    return store.sha256_file(path)


# ── lore-import ──────────────────────────────────────────────────────────────

def copy_tree(src: Path, dst: Path) -> None:
    dst.mkdir(parents=True, exist_ok=True)
    if os.name == "nt" and shutil.which("robocopy"):
        code = subprocess.run(
            ["robocopy", str(src), str(dst), "/E", "/R:1", "/W:1", "/NFL", "/NDL", "/NJH", "/NJS", "/NP",
             "/XF", ".DS_Store"], capture_output=True).returncode
        if code >= 8:
            raise SystemExit(f"robocopy devolvió {code}")
        return
    shutil.copytree(src, dst, dirs_exist_ok=True, ignore=shutil.ignore_patterns(".DS_Store"))


def cmd_lore_import(args) -> int:
    obra = Obra(args.obra)
    if args.from_dir:
        src = Path(args.from_dir).resolve()
        if not (src / "data" / "manifest.js").is_file():
            raise SystemExit(f"{src} no parece un export de X descomprimido (falta data/manifest.js)")
        manifest = read_manifest(src)
        generation = generation_of(manifest)
        if not generation:
            raise SystemExit("el manifest no trae archiveInfo.generationDate")
        dst = obra.exports_dir / generation
        if src == dst.resolve():
            raise SystemExit("origen y destino son el mismo directorio")
        print(f"→ {generation}: {src}  →  {dst}")
        copy_tree(src, dst)
        (n_src, b_src), (n_dst, b_dst) = tree_stats(src), tree_stats(dst)
        ds = sum(1 for p in src.rglob(".DS_Store"))
        if n_dst < n_src - ds or b_dst < b_src - ds * 20000:
            raise SystemExit(f"copia incompleta: origen {n_src} ficheros/{b_src} B, destino {n_dst}/{b_dst}")
        for name in ("manifest.js", "tweets.js"):
            if sha256(src / "data" / name) != sha256(dst / "data" / name):
                raise SystemExit(f"sha256 distinto tras la copia: data/{name}")
        sources = [s for s in obra.cfg.get("sources") or [] if s["generation"] != generation]
        sources.append({"generation": generation, "path": f"exports/{generation}"})
        sources.sort(key=lambda s: s["generation"])
        for item in sources:
            item.pop("primary", None)
        sources[-1]["primary"] = True
        obra.cfg.setdefault("obra", obra.name)
        obra.cfg["sources"] = sources
        obra.save()
        print(f"✅ {generation}: {n_dst} ficheros · {human(b_dst)} · sha256 de manifest.js y tweets.js verificados")
    if args.legacy:
        src = Path(args.legacy).resolve()
        obra.legacy_dir.mkdir(parents=True, exist_ok=True)
        for name in ("external_tweets.json", "external_worklist.json"):
            if (src / name).is_file():
                shutil.copy2(src / name, obra.legacy_dir / name)
                if sha256(src / name) != sha256(obra.legacy_dir / name):
                    raise SystemExit(f"sha256 distinto tras la copia: {name}")
                print(f"✅ legacy/{name}")
    return 0


def cmd_init(args) -> int:
    obra = Obra(args.obra)
    if not obra.cfg.get("sources"):
        raise SystemExit("la obra no tiene exports: ejecuta antes `lore-import`")
    primary = obra.primary()
    manifest = read_manifest(primary["dir"])
    user = manifest.get("userInfo") or {}
    account = (ytd.parse_ytd(primary["dir"] / "data", "account", required=False) or [{}])[0].get("account", {})
    cfg = obra.cfg
    cfg["obra"] = obra.name
    cfg["adapter"] = "twitter_x"
    cfg["title"] = args.title or cfg.get("title") or obra.name.replace("-", " ").title()
    cfg["base"] = args.base or cfg.get("base") or f"/teatro/{obra.name}"
    cfg["account"] = {
        "id": str(user.get("accountId") or account.get("accountId") or ""),
        "handle": user.get("userName") or account.get("username") or "",
        "name": user.get("displayName") or account.get("accountDisplayName") or "",
    }
    cfg.setdefault("stamp", "Obra")
    cfg.setdefault("tagline", "El archivo de una cuenta como pieza en actos, escenas y apartes.")
    cfg.setdefault("own_hosts", [])
    cfg.setdefault("publish", {"deleted_posts": "hidden", "external_media": "local", "viewer": True})
    obra.save()
    print(f"✅ {obra.config_path}")
    print(json.dumps({k: cfg[k] for k in ("obra", "title", "base", "account", "sources")}, ensure_ascii=False, indent=1))
    return 0


def cmd_ingest(args) -> int:
    print("ingest ok ·", store.ingest(Obra(args.obra).require()))
    return 0


# ── protocolos ───────────────────────────────────────────────────────────────

def cmd_fetch_voices(args) -> int:
    obra = Obra(args.obra).require()
    if args.migrate:
        print(f"migrados del store antiguo: {voices.migrate_legacy(obra)}")
    info = voices.plan(obra)
    print("worklist ·", {k: info[k] for k in ("retweets", "parents", "quotes", "level1", "pending")})
    if args.run:
        print("fetch ·", voices.run(obra, args.refetch_legacy, args.retry_unavailable, args.limit))
    if args.media:
        print("media ·", voices.fetch_media(obra))
    print("store ·", voices.summary(obra))
    return 0


def cmd_fetch_links(args) -> int:
    obra = Obra(args.obra).require()
    info = links.plan(obra)
    print(f"enlaces: {info['urls']}")
    for family, counts in sorted(info["by_family"].items()):
        print(f"  {family:<18} {counts}")
    if not args.run:
        return 0
    code = links.run(obra, args.family, args.retry, args.limit)
    final = links.plan(obra)
    print("resumen ·", {f: c for f, c in sorted(final["by_family"].items())})
    pending = sum(1 for e in links.load(obra).values() if e["status"] == "pending_browser")
    if pending:
        print(f"⏳ {pending} en la cola de navegador: `sidecar.py browser-next --obra {obra.name}`")
    return code


def cmd_browser_next(args) -> int:
    item = links.browser_next(Obra(args.obra).require())
    print(json.dumps(item, ensure_ascii=False, indent=1) if item else "cola de navegador vacía")
    return 0


def cmd_browser_save(args) -> int:
    obra = Obra(args.obra).require()
    links.browser_save(obra, args.hash, args.title, Path(args.md_file), args.final_url, args.meta)
    print(f"✅ guardado {args.hash}")
    return 0


def cmd_link_mark(args) -> int:
    links.mark(Obra(args.obra).require(), args.hash, args.status, args.note, args.waived_by)
    print(f"{args.hash} -> {args.status}")
    return 0


def cmd_link_public_url(args) -> int:
    links.set_public_url(Obra(args.obra).require(), args.hash, args.url)
    print(f"{args.hash} public_url = {args.url}")
    return 0


def cmd_browser_block(args) -> int:
    obra = Obra(args.obra).require()
    links.browser_block(obra, args.hash, args.evidence)
    links.print_blocked(links.active_blocked(obra))
    return links.EXIT_BLOCKED


# ── capa editorial (puerta semántica, curada por el custodio) ──

def load_editorial(obra: Obra):
    from lib import editorial, normalize

    records = normalize.records(obra)
    return editorial.Editorial(obra, records, normalize.threads_of(records), links.load(obra))


def cmd_editorial_init(args) -> int:
    obra = Obra(args.obra).require()
    target = obra.editorial_dir
    if (target / "obra-semantica.json").exists():
        print(f"ya existe {target / 'obra-semantica.json'}: no se toca")
        return 0
    copy_tree(Path(__file__).resolve().parent / "editorial.example", target)
    print(f"✅ esqueleto editorial en {target}\n   edita obra-semantica.json y los .md; luego: sidecar.py editorial-check --obra {obra.name}")
    return 0


def cmd_editorial_check(args) -> int:
    ed = load_editorial(Obra(args.obra).require())
    if not ed.present:
        print("esta obra no tiene capa editorial (editorial/obra-semantica.json): nada que comprobar")
        return 0
    report = ed.check()
    print("editorial ·", " · ".join(f"{k}: {v}" for k, v in report.items()))
    for line in ed.warnings:
        print("   aviso ·", line)
    for line in ed.problems:
        print("   ⛔", line)
    if args.verbose:
        for c in ed.constructs.values():
            print(f"   {c['territory']:>10} / {c['slug']:<28} curados {len(c['curated']):>3} · mecánicos {len(c['mechanical']):>3}")
    print("✅ capa editorial OK" if not ed.problems else f"⛔ {len(ed.problems)} errores")
    return 1 if ed.problems else 0


def cmd_editorial_delta(args) -> int:
    ed = load_editorial(Obra(args.obra).require())
    since = args.since or ed.raw.get("curated_at") or ""
    if not since:
        print("indica --since AAAA-MM-DD (la capa no tiene `curated_at`)")
        return 2
    delta = ed.delta(since)
    print(f"desde {since}: {len(delta['fresh'])} posts propios · {len(delta['uncurated'])} sin curar")
    for slug, ids in delta["suggestions"].items():
        print(f"\n  candidatos a `{slug}` (por sus términos): {len(ids)}")
        for pid in ids[: args.limit]:
            print(f"    {pid}  {ed.by_id[pid]['created_at'][:10]}  {' '.join(ed.by_id[pid]['text'].split())[:90]}")
    print(f"\n  sin constructo que los reclame: {len(delta['orphans'])}")
    for r in delta["orphans"][: args.limit]:
        print(f"    {r['id']}  {r['created_at'][:10]}  {' '.join(r['text'].split())[:90]}")
    return 0


# ── build / check / manifest / pack ──────────────────────────────────────────

def resolve_out(args, obra: Obra) -> Path:
    return Path(args.out).resolve() if getattr(args, "out", None) else obra.out


def run_guards(obra: Obra | None, out: Path, strict: bool) -> int:
    needles = guards.personal_needles(obra.primary()["dir"]) if obra else []
    needles += [str(repo_root()), repo_root().as_posix()]  # la ruta del operador tampoco se publica
    problems = guards.check(out, allow_placeholders=not strict, extra_needles=needles)
    if problems:
        print(f"⛔ {len(problems)} violaciones de invariantes en {out}:")
        for line in problems[:40]:
            print("   -", line)
        return 1
    print(f"✅ invariantes OK · {out}")
    return 0


def cmd_build(args) -> int:
    from tools import build_corpus, build_site, build_viewer

    obra = Obra(args.obra).require()
    blocked = links.active_blocked(obra)
    if blocked and not args.allow_blocked:
        links.print_blocked(blocked)
        print("build detenido: hay shares de agente bloqueados (REGLA PARAR).")
        return links.EXIT_BLOCKED
    out = resolve_out(args, obra)
    out.mkdir(parents=True, exist_ok=True)
    ed = load_editorial(obra)
    if ed.present:
        ed.check()
        if ed.problems:
            for line in ed.problems:
                print("   ⛔ editorial ·", line)
            print("build detenido: corrige la capa editorial (sidecar.py editorial-check).")
            return 1
    build_corpus.build(obra, out)
    build_site.build(obra, out)
    build_viewer.build(obra, out)
    catalog = repo_root() / "pub" / "site-templates" / "teatro" / "index.html"
    if catalog.is_file() and out.parent.is_dir():
        shutil.copy2(catalog, out.parent / "index.html")
    return run_guards(obra, out, strict=False)


def cmd_check(args) -> int:
    if args.dir:
        return run_guards(None, Path(args.dir).resolve(), strict=args.strict)
    obra = Obra(args.obra).require()
    code = run_guards(obra, resolve_out(args, obra), strict=args.strict)
    tracked = subprocess.run(["git", "-C", str(repo_root()), "ls-files", "ARCHIVO/LORE"],
                             capture_output=True, text=True).stdout.split()
    leaked = [t for t in tracked if Path(t).name not in ("README.md", ".gitignore")]
    if leaked:
        print(f"⛔ hay lore trackeado en git: {leaked[:5]}")
        code = 1
    return code


def manifest_files(out: Path) -> list[Path]:
    keep = []
    for path in sorted(out.rglob("*")):
        if not path.is_file():
            continue
        name = path.name
        if name.startswith("MANIFEST.sha256") or name == "allowed_signers":
            continue
        if path.parent == out and (name.endswith(NOT_IN_MANIFEST) or name == "index.html"):
            continue  # la portada se estampa en el VPS con el sha del zip: no puede ir en el manifiesto
        keep.append(path)
    return keep


def cmd_manifest(args) -> int:
    out = Path(args.dir).resolve() if args.dir else resolve_out(args, Obra(args.obra).require())
    files = manifest_files(out)
    lines = [f"{sha256(p)}  ./{p.relative_to(out).as_posix()}" for p in files]
    (out / "MANIFEST.sha256").write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
    total = sum(p.stat().st_size for p in files)
    print(f"✅ MANIFEST.sha256 · {len(files)} ficheros · {human(total)}")
    return 0


def cmd_pack(args) -> int:
    """Zips locales (alternativa al zip en el VPS que hace el deploy)."""
    obra = Obra(args.obra).require()
    out = resolve_out(args, obra)
    files = manifest_files(out)
    brain_roots = ("corpus/", "indexes/", "tools/", "AGENTS.md", "data/external_", "data/links_")
    for name, selector, method in (
        (f"{obra.name}-cerebro.zip", lambda rel: rel.startswith(brain_roots), zipfile.ZIP_DEFLATED),
        (f"{obra.name}.zip", lambda rel: True, zipfile.ZIP_STORED),
    ):
        if name == f"{obra.name}.zip" and not args.full:
            continue
        target = out / name
        with zipfile.ZipFile(target.with_suffix(".zip.tmp"), "w", method, allowZip64=True) as handle:
            for path in files:
                rel = path.relative_to(out).as_posix()
                if selector(rel):
                    handle.write(path, f"{obra.name}/{rel}")
        target.with_suffix(".zip.tmp").replace(target)
        digest = hashlib.sha256(target.read_bytes()).hexdigest() if target.stat().st_size < (1 << 28) else sha256(target)
        (out / f"{name}.sha256").write_text(f"{digest}  {name}\n", encoding="utf-8", newline="\n")
        print(f"✅ {name} · {human(target.stat().st_size)} · {digest}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="cmd", required=True)

    def add(name, func, help_):
        p = sub.add_parser(name, help=help_)
        p.set_defaults(func=func)
        return p

    p = add("lore-import", cmd_lore_import, "copia un export descomprimido al lore de la obra (verificado)")
    p.add_argument("--obra", required=True)
    p.add_argument("--from", dest="from_dir", help="directorio del export (contiene data/manifest.js)")
    p.add_argument("--legacy", help="directorio con external_tweets.json del pipeline antiguo")

    p = add("init", cmd_init, "crea/actualiza obra.json desde el manifest del export primario")
    p.add_argument("--obra", required=True)
    p.add_argument("--title")
    p.add_argument("--base")

    add("ingest", cmd_ingest, "store aditivo multi-generación").add_argument("--obra", required=True)

    p = add("fetch-voices", cmd_fetch_voices, "protocolo (a): voces ajenas a 1-2 niveles")
    p.add_argument("--obra", required=True)
    p.add_argument("--migrate", action="store_true", help="importa el store v1 de legacy/")
    p.add_argument("--run", action="store_true")
    p.add_argument("--refetch-legacy", action="store_true", help="re-consulta los migrados para ganar fecha, media y nivel 2")
    p.add_argument("--retry-unavailable", action="store_true")
    p.add_argument("--media", action="store_true", help="descarga foto/póster de terceros (≤600 KB)")
    p.add_argument("--limit", type=int, default=0)

    p = add("fetch-links", cmd_fetch_links, "protocolo (b): enlaces externos → markdown")
    p.add_argument("--obra", required=True)
    p.add_argument("--run", action="store_true")
    p.add_argument("--retry", action="store_true", help="reintenta también blocked y gone")
    p.add_argument("--family", action="append", help="prefijo de familia (repetible): agent, github, own, generic, video")
    p.add_argument("--limit", type=int, default=0)

    add("browser-next", cmd_browser_next, "siguiente página de la cola de navegador").add_argument("--obra", required=True)
    p = add("browser-save", cmd_browser_save, "guarda el markdown extraído con el navegador")
    p.add_argument("--obra", required=True)
    p.add_argument("--hash", required=True)
    p.add_argument("--title", required=True)
    p.add_argument("--md-file", required=True)
    p.add_argument("--final-url")
    p.add_argument("--meta", action="store_true", help="solo metadatos (vídeo): admite texto breve; nunca para agent:*")
    p = add("link-mark", cmd_link_mark, "marca un enlace no-agente como gone | link_only | pending")
    p.add_argument("--obra", required=True)
    p.add_argument("--hash", required=True)
    p.add_argument("--status", required=True, choices=["gone", "link_only", "pending"])
    p.add_argument("--note", default="")
    p.add_argument("--waived-by", default="", help="dispensa del custodio: deja un share de agente como enlace, sin rescatarlo")
    p = add("link-public-url", cmd_link_public_url, "anota la URL pública con que el autor republicó un share")
    p.add_argument("--obra", required=True)
    p.add_argument("--hash", required=True)
    p.add_argument("--url", required=True)
    p = add("browser-block", cmd_browser_block, "REGLA PARAR: el share resultó privado o caducado")
    p.add_argument("--obra", required=True)
    p.add_argument("--hash", required=True)
    p.add_argument("--evidence", required=True)

    add("editorial-init", cmd_editorial_init, "crea el esqueleto de la capa curada en el lore").add_argument("--obra", required=True)
    p = add("editorial-check", cmd_editorial_check, "verifica ids, ficheros, citas literales y cobertura de la capa curada")
    p.add_argument("--obra", required=True)
    p.add_argument("-v", "--verbose", action="store_true")
    p = add("editorial-delta", cmd_editorial_delta, "posts nuevos aún sin curar (tras un export nuevo)")
    p.add_argument("--obra", required=True)
    p.add_argument("--since", help="fecha ISO; por defecto `curated_at`")
    p.add_argument("--limit", type=int, default=40)

    p = add("build", cmd_build, "corpus + sitio + visor + guardas")
    p.add_argument("--obra", required=True)
    p.add_argument("--out")
    p.add_argument("--allow-blocked", action="store_true", help="solo con dispensa explícita del custodio")

    p = add("check", cmd_check, "invariantes de publicación")
    p.add_argument("--obra")
    p.add_argument("--dir", help="comprueba un árbol ya generado (pre-vuelo del deploy)")
    p.add_argument("--out")
    p.add_argument("--strict", action="store_true", help="falla si quedan placeholders sin estampar")

    p = add("manifest", cmd_manifest, "escribe MANIFEST.sha256 de la obra")
    p.add_argument("--obra")
    p.add_argument("--dir")
    p.add_argument("--out")

    p = add("pack", cmd_pack, "zips locales (cerebro; --full añade el zip completo)")
    p.add_argument("--obra", required=True)
    p.add_argument("--out")
    p.add_argument("--full", action="store_true")

    args = parser.parse_args()
    if args.cmd == "check" and not (args.obra or args.dir):
        parser.error("check necesita --obra o --dir")
    if args.cmd == "manifest" and not (args.obra or args.dir):
        parser.error("manifest necesita --obra o --dir")
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
