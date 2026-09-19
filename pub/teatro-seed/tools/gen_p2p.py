#!/usr/bin/env python3
"""gen_p2p.py — artefactos P2P de una obra del Teatro (WP-O110, fase 0). Corre DENTRO de teatro-p2p-tools.

Para cada fichero congelado de /obra genera en /obra/p2p/:
  <fichero>.torrent   con semilla web (BEP 19) = la URL HTTPS del propio Teatro
  <fichero>.meta4     metalink: HTTPS + sha256 + torrent
y una vez: p2p.json (fuente única de los enlaces) e index.html (ficha sin JS).

Entradas por variables de entorno:
  P2P_OBRA      nombre de la obra            P2P_BASE_URL  https://<pub>/teatro/<obra>
  P2P_FILES     ficheros, separados por «,»  P2P_TRACKERS  trackers, separados por «,» (vacío = solo DHT/PEX)
  P2P_TITULO    título legible de la obra    P2P_CONGELADO fecha ISO de congelación

Idempotente: un .torrent existente no se rehace (su infohash es el enlace publicado); se verifica.
No firma nada: la firma ed25519 de p2p.json se hace fuera, con la clave que no viaja al host.
"""
import hashlib, html, json, os, re, subprocess, sys, urllib.parse
from datetime import datetime, timezone

OBRA = os.environ["P2P_OBRA"]
BASE = os.environ["P2P_BASE_URL"].rstrip("/")
FILES = [f for f in os.environ["P2P_FILES"].split(",") if f]
TRACKERS = [t for t in os.environ.get("P2P_TRACKERS", "").split(",") if t]
TITULO = os.environ.get("P2P_TITULO", OBRA)
CONGELADO = os.environ.get("P2P_CONGELADO", "")
ROOT, OUT = "/obra", "/obra/p2p"


def run(*cmd):
    return subprocess.run(cmd, check=True, capture_output=True, text=True).stdout


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 22), b""):
            h.update(chunk)
    return h.hexdigest()


def human(n):
    for unit in ("B", "KiB", "MiB", "GiB"):
        if n < 1024 or unit == "GiB":
            return f"{n:.0f} {unit}" if unit == "B" else f"{n:.2f} {unit}"
        n /= 1024


def main():
    os.makedirs(OUT, exist_ok=True)
    items = []
    for name in FILES:
        src = os.path.join(ROOT, name)
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", name) or not os.path.isfile(src):
            sys.exit(f"ERROR: fichero no válido o ausente: {name}")
        size = os.path.getsize(src)
        digest = sha256(src)
        declared = os.path.join(ROOT, name + ".sha256")
        if os.path.isfile(declared):
            want = open(declared).read().split()[0]
            if want != digest:
                sys.exit(f"ERROR: {name}: sha256 {digest} != el publicado {want}. No se genera nada.")
        url = f"{BASE}/{urllib.parse.quote(name)}"
        torrent = os.path.join(OUT, name + ".torrent")
        if not os.path.isfile(torrent):
            piece = "22" if size >= 100 * 1024 * 1024 else "18"   # 4 MiB / 256 KiB
            cmd = ["mktorrent", "-l", piece, "-w", url, "-n", name, "-o", torrent,
                   "-c", f"{TITULO} · Teatro · sha256 {digest} · origen {BASE}/"]
            for t in TRACKERS:
                cmd += ["-a", t]
            if not TRACKERS:
                cmd += ["-a", "udp://tracker.opentrackr.org:1337/announce"]
            run(*cmd, src)
        show = run("transmission-show", torrent)
        infohash = re.search(r"Hash(?: v1)?:\s*([0-9a-f]{40})", show).group(1)
        if url not in show:
            sys.exit(f"ERROR: {torrent} no lleva la semilla web {url}")
        magnet = (f"magnet:?xt=urn:btih:{infohash}&dn={urllib.parse.quote(name)}"
                  + "".join("&tr=" + urllib.parse.quote(t, safe="") for t in TRACKERS)
                  + "&ws=" + urllib.parse.quote(url, safe=""))
        ed2k = run("rhash", "--ed2k-link", src).strip().splitlines()[-1]
        ed2k = re.sub(r"\|file\|[^|]*\|", f"|file|{name}|", ed2k, count=1)
        meta4 = os.path.join(OUT, name + ".meta4")
        with open(meta4, "w", encoding="utf-8") as fh:
            fh.write(f"""<?xml version="1.0" encoding="UTF-8"?>
<metalink xmlns="urn:ietf:params:xml:ns:metalink">
  <file name="{html.escape(name)}">
    <size>{size}</size>
    <hash type="sha-256">{digest}</hash>
    <url priority="1">{html.escape(url)}</url>
    <metaurl mediatype="torrent" priority="2">{html.escape(BASE)}/p2p/{html.escape(name)}.torrent</metaurl>
  </file>
</metalink>
""")
        items.append({"file": name, "size": size, "sizeHuman": human(size), "sha256": digest, "https": url,
                      "sha256Url": url + ".sha256", "sigUrl": url + ".sha256.sig",
                      "torrent": f"{BASE}/p2p/{name}.torrent", "infohash": infohash, "magnet": magnet,
                      "ed2k": ed2k, "metalink": f"{BASE}/p2p/{name}.meta4", "webSeed": url})
    meta = {"obra": OBRA, "titulo": TITULO, "estado": "cartelera", "congelado": CONGELADO,
            "generado": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "origen": BASE + "/", "firmantes": BASE + "/allowed_signers", "trackers": TRACKERS, "ficheros": items}
    with open(os.path.join(OUT, "p2p.json"), "w", encoding="utf-8") as fh:
        json.dump(meta, fh, ensure_ascii=False, indent=2)
        fh.write("\n")
    write_ficha(meta)
    print(json.dumps({"ok": True, "ficheros": [{k: i[k] for k in ("file", "infohash", "sha256")} for i in items]}))


