import http from 'node:http';
import os from 'node:os';
import { URL } from 'node:url';

const port = Number(process.env.PANEL_PORT || 8787);
const bindHost = process.env.PANEL_BIND_HOST || '0.0.0.0';
const dockerSocket = process.env.DOCKER_SOCKET || '/var/run/docker.sock';
const pubContainer = process.env.OASIS_PUB_CONTAINER || 'oasis-pub-scriptorium';
const pubHost = process.env.OASIS_PUB_HOST || 'pub.escrivivir.co';
const pubPort = process.env.OASIS_PUB_PORT || '8008';
const token = process.env.PUB_PANEL_TOKEN;
const corsOrigin = process.env.PANEL_CORS_ORIGIN || '*';

if (!token || token === 'change-me-before-deploy') {
  console.error('[panel-api] Refusing to start without a real PUB_PANEL_TOKEN.');
  process.exit(1);
}

function baseHeaders(extra = {}) {
  return {
    'access-control-allow-origin': corsOrigin,
    'access-control-allow-methods': 'GET,POST,OPTIONS',
    'access-control-allow-headers': 'authorization,content-type',
    'cache-control': 'no-store',
    ...extra
  };
}

function sendJson(res, statusCode, payload) {
  const body = JSON.stringify(payload, null, 2);
  res.writeHead(statusCode, baseHeaders({
    'content-type': 'application/json; charset=utf-8',
    'content-length': Buffer.byteLength(body)
  }));
  res.end(body);
}

function dockerRequest(method, path) {
  return new Promise((resolve, reject) => {
    const req = http.request({ socketPath: dockerSocket, method, path }, (res) => {
      const chunks = [];
      res.on('data', (chunk) => chunks.push(chunk));
      res.on('end', () => {
        const buffer = Buffer.concat(chunks);
        if (res.statusCode >= 400) {
          const message = buffer.toString('utf8') || `Docker API returned ${res.statusCode}`;
          reject(new Error(message));
          return;
        }
        resolve({ statusCode: res.statusCode, headers: res.headers, buffer });
      });
    });

    req.on('error', reject);
    req.end();
  });
}

async function dockerJson(method, path) {
  const response = await dockerRequest(method, path);
  const text = response.buffer.toString('utf8');
  return text ? JSON.parse(text) : null;
}

function decodeDockerLogs(buffer) {
  const parts = [];
  let offset = 0;

  while (offset + 8 <= buffer.length) {
    const size = buffer.readUInt32BE(offset + 4);
    if (size <= 0 || offset + 8 + size > buffer.length) break;
    parts.push(buffer.subarray(offset + 8, offset + 8 + size));
    offset += 8 + size;
  }

  if (parts.length === 0) return buffer.toString('utf8').replace(/\u0000/g, '');
  if (offset < buffer.length) parts.push(buffer.subarray(offset));
  return Buffer.concat(parts).toString('utf8').replace(/\u0000/g, '');
}

function summarizeInspect(inspect) {
  const state = inspect?.State || {};
  return {
    id: inspect?.Id,
    name: inspect?.Name?.replace(/^\//, '') || pubContainer,
    image: inspect?.Config?.Image,
    running: Boolean(state.Running),
    status: state.Status || 'unknown',
    health: state.Health?.Status || null,
    startedAt: state.StartedAt || null,
    finishedAt: state.FinishedAt || null,
    restartCount: inspect?.RestartCount ?? null,
    host: pubHost,
    port: pubPort
  };
}

async function getPubStatus() {
  const inspect = await dockerJson('GET', `/containers/${encodeURIComponent(pubContainer)}/json`);
  return summarizeInspect(inspect);
}

function isAuthorized(req) {
  const authorization = req.headers.authorization || '';
  return authorization === `Bearer ${token}`;
}

function systemSnapshot() {
  return {
    hostname: os.hostname(),
    platform: os.platform(),
    arch: os.arch(),
    uptimeSeconds: os.uptime(),
    loadAverage: os.loadavg(),
    memory: {
      total: os.totalmem(),
      free: os.freemem()
    }
  };
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);

  if (req.method === 'OPTIONS') {
    res.writeHead(204, baseHeaders());
    res.end();
    return;
  }

  try {
    if (req.method === 'GET' && url.pathname === '/health') {
      sendJson(res, 200, { ok: true, service: 'oasis-pub-panel-api' });
      return;
    }

    if (req.method === 'GET' && url.pathname === '/public/status') {
      try {
        const pub = await getPubStatus();
        sendJson(res, 200, {
          running: pub.running,
          status: pub.status,
          health: pub.health,
          host: pub.host,
          port: pub.port
        });
      } catch (error) {
        sendJson(res, 200, {
          running: false,
          status: 'unknown',
          health: null,
          host: pubHost,
          port: pubPort,
          degraded: true
        });
      }
      return;
    }

    if (url.pathname.startsWith('/api/') && !isAuthorized(req)) {
      sendJson(res, 401, { error: 'unauthorized' });
      return;
    }

    if (req.method === 'GET' && url.pathname === '/api/pub/status') {
      const pub = await getPubStatus();
      sendJson(res, 200, { pub, system: systemSnapshot() });
      return;
    }

    if (req.method === 'GET' && url.pathname === '/api/pub/logs') {
      const rawTail = Number(url.searchParams.get('tail') || 200);
      const tail = Math.max(10, Math.min(2000, Number.isFinite(rawTail) ? rawTail : 200));
      const response = await dockerRequest(
        'GET',
        `/containers/${encodeURIComponent(pubContainer)}/logs?stdout=1&stderr=1&timestamps=1&tail=${tail}`
      );
      sendJson(res, 200, { container: pubContainer, tail, logs: decodeDockerLogs(response.buffer) });
      return;
    }

    if (req.method === 'POST' && url.pathname === '/api/pub/restart') {
      await dockerRequest('POST', `/containers/${encodeURIComponent(pubContainer)}/restart?t=10`);
      sendJson(res, 202, { ok: true, action: 'restart', container: pubContainer });
      return;
    }

    sendJson(res, 404, { error: 'not found' });
  } catch (error) {
    sendJson(res, 500, { error: error.message || 'internal error' });
  }
});

server.listen(port, bindHost, () => {
  console.log(`[panel-api] listening on ${bindHost}:${port}`);
  console.log(`[panel-api] supervising container ${pubContainer}`);
});
