#!/usr/bin/env node
// pub-link.js — el enlace de un nodo de soporte (HUB, bot) con el pub de la casa, por RPC al sbot que corre
// DENTRO del contenedor (WP-O143, D-O38). Sustituye a hub-conn-fix.js (WP-O46). Nunca publica: solo toca
// la libreta de conexiones (conn.json) y las conexiones vivas.
//
// Por qué existe: ssb-conn mantiene 4 plazas salientes por nodo y las reparte por ranking (oasisPeerRank),
// sin prioridad para el pub de la casa; con las plazas llenas de pubs externos el nodo deja de marcar al
// suyo hasta una rotación (horas). Un conn.connect explícito abre el enlace fuera de ese reparto; el
// entrypoint lo repite cada N s (start_pub_link) y el protocolo de upgrade lo mide (pub_link en la foto).
//
// Autocontenido: viaja por stdin, los argumentos van tras `-`:
//   docker exec -i -u oasis -e HOME=/home/oasis <ctr> sh -lc 'cd /app/src/server && node - <acción> …' < pub/tools/pub-link.js
//   --status                      pares vivos (conn.peers) y libreta (conn.dbPeers)            [solo lectura]
//   --ensure <host> [--key <K>] [--port <P>] [--now]
//                                 si no hay un par CONECTADO con la clave de la entrada net:<host>:… de la
//                                 libreta (entrante o saliente, cualquier dirección), conn.connect a esa
//                                 entrada; espera hasta 8 s y vuelve a mirar. Sin entrada por nombre: con --key
//                                 (la clave del pub) la crea (remember) a partir de la entrada por clave que haya
//                                 (p. ej. la IP del invite; puerto de esa entrada, --port o 8008); si no,
//                                 OASIS_PUB_LINK_ADDR; si no, rc 3.
//   --remember <addr> [--type T]  conn.remember(addr, {key: la del ~shs:, type (pub), autoconnect: true}); sin conectar
//   --connect <addr>              conn.connect(addr, {key, type: pub})
//   --disconnect <host>           conn.disconnect de los pares vivos cuya dirección es net:<host>:… (drill)
//   --forget-seeded <KEY44>       disconnect + forget de toda entrada `~shs:KEY:SEED` (lo que dejaba invite.accept;
//                                 era hub-conn-fix.js); después --remember/--connect de la limpia si se pasa <addr>
//   --quiet                       aceptado (una sola línea siempre); el bucle del entrypoint decide cuándo mostrarla
// Salida: UNA línea JSON {action, host, key, before, after, did, inbound, error?}.
// rc: 0 ok · 1 error de sbot (p. ej. el socket aún no existe) · 2 uso · 3 sin entrada en la libreta.
// IMPORTANTE: ejecutar como `oasis` con HOME=/home/oasis (como root hablaría con el sbot como un desconocido).

'use strict';
const path = require('path');
const { createRequire } = require('module');

const serverPackage = process.env.OASIS_SERVER_PACKAGE || '/app/src/server/package.json';
const req = createRequire(serverPackage);
const ssbClient = req('ssb-client');
const pull = req('pull-stream');
const config = req('./ssb_config');

const args = process.argv.slice(2);
const flag = (name) => args.includes(name);
const val = (name) => { const i = args.indexOf(name); return i >= 0 && i + 1 < args.length ? args[i + 1] : null; };
const action = ['--status', '--ensure', '--remember', '--connect', '--disconnect', '--forget-seeded'].find((a) => args.includes(a));
if (!action) {
  console.error('uso: pub-link.js --status | --ensure <host> | --remember <addr> [--type pub] | --connect <addr> | --disconnect <host> | --forget-seeded <KEY44> [<addr>]');
  process.exit(2);
}
const arg = val(action);
if (action !== '--status' && !arg) { console.error(`uso: ${action} necesita un argumento`); process.exit(2); }

const canonical = (k) => { const m = String(k || '').match(/([A-Za-z0-9+/]{43}=)/); return m ? `@${m[1]}.ed25519` : null; };
const keyOfAddr = (addr) => { const m = String(addr || '').match(/~shs:([A-Za-z0-9+/]{43}=)(?::|$)/); return m ? `@${m[1]}.ed25519` : null; };
const hostOfAddr = (addr) => { const m = String(addr || '').match(/^net:([^:~]+):/); return m ? m[1] : null; };
const stripShs = (addr) => String(addr).replace(/~shs:.*$/, '');

