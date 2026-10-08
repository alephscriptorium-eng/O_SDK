// seed-hot.js — vía caliente de template-seed (WP-O131, docs/PUB/TEMPLATE-PROTOCOL.md §4.3).
// Siembra una plantilla desde la identidad «secretaría» (bot retro, contenedor en modo `server`), hablando
// con su sbot por el socket unix `noauth` (permisos master, misma vía que pub/tools/ssb-admin.js).
//
// Por qué no usa src/client/gui.js: su `cooler.open()` siempre intenta arrancar un sbot embebido sobre el
// mismo .ssb y, con el `server` vivo, muere por LOCK (gui.js:113-145). Aquí el `cooler` es un shim sobre
// ssb-client; los modelos de src/models solo piden `cooler.open()`.
//
// Reglas (AGENTES.md §3, D-O28): dry-run por defecto; `--yes <bloque>` publica SOLO ese bloque; nunca con
// la identidad del pub (gate whoami); recuento antes/después de cada bloque; ledger entidad → clave tras
// cada publicación para reejecutar sin duplicar. Códigos de salida: 0 ok · 1 error de modelo · 2 argumentos · 3 gate.
//
// Se ejecuta DENTRO del contenedor del bot (las dependencias solo existen en la imagen):
//   docker exec -i -u oasis -e HOME=/home/oasis -e OASIS_PUB_ID='@…' oasis-pub-retro-bot sh -lc \
//     'cd /app/src/server && node /app/pub/tools/template-seed.js --template /app/pub/templates/campamento.json \
//      --assets /app/pub/templates/assets/campamento --hot [--yes tribes] [--evidence /app/logs/seed-<tag>.json]'
'use strict';
const fs = require('fs');
const path = require('path');
const { createRequire } = require('module');

const SRC = process.env.OASIS_SRC_DIR || '/app/src';
const BLOCK_TYPES = {
  tribes: ['tribe'], subtribes: ['tribe'], invites: ['tribe-invite-msg', 'tribe-open-invite'],
  rooms: ['room', 'tribe-keys'], calendars: ['calendar', 'tribe-keys', 'tombstone', 'calendarDate'],
  events: ['event', 'tribe-keys'], mailing: ['mailingList'], wiki: ['wikiPage'], maps: ['map', 'tribe-keys', 'mapMarker'],
  clearnet: ['clearnetItem']
};
const ALLOWED_IMG = /\.(png|jpe?g|webp)$/i;
const MAX_BLOB = 50 * 1024 * 1024;

const cbp = (fn, ...a) => new Promise((res, rej) => fn(...a, (e, v) => (e ? rej(e) : res(v))));

