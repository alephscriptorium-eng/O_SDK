#!/usr/bin/env bash
# regenerar.sh — regenera TODO lo derivado del dosier de la 26S desde el organigrama (el JSON manda), en orden y de
# forma determinista. Pasadas plantilla↔guía hasta punto fijo: la guía lista las wikis y las páginas de la guía son
# wikis; como la guía cuenta una wiki partida como un solo objeto, el número de páginas se estabiliza a la segunda pasada.
#   bash ARCHIVO/DISCO/26sm-exported/entrada/regenerar.sh
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../../../.."
D=ARCHIVO/DISCO/26sm-exported
ORG=$D/entrada/acampada26s_organigrama.json
T=pub/templates/acampada26s.json
MANUAL_TITULO='Oasis para el nodo · manual de bienvenida'
GUIA_TITULO='Guía de reparto de accesos'
paginas() { python -X utf8 -c "import json,sys;print(len(json.load(open(sys.argv[1],encoding='utf-8'))['paginas']))" "$1"; }

echo "== manual sin tablas, en páginas"
python -X utf8 pub/tools/md-sin-tablas.py ARCHIVO/DISCO/retro-exporter/onboarding-nodo.md ARCHIVO/DISCO/retro-exporter/onboarding-nodo.wiki.md --titulo "$MANUAL_TITULO" | cut -c1-160
prev=-1
for pasada in 1 2 3 4; do
  echo "== pasada $pasada: derivador → guía (md + wiki) → guía en páginas"
  python -X utf8 $D/entrada/derivar-acampada26s.py | head -1 | cut -c1-120
  node pub/tools/template-seed.js --template $T --organigrama $ORG --out $D/guia-reparto-acampada26s.md --wiki $D/guia-reparto-acampada26s.wiki.md --reparto 2>&1 | grep -E "wiki \(" | sed "s#$D/##"
  python -X utf8 pub/tools/md-sin-tablas.py $D/guia-reparto-acampada26s.wiki.md $D/guia-reparto-acampada26s.wiki.md --titulo "$GUIA_TITULO" | cut -c1-120
  n=$(paginas $D/guia-reparto-acampada26s.wiki.json)
  if [ "$n" = "$prev" ]; then echo "== punto fijo: $n páginas de guía en dos pasadas seguidas"; break; fi
  prev=$n
  [ "$pasada" = 4 ] && { echo "PARADA: el número de páginas de la guía no se estabiliza" >&2; exit 1; }
done
echo "== guion"
node pub/tools/template-seed.js --template $T --organigrama $ORG --out $D/guion-acampada26s.md --guion 2>&1 | tail -1
echo "== kit 26S (marca)"
npm run -s pub:template:kit:26s 2>&1 | grep -v Deprecation | tail -1
echo "== Campamento (no regresión): derivar → guía en páginas → derivar → kit → Sala 02"
python -X utf8 ARCHIVO/DISCO/scriptorium-exported/entrada/derivar-campamento.py >/dev/null
npm run -s pub:template:reparto 2>&1 | grep -E "página" | cut -c1-120
python -X utf8 ARCHIVO/DISCO/scriptorium-exported/entrada/derivar-campamento.py >/dev/null
npm run -s pub:template:reparto 2>&1 | grep -E "página" | cut -c1-120
node pub/tools/template-seed.js --template pub/templates/campamento.json --organigrama ARCHIVO/DISCO/scriptorium-exported/entrada/campamento_organigrama.json --out ARCHIVO/DISCO/scriptorium-exported/guion-campamento.md --guion 2>&1 | tail -1
npm run -s pub:template:kit 2>&1 | tail -1
npm run -s pub:template:reparto:html 2>&1 | tail -1
echo "== formulario"
python -X utf8 $D/entrada/formulario.py | cut -c1-80
echo "== wikis de las dos plantillas"
python -X utf8 -c "
import json
for f in ('pub/templates/acampada26s.json','pub/templates/campamento.json'):
    t=json.load(open(f,encoding='utf-8')); print(f, len(t['wiki']), 'wikis:', ' '.join(w['id'] for w in t['wiki']))"
