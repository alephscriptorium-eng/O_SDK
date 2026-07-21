// Cableado REAL al sbot vía socket unix (respuesta ⑤: ops, socket local; zeus no habla sbot).
// Envuelve pull-streams de ssb-blobs en el contrato {add,get,has,want} del adaptador —
// mismo patrón que fileshare_model.js del fork. Import perezoso: las deps (ssb-client,
// pull-stream) solo existen en la imagen del contenedor; los tests NO pasan por aquí.
// Con ssb-no-auth + ssb-unix-socket activos en el pub, el remote `unix:...~noauth`
// no necesita claves.

export async function conectarSbot({ socket = '/ssb/socket', remote = null } = {}) {
  const { default: ssbClient } = await import('ssb-client');
  const { default: pull } = await import('pull-stream');

  const direccion = remote || `unix:${socket}~noauth`;
  const sbot = await new Promise((resolve, reject) => {
    ssbClient(null, { remote: direccion, manifest: { blobs: {
      add: 'sink', get: 'source', has: 'async', want: 'async', size: 'async'
    }, whoami: 'sync' } }, (err, s) => err ? reject(err) : resolve(s));
  });

  const blobs = {
    add: (buf) => new Promise((resolve, reject) => {
      pull(pull.values([buf]), sbot.blobs.add((err, cid) => err ? reject(err) : resolve(cid)));
    }),
    get: (cid) => new Promise((resolve, reject) => {
      pull(sbot.blobs.get(cid), pull.collect((err, trozos) => {
        if (err) return reject(new Error('404 no-lo-tengo: ' + cid));
        resolve(Buffer.concat(trozos.map((t) => Buffer.isBuffer(t) ? t : Buffer.from(t))));
      }));
    }),
    has: (cid) => new Promise((resolve) => {
      sbot.blobs.has(cid, (err, tiene) => resolve(!err && !!tiene));
    }),
    want: (cid) => new Promise((resolve) => {
      sbot.blobs.want(cid, (err) => resolve(!err));
    })
  };

  const whoami = () => new Promise((resolve) => {
    try { sbot.whoami((err, r) => resolve(err ? null : r && r.id)); } catch { resolve(null); }
  });

  return { sbot, blobs, whoami, cerrar: () => { try { sbot.close(); } catch { /* ya cerrado */ } } };
}