function connect(req, ssbConfig) {
  const ssbClient = req('ssb-client');
  const pubKey = String(ssbConfig.keys.public).replace(/\.ed25519$/, '');
  const remotes = [
    `unix:${path.join(ssbConfig.path, 'socket')}~noauth:${pubKey}`,
    `net:127.0.0.1:${ssbConfig.port || 8008}~shs:${pubKey}`
  ];
  return new Promise((resolve, reject) => {
    const tryAt = (i) => {
      // Sin `manifest`: ssb-client se lo pide al servidor vivo (mismo motivo que ssb-probe.js).
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

async function evidence(sbot, pull, me, types) {
  const latest = await new Promise((res, rej) => pull(sbot.createUserStream({ id: me, reverse: true, limit: 1 }), pull.collect((e, v) => (e ? rej(e) : res(v || [])))));
  const seq = latest[0] && latest[0].value ? latest[0].value.sequence : 0;
  const byType = {};
  for (const type of types) {
    const msgs = await new Promise((res, rej) => pull(sbot.messagesByType({ type }), pull.collect((e, v) => (e ? rej(e) : res(v || [])))));
    byType[type] = msgs.filter(m => m && m.value && m.value.author === me).length;
  }
  return { seq, byType };
}

function readLedger(file) {
  try { return JSON.parse(fs.readFileSync(file, 'utf8')); } catch (e) { if (e.code === 'ENOENT') return {}; throw e; }
}
function writeLedger(file, ledger) {
  const tmp = `${file}.tmp.${process.pid}`;
  fs.writeFileSync(tmp, JSON.stringify(ledger, null, 2), { mode: 0o600 });
  fs.renameSync(tmp, file);
}

async function run({ t, args, plan, pending }) {
  const log = (o) => process.stdout.write(JSON.stringify(o) + '\n');
  const req = createRequire(path.join(SRC, 'server/package.json'));
  const pull = req('pull-stream');
  // ssb_config.js resuelve ~/.ssb con HOME (os-homedir): ejecutar como `oasis` con HOME=/home/oasis.
  const ssbConfig = createRequire(path.join(SRC, 'server/package.json'))('./ssb_config');
  const pubId = args.pubId || process.env.OASIS_PUB_ID || '';
  if (!pubId) { console.error('[seed-hot] --pub-id (o OASIS_PUB_ID) obligatorio: el feed id del pub, para el gate «nunca con la identidad del pub»'); return 2; }
  if (!args.assets && plan.assets.length) { console.error(`[seed-hot] la plantilla referencia ${plan.assets.length} imágenes: falta --assets <dir>`); return 2; }
  const wanted = new Set(args.yes || []);
  for (const b of wanted) if (!plan.blocks.some(x => x.name === b)) { console.error(`[seed-hot] --yes ${b}: bloque desconocido (${plan.blocks.map(x => x.name).join(' ')})`); return 2; }

  const { sbot, via } = await connect(req, ssbConfig);
  let code = 0;
  try {
    const me = (await cbp(sbot.whoami)).id;
    const peers = await new Promise((res) => pull(sbot.conn.peers(), pull.take(1), pull.collect((e, v) => res(e ? [] : (v[0] || [])))));
    const pubConnected = peers.some(([, d]) => d && d.state === 'connected' && d.type === 'pub');
    const gates = { notPub: me !== pubId, configPubFalse: ssbConfig.pub !== true, pubConnected };
    log({ event: 'start', whoami: me, via, pubId, gates, dryRun: wanted.size === 0, yes: [...wanted], plan: plan.summary, assets: plan.assets, pending: pending.length });
    if (!gates.notPub || !gates.configPubFalse) { console.error('[seed-hot] GATE: esta identidad es el pub (o su config lleva pub:true). D-O28: nunca con la identidad del pub.'); return 3; }

    const keysDir = require(path.join(SRC, 'configs/state-manager')).keysDir(ssbConfig.path);
    fs.mkdirSync(keysDir, { recursive: true, mode: 0o700 });
    const ledgerFile = args.ledger || path.join(keysDir, `plantilla-${t.meta.id}.json`);
    const lockFile = `${ledgerFile}.lock`;
    if (wanted.size) {
      // El keyring de tribus se reescribe entero (crypto.js:60-65): dos seeders a la vez se pisan.
      if (fs.existsSync(lockFile)) { console.error(`[seed-hot] GATE: lock ${lockFile} presente (otra siembra en curso o abortada: borrarlo solo tras comprobarlo)`); return 3; }
      fs.writeFileSync(lockFile, String(process.pid));
    }
    const ledger = readLedger(ledgerFile);
    ledger.meta = Object.assign(ledger.meta || {}, { id: t.meta.id, whoami: me, pubId });
    ledger.blobs = ledger.blobs || {};
    for (const b of plan.blocks) ledger[b.name] = ledger[b.name] || {};
    const save = () => writeLedger(ledgerFile, ledger);

    // Modelos, cableados como en src/backend/backend.js:1922-2065 pero sin backend.
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

    const uploadAsset = async (name) => {
      if (ledger.blobs[name]) return ledger.blobs[name];
      if (!ALLOWED_IMG.test(name)) throw new Error(`asset ${name}: solo png/jpg/webp`);
      const buf = fs.readFileSync(path.join(args.assets, name));
      if (buf.length > MAX_BLOB) throw new Error(`asset ${name}: ${buf.length} B > 50 MB`);
      const id = await new Promise((res, rej) => pull(pull.values([buf]), sbot.blobs.add((e, v) => (e ? rej(e) : res(v)))));
      await cbp(sbot.blobs.push, id).catch(() => {});   // que el pub (y tras él el HUB) lo traigan sin esperar a un want
      ledger.blobs[name] = id; save();
      return id;
    };
    const keyOf = (block, id) => ledger[block][id] && ledger[block][id].key;
    const tribeKey = (ref) => keyOf('tribes', ref) || keyOf('subtribes', ref);
    const refKey = (section, ref) => keyOf(section, ref);

    const exec = async (block, c) => {
      switch (c.fn) {
        case 'tribes.createTribe': {
          const parent = c.parent ? tribeKey(c.parent) : null;
          if (c.parent && !parent) throw new Error(`${c.id}: la tribu madre ${c.parent} no está en el ledger (siembra antes --yes tribes)`);
          const image = c.image ? await uploadAsset(c.image) : null;
          const r = await M.tribes.createTribe(c.args.title, c.args.description, image, '', c.args.tags, c.args.isAnonymous, c.args.inviteMode, parent, c.args.status, '');
          return r.key;
        }
        case 'tribes.generateOpenInvite': {
          const k = tribeKey(c.tribe); if (!k) throw new Error(`${c.id}: tribu sin sembrar`);
          await M.tribes.generateOpenInvite(k);   // devuelve el código: NO se guarda ni se imprime (TEMPLATE §5)
          return `invite:${k}`;
        }
        case 'rooms.createRoom': {
          const tribeId = c.tribe ? tribeKey(c.tribe) : null;
          if (c.tribe && !tribeId) throw new Error(`${c.id}: tribu ${c.tribe} sin sembrar`);
          const image = c.image ? await uploadAsset(c.image) : undefined;
          const r = await M.rooms.createRoom({ ...c.args, image, tribeId });
          return r.key;
        }
        case 'calendars.createCalendar': {
          const tribeId = c.tribe ? tribeKey(c.tribe) : null;
          if (c.tribe && !tribeId) throw new Error(`${c.id}: tribu ${c.tribe} sin sembrar`);
          const r = await M.calendars.createCalendar({ ...c.args, deadline: '', intervalDeadline: '', mapUrl: '', tribeId });
          return r.key || r;
        }
        case 'calendars.addDate': {
          const cal = refKey('calendars', c.calendar); if (!cal) throw new Error(`${c.id}: calendario ${c.calendar} sin sembrar`);
          const r = await M.calendars.addDate(cal, c.args.date, c.args.label, c.args.intervalWeekly, c.args.intervalMonthly, c.args.intervalYearly, '');
          return (r && r.key) || `date:${cal}`;
        }
        case 'events.createEvent': {
          const image = c.image ? await uploadAsset(c.image) : null;
          const r = await M.events.createEvent(c.args.title, c.args.description, c.args.date, c.args.location, 0, '', [], c.args.tags, c.args.isPublic, '', c.args.clearnetPublic, image ? { images: [image] } : {}, c.args.recurrence);
          return r.key || r;
        }
        case 'mailing.createList': {
          const r = await M.mailing.createList(c.args);
          return r.msgKey || r.key;
        }
        case 'wiki.createPage': {
          let body = c.args.body;
          // template-kit.py copia cada `file:` a <assets>/wiki/<id>.md (el repo no está en el contenedor).
          if (c.file) body = fs.readFileSync(path.join(args.assets, 'wiki', `${c.id}.md`), 'utf8');
          if (c.image) { const id = await uploadAsset(c.image); body = `![image:${c.args.title}](${id})\n\n${body || ''}`; }
          const r = await M.wiki.createPage({ title: c.args.title, body, tags: c.args.tags, aliases: [], editPolicy: c.args.editPolicy, license: '', tribeId: null });
          return r.key;
        }
        case 'maps.createMap': {
          const tribeId = c.tribe ? tribeKey(c.tribe) : null;
          const image = c.image ? await uploadAsset(c.image) : undefined;
          const r = await M.maps.createMap(c.args.lat, c.args.lng, c.args.description, c.args.mapType, c.args.tags, c.args.title, tribeId, c.args.markerLabel, image);
          return r.key || r;
        }
        case 'maps.addMarker': {
          const map = refKey('maps', c.map); if (!map) throw new Error(`${c.id}: mapa ${c.map} sin sembrar`);
          const r = await M.maps.addMarker(map, c.args.lat, c.args.lng, c.args.label, undefined);
          return (r && r.key) || `marker:${map}`;
        }
        case 'clearnet.setItem': {
          const target = refKey(c.section, c.ref); if (!target) throw new Error(`${c.id}: ${c.section}/${c.ref} sin sembrar`);
          if (!String(target).startsWith('%')) throw new Error(`${c.id}: ${target} no es una clave de mensaje`);
          await cbp(sbot.publish, { type: 'clearnetItem', target, kind: c.kind, on: true, createdAt: new Date().toISOString() });
          return `clearnet:${target}`;
        }
        default: throw new Error(`llamada desconocida ${c.fn}`);
      }
    };

    for (const b of plan.blocks) {
      const todo = b.calls.filter(c => !ledger[b.name][c.id]);
      const summary = { block: b.name, calls: b.calls.length, done: b.calls.length - todo.length, pending: todo.length, expected: todo.reduce((n, c) => n + c.msgs, 0) };
      if (!wanted.has(b.name)) { log({ event: 'dry-run', ...summary, calls: todo.map(c => ({ id: c.id, fn: c.fn, msgs: c.msgs, image: c.image || null })) }); continue; }
      if (b.name === 'rooms' && !pubConnected) { console.error('[seed-hot] GATE rooms: sin un pub conectado la sala queda sin centralita (rooms_model.js:339-345)'); code = 3; break; }
      const before = await evidence(sbot, pull, me, BLOCK_TYPES[b.name]);
      log({ event: 'begin', ...summary, before });
      const keys = [];
      let failed = null;
      for (const c of todo) {
        try {
          const key = await exec(b.name, c);
          ledger[b.name][c.id] = { key, at: new Date().toISOString() }; save();
          keys.push({ id: c.id, key });
        } catch (e) { failed = { id: c.id, fn: c.fn, error: e.message }; break; }
      }
      const after = await evidence(sbot, pull, me, BLOCK_TYPES[b.name]);
      const delta = after.seq - before.seq;
      const ok = !failed && delta === summary.expected;
      const rec = { event: 'end', block: b.name, before, after, delta, expected: summary.expected, ok, keys, failed, unmeasurableByType: ['tribe-msg (cifrados)', 'mailingList CLOSED (cifrados)'] };
      log(rec);
      if (args.evidence) fs.appendFileSync(args.evidence, JSON.stringify({ whoami: me, via, at: new Date().toISOString(), ...rec }) + '\n');
      if (failed) { code = 1; break; }
      if (!ok) { console.error(`[seed-hot] PARADA: bloque ${b.name} publicó ${delta} mensajes y se esperaban ${summary.expected}. Nada más se siembra hasta entenderlo.`); code = 1; break; }
    }
    if (wanted.size) { try { fs.unlinkSync(lockFile); } catch (_) {} }
  } finally {
    // tribes_model abre un createLogStream({live:true}) (tribes_model.js:240) que mantiene vivo el proceso.
    await new Promise((res) => { try { sbot.close(() => res()); } catch (_) { res(); } setTimeout(res, 3000).unref(); });
  }
  return code;
}

module.exports = { run };
