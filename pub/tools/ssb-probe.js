#!/usr/bin/env node
// ssb-probe.js — sonda de solo lectura (salvo `invite-accept`) contra el sbot que corre DENTRO de un
// contenedor de esta imagen (pub, HUB o cliente en modo `server`). Autocontenido: se puede enviar por
// stdin sin reconstruir la imagen:
//
//   docker exec -i -u oasis -e HOME=/home/oasis [-e SSB_FEED='@…=.ed25519'] [-e SSB_ACTION=seq|peers|invite-accept] \
//     [-e SSB_LINK_KEY='@…=.ed25519'] [-e SSB_INVITE='host:port:@key~seed'] <ctr> sh -lc 'cd /app/src/server && node -' < pub/tools/ssb-probe.js
//
// Salida: JSON {via, me, feed, seq, key, lastTs, iFollow, followsMe, peers[], peersTotal, peersInbound, peersError?, link?, accept?}
//   seq       último `sequence` que ESTE sbot tiene del feed (0 = no tiene nada; si la consulta falla,
//             la sonda sale con error y sin JSON: nunca devuelve 0 por un fallo)
//   iFollow   este sbot sigue al feed · followsMe  el feed sigue a este sbot
//   peers[]   conn.peers() (lo vivo) fundido con conn.dbPeers() (la libreta, conn.json) por dirección:
//             {addr sin shs, key, state, type, inbound, failure, stateChange}. Si conn.peers() falla,
//             peers=[] y peersError dice por qué: quien mide debe tratarlo como «?», nunca como «sin pares».
//   link      con SSB_LINK_KEY: {key, state: connected|absent|?, inbound, addr, failure, stateChange}, buscando POR
//             CLAVE (cualquier dirección, entrante o saliente) primero en lo vivo y si no en la libreta.
//             `?` solo si hubo peersError. El shell lo lee con grep -o '"linkState": *"…"' (ver abajo: se
//             duplica plano como linkState/linkInbound para no parsear JSON en bash).
//
// Conexión: 1º socket unix `noauth` (mismo patrón que src/client/gui.js), 2º TCP loopback con las
// claves propias (permisos master). Reutiliza ssb_config.js igual que pub/tools/ssb-admin.js.
// IMPORTANTE: ejecutar como `oasis` con HOME=/home/oasis; como root, ssb_config resolvería ~/.ssb = /root/.ssb
// (claves nuevas, socket inexistente) y la sonda hablaría con el sbot como un desconocido.

'use strict';
const path = require('path');
const { createRequire } = require('module');

const serverPackage = process.env.OASIS_SERVER_PACKAGE || '/app/src/server/package.json';
const req = createRequire(serverPackage);
const ssbClient = req('ssb-client');
const pull = req('pull-stream');
const config = req('./ssb_config');

const feed = process.env.SSB_FEED || null;
const action = process.env.SSB_ACTION || (feed ? 'seq' : 'peers');
const linkKey = process.env.SSB_LINK_KEY || null;

const pubKey = String(config.keys.public).replace(/\.ed25519$/, '');
const remotes = [
  `unix:${path.join(config.path, 'socket')}~noauth:${pubKey}`,
  `net:127.0.0.1:${config.port || 8008}~shs:${pubKey}`,
];

// Clave canónica: `@<44>.ed25519` tanto si llega así, como `<44>` o como `@<44>`.
const canonical = (k) => {
  const m = String(k || '').match(/([A-Za-z0-9+/]{43}=)/);
  return m ? `@${m[1]}.ed25519` : null;
};
const keyOfAddr = (addr) => {
  const m = String(addr || '').match(/~shs:([A-Za-z0-9+/]{43}=)/);
  return m ? `@${m[1]}.ed25519` : null;
};

function connect(i, cb) {
  // Sin `manifest`: ssb-client se lo pide al servidor. El manifest.json del disco puede ser el de
  // otra versión (en un backend nadie lo reescribe) y ofrecería RPCs que el sbot vivo ya no tiene.
  const opts = Object.assign({}, config, { remote: remotes[i] });
  let called = false;
  const done = (err, sbot) => {
    if (called) return;
    called = true;
    if (err && i + 1 < remotes.length) return connect(i + 1, cb);
    cb(err, sbot, remotes[i]);
  };
  try {
    ssbClient(config.keys, opts, done);
  } catch (e) {
    done(e);
  }
}

