#!/usr/bin/env node
// seed-tombstone.js — deshacer de template-seed --hot (WP-O135, D-O33, docs/PUB/TEMPLATE-PROTOCOL.md §9).
// Retira una siembra publicando, desde la MISMA identidad que la sembró (la secretaría), un borrado lógico por
// objeto: `tombstone` (tribus, salas, calendarios, eventos, listas, wikis, mapas, el post de entrada),
// `tribe-open-invite-tombstone` + `tribe-invite-tombstone` (invitaciones) y `clearnetItem on:false` (visor /c).
// Un tombstone solo esconde: los mensajes originales siguen en todos los logs que los replicaron (AGENTES §3).
//
// Fuente de verdad: el PROPIO FEED del bot (createUserStream). El ledger de la siembra (plantilla-<id>.json,
// pub/tools/lib/seed-hot.js) es el índice por bloque y sirve para cruzar; lo que el ledger no tiene (el post de
// entrada, los clearnetItem) se lee del feed. Oasis borra POR RAÍZ: las funciones de cada modelo resuelven la
// punta de la cadena `replaces`, cifran lo de tribu y tratan las listas CLOSED.
//
// Orden (hojas → raíces, el inverso de la siembra): clearnet → entrada → maps → wiki → mailing → events →
// calendars → rooms → invites → subtribes → tribes. `removeOpenInvite` exige la tribu viva y borrar contenido de
// tribu exige descifrarlo con su clave: por eso las tribus van las últimas.
//
// Reglas (AGENTES §3, D-O28/D-O33): dry-run por defecto; `--yes <bloque>` publica SOLO ese bloque; nunca con la
// identidad del pub ni con otra que no sea la autora del ledger (gates whoami); un pub conectado (los tombstones
// deben replicar); recuento antes/después por bloque y PARADA si no cuadra; ledger propio para reejecutar sin
// duplicar. Códigos de salida: 0 ok · 1 error de modelo o desviación · 2 argumentos · 3 gate.
//
// Se ejecuta DENTRO del contenedor del bot (las dependencias solo existen en la imagen); pub/tools va montado:
//   docker exec -i -u oasis -e HOME=/home/oasis -e OASIS_PUB_ID='@…' oasis-pub-retro-bot sh -lc \
//     'cd /app/src/server && node /app/pub/tools/seed-tombstone.js --ledger /home/oasis/.ssb/oasis/keys/plantilla-campamento.json \
//      [--yes clearnet] [--evidence /app/logs/tombstone-<tag>.jsonl]'
// Envoltorio desde la máquina operadora: pub/scripts/retro-tombstone.sh.
'use strict';
const fs = require('fs');
const path = require('path');
const { createRequire } = require('module');

const SRC = process.env.OASIS_SRC_DIR || '/app/src';
const BLOCKS = ['clearnet', 'entrada', 'maps', 'wiki', 'mailing', 'events', 'calendars', 'rooms', 'invites', 'subtribes', 'tribes'];
// Tipos que se cuentan antes y después de cada bloque (propios, en claro). Lo cifrado (tribus privadas, listas
// CLOSED) no se ve por tipo: lo mide Δseq.
const EVIDENCE_TYPES = ['tombstone', 'clearnetItem', 'tribe-open-invite-tombstone', 'tribe-invite-tombstone', 'mailingList'];
const CLEARNET_KINDS = { tribes: 'tribes', rooms: 'rooms', calendars: 'calendars', maps: 'maps', wiki: 'wiki', events: 'events' };

const cbp = (fn, ...a) => new Promise((res, rej) => fn(...a, (e, v) => (e ? rej(e) : res(v))));
const collect = (pull, stream) => new Promise((res, rej) => pull(stream, pull.collect((e, v) => (e ? rej(e) : res(v || [])))));

function parseArgs(argv) {
  const args = { yes: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (['--ledger', '--out-ledger', '--pub-id', '--evidence'].includes(a)) args[a.slice(2).replace(/-([a-z])/g, (_, c) => c.toUpperCase())] = argv[++i];
    else if (a === '--yes') args.yes.push(argv[++i]);
    else if (a === '--skip') { args.skip = args.skip || []; args.skip.push(argv[++i]); }   // <bloque>:<id> que se da por no retirable; queda en el ledger con motivo
    else if (a === '-h' || a === '--help') args.help = true;
    else { console.error(`argumento desconocido: ${a}`); process.exit(2); }
  }
  return args;
}

