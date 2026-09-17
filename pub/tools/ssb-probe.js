#!/usr/bin/env node
// ssb-probe.js — sonda de solo lectura (salvo `invite-accept`) contra el sbot que corre DENTRO de un
// contenedor de esta imagen (pub, HUB o cliente en modo `server`). Autocontenido: se puede enviar por
// stdin sin reconstruir la imagen:
//
//   docker exec -i -u oasis -e HOME=/home/oasis -e SSB_FEED='@…=.ed25519' [-e SSB_ACTION=seq|peers|invite-accept] [-e SSB_INVITE='host:port:@key~seed'] <ctr> \
//     sh -lc 'cd /app/src/server && node -' < pub/tools/ssb-probe.js
//
// Salida: JSON {via, me, feed, seq, key, lastTs, iFollow, followsMe, peers[], accept?}
//   seq       último `sequence` que ESTE sbot tiene del feed (0 = no tiene nada)
//   iFollow   este sbot sigue al feed · followsMe  el feed sigue a este sbot
//
// Conexión: 1º socket unix `noauth` (mismo patrón que src/client/gui.js), 2º TCP loopback con las
// claves propias (permisos master). Reutiliza ssb_config.js igual que pub/tools/ssb-admin.js.
// IMPORTANTE: ejecutar como `oasis` con HOME=/home/oasis; como root, ssb_config resolvería ~/.ssb = /root/.ssb
// (claves nuevas, socket inexistente) y la sonda hablaría con el sbot como un desconocido.

'use strict';
const fs = require('fs');
const path = require('path');
const { createRequire } = require('module');

const serverPackage = process.env.OASIS_SERVER_PACKAGE || '/app/src/server/package.json';
const req = createRequire(serverPackage);
const ssbClient = req('ssb-client');
const pull = req('pull-stream');
const config = req('./ssb_config');

const feed = process.env.SSB_FEED || null;
const action = process.env.SSB_ACTION || 'seq';

let manifest = null;
try {
  manifest = JSON.parse(fs.readFileSync(path.join(config.path, 'manifest.json'), 'utf8'));
} catch (_) { /* el cliente de ssb lo pedirá al servidor */ }

const pubKey = String(config.keys.public).replace(/\.ed25519$/, '');
const remotes = [
  `unix:${path.join(config.path, 'socket')}~noauth:${pubKey}`,
  `net:127.0.0.1:${config.port || 8008}~shs:${pubKey}`,
];

function connect(i, cb) {
  const opts = Object.assign({}, config, { remote: remotes[i] });
  if (manifest) opts.manifest = manifest;
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
      const latest = await cbp(sbot.getLatest, feed).catch(() => null);
      out.seq = latest && latest.value ? latest.value.sequence : 0;
      out.key = latest ? latest.key : null;
      out.lastTs = latest && latest.value && latest.value.timestamp ? new Date(latest.value.timestamp).toISOString() : null;
      out.iFollow = await cbp(sbot.friends.isFollowing, { source: sbot.id, dest: feed }).catch(() => null);
      out.followsMe = await cbp(sbot.friends.isFollowing, { source: feed, dest: sbot.id }).catch(() => null);
    }
    const peers = await first(sbot.conn.peers()).catch(() => []);
    out.peers = peers.map(([addr, data]) => ({
      addr: String(addr).replace(/~shs:.*$/, ''),
      key: data && data.key,
      state: data && data.state,
      type: data && data.type,
    }));
    console.log(JSON.stringify(out, null, 2));
  } catch (e) {
    failed = true;
    console.error('probe:', e.message);
  }
  sbot.close(() => process.exit(failed ? 1 : 0));
  setTimeout(() => process.exit(failed ? 1 : 0), 3000).unref();
});