def write_ficha(meta):
    e = html.escape
    rows = []
    for i in meta["ficheros"]:
        rows.append(f"""
<section>
<h2>{e(i['file'])} <small>· {e(i['sizeHuman'])}</small></h2>
<ul>
<li><a href="{e(i['torrent'])}">.torrent</a> (lleva semilla web: baja aunque no haya nadie más)</li>
<li><a href="{e(i['magnet'])}">magnet</a> · infohash <code>{e(i['infohash'])}</code></li>
<li><a href="{e(i['ed2k'])}">ed2k</a> (eMule · aMule)</li>
<li><a href="{e(i['metalink'])}">metalink</a> (aria2c: HTTPS y BitTorrent a la vez)</li>
<li><a href="{e(i['https'])}">HTTPS directo</a></li>
<li>sha256 <code>{e(i['sha256'])}</code> · <a href="{e(i['sha256Url'])}">.sha256</a> · <a href="{e(i['sigUrl'])}">firma ed25519</a></li>
</ul>
</section>""")
    page = f"""<!doctype html>
<html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>{e(meta['titulo'])} · P2P · Teatro</title>
<style>body{{font:16px/1.5 system-ui,sans-serif;max-width:46rem;margin:2rem auto;padding:0 1rem;background:#111;color:#ddd}}
a{{color:#9cf}}code{{word-break:break-all;font-size:.85em}}small{{color:#999}}section{{border-top:1px solid #333;margin-top:1.5rem}}</style>
</head><body>
<p><a href="../">← {e(meta['titulo'])}</a> · <a href="../../">Teatro</a></p>
<h1>{e(meta['titulo'])} · por P2P</h1>
<p><strong>En cartelera.</strong> Estos ficheros están <strong>congelados</strong>{(' desde el ' + e(meta['congelado'])) if meta['congelado'] else ''}:
sus bytes no cambian, así que los enlaces de esta página valen para siempre. Una edición futura saldrá con otro nombre.</p>
{''.join(rows)}
<section><h2>Verificar</h2>
<p>Da igual por dónde llegue: <code>sha256sum -c &lt;fichero&gt;.sha256</code> y la firma con
<code>ssh-keygen -Y verify -f allowed_signers -I teatro@escrivivir.co -n file -s &lt;fichero&gt;.sha256.sig &lt; &lt;fichero&gt;.sha256</code>
(<a href="../allowed_signers">allowed_signers</a>). Todos los enlaces, en <a href="p2p.json">p2p.json</a> (<a href="p2p.json.sig">firma</a>).</p></section>
<section><h2>Ayudar</h2><p>Cuando termine la descarga, <strong>deja tu cliente sembrando</strong>. El pub es un hub, no un almacén:
sostiene la obra mientras está en cartelera; después vive en quien la comparte.</p></section>
<p><small>Generado {e(meta['generado'])} · o-sdk · Teatro del Scriptorium</small></p>
</body></html>
"""
    with open(os.path.join(OUT, "index.html"), "w", encoding="utf-8") as fh:
        fh.write(page)


if __name__ == "__main__":
    main()
