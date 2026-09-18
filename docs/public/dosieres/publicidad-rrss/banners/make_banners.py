"""Genera los banners del dosier de publicidad (HTML autocontenido, B/N, Courier)."""
import os
import re
from pathlib import Path

OUT = Path(__file__).resolve().parent
OUT.mkdir(parents=True, exist_ok=True)
# Sigilo de la obra: el SVG de portada de su capa curada (editorial/portada.svg en el lore).
SIGIL = Path(os.environ.get("TEATRO_SIGIL") or Path(__file__).with_name("sigilo.svg")).read_text(encoding="utf-8")
SIGIL = re.sub(r'<rect width="400" height="400" fill="#f6f1e6"/>', "", SIGIL).strip()

D = dict(
    gen="2026-09-18", prev="2026-08-21", posts="1940", prev_posts="1454", media="1844", hilos="259", tags="76",
    voces="891", enlaces="331", conv="38", interloc="274", constructos="22", cortes="13", ficheros="14442",
    zip="aleph-cero.zip", zip_size="1,52 GiB", zip_bytes="1 631 937 463",
    zip_sha="39d726c8bdad2c5a9c9c789ae1b92cc25ca3403615b28c2bc947e85dff1b2c1d",
    brain="aleph-cero-cerebro.zip", brain_size="33,4 MiB", brain_bytes="35 064 225",
    brain_sha="634feaf422054ce911ceb52168a987aa527f5f0eb9cbcbf6a936e65ec95c24bf",
    last_id="2100802059889000553", last_at="2026-09-18 04:20 UTC", first_at="2024-06-30",
    url="pub.escrivivir.co/teatro", obra="pub.escrivivir.co/teatro/aleph-cero",
)

CSS = """
*{box-sizing:border-box;margin:0;padding:0}
html,body{background:#f6f1e6;color:#000;font-family:'Courier New',Courier,monospace}
body{width:1200px;padding:34px 40px 26px;position:relative}
.kick{font-size:13px;letter-spacing:.2em;text-transform:uppercase;display:flex;justify-content:space-between;border-bottom:3px solid #000;padding-bottom:8px}
h1{font-size:64px;letter-spacing:.16em;text-transform:uppercase;line-height:1;margin:18px 0 6px}
h1 small{font-size:22px;letter-spacing:.12em;display:block;margin-top:10px;font-weight:400}
h2{font-size:20px;letter-spacing:.14em;text-transform:uppercase;border-bottom:2px solid #000;padding-bottom:4px;margin:22px 0 10px}
.stamp{position:absolute;top:70px;right:44px;border:3px solid #000;padding:6px 12px;font-size:15px;font-weight:700;letter-spacing:.12em;transform:rotate(4deg);background:#f6f1e6;text-transform:uppercase}
.row{display:flex;gap:18px}.row>*{flex:1}
.box{border:3px solid #000;background:#fff;padding:14px 16px}
.inv{background:#000;color:#f6f1e6;border-color:#000}
.t{font-size:17px;font-weight:700;letter-spacing:.1em;text-transform:uppercase;margin-bottom:6px}
.p{font-size:15px;line-height:1.45}
.u{font-size:17px;font-weight:700;margin-top:8px;word-break:break-all}
.stats{display:flex;border-top:3px solid #000;border-bottom:3px solid #000;margin:16px 0}
.stats div{flex:1;text-align:center;padding:9px 0;border-right:1px dashed #000}.stats div:last-child{border-right:0}
.stats b{display:block;font-size:30px}.stats span{font-size:11px;letter-spacing:.16em;text-transform:uppercase}
table{width:100%;border-collapse:collapse;font-size:15px}
td,th{border:1.5px solid #000;padding:6px 9px;text-align:left;vertical-align:top;background:#fff}
th{background:#000;color:#f6f1e6;text-transform:uppercase;letter-spacing:.1em;font-size:12px;white-space:nowrap}
.sha{font-size:15.5px;font-weight:700;letter-spacing:.02em;word-break:break-all}
.cmd{background:#000;color:#f6f1e6;padding:12px 14px;font-size:13.5px;line-height:1.6;white-space:pre-wrap;overflow-wrap:anywhere}
.cmd i{font-style:normal;opacity:.6}
.foot{border-top:3px solid #000;margin-top:20px;padding-top:9px;font-size:11.5px;letter-spacing:.1em;text-transform:uppercase;text-align:center;line-height:1.7}
.washi{height:8px;margin:12px 0;background:repeating-linear-gradient(90deg,#000 0 6px,transparent 6px 11px)}
.sig{width:150px;height:150px;flex:none}.sig svg{width:100%;height:100%}
.plus{color:#000;font-weight:700}.big{font-size:44px;font-weight:700;line-height:1.05}
.diff{font-size:17px;line-height:1.65;white-space:pre}
.k{font-size:11px;letter-spacing:.16em;text-transform:uppercase}
"""

