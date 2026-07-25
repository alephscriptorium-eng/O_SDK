// Núcleo puro del sidecar de ficheros (SPEC-sidecar-ficheros-v0, fase núcleo de WP-S14).
// Sin dependencias, sin sbot: troceo, manifiesto v1, validación y reensamblado.
// Modo público SIN cifrado: la integridad ES el cid (mismo contenido ⇒ mismo cid).
import { createHash } from 'node:crypto';

export const TAMANO_CHUNK_DEFECTO = 5 * 1024 * 1024;   // patrón fileshare 0.8.8
export const MAX_BLOB = 50 * 1024 * 1024;               // blobs.max del fork (ssb_config.js)

export const sha256Hex = (buf) => createHash('sha256').update(buf).digest('hex');

// ref de blob SSB: '&' + sha256(bytes) en base64 + '.sha256' — determinista por contenido.
export const cidDe = (buf) => '&' + createHash('sha256').update(buf).digest('base64') + '.sha256';

export const necesitaTroceo = (tamano, maxBlob = MAX_BLOB) => tamano > maxBlob;

export function trocear(buffer, tamanoChunk = TAMANO_CHUNK_DEFECTO) {
  const tam = Math.max(1, Number(tamanoChunk) || TAMANO_CHUNK_DEFECTO);
  const partes = [];
  for (let off = 0; off < buffer.length; off += tam) {
    partes.push(buffer.subarray(off, Math.min(off + tam, buffer.length)));
  }
  if (!partes.length) partes.push(Buffer.alloc(0));
  return partes;
}

// Serialización canónica del manifiesto: el manifestCid se calcula SIEMPRE sobre estos bytes.
export const serializarManifiesto = (m) => Buffer.from(JSON.stringify(m), 'utf8');

export function validarManifiesto(m) {
  if (!m || m.v !== 1 || m.tipo !== 'manifiesto-chunks') throw new Error('manifiesto inválido: cabecera');
  if (!Number.isInteger(m.tamano) || m.tamano < 0) throw new Error('manifiesto inválido: tamano');
  if (typeof m.sha256Total !== 'string' || m.sha256Total.length !== 64) throw new Error('manifiesto inválido: sha256Total');
  if (!Array.isArray(m.chunks) || m.chunks.length === 0) throw new Error('manifiesto inválido: chunks');
  let suma = 0;
  for (const ch of m.chunks) {
    if (typeof ch.cid !== 'string' || !ch.cid.startsWith('&') || !ch.cid.endsWith('.sha256')) throw new Error('manifiesto inválido: cid de chunk');
    if (!Number.isInteger(ch.tamano) || ch.tamano < 0) throw new Error('manifiesto inválido: tamano de chunk');
    if (typeof ch.sha256 !== 'string' || ch.sha256.length !== 64) throw new Error('manifiesto inválido: sha256 de chunk');
    suma += ch.tamano;
  }
  if (suma !== m.tamano) throw new Error('manifiesto inválido: la suma de chunks no cuadra con tamano');
  return true;
}

// Plan de publicación puro: decide directo-vs-troceado y produce cids/manifiesto sin tocar red.
export function planPublicacion(buffer, { tamanoChunk = TAMANO_CHUNK_DEFECTO, maxBlob = MAX_BLOB } = {}) {
  if (!Buffer.isBuffer(buffer)) throw new Error('buffer requerido');
  if (tamanoChunk > maxBlob) throw new Error('tamanoChunk no puede superar maxBlob');
  if (!necesitaTroceo(buffer.length, maxBlob)) {
    return { troceado: false, cid: cidDe(buffer), tamano: buffer.length };
  }
  const chunks = trocear(buffer, tamanoChunk).map((datos) => ({
    datos,
    cid: cidDe(datos),
    tamano: datos.length,
    sha256: sha256Hex(datos)
  }));
  const manifiesto = {
    v: 1,
    tipo: 'manifiesto-chunks',
    sha256Total: sha256Hex(buffer),
    tamano: buffer.length,
    chunks: chunks.map(({ cid, tamano, sha256 }) => ({ cid, tamano, sha256 }))
  };
  const bytesManifiesto = serializarManifiesto(manifiesto);
  // Invariante (ii) estructural: el manifiesto TAMBIÉN es un blob y no puede superar maxBlob.
  // Con defaults (5MB/50MB) esto solo pasaría con objetos de ~1.7 TB — pero se rechaza
  // explícitamente (409 del SPEC), nunca se viola el tope en silencio.
  if (bytesManifiesto.length > maxBlob) {
    throw new Error('409: el manifiesto superaría maxBlob — objeto demasiado grande para manifiesto v1 plano');
  }
  return { troceado: true, chunks, manifiesto, manifestCid: cidDe(bytesManifiesto) };
}

// Reensambla validando sha256 por chunk y total (422 del SPEC = throw aquí).
export function reensamblar(buffersChunks, manifiesto) {
  validarManifiesto(manifiesto);
  if (!Array.isArray(buffersChunks) || buffersChunks.length !== manifiesto.chunks.length) {
    throw new Error('reensamblado: número de chunks no cuadra con el manifiesto');
  }
  for (let i = 0; i < buffersChunks.length; i++) {
    if (sha256Hex(buffersChunks[i]) !== manifiesto.chunks[i].sha256) {
      throw new Error(`reensamblado: sha256 mismatch en chunk ${i}`);
    }
  }
  const total = Buffer.concat(buffersChunks);
  if (total.length !== manifiesto.tamano) throw new Error('reensamblado: tamaño total no cuadra');
  if (sha256Hex(total) !== manifiesto.sha256Total) throw new Error('reensamblado: sha256Total mismatch');
  return total;
}
