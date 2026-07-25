#!/usr/bin/env python3
# =============================================================================
# directory-status.py — deriva el estado de red desde oasis-project.pub/api/pubs.
#
# Lee el JSON del directorio por STDIN y emite líneas KEY=VALUE (para `eval` en
# bash). El "ciclo actual" no viene como campo top-level: se deriva como el
# max(cycle) entre los pubs online; el "cap actual" es el shs mayoritario en ese
# ciclo. Localiza además la fila de nuestro pub (OUR_PUB_HOST).
#
# Uso:  curl -s https://oasis-project.pub/api/pubs | \
#         OUR_PUB_HOST=pub.escrivivir.co python3 scripts/directory-status.py
# =============================================================================
import sys
import os
import json
from collections import Counter

host = os.environ.get("OUR_PUB_HOST", "pub.escrivivir.co")


def emit(key, value):
    print("%s=%s" % (key, "" if value is None else value))


try:
    data = json.load(sys.stdin)
except Exception:
    emit("PARSE_ERR", "1")
    sys.exit(0)

if not isinstance(data, list):
    data = data.get("pubs", []) if isinstance(data, dict) else []

online = [p for p in data if p.get("status") == "online" and isinstance(p.get("cycle"), int)]
cur_cycle = max((p["cycle"] for p in online), default="")

shs_counter = Counter(
    p.get("shs") for p in online if p.get("cycle") == cur_cycle and p.get("shs")
)
cur_shs = shs_counter.most_common(1)[0][0] if shs_counter else ""

emit("CUR_CYCLE", cur_cycle)
emit("CUR_SHS", cur_shs)

me = next((p for p in data if p.get("host") == host), None)
if me is None:
    emit("SELF_PRESENT", "0")
else:
    emit("SELF_PRESENT", "1")
    emit("SELF_CYCLE", me.get("cycle"))
    emit("SELF_SHS", me.get("shs"))
    emit("SELF_STATUS", me.get("status"))