FOOT = ('<div class="foot">Escrivivir · Scriptorium Skins · Animus Iocandi · Aleph Cero · F.A.R.O. · '
        'Material transmedia para agentes del juego ARG · AIGPL<br>'
        'texto verbatim · citar por id · nada inventado · sin JavaScript · sin rastreadores · sin CDNs</div>')

SHAS = """<table>
<tr><th>fichero</th><th>tamaño</th><th>sha-256</th></tr>
<tr><td><b>{zip}</b><br><span class="k">todo: páginas + corpus + media</span></td><td>{zip_size}</td><td class="sha">{zip_sha}</td></tr>
<tr><td><b>{brain}</b><br><span class="k">solo texto, índices y herramientas</span></td><td>{brain_size}</td><td class="sha">{brain_sha}</td></tr>
</table>"""

STATS = """<div class="stats"><div><b>{posts}</b><span>posts</span></div><div><b>{media}</b><span>media</span></div>
<div><b>{hilos}</b><span>hilos</span></div><div><b>{voces}</b><span>voces ajenas</span></div>
<div><b>{enlaces}</b><span>enlaces en md</span></div><div><b>{conv}</b><span>convers. con agentes</span></div>
<div><b>{constructos}</b><span>constructos</span></div></div>"""

KICK = '<div class="kick"><span>Teatro del Scriptorium · Obra Nº 1</span><span>generación {gen} · {url}</span></div>'

BANNERS = {}

# 1 ── FICHA: solo dato ──
BANNERS["banner-01-ficha"] = KICK + """<div class="stamp" style="right:215px">delta listo</div>
<div class="row" style="align-items:center;margin-top:8px"><div><h1>Aleph Cero<small>el archivo de @_dev_aleph_1 en X, como obra · actualizado al {gen}</small></h1></div><div class="sig">__SIGIL__</div></div>
""" + STATS + """
<h2>Ficha</h2>
<table>
<tr><th>cubre</th><td>{first_at} → {last_at}</td><th>generaciones</th><td>3 (07-08 · 08-21 · 09-18)</td></tr>
<tr><th>delta</th><td>{prev_posts} → {posts} posts desde el corte {prev}</td><th>ficheros servidos</th><td>{ficheros}, cada uno con su hash en MANIFEST.sha256</td></tr>
<tr><th>último post</th><td>id {last_id}</td><th>firma</th><td>ed25519 · teatro@escrivivir.co · allowed_signers publicado</td></tr>
<tr><th>leer</th><td>{obra}/ — puertas sin JavaScript</td><th>navegar</th><td>{obra}/navegador.html — visor del archivo de X</td></tr>
</table>
<h2>Descarga offline · checksums</h2>
""" + SHAS + """
<div class="cmd" style="margin-top:12px"><i>$</i> sha256sum -c {zip}.sha256
<i>$</i> ssh-keygen -Y verify -f allowed_signers -I teatro@escrivivir.co -n file -s {zip}.sha256.sig &lt; {zip}.sha256</div>
<div class="row" style="margin-top:16px"><div class="box inv"><div class="t">call4obras</div><div class="p">Aleph Cero es una obra. El pub acoge otras: <b>secretaria@escrivivir.co</b> · asunto: <b>call4obras</b></div></div>
<div class="box"><div class="t">o móntate el tuyo</div><div class="p">solarnethub.com · github.com/epsylon/oasis · o-sdk.escrivivir.co (wrapper no oficial). Federamos.</div></div></div>
""" + FOOT

