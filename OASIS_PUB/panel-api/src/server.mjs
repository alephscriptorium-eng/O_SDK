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
const directoryUrl = process.env.OASIS_DIRECTORY_URL || 'https://oasis-project.pub/api/pubs';
const inviteUses = Number(process.env.PUB_INVITE_USES || 1000);
const LIVE_TTL_MS = 5 * 60 * 1000;

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

// --- Docker exec (para leer valores en vivo del contenedor del pub) ----------
function dockerCall(method, path, bodyObj) {
  return new Promise((resolve, reject) => {
    const body = bodyObj ? Buffer.from(JSON.stringify(bodyObj)) : null;
    const headers = body
      ? { 'content-type': 'application/json', 'content-length': body.length }
      : {};
    const req = http.request({ socketPath: dockerSocket, method, path, headers }, (res) => {
      const chunks = [];
      res.on('data', (c) => chunks.push(c));
      res.on('end', () => {
        const buffer = Buffer.concat(chunks);
        if (res.statusCode >= 400) {
          reject(new Error(buffer.toString('utf8') || `Docker API ${res.statusCode}`));
          return;
        }
        resolve({ statusCode: res.statusCode, headers: res.headers, buffer });
      });
    });
    req.on('error', reject);
    if (body) req.write(body);
    req.end();
  });
}

async function dockerExec(container, shellCmd) {
  const create = await dockerCall('POST', `/containers/${encodeURIComponent(container)}/exec`, {
    AttachStdout: true, AttachStderr: true, Tty: false,
    Cmd: ['sh', '-lc', shellCmd]
  });
  const execId = JSON.parse(create.buffer.toString('utf8')).Id;
  const start = await dockerCall('POST', `/exec/${execId}/start`, { Detach: false, Tty: false });
  return decodeDockerLogs(start.buffer);
}

// --- Valores SSB en vivo del pub (feedId/cap/version/connect), cacheados -----
let liveCache = { ts: 0, data: null };
let inviteCache = null;

async function getPubLiveInfo() {
  const now = Date.now();
  if (liveCache.data && (now - liveCache.ts) < LIVE_TTL_MS) return liveCache.data;

  const whoamiOut = await dockerExec(pubContainer, 'node /app/OASIS_PUB/tools/ssb-admin.js whoami 2>/dev/null').catch(() => '');
  const feedId = (whoamiOut.match(/@[A-Za-z0-9+/]+=\.ed25519/) || [])[0] || null;

  const shsOut = await dockerExec(pubContainer, 'grep -m1 \'"shs"\' /home/oasis/.ssb/config 2>/dev/null').catch(() => '');
  const capsShs = (shsOut.match(/"shs"\s*:\s*"([^"]+)"/) || [])[1] || null;

  const verOut = await dockerExec(pubContainer, 'grep -m1 \'"version"\' /app/src/server/package.json 2>/dev/null').catch(() => '');
  const version = (verOut.match(/"version"\s*:\s*"([^"]+)"/) || [])[1] || null;

  const connect = feedId
    ? `net:${pubHost}:${pubPort}~shs:${feedId.replace(/^@/, '').replace(/\.ed25519$/, '')}`
    : null;

  const data = { feedId, capsShs, version, connect };
  liveCache = { ts: now, data };
  return data;
}

async function getInvite() {
  if (inviteCache) return inviteCache;
  const out = await dockerExec(pubContainer, `node /app/OASIS_PUB/tools/ssb-admin.js invite.create ${inviteUses} 2>/dev/null`).catch(() => '');
  const inv = (out.match(/[^\s"']+:\d+:@[A-Za-z0-9+/]+=\.ed25519~[A-Za-z0-9+/]+=?/) || [])[0] || null;
  if (inv) inviteCache = inv;
  return inv;
}

// --- Estado de red desde el directorio oficial (cacheado) --------------------
let netCache = { ts: 0, data: null };

async function getNetwork() {
  const now = Date.now();
  if (netCache.data && (now - netCache.ts) < LIVE_TTL_MS) return netCache.data;

  const resp = await fetch(directoryUrl, { signal: AbortSignal.timeout(10000) });
  const arr = await resp.json();
  const list = Array.isArray(arr) ? arr : (arr && Array.isArray(arr.pubs) ? arr.pubs : []);

  const online = list.filter((p) => p.status === 'online' && Number.isInteger(p.cycle));
  const currentCycle = online.reduce((m, p) => Math.max(m, p.cycle), 0) || null;

  const counts = {};
  for (const p of online) {
    if (p.cycle === currentCycle && p.shs) counts[p.shs] = (counts[p.shs] || 0) + 1;
  }
  const currentShs = Object.keys(counts).sort((a, b) => counts[b] - counts[a])[0] || null;

  const self = list.find((p) => p.host === pubHost) || null;
  const onCurrentCycle = Boolean(self && self.shs && self.cycle === currentCycle);

  const data = {
    currentCycle,
    currentShs,
    self: self ? { cycle: self.cycle, shs: self.shs, status: self.status } : null,
    onCurrentCycle,
    fetchedAt: new Date(now).toISOString()
  };
  netCache = { ts: now, data };
  return data;
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
        // Valores SSB en vivo (best-effort: si el exec falla, quedan null).
        const live = await getPubLiveInfo().catch(() => ({ feedId: null, capsShs: null, version: null, connect: null }));
        const invite = await getInvite().catch(() => null);
        sendJson(res, 200, {
          running: pub.running,
          status: pub.status,
          health: pub.health,
          host: pub.host,
          port: pub.port,
          feedId: live.feedId,
          capsShs: live.capsShs,
          version: live.version,
          connect: live.connect,
          invite
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

    if (req.method === 'GET' && url.pathname === '/public/network') {
      try {
        sendJson(res, 200, await getNetwork());
      } catch (error) {
        // Nunca "verde falso": ante fallo, estado desconocido.
        sendJson(res, 200, {
          currentCycle: null,
          currentShs: null,
          self: null,
          onCurrentCycle: null,
          degraded: true,
          error: error.message || 'directory fetch failed'
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
