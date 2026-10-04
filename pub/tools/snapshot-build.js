#!/usr/bin/env node
// snapshot-build.js — construye el snapshot que el PUB ofrece a los clientes nuevos (Oasis >= 1.2,
// D-O27, docs/PUB/HUB-PROTOCOL.md). Corre DENTRO del contenedor del pub, como `oasis`:
//
//   docker exec -u oasis -e HOME=/home/oasis <pub> node /app/pub/tools/snapshot-build.js
//   (o por stdin, sin reconstruir la imagen:  … sh -lc 'cd /app/src/server && node -' < pub/tools/snapshot-build.js)
//
// Por qué existe. Upstream da por hecho que el pub es sbot + backend público sobre el mismo `.ssb`:
// el backend construye `oasis/content/snapshot.oasissn` y el sbot lo sirve (snapshot_plugin.js) a
// quien acepta un invite. Nuestro pub es SOLO sbot: sirve el fichero, pero nadie se lo hace.
//
// Qué hace: se conecta al sbot por su socket, lee `createLogStream` (solo lectura) y escribe el
// fichero con `.tmp` + rename. NO arranca un backend sobre la identidad del pub, NO publica y NO
// carga modelos de upstream (su state-manager muda ficheros del `.ssb` con solo cargarse).
//
// Qué escribe: cabecera `OASISSN1` y, en gzip, registros [tipo u8][longitud u32BE][JSON]:
//   1 (META) una vez · 2 (MSG) por mensaje: {key, value, timestamp}
// y NADA MÁS. El formato admite además registros de blob (3) y de fichero de estado (4), que el
// cliente escribe en su `~/.ssb/oasis/` sin validar: el snapshot del pub no los lleva nunca.
// Los mensajes privados van como están en el log (cifrados); cada mensaje lleva su firma y el
// cliente la valida al ingerirlo.
//
// Solo el nivel `full` (snapshot.oasissn). Upstream construye también uno «reciente» que pesa casi
// lo mismo; el cliente salta el nivel que no existe y así no descarga dos veces.
//
// Memoria constante: dos pasadas por el log (contar, escribir), sin cargarlo en memoria.
// Entorno: SNAPSHOT_MAX_MB (techo del fichero; por defecto 1024; upstream rechaza más de 2048).
// Salida: una línea JSON {ok, path, messages, feeds, boxed, bytes, ms} · exit 0 ok · 1 error · 3 techo superado

'use strict';
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');
const { createRequire } = require('module');

const req = createRequire(process.env.OASIS_SERVER_PACKAGE || '/app/src/server/package.json');
const ssbClient = req('ssb-client');
const pull = req('pull-stream');
const config = req('./ssb_config');

const MAGIC = Buffer.from('OASISSN1');
const REC_META = 1;
const REC_MSG = 2;
const MAX_BYTES = (Number(process.env.SNAPSHOT_MAX_MB) || 1024) * 1024 * 1024;

const dir = path.join(config.path, 'oasis', 'content');
const target = path.join(dir, 'snapshot.oasissn');
const tmp = target + '.tmp';

const pubKey = String(config.keys.public).replace(/\.ed25519$/, '');
const remotes = [
  `unix:${path.join(config.path, 'socket')}~noauth:${pubKey}`,
  `net:127.0.0.1:${config.port || 8008}~shs:${pubKey}`,
];
const connect = (i, cb) => {
  let called = false;
  const done = (err, sbot) => {
    if (called) return;
    called = true;
    if (err && i + 1 < remotes.length) return connect(i + 1, cb);
    cb(err, sbot);
  };
  try { ssbClient(config.keys, Object.assign({}, config, { remote: remotes[i] }), done); } catch (e) { done(e); }
};

const record = (type, payload) => {
  const head = Buffer.alloc(5);
  head.writeUInt8(type, 0);
  head.writeUInt32BE(payload.length, 1);
  return Buffer.concat([head, payload]);
};
// Un mensaje entra si tiene contenido y viene tal cual está en el log (sin descifrar).
const usable = (m) => m && m.key && m.value && m.value.author && m.value.content !== undefined && m.value.content !== null
  && m.value.private !== true;
// Recorre el log entero, de uno en uno, esperando a `each` (contrapresión del gzip).
const walk = (sbot, each) => new Promise((resolve, reject) => {
  pull(
    sbot.createLogStream({ reverse: false }),
    pull.asyncMap((m, cb) => { Promise.resolve(each(m)).then(() => cb(null, true), cb); }),
    pull.onEnd((err) => (err ? reject(err) : resolve()))
  );
});

const fail = (code, msg) => {
  try { fs.unlinkSync(tmp); } catch (_) { /* no había temporal */ }
  console.log(JSON.stringify({ ok: false, error: msg }));
  process.exit(code);
};

connect(0, async (err, sbot) => {
  if (err) return fail(1, 'no conecto con el sbot: ' + err.message);
  const t0 = Date.now();
  try {
    // 1ª pasada: lo que va en META
    const feeds = new Set();
    let messages = 0, boxed = 0;
    await walk(sbot, (m) => {
      if (!usable(m)) return;
      messages++;
      feeds.add(m.value.author);
      if (typeof m.value.content === 'string') boxed++;
    });

    // 2ª pasada: escribir
    fs.mkdirSync(dir, { recursive: true });
    const gzip = zlib.createGzip();
    const out = fs.createWriteStream(tmp);
    const finished = new Promise((resolve, reject) => { out.on('finish', resolve); out.on('error', reject); gzip.on('error', reject); });
    out.write(MAGIC);
    gzip.pipe(out);
    const write = (chunk) => new Promise((resolve) => (gzip.write(chunk) ? resolve() : gzip.once('drain', resolve)));
    const meta = { version: 1, kind: 'snapshot', createdAt: new Date().toISOString(), author: sbot.id, messages, feeds: feeds.size, boxed, sinceMs: null };
    await write(record(REC_META, Buffer.from(JSON.stringify(meta), 'utf8')));
    let written = 0, over = false;
    await walk(sbot, async (m) => {
      if (over || !usable(m) || written >= messages) return;   // lo que llegó después de contar se queda fuera
      await write(record(REC_MSG, Buffer.from(JSON.stringify({ key: m.key, value: m.value, timestamp: m.timestamp }), 'utf8')));
      written++;
      if (out.bytesWritten > MAX_BYTES) over = true;
    });
    gzip.end();
    await finished;
    const bytes = fs.statSync(tmp).size;
    if (over || bytes > MAX_BYTES) { sbot.close(() => {}); return fail(3, `el snapshot supera el techo de ${MAX_BYTES} bytes: no se publica (SNAPSHOT_MAX_MB)`); }
    if (written !== messages) { sbot.close(() => {}); return fail(1, `escritos ${written} de ${messages} mensajes`); }
    fs.renameSync(tmp, target);
    console.log(JSON.stringify({ ok: true, path: target, messages, feeds: feeds.size, boxed, bytes, ms: Date.now() - t0 }));
    sbot.close(() => process.exit(0));
    setTimeout(() => process.exit(0), 3000).unref();
  } catch (e) {
    try { sbot.close(() => {}); } catch (_) { /* ya cerrado */ }
    fail(1, e.message);
  }
});