# 2 ── DELTA: estilo diff ──
BANNERS["banner-02-delta"] = KICK + """<div class="stamp">+delta</div>
<h1>Aleph Cero<small>delta fijado · {prev} → {gen}</small></h1>
<div class="row" style="margin-top:14px">
<div class="box"><div class="diff">@@ teatro/aleph-cero  {prev} → {gen} @@
<b>+ 490</b> posts nuevos      ({prev_posts} → {posts} visibles)
<b>+ 553</b> ficheros de media ({media} en total)
<b>+ 354</b> voces ajenas      (537 → {voces}; ahora con citas, a 2 niveles)
<b>+ {enlaces}</b> enlaces a Markdown ({conv} conversaciones con agentes)
<b>+  {constructos}</b> constructos        (puerta «El sistema»)
<b>+  {cortes}</b> cortes             (puerta «El cantar de Aleph»)
<b>+ {interloc}</b> interlocutores     (puerta nueva)
<b>-   4</b> posts borrados por el autor (no se publican)</div></div>
<div style="flex:0 0 330px"><div class="box inv"><div class="t">el delta queda fijado en</div><div class="big">{last_at}</div><div class="p" style="margin-top:8px">post id<br><b>{last_id}</b><br><br>Lo posterior a ese id en el timeline de X no está en la obra: entrará con la próxima generación.</div></div></div>
</div>
<h2>Checksums</h2>
""" + SHAS + """
<div class="row" style="margin-top:14px"><div class="box"><div class="t">leer · sin JS</div><div class="u">{obra}/</div></div>
<div class="box"><div class="t">navegar · visor de X</div><div class="u">…/aleph-cero/navegador.html</div></div>
<div class="box inv"><div class="t">call4obras</div><div class="p">secretaria@escrivivir.co<br>asunto: call4obras</div></div></div>
""" + FOOT

# 3 ── TRES PUERTAS ──
BANNERS["banner-03-tres-puertas"] = KICK + """<div class="stamp" style="right:215px">actualizado</div>
<div class="row" style="align-items:center"><div><h1>Aleph Cero<small>{posts} posts · {first_at} → {gen} · tres maneras de entrar</small></h1></div><div class="sig">__SIGIL__</div></div>
<div class="washi"></div>
<div class="row">
<div class="box"><div class="k">01 · leer</div><div class="t">Puertas sin JavaScript</div><div class="p">El sistema ({constructos} constructos) · El cantar · Cronología · {hilos} hilos · Hashtags · Conversaciones · Interlocutores · Externos · Enlaces. HTML estático. Cero scripts, cero CDNs, cero cookies.</div><div class="u">{obra}/</div></div>
<div class="box"><div class="k">02 · navegar</div><div class="t">El visor del archivo de X</div><div class="p">El navegador que entrega X con el export, limpiado: sin datos privados, sin llamadas externas, con vídeo múltiple. Línea de tiempo y búsqueda. Única página con JS, declarada.</div><div class="u">…/aleph-cero/navegador.html</div></div>
<div class="box inv"><div class="k">03 · llevárselo</div><div class="t">Descarga offline</div><div class="p">Un zip con todo ({zip_size}) o el segundo cerebro en Markdown ({brain_size}) para tu agente: AGENTS.md + corpus + índices + el generador.</div><div class="u">…/aleph-cero/{zip}</div></div>
</div>
<h2>Checksums · verifica antes de abrir</h2>
""" + SHAS + """
<div class="cmd" style="margin-top:10px"><i>$</i> sha256sum -c {zip}.sha256     <i># firma ed25519: {zip}.sha256.sig · allowed_signers · MANIFEST.sha256 ({ficheros} ficheros)</i></div>
<div class="row" style="margin-top:14px"><div class="box"><div class="t">delta fijado</div><div class="p">{prev_posts} → {posts} posts. Último: <b>{last_id}</b> ({last_at}).</div></div>
<div class="box"><div class="t">call4obras</div><div class="p">Esto es una obra. Hay sitio para la tuya: <b>secretaria@escrivivir.co</b> · asunto <b>call4obras</b>. O DIY: o-sdk.escrivivir.co</div></div></div>
""" + FOOT