function connect(req, ssbConfig) {
  const ssbClient = req('ssb-client');
  const pubKey = String(ssbConfig.keys.public).replace(/\.ed25519$/, '');
  const remotes = [`unix:${path.join(ssbConfig.path, 'socket')}~noauth:${pubKey}`, `net:127.0.0.1:${ssbConfig.port || 8008}~shs:${pubKey}`];
  return new Promise((resolve, reject) => {
    const tryAt = (i) => {
      const opts = Object.assign({}, ssbConfig, { remote: remotes[i] });
      let called = false;
      const done = (err, sbot) => {
        if (called) return; called = true;
        if (err && i + 1 < remotes.length) return tryAt(i + 1);
        if (err) return reject(err);
        resolve({ sbot, via: remotes[i] });
      };
      try { ssbClient(ssbConfig.keys, opts, done); } catch (e) { done(e); }
    };
    tryAt(0);
  });
}

async function evidence(sbot, pull, me) {
  const latest = await collect(pull, sbot.createUserStream({ id: me, reverse: true, limit: 1 }));
  const seq = latest[0] && latest[0].value ? latest[0].value.sequence : 0;
  const byType = {};
  for (const type of EVIDENCE_TYPES) {
    const msgs = await collect(pull, sbot.messagesByType({ type }));
    byType[type] = msgs.filter(m => m && m.value && m.value.author === me).length;
  }
  return { seq, byType };
}

