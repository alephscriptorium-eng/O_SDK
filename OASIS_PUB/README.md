# PUB OASIS SCRIPTORIUM

Este directorio contiene el backlog y la base de despliegue del feature **PUB OASIS SCRIPTORIUM**.

La instalación de cliente Oasis existente queda como base técnica, pero el pub se despliega como servicio separado y minimalista: SSB/Oasis server, landing web, API local de panel y espacio preparado para frontend Angular 21.

## Dominio `escrivivir.co`

Sí, puedes usar `escrivivir.co` con el nuevo VPS sin romper WordPress.com ni Bluesky.

Recomendación:

- Mantén `escrivivir.co` como está.
- Crea un subdominio `pub.escrivivir.co`.
- En el panel DNS de WordPress.com, añade:
  - `A pub <IPv4-del-VPS>`
  - `AAAA pub <IPv6-del-VPS>` si usas IPv6
- No toques los registros de Bluesky (`_atproto`, TXT/DID o equivalentes) salvo que los vayamos a migrar conscientemente.

Así el root puede seguir en WordPress/Bluesky y el pub vive en el VPS.

## VPS recomendado

Para el despliegue típico con pub + Caddy + panel API + frontend Angular/Node:

- GandiCloud VPS V-R4 o equivalente
- 2 vCPU
- 4 GB RAM
- Ubuntu LTS o Debian estable
- 25 GB iniciales, ampliable

Si quieres gastar menos en MVP, un plan de 2 GB RAM puede servir para solo pub + landing simple. El plan de 1 GB lo dejaría para pruebas.

## Servicios incluidos

- `oasis-pub`: nodo Oasis/SSB en modo pub, puerto `8008`.
- `pub-panel-api`: API local de control/monitorización, puerto local `127.0.0.1:8787`.
- `pub-web`: Caddy con HTTPS automático para `pub.escrivivir.co`.
- `pub-frontend`: perfil opcional para integrar tu app Node.js/Angular 21 cuando la aportes.

## Panel de control

El panel se plantea así:

- API privada: `http://127.0.0.1:8787/api/*`
- Token: `PUB_PANEL_TOKEN` en `.env`
- Acceso remoto: VS Code Port Forwarding o túnel SSH
- Público solo: `https://pub.escrivivir.co/public/status`

No exponemos el panel admin públicamente porque controla el contenedor del pub y monta el Docker socket. Cómodo sí; kamikaze no.

Endpoints MVP:

- `GET /health`
- `GET /public/status`
- `GET /api/pub/status`
- `GET /api/pub/logs?tail=200`
- `POST /api/pub/restart`

## Flujo de deploy típico

1. Copia `.env.example` a `.env`.
2. Cambia `PUB_PANEL_TOKEN`.
3. Ajusta `OASIS_PUB_HOST` si no usas `pub.escrivivir.co`.
4. Revisa `config/ssb/config` antes del primer arranque.
5. Arranca con `bash scripts/deploy.sh`.
6. Obtén la identidad con `bash scripts/whoami.sh`.
7. Publica perfil con `bash scripts/publish-profile.sh`.
8. Anuncia el pub con `bash scripts/announce-pub.sh`.
9. Genera invite con `bash scripts/invite.sh 1`.

## Prueba local rápida

Puedes probar el pub en local sin tocar el despliegue del VPS.

- `npm run pub:local:up` levanta el stack de prueba.
- `npm run pub:local:status` muestra el estado.
- `npm run pub:local:join` imprime URL local, feed ID e invite de un solo uso.
- `npm run pub:local:join-client` intenta unir tu cliente Oasis local en `http://localhost:3000` usando un invite recién generado.
- `npm run pub:local:down` baja el stack.

Valores locales por defecto:

- Landing web: `http://localhost:8088`
- Panel API local: `http://127.0.0.1:8788`
- Puerto SSB del pub: `localhost:8009`

La primera vez se crea `OASIS_PUB/.env.local` automáticamente a partir de `.env.local.example`.

Nota importante: el pub local sí puede arrancar, replicar y mostrar panel/estado, pero `invite.create` de SSB solo genera invites utilizables cuando el nodo anuncia una dirección pública válida. En local puro (`localhost`) verás un aviso explicativo en vez de un invite real.

Los datos persistentes del pub quedan en `volumes-dev/oasis-pub/` para manipulación sencilla, backup y depuración manual, siguiendo el mismo espíritu del cliente:

- `volumes-dev/oasis-pub/ssb-data`
- `volumes-dev/oasis-pub/logs`
- `volumes-dev/oasis-pub/caddy-data`
- `volumes-dev/oasis-pub/caddy-config`

## VS Code remoto

Ruta recomendada:

1. Instala la extensión oficial **Remote - SSH**.
2. Conecta al VPS por SSH.
3. Clona el repo en `/srv/oasis-scriptorium` o `/opt/oasis-scriptorium`.
4. Abre `OASIS_PUB/OASIS_PUB.code-workspace`.
5. Usa la terminal integrada remota para ejecutar scripts.
6. Usa Port Forwarding de VS Code para abrir `127.0.0.1:8787` en local.

Extensiones recomendadas en el workspace:

- `ms-vscode-remote.remote-ssh`
- `ms-vscode-remote.remote-containers`
- `ms-azuretools.vscode-docker`

## Angular 21

Cuando aportes la app Node.js/Angular 21 hay dos caminos:

### Angular estático

Compilar y copiar el resultado a `OASIS_PUB/site/`, dejando Caddy como servidor estático.

### Angular SSR / Node

Añadir el proyecto en `OASIS_PUB/frontend` o configurar `PUB_FRONTEND_DIR` en `.env`, asegurar que expone `8080`, y levantar el profile `frontend`.

Luego se ajusta `caddy/Caddyfile` para hacer reverse proxy al servicio `pub-frontend`.