const pubKey = String(config.keys.public).replace(/\.ed25519$/, '');
const remotes = [
  `unix:${path.join(config.path, 'socket')}~noauth:${pubKey}`,
  `net:127.0.0.1:${config.port || 8008}~shs:${pubKey}`,
];
function connect(i, cb) {
  const opts = Object.assign({}, config, { remote: remotes[i] });
  let called = false;
  const done = (err, sbot) => { if (called) return; called = true; if (err && i + 1 < remotes.length) return connect(i + 1, cb); cb(err, sbot); };
  try { ssbClient(config.keys, opts, done); } catch (e) { done(e); }
}
const cbp = (fn, ...a) => new Promise((res, rej) => fn(...a, (e, v) => (e ? rej(e) : res(v))));
const first = (src) => new Promise((res, rej) => pull(src, pull.take(1), pull.collect((e, v) => (e ? rej(e) : res(v[0] || [])))));
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const out = { action: action.replace(/^--/, ''), host: null, key: null, before: null, after: null, did: 'nothing', inbound: null };
const finish = (sbot, rc) => { console.log(JSON.stringify(out)); const bye = () => process.exit(rc); if (sbot) sbot.close(bye); else bye(); setTimeout(bye, 3000).unref(); };

connect(0, async (err, sbot) => {
  if (err) { out.did = 'error'; out.error = `connect: ${err.message}`; return finish(null, 1); }
  try {
    const livePeers = async () => first(sbot.conn.peers());
    const book = async () => (await cbp(sbot.conn.dbPeers)) || [];
    const liveByKey = (peers, key) => peers.find(([a, d]) => d && d.state === 'connected' && canonical((d.key) || keyOfAddr(a)) === key) || null;

    if (action === '--status') {
      const peers = await livePeers(); const db = await book();
      out.peers = peers.map(([a, d]) => ({ addr: stripShs(a), key: canonical((d && d.key) || keyOfAddr(a)), state: d && d.state, type: d && d.type, inbound: !!(d && d.inbound) }));
      out.book = db.map(([a, d]) => ({ addr: stripShs(a), key: canonical((d && d.key) || keyOfAddr(a)), type: d && d.type, autoconnect: d ? d.autoconnect !== false : null, failure: d && d.failure, stateChange: d && d.stateChange ? new Date(d.stateChange).toISOString() : null }));
      out.peersTotal = out.peers.length; out.peersInbound = out.peers.filter((p) => p.inbound).length; out.bookTotal = out.book.length;
      return finish(sbot, 0);
    }

    if (action === '--ensure') {
      out.host = arg;
      const db = await book();
      // Prefiere la entrada por nombre de servicio (DNS, sobrevive a un cambio de IP del pub) de tipo pub.
      let entry = db.find(([a, d]) => hostOfAddr(a) === arg && keyOfAddr(a) && (!d || !d.type || d.type === 'pub')) || null;
      // Sin entrada por nombre pero con --key (la clave del pub, que el gate conoce): se busca por clave (p. ej. la
      // entrada por IP que dejó el invite), se toma su puerto y se RECUERDA la dirección por nombre: a partir de ahí
      // el keepalive, que no sabe la clave, ya tiene su entrada.
      const wantKey = canonical(val('--key'));
      if (!entry && wantKey) {
        const byKey = db.find(([a, d]) => canonical((d && d.key) || keyOfAddr(a)) === wantKey) || null;
        const port = val('--port') || (byKey ? (String(byKey[0]).match(/^net:[^:]+:(\d+)/) || [])[1] : null) || '8008';
        const k44 = wantKey.replace(/^@/, '').replace(/\.ed25519$/, '');
        const a = `net:${arg}:${port}~shs:${k44}`;
        await cbp(sbot.conn.remember, a, { key: wantKey, type: 'pub', autoconnect: true });
        entry = [a, { key: wantKey, type: 'pub' }]; out.did = 'remember';
      }
      if (!entry && process.env.OASIS_PUB_LINK_ADDR) {
        const a = process.env.OASIS_PUB_LINK_ADDR; if (keyOfAddr(a)) entry = [a, { key: keyOfAddr(a), type: 'pub' }];
      }
      if (!entry) { out.before = out.after = 'no-entry'; return finish(sbot, 3); }
      const addr = String(entry[0]); const key = canonical((entry[1] && entry[1].key) || keyOfAddr(addr)); out.key = key; out.addr = stripShs(addr);
      const live = liveByKey(await livePeers(), key);
      if (live) { out.before = out.after = 'connected'; out.inbound = !!live[1].inbound; return finish(sbot, 0); }
      out.before = 'absent';
      try { await cbp(sbot.conn.connect, addr, { key, type: 'pub' }); out.did = out.did === 'remember' ? 'remember+connect' : 'connect'; } catch (e) { out.did = 'error'; out.error = `connect: ${e.message || e}`; }
      let hit = null;
      for (let i = 0; i < 8 && !hit; i++) { await sleep(1000); hit = liveByKey(await livePeers(), key); }
      out.after = hit ? 'connected' : 'absent'; out.inbound = hit ? !!hit[1].inbound : null;
      return finish(sbot, 0);
    }

    if (action === '--remember' || action === '--connect') {
      const addr = arg; const key = keyOfAddr(addr); if (!key) { console.error('la dirección debe llevar ~shs:<KEY44>'); return finish(sbot, 2); }
      const type = val('--type') || 'pub'; out.key = key; out.addr = stripShs(addr); out.host = hostOfAddr(addr);
      const live = liveByKey(await livePeers(), key); out.before = live ? 'connected' : 'absent';
      if (action === '--remember') { await cbp(sbot.conn.remember, addr, { key, type, autoconnect: true }); out.did = 'remember'; }
      else { await cbp(sbot.conn.connect, addr, { key, type }); out.did = 'connect'; await sleep(3000); }
      const after = liveByKey(await livePeers(), key); out.after = after ? 'connected' : 'absent'; out.inbound = after ? !!after[1].inbound : null;
      return finish(sbot, 0);
    }

    if (action === '--disconnect') {
      // Un nodo suele tener al pub por varias direcciones (nombre de servicio e IP): se corta POR CLAVE, todas.
      out.host = arg; const peers = await livePeers();
      const byHost = peers.find(([a]) => hostOfAddr(a) === arg) || (await book()).find(([a]) => hostOfAddr(a) === arg) || null;
      const key = byHost ? canonical((byHost[1] && byHost[1].key) || keyOfAddr(byHost[0])) : null; out.key = key;
      const mine = peers.filter(([a, d]) => hostOfAddr(a) === arg || (key && canonical((d && d.key) || keyOfAddr(a)) === key));
      out.before = mine.some(([, d]) => d && d.state === 'connected') ? 'connected' : 'absent';
      for (const [a] of mine) { try { await cbp(sbot.conn.disconnect, a); out.did = 'disconnect'; } catch (e) { out.did = 'error'; out.error = e.message || String(e); } }
      await sleep(1000);
      out.after = (key && liveByKey(await livePeers(), key)) ? 'connected' : 'absent';
      return finish(sbot, 0);
    }

    if (action === '--forget-seeded') {
      // Entrada «stale» = cualquier dirección que lleve la clave seguida de un seed (`…~shs:KEY:SEED`): con seed el
      // autoconnect se autentica como la clave desechable del invite, y sin `key` el scheduler espera infinito.
      const k44 = String(arg).replace(/^@/, '').replace(/\.ed25519$/, ''); out.key = canonical(k44);
      const re = new RegExp('~shs:' + k44.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + ':[^:]+$');
      const db = await book(); const stale = db.map(([a]) => String(a)).filter((a) => re.test(a));
      out.stale = stale.length; out.before = stale.length ? 'seeded' : 'clean';
      for (const a of stale) { try { await cbp(sbot.conn.disconnect, a); } catch (_) {} try { await cbp(sbot.conn.forget, a); out.did = 'forget'; } catch (e) { out.did = 'error'; out.error = e.message || String(e); } }
      const clean = args[args.indexOf(action) + 2] && !args[args.indexOf(action) + 2].startsWith('--') ? args[args.indexOf(action) + 2] : null;
      if (clean && keyOfAddr(clean)) {
        await cbp(sbot.conn.remember, clean, { key: out.key, type: 'pub', autoconnect: true });
        await cbp(sbot.conn.connect, clean, { key: out.key, type: 'pub' }).catch((e) => { out.error = `connect: ${e.message || e}`; });
        out.did = 'forget+remember+connect'; await sleep(3000);
        out.after = liveByKey(await livePeers(), out.key) ? 'connected' : 'absent';
      } else { out.after = 'clean'; }
      return finish(sbot, 0);
    }
  } catch (e) {
    out.did = 'error'; out.error = e.message || String(e); return finish(sbot, 1);
  }
});
