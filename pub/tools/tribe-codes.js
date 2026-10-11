#!/usr/bin/env node
// tribe-codes.js — los códigos de acceso de las tribus que sembró la secretaría (WP-O137, TEMPLATE-PROTOCOL §4.6).
//
// Upstream (1.2.3-1.2.5) no enseña en la interfaz las invitaciones abiertas (`TRIBE_LOG_TYPES` sin
// `tribe-open-invite`): el código existe, en claro, en el registro, es multiuso y vale en «INTRODUCIR INVITACIÓN»
// (/tribes/join-code). Y la secretaría, autora de las tribus estrictas, no tiene interfaz para «Generar invitación».
// Esta herramienta hace lo que la mesa técnica necesita, con los modelos reales de src/models (seed-hot.openModels):
//
//   list    [--show] [--json]   qué tribus hay en el ledger, modo, miembros y si tienen código abierto (enmascarado)
//   sheet   --out <dir> [--brand <marca.json>]
//                               hoja imprimible (HTML sin JS + un QR PNG por tribu) con los códigos ABIERTOS;
//                               el QR codifica el código en texto plano (el de upstream codifica una URL localhost)
//   one-use <id de plantilla> [--yes]
//                               un código de UN uso para una tribu (estricta): publica 2 mensajes, irreversible;
//                               sin --yes solo dice qué publicaría. El código se imprime UNA vez y no se guarda.
//
// Reglas: solo lectura salvo `one-use --yes`; gate D-O28 (nunca con la identidad del pub: --pub-id / OASIS_PUB_ID
// obligatorio para one-use); respeta el lock del seeder; nunca escribe códigos en el ledger ni en los logs.
// Códigos de salida: 0 ok · 1 error · 2 argumentos · 3 gate.
// Se ejecuta DENTRO del contenedor del bot (pub/scripts/retro-codes.sh), como `oasis` con HOME=/home/oasis:
//   cd /app/src/server && node /app/pub/tools/tribe-codes.js list --template acampada26s
'use strict';
const fs = require('fs');
const path = require('path');
const { createRequire } = require('module');

const SRC = process.env.OASIS_SRC_DIR || '/app/src';
const { connect, openModels, readLedger } = require(path.join(__dirname, 'lib/seed-hot.js'));

function parseArgs(argv) {
  const a = { _: [] };
  for (let i = 0; i < argv.length; i++) {
    const x = argv[i];
    if (['--template', '--ledger', '--out', '--brand', '--pub-id'].includes(x)) a[x.slice(2).replace('-id', 'Id')] = argv[++i];
    else if (x === '--show') a.show = true;
    else if (x === '--yes') a.yes = true;
    else if (x === '--json') a.json = true;
    else if (x === '-h' || x === '--help') a.help = true;
    else if (x.startsWith('--')) { console.error(`argumento desconocido: ${x}`); process.exit(2); }
    else a._.push(x);
  }
  return a;
}

const mask = (code) => (code ? `…${String(code).slice(-4)}` : '');
const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

