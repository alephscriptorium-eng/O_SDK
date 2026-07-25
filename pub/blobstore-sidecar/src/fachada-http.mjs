// Fachada HTTP del sidecar (WP-S14 fase 2) — contrato adoptado por U101 (SPEC v0.2).
// Respuestas del refinement aplicadas: ① poll (sin webhook) · ② token OPCIONAL vía
// env, sin mTLS · ③ manifiesto v1 tal cual · ④ consumo por HTTP · ⑤ el sbot queda
// detrás (almacén inyectado). Cero dependencias: testeable con un almacén fake.
import http from 'node:http';
import { publicarObjeto, obtenerObjeto, estadoObjeto } from './adaptador-sbot.mjs';

const PREFIJO = '/x/blobstore/v0';

function json(res, codigo, cuerpo) {
  const body = JSON.stringify(cuerpo);
  res.writeHead(codigo, { 'content-type': 'application/json; charset=utf-8', 'content-length': Buffer.byteLength(body) });
  res.end(body);
}

// Mapea errores del núcleo/almacén a los códigos del SPEC.
function codigoDe(err) {
  const m = String(err && err.message || '');
  if (m.startsWith('404')) return 404;
  if (m.startsWith('409')) return 409;
  if (/sha256 mismatch|manifiesto inválido|reensamblado/.test(m)) return 422;
  if (/ECONNREFUSED|sbot caído|socket/.test(m)) return 503;
  return 500;
}

function leerCuerpo(req, maxTamano) {
  return new Promise((resolve, reject) => {
    const partes = [];
    let total = 0;
    req.on('data', (ch) => {
      total += ch.length;
      if (total > maxTamano) { req.destroy(); reject(new Error('409: supera maxTamano configurado')); return; }
      partes.push(ch);
    });
    req.on('end', () => resolve(Buffer.concat(partes)));
    req.on('error', reject);
  });
}

// Range simple: bytes=a-b | bytes=a- | bytes=-n. Devuelve [ini, fin] inclusive o null.
function parsearRange(cabecera, tamano) {
  const m = /^bytes=(\d*)-(\d*)$/.exec(String(cabecera || '').trim());
  if (!m || (m[1] === '' && m[2] === '')) return null;
  let ini, fin;
  if (m[1] === '') { const n = Number(m[2]); ini = Math.max(0, tamano - n); fin = tamano - 1; }
  else { ini = Number(m[1]); fin = m[2] === '' ? tamano - 1 : Number(m[2]); }
  if (Number.isNaN(ini) || Number.isNaN(fin) || ini > fin || ini >= tamano) return { invalido: true };
  return { ini, fin: Math.min(fin, tamano - 1) };
}

/**
 * Crea el servidor HTTP de la fachada.
 * @param {object} deps
 *   blobs      — almacén inyectado {add,get,has,want?} (muxrpc real o fake)
 *   infoSalud  — async () => ({ sbot: bool, version, feedId })
 *   token      — string|null (② token opcional; null = abierto en LAN)
 *   maxTamano  — tope de POST (default 1 GB, mismo criterio que fileShare.maxSize)
 *   opcionesNucleo — { tamanoChunk, maxBlob } inyectables (tests)
 */
export function crearFachada({ blobs, infoSalud, token = null, maxTamano = 1024 * 1024 * 1024, opcionesNucleo = {} } = {}) {
  if (!blobs) throw new Error('blobs requerido');

  return http.createServer(async (req, res) => {
    try {
      const url = new URL(req.url, 'http://localhost');
      if (!url.pathname.startsWith(PREFIJO + '/')) return json(res, 404, { error: 'not found' });
      const resto = url.pathname.slice(PREFIJO.length + 1); // p.ej. "objetos/&abc.sha256"

      // ② auth: token opcional — si está configurado, se exige Bearer en TODO el namespace.
      if (token && req.headers.authorization !== `Bearer ${token}`) {
        return json(res, 401, { error: 'no autorizado' });
      }

      // GET /salud
      if (req.method === 'GET' && resto === 'salud') {
        const info = infoSalud ? await infoSalud() : { sbot: true };
        return json(res, 200, info);
      }

      // POST /objetos — stream de bytes → blob directo o chunk-as-blob (idempotente por contenido).
      if (req.method === 'POST' && resto === 'objetos') {
        const cuerpo = await leerCuerpo(req, maxTamano);
        const r = await publicarObjeto(blobs, cuerpo, opcionesNucleo);
        return json(res, 201, r);
      }

      // GET /objetos/:cid — reensambla validando; soporta Range (206).
      if (req.method === 'GET' && resto.startsWith('objetos/')) {
        const cid = decodeURIComponent(resto.slice('objetos/'.length));
        const datos = await obtenerObjeto(blobs, cid);
        const range = req.headers.range ? parsearRange(req.headers.range, datos.length) : null;
        if (range && range.invalido) {
          res.writeHead(416, { 'content-range': `bytes */${datos.length}` });
          return res.end();
        }
        if (range) {
          const trozo = datos.subarray(range.ini, range.fin + 1);
          res.writeHead(206, {
            'content-type': 'application/octet-stream',
            'content-length': trozo.length,
            'content-range': `bytes ${range.ini}-${range.fin}/${datos.length}`,
            'accept-ranges': 'bytes'
          });
          return res.end(trozo);
        }
        res.writeHead(200, {
          'content-type': 'application/octet-stream',
          'content-length': datos.length,
          'accept-ranges': 'bytes'
        });
        return res.end(datos);
      }

      // GET /estado/:cid — `has` local, sin red (① el poll del consumidor va aquí).
      if (req.method === 'GET' && resto.startsWith('estado/')) {
        const cid = decodeURIComponent(resto.slice('estado/'.length));
        return json(res, 200, await estadoObjeto(blobs, cid));
      }

      // POST /deseos — {cid} → dispara blobs.want (gossip); progreso por poll de estado/:cid.
      if (req.method === 'POST' && resto === 'deseos') {
        const cuerpo = await leerCuerpo(req, 1024 * 64);
        let cid;
        try { cid = JSON.parse(cuerpo.toString('utf8')).cid; } catch { /* abajo */ }
        if (!cid) return json(res, 422, { error: 'cid requerido' });
        if (typeof blobs.want === 'function') blobs.want(cid).catch(() => {});
        return json(res, 202, { cid, estado: 'buscando' });
      }

      return json(res, 404, { error: 'not found' });
    } catch (err) {
      const codigo = codigoDe(err);
      return json(res, codigo, { error: String(err && err.message || err) });
    }
  });
}
