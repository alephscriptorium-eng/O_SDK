// Tests de la fase núcleo (WP-S14) — node --test, sin sbot ni Docker.
// Demuestran los invariantes (ii) ningún blob > maxBlob (incluido el MANIFIESTO, que se
// rechaza con 409 si no cabe) y (iii) mismo contenido ⇒ mismo cid, más idempotencia
// (re-publicación sin re-add), reensamblado validado y rechazo de corrupción.
import test from 'node:test';
import assert from 'node:assert/strict';
import { randomBytes, createHash } from 'node:crypto';
import {
  planPublicacion, reensamblar, validarManifiesto, serializarManifiesto,
  cidDe, sha256Hex, necesitaTroceo, trocear
} from '../src/nucleo.mjs';
import { publicarObjeto, obtenerObjeto, estadoObjeto } from '../src/adaptador-sbot.mjs';

// Almacén fake con la misma regla de cid que ssb-blobs (sha256 del contenido).
function almacenFake() {
  const mapa = new Map();
  let adds = 0;
  return {
    async add(buf) { const cid = cidDe(buf); mapa.set(cid, Buffer.from(buf)); adds++; return cid; },
    async get(cid) { if (!mapa.has(cid)) throw new Error('404 no-lo-tengo: ' + cid); return mapa.get(cid); },
    async has(cid) { return mapa.has(cid); },
    _mapa: mapa,
    get _adds() { return adds; }
  };
}

// Tamaños chicos inyectados para que los tests vuelen (la lógica es la misma que 5MB/50MB).
// Elegidos para que el manifiesto (~152 bytes por chunk) quepa bajo maxBlob en los casos legales.
const OPTS = { tamanoChunk: 512, maxBlob: 4000 };

test('invariante (iii): mismo contenido ⇒ mismo cid y mismo manifestCid', () => {
  const datos = randomBytes(9000);
  const p1 = planPublicacion(Buffer.from(datos), OPTS);
  const p2 = planPublicacion(Buffer.from(datos), OPTS);
  assert.equal(p1.manifestCid, p2.manifestCid);
  assert.deepEqual(p1.chunks.map(c => c.cid), p2.chunks.map(c => c.cid));
});

test('objeto pequeño (≤ maxBlob): blob directo, bytes idénticos al volver', async () => {
  const blobs = almacenFake();
  const datos = randomBytes(4000); // exactamente maxBlob → NO trocea (necesitaTroceo es >)
  assert.equal(necesitaTroceo(datos.length, OPTS.maxBlob), false);
  const res = await publicarObjeto(blobs, datos, OPTS);
  assert.equal(res.troceado, false);
  const vuelta = await obtenerObjeto(blobs, res.cid);
  assert.equal(sha256Hex(vuelta), sha256Hex(datos));
});

test('objeto grande: trocea, publica y reensambla íntegro validando SHA-256', async () => {
  const blobs = almacenFake();
  const datos = randomBytes(9333);
  const res = await publicarObjeto(blobs, datos, OPTS);
  assert.equal(res.troceado, true);
  assert.equal(res.chunkCount, Math.ceil(9333 / OPTS.tamanoChunk));
  const vuelta = await obtenerObjeto(blobs, res.manifestCid);
  assert.equal(vuelta.length, datos.length);
  assert.equal(sha256Hex(vuelta), sha256Hex(datos));
  const estado = await estadoObjeto(blobs, res.manifestCid);
  assert.deepEqual(estado, { tiene: true, troceado: true, tamano: 9333 });
});

test('invariante (ii): ningún blob almacenado supera maxBlob (manifiesto incluido)', async () => {
  const blobs = almacenFake();
  await publicarObjeto(blobs, randomBytes(10000), OPTS);
  for (const [, buf] of blobs._mapa) {
    assert.ok(buf.length <= OPTS.maxBlob, `blob de ${buf.length} bytes supera maxBlob=${OPTS.maxBlob}`);
  }
});

test('invariante (ii) estructural: si el manifiesto no cabe, la publicación se RECHAZA (409)', () => {
  // chunk chico + maxBlob chico ⇒ manifiesto de ~12 entradas (~1.9 KB) > maxBlob=1000
  assert.throws(() => planPublicacion(randomBytes(3000), { tamanoChunk: 256, maxBlob: 1000 }), /409/);
});

test('idempotencia: re-publicar el mismo objeto no re-sube nada (0 adds nuevos)', async () => {
  const blobs = almacenFake();
  const datos = randomBytes(9000);
  const r1 = await publicarObjeto(blobs, datos, OPTS);
  const addsTrasPrimera = blobs._adds;
  const r2 = await publicarObjeto(blobs, datos, OPTS);
  assert.equal(r2.manifestCid, r1.manifestCid);
  assert.equal(blobs._adds, addsTrasPrimera, 'la segunda publicación no debe añadir blobs');
});

test('corrupción de un chunk en el almacén ⇒ el reensamblado LANZA (422)', async () => {
  const blobs = almacenFake();
  const res = await publicarObjeto(blobs, randomBytes(9000), OPTS);
  const manifiesto = JSON.parse((await blobs.get(res.manifestCid)).toString('utf8'));
  const cidChunk = manifiesto.chunks[0].cid;
  blobs._mapa.set(cidChunk, randomBytes(manifiesto.chunks[0].tamano));
  await assert.rejects(() => obtenerObjeto(blobs, res.manifestCid), /sha256 mismatch/);
});

test('manifiesto inválido se rechaza (cabecera, suma de tamaños, cids)', () => {
  assert.throws(() => validarManifiesto({ v: 2 }), /cabecera/);
  const { manifiesto } = planPublicacion(randomBytes(9000), OPTS);
  const roto = structuredClone(manifiesto);
  roto.chunks[0].tamano += 1;
  assert.throws(() => validarManifiesto(roto), /suma de chunks/);
  const cidMalo = structuredClone(manifiesto);
  cidMalo.chunks[0].cid = 'no-es-un-cid';
  assert.throws(() => validarManifiesto(cidMalo), /cid de chunk/);
});

test('borde: buffer vacío y chunk exacto', () => {
  assert.equal(trocear(Buffer.alloc(0)).length, 1); // un chunk vacío, no cero chunks
  const exacto = randomBytes(512); // múltiplo exacto de tamanoChunk
  const plan = planPublicacion(exacto, { tamanoChunk: 256, maxBlob: 500 });
  assert.equal(plan.chunks.length, 2);
  assert.equal(plan.chunks[0].tamano, 256);
  assert.equal(plan.chunks[1].tamano, 256);
  const vuelta = reensamblar(plan.chunks.map(c => c.datos), plan.manifiesto);
  assert.equal(sha256Hex(vuelta), sha256Hex(exacto));
});

test('el manifestCid se calcula sobre la serialización canónica', () => {
  const { manifiesto, manifestCid } = planPublicacion(randomBytes(9000), OPTS);
  const bytes = serializarManifiesto(manifiesto);
  const esperado = '&' + createHash('sha256').update(bytes).digest('base64') + '.sha256';
  assert.equal(manifestCid, esperado);
});