const cbp = (fn, ...args) => new Promise((res, rej) => fn(...args, (e, v) => (e ? rej(e) : res(v))));
const collect = (src) => new Promise((res, rej) => pull(src, pull.collect((e, v) => (e ? rej(e) : res(v || [])))));
const first = (src) => new Promise((res, rej) =>
  pull(src, pull.take(1), pull.collect((e, v) => (e ? rej(e) : res(v[0] || [])))));

connect(0, async (err, sbot, via) => {
  if (err) {
    console.error('connect:', err.message);
    process.exit(1);
  }
  const out = { via, me: sbot.id, feed };
  let failed = false;
  try {
    if (action === 'invite-accept') {
      const invite = process.env.SSB_INVITE;
      if (!invite) throw new Error('SSB_INVITE vacío');
      out.accept = await cbp(sbot.invite.accept, invite);
    }
    if (feed) {
      // createUserStream existe con ssb-db (<= 1.1.x) y con ssb-db2 (>= 1.2, db2_legacy.js); getLatest
      // no. Un fallo aquí es un fallo de la sonda, no «seq 0»: quien mide debe poder distinguirlos.
      const latest = (await collect(sbot.createUserStream({ id: feed, reverse: true, limit: 1 })))[0] || null;
      out.seq = latest && latest.value ? latest.value.sequence : 0;
      out.key = latest ? latest.key : null;
      out.lastTs = latest && latest.value && latest.value.timestamp ? new Date(latest.value.timestamp).toISOString() : null;
      out.iFollow = await cbp(sbot.friends.isFollowing, { source: sbot.id, dest: feed }).catch(() => null);
      out.followsMe = await cbp(sbot.friends.isFollowing, { source: feed, dest: sbot.id }).catch(() => null);
    }
    // Lo vivo (conn.peers) y la libreta (conn.dbPeers = conn.json). Un fallo de lo vivo se dice, no se tapa.
    let live = [];
    try { live = await first(sbot.conn.peers()); } catch (e) { out.peersError = e.message || String(e); }
    let book = [];
    try { book = (await cbp(sbot.conn.dbPeers)) || []; } catch (e) { out.dbPeersError = e.message || String(e); }
    const bookByAddr = new Map(book.map(([addr, data]) => [String(addr), data || {}]));
    out.peers = live.map(([addr, data]) => {
      const b = bookByAddr.get(String(addr)) || {};
      return {
        addr: String(addr).replace(/~shs:.*$/, ''),
        key: canonical((data && data.key) || b.key || keyOfAddr(addr)),
        state: data && data.state,
        type: (data && data.type) || b.type || null,
        inbound: !!(data && data.inbound),
        failure: typeof b.failure === 'number' ? b.failure : null,
        stateChange: b.stateChange ? new Date(b.stateChange).toISOString() : null,
      };
    });
    out.peersTotal = out.peers.length;
    out.peersInbound = out.peers.filter((p) => p.inbound).length;
    if (linkKey) {
      const want = canonical(linkKey);
      const hit = out.peers.find((p) => p.key === want && p.state === 'connected');
      if (hit) {
        out.link = { key: want, state: 'connected', inbound: hit.inbound, addr: hit.addr, failure: hit.failure, stateChange: hit.stateChange };
      } else if (out.peersError) {
        out.link = { key: want, state: '?', inbound: null, addr: null, failure: null, stateChange: null };
      } else {
        const entry = book.find(([addr, data]) => canonical((data && data.key) || keyOfAddr(addr)) === want) || null;
        out.link = {
          key: want, state: 'absent', inbound: null,
          addr: entry ? String(entry[0]).replace(/~shs:.*$/, '') : null,
          failure: entry && typeof entry[1].failure === 'number' ? entry[1].failure : null,
          stateChange: entry && entry[1].stateChange ? new Date(entry[1].stateChange).toISOString() : null,
        };
      }
      // Planos, para bash: grep -o '"linkState": *"[a-z?]*"' / '"linkInbound": *[a-z]*'
      out.linkState = out.link.state;
      out.linkInbound = out.link.inbound === true;
    }
    console.log(JSON.stringify(out, null, 2));
  } catch (e) {
    failed = true;
    console.error('probe:', e.message);
  }
  sbot.close(() => process.exit(failed ? 1 : 0));
  setTimeout(() => process.exit(failed ? 1 : 0), 3000).unref();
});