function brandOf(file) {
  const b = { bg: '#0452C5', accent: '#FF981F', fg: '#FFFFFF', label: 'TRIBU' };
  if (!file) return b;
  const m = JSON.parse(fs.readFileSync(file, 'utf8'));
  const hex = Object.values(m.paleta || {}).filter(v => /^#[0-9a-fA-F]{6}$/.test(String(v)));
  if (hex[0]) b.bg = hex[0];
  if (hex[1]) b.accent = hex[1];
  if (m.etiquetas && m.etiquetas.tribu) b.label = m.etiquetas.tribu;
  return b;
}

function sheetHtml(rows, brand, meta) {
  const cards = rows.map(r => `
  <article class="card">
    <header><span class="label">${esc(brand.label)}</span><h2>${esc(r.title)}</h2></header>
    <img src="${esc(r.png)}" alt="QR del código de ${esc(r.title)}" width="220" height="220">
    <p class="code">${esc(r.code)}</p>
    <ol>
      <li>Abre Oasis en tu móvil u ordenador.</li>
      <li>Menú → <b>Tribus</b> → <b>INTRODUCIR INVITACIÓN</b>.</li>
      <li>Escanea el QR o copia el código, pégalo y entra.</li>
    </ol>
    <footer>Código multiuso: sirve a cualquiera que lo tenga. Repártelo solo donde deba llegar.</footer>
  </article>`).join('\n');
  return `<!doctype html>
<html lang="es"><head><meta charset="utf-8"><title>Hoja de códigos · ${esc(meta.template)}</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
:root{--bg:${brand.bg};--accent:${brand.accent};--fg:${brand.fg}}
*{box-sizing:border-box}body{margin:0;font:16px/1.3 system-ui,sans-serif;color:#111;background:#fff}
h1{margin:0 0 4px;font-size:22px}.intro{padding:16px;border-bottom:4px solid var(--bg)}
.intro p{margin:4px 0;font-size:14px}.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:12px;padding:12px}
.card{border:2px solid var(--bg);border-radius:8px;padding:12px;break-inside:avoid;page-break-inside:avoid;background:#fff}
.card header{background:var(--bg);color:var(--fg);margin:-12px -12px 10px;padding:8px 12px;border-radius:6px 6px 0 0}
.label{display:inline-block;background:var(--accent);color:#000;font-weight:700;font-size:11px;padding:2px 6px;border-radius:3px;letter-spacing:.06em}
.card h2{margin:4px 0 0;font-size:18px;text-transform:uppercase}.card img{display:block;margin:0 auto}
.code{font:700 15px/1.2 ui-monospace,Consolas,monospace;word-break:break-all;text-align:center;background:#f3f3f3;padding:8px;border-radius:4px;margin:8px 0}
ol{margin:6px 0;padding-left:20px;font-size:14px}footer{font-size:11px;color:#444;border-top:1px dashed #999;padding-top:6px;margin-top:6px}
@media print{.intro{break-after:avoid}.grid{gap:8px}}
</style></head><body>
<div class="intro"><h1>Hoja de códigos de acceso · ${esc(meta.template)}</h1>
<p>Generada el ${esc(meta.at)} desde la secretaría. ${rows.length} tribu(s) con código abierto. Las tribus estrictas no salen aquí: su código es de un uso y se da en mano.</p>
<p><b>Esta hoja es para imprimir y repartir, no para guardar.</b> Cada código es público para quien lo tenga; quien entra puede dar más códigos desde la tarjeta de su tribu (Generar invitación).</p></div>
<section class="grid">${cards}
</section></body></html>
`;
}

async function main() {
  const a = parseArgs(process.argv.slice(2));
  const cmd = a._[0];
  if (a.help || !['list', 'sheet', 'one-use'].includes(cmd)) { console.error(fs.readFileSync(__filename, 'utf8').split('\n').slice(1, 21).join('\n')); return 2; }
  const req = createRequire(path.join(SRC, 'server/package.json'));
  const ssbConfig = req('./ssb_config');
  const pull = req('pull-stream');
  const keysDir = require(path.join(SRC, 'configs/state-manager')).keysDir(ssbConfig.path);
  const template = a.template || 'campamento';
  const ledgerFile = a.ledger || path.join(keysDir, `plantilla-${template}.json`);
  const ledger = readLedger(ledgerFile);
  if (!ledger.tribes) { console.error(`[tribe-codes] ledger sin tribus: ${ledgerFile} (¿se sembró --yes tribes?)`); return 1; }
  const entries = Object.entries(Object.assign({}, ledger.tribes || {}, ledger.subtribes || {}));

  const { sbot, via } = await connect(req, ssbConfig);
  let code = 0;
  try {
    const me = (await new Promise((res, rej) => sbot.whoami((e, v) => (e ? rej(e) : res(v))))).id;
    const pubId = a.pubId || process.env.OASIS_PUB_ID || '';
    if (ssbConfig.pub === true || (pubId && me === pubId)) { console.error('[tribe-codes] GATE: esta identidad es el pub (D-O28)'); return 3; }
    const M = openModels(sbot, ssbConfig);
    // Los marcadores `tribe-open-invite` se leen del registro directamente: el modelo de upstream no los indexa
    // (TRIBE_LOG_TYPES, tribes_model.js:8; H9 de WP-O135) y getOpenInvite() no ve ninguno. Solo los de la secretaría.
    const byType = (type) => new Promise((res, rej) => pull(sbot.messagesByType({ type }), pull.collect((e, v) => (e ? rej(e) : res(v || [])))));
    const gone = new Set((await byType('tribe-open-invite-tombstone')).map(m => m.value && m.value.content && m.value.content.target).filter(Boolean));
    const openByRoot = new Map();
    for (const m of await byType('tribe-open-invite')) {
      const c = m.value && m.value.content;
      if (!c || c.v !== 1 || m.value.author !== me || gone.has(m.key) || typeof c.rootId !== 'string' || typeof c.code !== 'string') continue;
      openByRoot.set(c.rootId, c.code);
    }
    const rows = [];
    for (const [id, ref] of entries) {
      const key = ref && ref.key;
      let tribe = null;
      try { tribe = await M.tribes.getTribeById(key); } catch (_) { tribe = null; }
      if (!tribe) { rows.push({ id, key, title: '(no legible: ¿borrada o sin réplica?)', inviteMode: '?', members: 0, mine: false, code: null }); continue; }
      const root = await M.tribes.getRootId(key).catch(() => key);
      rows.push({ id, key, title: tribe.title, inviteMode: tribe.inviteMode, members: (tribe.members || []).length, mine: tribe.author === me, code: openByRoot.get(root) || openByRoot.get(key) || null });
    }
    const withCode = rows.filter(r => r.code);
    const strict = rows.filter(r => r.inviteMode === 'strict');
    if (cmd === 'list') {
      const out = rows.map(r => Object.assign({}, r, { code: a.show ? r.code : mask(r.code) }));
      if (a.json) process.stdout.write(JSON.stringify({ via, me, ledger: ledgerFile, tribes: out }, null, 2) + '\n');
      else {
        const w = Math.max(...out.map(r => r.title.length), 5);
        console.log(`ledger ${ledgerFile} · ${rows.length} tribus · ${withCode.length} con código abierto · ${strict.length} estrictas`);
        for (const r of out) console.log(`${r.title.padEnd(w)}  ${String(r.inviteMode).padEnd(6)}  ${String(r.members).padStart(3)} miembro(s)  ${r.code ? 'abierto ' + r.code : (r.inviteMode === 'strict' ? 'de un uso (one-use)' : 'sin código abierto')}`);
        if (!a.show && withCode.length) console.log('(códigos enmascarados: --show para verlos, o `sheet` para la hoja imprimible)');
      }
    } else if (cmd === 'sheet') {
      if (!a.out) { console.error('[tribe-codes] sheet: falta --out <dir>'); return 2; }
      fs.mkdirSync(a.out, { recursive: true });
      const QRCode = req('qrcode');
      const brand = brandOf(a.brand);
      const cards = [];
      for (const r of withCode) {
        const png = `${r.id}.png`;
        const buf = await QRCode.toBuffer(r.code, { type: 'png', width: 440, margin: 1, errorCorrectionLevel: 'M' });
        fs.writeFileSync(path.join(a.out, png), buf);
        cards.push({ title: r.title, code: r.code, png });
      }
      const at = new Date().toISOString().slice(0, 16).replace('T', ' ') + ' UTC';
      fs.writeFileSync(path.join(a.out, 'hoja-codigos.html'), sheetHtml(cards, brand, { template, at }));
      console.log(`hoja: ${path.join(a.out, 'hoja-codigos.html')} · ${cards.length} tarjeta(s) con QR · imprimir y borrar el directorio`);
      if (strict.length) console.log(`estrictas sin hoja (código de un uso, en mano): ${strict.map(r => r.title).join(' · ')}`);
    } else if (cmd === 'one-use') {
      const id = a._[1];
      const r = rows.find(x => x.id === id);
      if (!id || !r) { console.error(`[tribe-codes] one-use: tribu desconocida «${id}». Ids: ${rows.map(x => x.id).join(' ')}`); return 2; }
      if (!r.mine) { console.error(`[tribe-codes] GATE: la secretaría no es la autora de «${r.title}»: no puede generar su código`); return 3; }
      const plan = `publicaría 2 mensajes como ${me.slice(0, 8)}…: tribe-invite-msg (código de un uso) + tribe (invites+1) para «${r.title}» (${r.inviteMode}, ${r.members} miembro(s))`;
      if (!a.yes) { console.log(`[dry] ${plan}. Con --yes se publica (irreversible) y el código se muestra una sola vez.`); return 0; }
      if (!pubId) { console.error('[tribe-codes] one-use --yes: --pub-id (o OASIS_PUB_ID) obligatorio para el gate D-O28'); return 2; }
      if (fs.existsSync(`${ledgerFile}.lock`)) { console.error(`[tribe-codes] GATE: lock ${ledgerFile}.lock presente (siembra en curso o abortada)`); return 3; }
      const oneUse = await M.tribes.generateInvite(r.key);
      console.log(`[one-use] ${plan}: publicado.`);
      console.log(`CÓDIGO DE UN USO para «${r.title}» (apúntalo ahora; no se guarda): ${oneUse}`);
    }
  } catch (e) {
    console.error('[tribe-codes]', e && e.message ? e.message : e); code = 1;
  } finally {
    // tribes_model deja un createLogStream({live:true}) abierto: hay que salir explícitamente (como seed-hot).
    try { sbot.close(() => process.exit(code)); } catch (_) { process.exit(code); }
    setTimeout(() => process.exit(code), 3000).unref();
  }
  return code;
}

main().then((c) => { if (typeof c === 'number' && c !== 0) process.exit(c); }).catch((e) => { console.error('[tribe-codes]', e.message); process.exit(1); });
