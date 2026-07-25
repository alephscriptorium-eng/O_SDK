// Entrada del contenedor: cablea el sbot real y levanta la fachada.
// Env: BLOBSTORE_PORT (8790) · OASIS_SOCKET (/ssb/socket) · BLOBSTORE_TOKEN (opcional, ②)
//      BLOBSTORE_MAX_TAMANO (bytes, default 1 GB) · OASIS_REMOTE (multiserver, opcional)
import { createRequire } from 'node:module';
import { conectarSbot } from './cableado-sbot.mjs';
import { crearFachada } from './fachada-http.mjs';

const require = createRequire(import.meta.url);
const pkg = require('../package.json');

const puerto = Number(process.env.BLOBSTORE_PORT || 8790);
const socket = process.env.OASIS_SOCKET || '/ssb/socket';
const remote = process.env.OASIS_REMOTE || null;
const token = process.env.BLOBSTORE_TOKEN || null;
const maxTamano = Number(process.env.BLOBSTORE_MAX_TAMANO || 1024 * 1024 * 1024);

let conexion = null;
let feedId = null;

async function asegurarSbot() {
  if (conexion) return conexion;
  conexion = await conectarSbot({ socket, remote });
  feedId = await conexion.whoami();
  console.log(`[blobstore] sbot conectado (${feedId || 'feed desconocido'})`);
  conexion.sbot.on && conexion.sbot.on('closed', () => { conexion = null; });
  return conexion;
}

// Almacén que reconecta perezosamente: si el sbot cae, el error mapea a 503 en la fachada.
const blobs = {
  add: async (buf) => (await asegurarSbot()).blobs.add(buf),
  get: async (cid) => (await asegurarSbot()).blobs.get(cid),
  has: async (cid) => (await asegurarSbot()).blobs.has(cid),
  want: async (cid) => (await asegurarSbot()).blobs.want(cid)
};

const infoSalud = async () => {
  try { await asegurarSbot(); return { sbot: true, version: pkg.version, feedId }; }
  catch { return { sbot: false, version: pkg.version, feedId: null }; }
};

const servidor = crearFachada({ blobs, infoSalud, token, maxTamano });
servidor.listen(puerto, '0.0.0.0', () => {
  console.log(`[blobstore] fachada /x/blobstore/v0 en :${puerto} (token ${token ? 'ACTIVO' : 'desactivado — LAN abierta, respuesta ②'})`);
});
