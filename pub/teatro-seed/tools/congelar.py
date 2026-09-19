#!/usr/bin/env python3
"""congelar.py — marca una obra del Teatro como CONGELADA (WP-O110). Corre en el host, dentro de <obra>/.

Uso: python3 - <obra> <fichero,fichero> <motivo>   (teatro-p2p.sh lo envía por stdin)

Comprueba cada fichero contra su .sha256 publicado y escribe CONGELADO.json. Si la marca ya existe,
solo verifica que los bytes siguen siendo los mismos: nunca re-congela con otros hashes.
"""
import hashlib, json, os, sys
from datetime import datetime, timezone

obra, files, motivo = sys.argv[1], sys.argv[2].split(","), sys.argv[3]


def sha(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 22), b""):
            h.update(chunk)
    return h.hexdigest()


items = []
for f in files:
    if not (os.path.isfile(f) and os.path.isfile(f + ".sha256")):
        sys.exit(f"ERROR: falta {f} o su .sha256")
    have, want = sha(f), open(f + ".sha256").read().split()[0]
    if have != want:
        sys.exit(f"ERROR: {f}: sha256 {have} != publicado {want}. PARAR.")
    items.append({"file": f, "size": os.path.getsize(f), "sha256": have})

if os.path.isfile("CONGELADO.json"):
    old = json.load(open("CONGELADO.json", encoding="utf-8"))
    if [(i["file"], i["sha256"]) for i in old["ficheros"]] != [(i["file"], i["sha256"]) for i in items]:
        sys.exit("ERROR: los ficheros YA NO coinciden con CONGELADO.json. PARAR: alguien los ha regenerado.")
    print("ya congelada; los hashes coinciden:")
    print(json.dumps(old, ensure_ascii=False, indent=2))
    sys.exit(0)

meta = {
    "obra": obra,
    "congelado": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
    "motivo": motivo,
    "regla": "estos ficheros no se regeneran ni se sustituyen; una edición nueva sale con sufijo (TEATRO_ZIP_SUFIJO)",
    "ficheros": items,
}
with open("CONGELADO.json", "w", encoding="utf-8") as fh:
    json.dump(meta, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
os.chmod("CONGELADO.json", 0o444)
for f in files:
    os.chmod(f, 0o444)
print(json.dumps(meta, ensure_ascii=False, indent=2))
