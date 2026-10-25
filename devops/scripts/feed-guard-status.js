// feed-guard-status.js — sonda de solo lectura del guardián de feeds de Oasis (>= 1.3.8, `feed_guard.js`)
// contra el sbot que corre DENTRO de un contenedor. Viaja por stdin, como ssb-probe.js:
//
//   MSYS_NO_PATHCONV=1 docker exec -i -u oasis -e HOME=/home/oasis <ctr> sh -lc 'cd /app/src/server && node -' \
//     < devops/scripts/feed-guard-status.js
//
// Imprime el `feedGuard.status()` del nodo en una línea JSON. Lo que se espera tras recrear un nodo
// (UPGRADE-PROTOCOL §3.4 U3 y §4 pasos 7-9): `selfChecked: true` (su feed valida), `reportedOk: true` (coincide
// con la copia de al menos un par) y `lastRepair: null` (no ha borrado ni republicado nada). Un `lastRepair`
// con contenido es una reparación autónoma e irreversible (AGENTES §3): parada dura y RECOVERY-PROTOCOL.
// En un nodo < 1.3.8 el manifest no trae `feedGuard`: se dice y se sale con 2.
const Client = require('ssb-client');
Client((err, sbot) => {
  if (err) { console.log(JSON.stringify({ error: err.message })); process.exit(1); }
  if (!sbot.feedGuard || typeof sbot.feedGuard.status !== 'function') {
    console.log(JSON.stringify({ error: 'sin feedGuard en el manifest (Oasis < 1.3.8)' })); sbot.close(); process.exit(2);
  }
  sbot.feedGuard.status((e, s) => {
    console.log(JSON.stringify(e ? { error: e.message } : s));
    sbot.close();
    process.exit(e || !s || s.lastRepair ? 1 : 0);
  });
});
