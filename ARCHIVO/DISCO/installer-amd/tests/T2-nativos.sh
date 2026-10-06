#!/usr/bin/env bash
# T2 · Node embebido y módulos nativos cargan con la glibc del sistema.
source "$(dirname "$0")/../bin/lib.sh"; CASE=T2-nativos
evx "$C_MAIN" '/opt/oasis/node/bin/node -v; /opt/oasis/node/bin/node -p "process.versions.modules + \" \" + process.arch"'
evx "$C_MAIN" 'ldd /opt/oasis/node/bin/node'
evx "$C_MAIN" 'cd /opt/oasis/src/server && /opt/oasis/node/bin/node -e "for (const m of [\"ssb-db2\",\"secret-stack\",\"sodium-native\",\"leveldown\",\"sharp\",\"koa\",\"bipf\",\"ssb-config\",\"ssb-client\",\"@open-rpc/client-js\"]) { require(m); console.log(\"ok\", m) }"'; rc=$?
obs native_require_exit "$rc"
evx "$C_MAIN" 'ls /opt/oasis/node/bin; du -sh /opt/oasis/node/include /opt/oasis/node/lib/node_modules/npm /opt/oasis/node/lib/node_modules/corepack 2>/dev/null; true'