# 4 ── CALL4OBRAS ──
BANNERS["banner-04-call4obras"] = """<div class="kick"><span>Teatro del Scriptorium · pub.escrivivir.co</span><span>call4obras · call4cypherpunks · {gen}</span></div>
<div class="stamp">call4obras</div>
<h1>Tu archivo<br>es una obra<small>Aleph Cero es la Nº 1. El Teatro tiene más butacas.</small></h1>
<div class="washi"></div>
<div class="row">
<div class="box"><div class="k">la prueba</div><div class="t">Aleph Cero · generación {gen}</div><div class="p">{posts} posts, {media} media, {voces} voces ajenas, {enlaces} enlaces en Markdown. Un export de X convertido en sitio estático sin JS + visor + zip firmado. Nada inventado: texto verbatim, citado por id.</div><div class="u">{obra}/</div></div>
<div class="box inv"><div class="k">opción A · te acogemos</div><div class="t">El pub publica tu obra</div><div class="p">Trae tu export (X hoy; más fuentes después). Sale como obra del Teatro, con sus checksums y su firma.</div><div class="u">secretaria@escrivivir.co</div><div class="p">asunto: <b>call4obras</b></div></div>
</div>
<div class="row" style="margin-top:18px">
<div class="box"><div class="k">opción B · DIY</div><div class="t">Monta tu pub y tu teatro</div><div class="p"><b>Oficial</b> · solarnethub.com · wiki.solarnethub.com · github.com/epsylon/oasis<br><b>No oficial</b> · o-sdk.escrivivir.co · github.com/alephscriptorium-eng/O_SDK — Oasis dockerizado + hub clearnet + Teatro + sidecar de RRSS (Python stdlib). <code>lore-import → ingest → build → deploy</code></div></div>
<div class="box"><div class="k">y después · federar</div><div class="t">Conecta con este pub</div><div class="p">Los datos no se imprimen: cambian.<br><b>connect · caps · versión</b> pub.escrivivir.co/public/status<br><b>invite vivo</b> pub.escrivivir.co (COPY)</div></div>
</div>
<h2>Checksums de la obra Nº 1</h2>
""" + SHAS + FOOT

# 5 ── TERMINAL ──
BANNERS["banner-05-terminal"] = """<style>html,body{{background:#000;color:#f6f1e6}}.kick,.foot,h2{{border-color:#f6f1e6}}.cmd{{border:2px solid #f6f1e6;font-size:14.5px}}.stamp{{background:#000;border-color:#f6f1e6}}</style>
""" + KICK + """<div class="stamp">verifica</div>
<h1>Aleph Cero<small>no te fíes: comprueba · delta {prev} → {gen}</small></h1>
<div class="cmd" style="margin-top:16px"><i># {zip_size} · todo: páginas + corpus + media</i>
<i>$</i> curl -O https://{obra}/{zip}
<i>$</i> curl -O https://{obra}/{zip}.sha256
<i>$</i> sha256sum -c {zip}.sha256
{zip}: <b>OK</b>
<i>$</i> cat {zip}.sha256
<b>{zip_sha}</b>  {zip}
<i>$</i> sha256sum {brain}   <i># {brain_size} · Markdown para tu agente</i>
<b>{brain_sha}</b>  {brain}
<i>$</i> ssh-keygen -Y verify -f allowed_signers -I teatro@escrivivir.co -n file -s {zip}.sha256.sig &lt; {zip}.sha256
Good "file" signature for teatro@escrivivir.co with ED25519 key
<i>$</i> unzip -q {zip} &amp;&amp; grep -c . aleph-cero/MANIFEST.sha256
{ficheros}
<i>$</i> ls aleph-cero/
AGENTS.md  cantar/  conversaciones.html  corpus/  cronologia/  enlaces/  hashtags/  hilos/
indexes/  interlocutores/  navegador.html  posts/  sistema/  tools/
<i># {posts} posts ({prev_posts} en el corte anterior) · último id {last_id} · {last_at}</i></div>
<div class="row" style="margin-top:16px">
<div class="cmd"><b>ONLINE</b>
leer · sin JS    {obra}/
navegar · visor  …/aleph-cero/navegador.html</div>
<div class="cmd"><b>CALL4CYPHERPUNKS · CALL4OBRAS</b>
secretaria@escrivivir.co · asunto: call4obras
DIY: solarnethub.com · o-sdk.escrivivir.co</div></div>
""" + FOOT

for name, body in BANNERS.items():
    html = ("<!doctype html>\n<html lang=\"es\"><head><meta charset=\"utf-8\"><title>" + name + "</title><style>" + CSS
            + "</style></head><body>\n" + body.format(**D).replace("__SIGIL__", SIGIL) + "\n</body></html>\n")
    (OUT / f"{name}.html").write_text(html, encoding="utf-8", newline="\n")
    print("ok", name)
