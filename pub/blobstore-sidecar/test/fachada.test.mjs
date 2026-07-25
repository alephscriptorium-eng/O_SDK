// Tests de la fachada HTTP (WP-S14 fase 2) — node --test, fetch real contra un
// servidor en puerto efímero, almacén fake inyectado. Sin sbot, sin Docker.
import test from 'node:test';
import assert from 'node:assert/strict';
import { randomBytes } from 'node:crypto';
import { crearFachada } from '../src/fachada-http.mjs';
import { cidDe, sha256Hex } from '../src/nucleo.mjs';

const OPTS = { tamanoChunk: 512, maxBlob: 4000 };
const BASE = '/x/blobstore/v0';

function almacenFake() {
  const mapa = new Map();
  const deseados = new Set();
  return {
    async add(buf) { const cid = cidDe(buf); mapa.set(cid, Buffer.from(buf)); return cid; },
    async get(cid) { if (!mapa.has(cid)) throw new Error('404 no-lo-tengo: ' + cid); return mapa.get(cid); },
    async has(cid) { return mapa.has(cid); },
    async want(cid) { deseados.add(cid); return true; },
    _mapa: mapa,
    _deseados: deseados
  };
}

async function levantar(extra = {}) {
  const blobs = almacenFake();
  const servidor = crearFachada({
    blobs,
    infoSalud: async () => ({ sbot: true, version: '0.0.1', feedId: '@feedDePrueba=.ed25519' }),
    opcionesNucleo: OPTS,
    ...extra
  });
  await new Promise((ok) => servidor.listen(0, '127.0.0.1', ok));
  const url = `http://127.0.0.1:${servidor.address().port}`;
  return { blobs, servidor, url, cerrar: () => new Promise((ok) => servidor.close(ok)) };
}

test('salud responde con sbot/version/feedId', async () => {
  const s = await levantar();
  try {
    const r = await fetch(`${s.url}${BASE}/salud`);
    assert.equal(r.status, 200);
    assert.deepEqual(await r.json(), { sbot: true, version: '0.0.1', feedId: '@feedDePrueba=.ed25519' });
  } finally { await s.cerrar(); }
});

test('POST objetos pequeño → 201 directo; GET devuelve bytes idénticos', async () => {
  const s = await levantar();
  try {
    const datos = randomBytes(1000);
    const r = await fetch(`${s.url}${BASE}/objetos`, { method: 'POST', body: datos });
    assert.equal(r.status, 201);
    const cuerpo = await r.json();
    assert.equal(cuerpo.troceado, false);
    const g = await fetch(`${s.url}${BASE}/objetos/${encodeURIComponent(cuerpo.cid)}`);
    assert.equal(g.status, 200);
    const vuelta = Buffer.from(await g.arrayBuffer());
    assert.equal(sha256Hex(vuelta), sha256Hex(datos));
  } finally { await s.cerrar(); }
});

test('POST objetos grande → 201 troceado con manifestCid; GET reensambla validando', async () => {
  const s = await levantar();
  try {
    const datos = randomBytes(9333);
    const r = await fetch(`${s.url}${BASE}/objetos`, { method: 'POST', body: datos });
    assert.equal(r.status, 201);
    const cuerpo = await r.json();
    assert.equal(cuerpo.troceado, true);
    assert.ok(cuerpo.manifestCid.startsWith('&'));
    const g = await fetch(`${s.url}${BASE}/objetos/${encodeURIComponent(cuerpo.manifestCid)}`);
    const vuelta = Buffer.from(await g.arrayBuffer());
    assert.equal(vuelta.length, datos.length);
    assert.equal(sha256Hex(vuelta), sha256Hex(datos));
    // estado/:cid (el poll de la respuesta ①)
    const e = await fetch(`${s.url}${BASE}/estado/${encodeURIComponent(cuerpo.manifestCid)}`);
    assert.deepEqual(await e.json(), { tiene: true, troceado: true, tamano: 9333 });
  } finally { await s.cerrar(); }
});

test('Range: 206 con el trozo y Content-Range correctos; inválido → 416', async () => {
  const s = await levantar();
  try {
    const datos = randomBytes(1000);
    const { cid } = await (await fetch(`${s.url}${BASE}/objetos`, { method: 'POST', body: datos })).json();
    const r = await fetch(`${s.url}${BASE}/objetos/${encodeURIComponent(cid)}`, { headers: { range: 'bytes=100-199' } });
    assert.equal(r.status, 206);
    assert.equal(r.headers.get('content-range'), 'bytes 100-199/1000');
    const trozo = Buffer.from(await r.arrayBuffer());
    assert.equal(sha256Hex(trozo), sha256Hex(datos.subarray(100, 200)));
    const malo = await fetch(`${s.url}${BASE}/objetos/${encodeURIComponent(cid)}`, { headers: { range: 'bytes=5000-6000' } });
    assert.equal(malo.status, 416);
  } finally { await s.cerrar(); }
});

test('404 con cid desconocido; 422 con chunk corrompido en el almacén', async () => {
  const s = await levantar();
  try {
    const noEsta = await fetch(`${s.url}${BASE}/objetos/${encodeURIComponent('&AAAA.sha256')}`);
    assert.equal(noEsta.status, 404);
    const datos = randomBytes(9000);
    const { manifestCid } = await (await fetch(`${s.url}${BASE}/objetos`, { method: 'POST', body: datos })).json();
    const manifiesto = JSON.parse((await s.blobs.get(manifestCid)).toString('utf8'));
    s.blobs._mapa.set(manifiesto.chunks[0].cid, randomBytes(manifiesto.chunks[0].tamano));
    const g = await fetch(`${s.url}${BASE}/objetos/${encodeURIComponent(manifestCid)}`);
    assert.equal(g.status, 422);
  } finally { await s.cerrar(); }
});

test('409 si el POST supera maxTamano', async () => {
  const s = await levantar({ maxTamano: 500 });
  try {
    const r = await fetch(`${s.url}${BASE}/objetos`, { method: 'POST', body: randomBytes(2000) }).catch(() => null);
    // según timing, el server corta la conexión o responde 409 — ambas valen si NO es 201
    if (r) assert.equal(r.status, 409);
  } finally { await s.cerrar(); }
});

test('deseos → 202 buscando y dispara blobs.want', async () => {
  const s = await levantar();
  try {
    const cid = '&' + 'x'.repeat(44) + '.sha256';
    const r = await fetch(`${s.url}${BASE}/deseos`, {
      method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ cid })
    });
    assert.equal(r.status, 202);
    assert.deepEqual(await r.json(), { cid, estado: 'buscando' });
    assert.ok(s.blobs._deseados.has(cid));
  } finally { await s.cerrar(); }
});

test('② token opcional: sin token abierto; con token exige Bearer en todo el namespace', async () => {
  const s = await levantar({ token: 'secreto123' });
  try {
    const sinAuth = await fetch(`${s.url}${BASE}/salud`);
    assert.equal(sinAuth.status, 401);
    const conAuth = await fetch(`${s.url}${BASE}/salud`, { headers: { authorization: 'Bearer secreto123' } });
    assert.equal(conAuth.status, 200);
  } finally { await s.cerrar(); }
});
