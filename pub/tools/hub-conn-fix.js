#!/usr/bin/env node
// WP-O46 · HUB clearnet: normaliza la entrada del pub en conn.json tras `invite.accept`.
// Problema observado (G3, Oasis 1.0.8 / ssb-conn 6.0.3 / ssb-invite): al aceptar un invite el HUB
// persiste en conn.json la direccion CON el seed del invite (`~shs:KEY:SEED`) y sin campo `key`.
//   - con seed: el autoconnect se autentica como la clave desechable del invite -> el pub no replica;
//   - sin `key`: conn-scheduler hace hops[data.key] -> undefined -> cooldown Infinity -> nunca reconecta.
// Uso (dentro del contenedor del HUB; pub/tools no esta montado ahi, copiar con docker cp):
//   cd /app/src/server && node /tmp/hub-conn-fix.js 'net:<host>:<port>~shs:<KEY44>'
const fs = require('fs');
const path = require('path');
const { createRequire } = require('module');

const defaultServerPackage = '/app/src/server/package.json';
const fallbackServerPackage = path.resolve(__dirname, '../../src/server/package.json');
const serverPackage = process.env.OASIS_SERVER_PACKAGE || (fs.existsSync(defaultServerPackage) ? defaultServerPackage : fallbackServerPackage);
const serverRequire = createRequire(serverPackage);
const ssbClient = serverRequire('ssb-client');
const pull = serverRequire('pull-stream');
const config = serverRequire('./ssb_config');

const cleanAddr = String(process.argv[2] || '').trim();
const m = cleanAddr.match(/^net:[^~]+~shs:([A-Za-z0-9+/=]{44})$/);
if (!m) {
  console.error('usage: hub-conn-fix.js net:<host>:<port>~shs:<KEY44>');
  process.exit(2);
}
const key = `@${m[1]}.ed25519`;
const log = (label) => (err) => console.log(`${label}: ${err ? err.message || err : 'ok'}`);

let entries = [];
try {
  entries = Object.keys(JSON.parse(fs.readFileSync(path.join(config.path, 'conn.json'), 'utf8') || '{}'));
} catch (e) {
  console.log('conn.json unreadable:', e.message);
}
// Entrada "stale" = cualquier direccion (sea cual sea el host: el invite se redime con la IP del bridge,
// no con el alias) que lleve la clave del pub seguida de un seed: `...~shs:KEY:SEED`.
const keyRe = new RegExp('~shs:' + m[1].replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + ':[^:]+$');
const stale = entries.filter((a) => a !== cleanAddr && keyRe.test(a));
console.log('conn.json entries:', entries.length, '| stale (con seed):', stale.length);

ssbClient(config.keys, config, (err, sbot) => {
  if (err) { console.error('connect err:', err.message); process.exit(1); }
  const done = () => sbot.close(() => process.exit(0));
  let i = 0;
  const next = () => {
    if (i < stale.length) {
      const a = stale[i++];
      sbot.conn.disconnect(a, () => sbot.conn.forget(a, (e) => { log(`forget ${a.slice(0, 48)}...:SEED`)(e); next(); }));
      return;
    }
    sbot.conn.remember(cleanAddr, { key, type: 'pub', autoconnect: true }, (e) => {
      log('remember (key,type=pub,autoconnect)')(e);
      sbot.conn.connect(cleanAddr, { key, type: 'pub' }, (e2) => {
        log('connect')(e2);
        setTimeout(() => pull(sbot.conn.peers(), pull.take(1), pull.drain((ps) => {
          ps.forEach(([a, d]) => console.log('peer:', a.replace(/:[^:]{43}=$/, ''), d.state, d.type, d.key));
        }, done)), 3000);
      });
    });
  };
  next();
});