function readJson(file, fallback) {
  try { return JSON.parse(fs.readFileSync(file, 'utf8')); } catch (e) { if (e.code === 'ENOENT' && fallback !== undefined) return fallback; throw e; }
}
function writeJson(file, obj) {
  const tmp = `${file}.tmp.${process.pid}`;
  fs.writeFileSync(tmp, JSON.stringify(obj, null, 2), { mode: 0o600 });
  fs.renameSync(tmp, file);
}
const realKeys = (section) => Object.entries(section || {}).filter(([, v]) => v && typeof v.key === 'string' && v.key.startsWith('%')).map(([id, v]) => ({ id, key: v.key }));

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) { console.log(fs.readFileSync(__filename, 'utf8').split('\n').slice(1, 26).map(l => l.replace(/^\/\/ ?/, '')).join('\n')); return 0; }
  const log = (o) => process.stdout.write(JSON.stringify(o) + '\n');
  const req = createRequire(path.join(SRC, 'server/package.json'));
  const pull = req('pull-stream');
  const ssbConfig = req('./ssb_config');
  const pubId = args.pubId || process.env.OASIS_PUB_ID || '';
  if (!pubId) { console.error('[seed-tombstone] --pub-id (o OASIS_PUB_ID) obligatorio: feed id del pub (gate «nunca con la identidad del pub»)'); return 2; }
  const keysDir = require(path.join(SRC, 'configs/state-manager')).keysDir(ssbConfig.path);
  const ledgerFile = args.ledger || path.join(keysDir, 'plantilla-campamento.json');
  const seed = readJson(ledgerFile);
  if (!seed || !seed.meta || !seed.meta.whoami) { console.error(`[seed-tombstone] ${ledgerFile}: no es un ledger de siembra (sin meta.whoami)`); return 2; }
  const wanted = new Set(args.yes || []);
  for (const b of wanted) if (!BLOCKS.includes(b)) { console.error(`[seed-tombstone] --yes ${b}: bloque desconocido (${BLOCKS.join(' ')})`); return 2; }

  const { sbot, via } = await connect(req, ssbConfig);
  let code = 0;
  try {
    const me = (await cbp(sbot.whoami)).id;
    const peers = await new Promise((res) => pull(sbot.conn.peers(), pull.take(1), pull.collect((e, v) => res(e ? [] : (v[0] || [])))));
    const pubConnected = peers.some(([, d]) => d && d.state === 'connected' && d.type === 'pub');
    const gates = { notPub: me !== pubId, configPubFalse: ssbConfig.pub !== true, isAuthor: me === seed.meta.whoami, pubConnected };
    log({ event: 'start', whoami: me, via, pubId, ledger: ledgerFile, gates, dryRun: wanted.size === 0, yes: [...wanted], order: BLOCKS });
    if (!gates.notPub || !gates.configPubFalse) { console.error('[seed-tombstone] GATE: esta identidad es el pub (o su config lleva pub:true).'); return 3; }
    if (!gates.isAuthor) { console.error(`[seed-tombstone] GATE: whoami ${me} no es la autora del ledger (${seed.meta.whoami}): solo el autor puede tombstonear.`); return 3; }
    if (wanted.size && !gates.pubConnected) { console.error('[seed-tombstone] GATE: sin un pub conectado los tombstones no replicarían. Primero conn.remember del pub real (hub-conn-fix.js).'); return 3; }

    const outFile = args.outLedger || path.join(keysDir, `plantilla-${seed.meta.id}-tombstones.json`);
    const lockFile = `${outFile}.lock`;
    if (wanted.size) {
      if (fs.existsSync(lockFile)) { console.error(`[seed-tombstone] GATE: lock ${lockFile} presente (otra ejecución en curso o abortada: borrarlo solo tras comprobarlo)`); return 3; }
      fs.writeFileSync(lockFile, String(process.pid));
    }
    const done = readJson(outFile, {});
    done.meta = Object.assign(done.meta || {}, { id: seed.meta.id, whoami: me, pubId, source: ledgerFile });
    for (const b of BLOCKS) done[b] = done[b] || {};
    const save = () => writeJson(outFile, done);

    // El feed propio, en claro: qué sigue encendido en /c, qué post hay, qué tombstones ya existen.
    const own = (await collect(pull, sbot.createUserStream({ id: me }))).filter(m => m && m.value && m.value.content && typeof m.value.content === 'object');
    const tombTargets = new Set(own.filter(m => m.value.content.type === 'tombstone').map(m => m.value.content.target));
    const clearnetLatest = new Map();   // target → último clearnetItem propio
    for (const m of own) { const c = m.value.content; if (c.type === 'clearnetItem' && typeof c.target === 'string') clearnetLatest.set(c.target, { kind: c.kind, on: c.on !== false, key: m.key }); }
    const posts = own.filter(m => m.value.content.type === 'post' && !m.value.content.root).map(m => ({ id: `post:${m.key.slice(1, 9)}`, key: m.key }));

    // Modelos, cableados como seed-hot.js (sin backend).
    const mk = (ns) => require(path.join(SRC, 'models/crypto'))(ssbConfig.path, ns);
    const cooler = { open: async () => sbot, close: () => {} };
    const tribeCrypto = mk('tribes');
    const tribes = require(path.join(SRC, 'models/tribes_model'))({ cooler, tribeCrypto });
    const M = {
      tribes,
      rooms: require(path.join(SRC, 'models/rooms_model'))({ cooler, tribeCrypto, roomCrypto: mk('rooms'), tribesModel: tribes }),
      calendars: require(path.join(SRC, 'models/calendars_model'))({ cooler, pmModel: null, tribeCrypto, calendarCrypto: mk('calendars'), tribesModel: tribes }),
      events: require(path.join(SRC, 'models/events_model'))({ cooler, tribeCrypto, eventCrypto: mk('events'), tribesModel: tribes }),
      mailing: require(path.join(SRC, 'models/mailing_model'))({ cooler, subscriptionsModel: null }),
      wiki: require(path.join(SRC, 'models/wiki_model'))({ cooler, tribeCrypto, tribesModel: tribes }),
      maps: require(path.join(SRC, 'models/maps_model'))({ cooler, tribeCrypto, mapCrypto: mk('maps'), tribesModel: tribes })
    };
    const tipOf = async (model, key) => { try { return await M[model].resolveCurrentId(key); } catch (_) { return key; } };
    // Contenido envuelto para una tribu (sobre `tribe-msg`): deleteCalendarById lee la punta en crudo y no la
    // desenvuelve («Not the author», medido en WP-O135). Se hace lo que maps_model (tombFor): descifrar con la clave
    // de la tribu del keyring, comprobar que el autor es este bot y publicar el tombstone ENVUELTO para la tribu.
    const H = tribeCrypto.createHelpers(tribes);
    const wrappedTomb = async (tip) => {
      const msg = await cbp(sbot.get, tip);
      if (!msg || !tribeCrypto.isTribeMsg(msg.content)) return null;
      const dec = await H.decryptIfTribe(msg.content);
      H.assertReadable(dec, 'Tribe content');
      if (dec.author !== me) throw new Error(`Not the author (${String(dec.author).slice(0, 9)})`);
      const tomb = await H.encryptTombstone(tip, dec.tribeId || dec._rootId, me);
      const r = await cbp(sbot.publish, tomb);
      return (r && r.key) || tip;
    };

    // Plan por bloque: {id, target, fn, msgs (esperados, mínimo), note}
    const plan = {};
    plan.clearnet = [...clearnetLatest.entries()].filter(([, v]) => v.on).map(([target, v]) => ({ id: `clearnet:${target.slice(1, 9)}`, target, kind: v.kind, fn: 'clearnet.off', msgs: 1 }));
    plan.entrada = posts.map(p => ({ id: p.id, target: p.key, fn: 'post.tombstone', msgs: 1, dead: tombTargets.has(p.key) }));
    plan.maps = realKeys(seed.maps).map(e => ({ ...e, target: e.key, fn: 'maps.deleteMapById', msgs: 1 }));
    plan.wiki = realKeys(seed.wiki).map(e => ({ ...e, target: e.key, fn: 'wiki.deletePage', msgs: 1 }));
    // Listas CLOSED: el ledger guarda la clave del primer mensaje PRIVADO; mailing_model las indexa por `listId`
    // (mailing_model.js:134). Se lee el privado (descifrado para el autor) y se borra por su listId.
    const privById = new Map();
    try { for (const m of await collect(pull, sbot.private.read({ reverse: true }))) if (m && m.key && m.value && m.value.content && m.value.content.listId) privById.set(m.key, m.value.content.listId); } catch (_) {}
    plan.mailing = realKeys(seed.mailing).map(e => ({ ...e, target: privById.get(e.key) || e.key, fn: 'mailing.deleteList', msgs: 1, note: privById.has(e.key) ? `CLOSED (listId ${String(privById.get(e.key)).slice(0, 12)}…): publica mailingList DELETED cifrado (≥1)` : undefined }));
    plan.events = realKeys(seed.events).map(e => ({ ...e, target: e.key, fn: 'events.deleteEventById', msgs: 1 }));
    plan.calendars = realKeys(seed.calendars).map(e => ({ ...e, target: e.key, fn: 'calendars.deleteCalendarById', msgs: 1 }));
    plan.rooms = realKeys(seed.rooms).map(e => ({ ...e, target: e.key, fn: 'rooms.deleteRoomById', msgs: 1 }));
    // Invitaciones abiertas: desde el feed propio, no desde el modelo. En Oasis 1.2.5 TRIBE_LOG_TYPES
    // (tribes_model.js:8) no incluye `tribe-open-invite`, así que getOpenInvite/removeOpenInvite no ven los
    // marcadores (medido en WP-O135). Se publica lo mismo que removeOpenInvite: tombstone del marcador y del invite.
    const tribeNames = new Map([...realKeys(seed.tribes), ...realKeys(seed.subtribes)].map(e => [e.key, e.id]));
    const openTomb = new Set(own.filter(m => m.value.content.type === 'tribe-open-invite-tombstone').map(m => m.value.content.target));
    plan.invites = own
      .filter(m => m.value.content.type === 'tribe-open-invite' && m.value.content.v === 1 && !openTomb.has(m.key))
      .map(m => ({ id: `invite:${tribeNames.get(m.value.content.rootId) || m.value.content.rootId.slice(1, 9)}`, target: m.value.content.rootId, fn: 'invite.tombstones', msgs: m.value.content.inviteKey ? 2 : 1, marker: m.key, inviteKey: m.value.content.inviteKey || null }));
    plan.subtribes = realKeys(seed.subtribes).map(e => ({ ...e, target: e.key, fn: 'tribes.deleteTribeById', msgs: 1 }));
    plan.tribes = realKeys(seed.tribes).map(e => ({ ...e, target: e.key, fn: 'tribes.deleteTribeById', msgs: 1 }));
    // Estado actual (dry-run informativo): punta y si ya está tombstonada.
    for (const b of ['maps', 'calendars', 'rooms']) for (const c of plan[b]) { c.tip = await tipOf(b, c.key); c.dead = tombTargets.has(c.tip); }
    for (const b of ['wiki', 'events']) for (const c of plan[b]) c.dead = tombTargets.has(c.key);
    for (const b of ['subtribes', 'tribes']) for (const c of plan[b]) { try { await M.tribes.getTribeById(c.key); c.dead = false; } catch (_) { c.dead = true; } }

    const exec = async (c) => {
      switch (c.fn) {
        case 'clearnet.off': await cbp(sbot.publish, { type: 'clearnetItem', target: c.target, kind: c.kind, on: false, createdAt: new Date().toISOString() }); return c.target;
        case 'post.tombstone': { const r = await cbp(sbot.publish, { type: 'tombstone', target: c.target, deletedAt: new Date().toISOString(), author: me }); return r && r.key; }
        case 'maps.deleteMapById': { const r = await M.maps.deleteMapById(c.key); return (r && r.key) || c.tip; }
        case 'wiki.deletePage': { const r = await M.wiki.deletePage(c.key); return (r && r.key) || c.key; }
        case 'mailing.deleteList': { const r = await M.mailing.deleteList(c.target); return (r && r.key) || c.target; }
        case 'events.deleteEventById': { const w = await wrappedTomb(c.key); if (w) return w; const r = await M.events.deleteEventById(c.key); return (r && r.key) || c.key; }
        case 'calendars.deleteCalendarById': { const w = await wrappedTomb(c.tip || c.key); if (w) return w; await M.calendars.deleteCalendarById(c.key); return c.tip; }
        case 'rooms.deleteRoomById': { const w = await wrappedTomb(c.tip || c.key); if (w) return w; await M.rooms.deleteRoomById(c.key); return c.tip; }
        case 'invite.tombstones': {
          await cbp(sbot.publish, { type: 'tribe-open-invite-tombstone', v: 1, target: c.marker, ts: new Date().toISOString() });
          if (c.inviteKey) await cbp(sbot.publish, { type: 'tribe-invite-tombstone', v: 1, target: c.inviteKey, ts: new Date().toISOString() });
          return c.marker;
        }
        case 'tribes.deleteTribeById': { const r = await M.tribes.deleteTribeById(c.key); return (r && r.key) || c.key; }
        default: throw new Error(`llamada desconocida ${c.fn}`);
      }
    };

    // --skip bloque:id — lo que el custodio da por no retirable (p. ej. listas CLOSED que el índice del modelo no ve
    // por el socket): se anota en el ledger con motivo y el bloque puede cerrarse. Decisión explícita, nunca silenciosa.
    for (const s of args.skip || []) {
      const [b, id] = [s.slice(0, s.indexOf(':')), s.slice(s.indexOf(':') + 1)];
      if (!BLOCKS.includes(b) || !plan[b].some(c => c.id === id)) { console.error(`[seed-tombstone] --skip ${s}: no existe en el plan`); return 2; }
      if (!done[b][id]) { done[b][id] = { skipped: true, reason: 'custodio: no retirable desde el seeder', at: new Date().toISOString() }; save(); }
      log({ event: 'skip-entry', block: b, id });
    }
    for (const b of BLOCKS) {
      const todo = plan[b].filter(c => !done[b][c.id] && !c.dead);
      const summary = { block: b, calls: plan[b].length, alreadyDead: plan[b].filter(c => c.dead).length, done: Object.keys(done[b]).length, pending: todo.length, expectedMin: todo.reduce((n, c) => n + c.msgs, 0) };
      if (!wanted.has(b)) { log({ event: 'dry-run', ...summary, calls: todo.map(c => ({ id: c.id, fn: c.fn, target: c.target, tip: c.tip || undefined, msgs: c.msgs, note: c.note || undefined })) }); continue; }
      if (!todo.length) { log({ event: 'skip', ...summary }); continue; }
      const before = await evidence(sbot, pull, me);
      log({ event: 'begin', ...summary, before });
      const keys = []; let failed = null; let expectedMin = 0;
      for (const c of todo) {
        try {
          const key = await exec(c);
          done[b][c.id] = { target: c.target, key, at: new Date().toISOString() }; save();
          keys.push({ id: c.id, target: c.target, key }); expectedMin += c.msgs;
        } catch (e) { failed = { id: c.id, fn: c.fn, target: c.target, error: e.message }; break; }
      }
      const after = await evidence(sbot, pull, me);
      const delta = after.seq - before.seq;
      // mailing CLOSED publica cifrado por lotes: ≥; el resto exacto.
      const ok = !failed && (b === 'mailing' ? delta >= expectedMin : delta === expectedMin);
      const rec = { event: 'end', block: b, before, after, delta, expectedMin, ok, keys, failed };
      log(rec);
      if (args.evidence) fs.appendFileSync(args.evidence, JSON.stringify({ whoami: me, via, at: new Date().toISOString(), ...rec }) + '\n');
      if (failed) { code = 1; break; }
      if (!ok) { console.error(`[seed-tombstone] PARADA: bloque ${b} publicó ${delta} mensajes y se esperaban ${expectedMin}. Nada más se retira hasta entenderlo.`); code = 1; break; }
    }
    if (wanted.size) { try { fs.unlinkSync(lockFile); } catch (_) {} }
    log({ event: 'ledger', file: outFile });
  } finally {
    await new Promise((res) => { try { sbot.close(() => res()); } catch (_) { res(); } setTimeout(res, 3000).unref(); });
  }
  return code;
}

main().then((c) => process.exit(c)).catch((e) => { console.error('[seed-tombstone]', e && e.stack || e); process.exit(1); });
