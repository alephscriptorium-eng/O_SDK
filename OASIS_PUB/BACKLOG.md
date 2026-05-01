# PUB OASIS SCRIPTORIUM - Backlog

Feature: **PUB OASIS SCRIPTORIUM**

Objetivo: desplegar un pub Oasis/SSB siempre encendido para el ecosistema Scriptorium, usando esta codebase como base de servidor, pero separándolo explícitamente de la instalación de cliente Oasis local.

## Decisiones iniciales

- El pub es un servicio dedicado: no se mezcla con el cliente `oasis-dev` actual.
- El primer despliegue objetivo es VPS CPU-only en GandiCloud VPS.
- La IA local, GPU y cliente Oasis completo quedan fuera del MVP del pub.
- El puerto SSB público será `8008/tcp`.
- La web pública puede vivir en `pub.escrivivir.co` sin romper el uso actual de `escrivivir.co` en WordPress.com o Bluesky.
- La administración del pub no se expondrá públicamente: se accederá por SSH, VS Code Remote SSH o túnel local.
- La red por defecto será la red Oasis existente usando `caps.shs = zTmidAb7t+tKi7W93FIHbOvlbd936x6G/vm8e8Td//A=`. Si se decide red propia, se cambia en `config/ssb/config` antes del primer arranque.

## Fuera de alcance del feature

- Reemplazar la instalación local de cliente Oasis.
- Servir la app completa de navegación Oasis como frontend principal.
- Ejecutar modelo IA GGUF en el VPS.
- Exponer RPC de ECOin al público.
- Montar una plataforma multiusuario de administración del servidor.

## Recomendación de VPS

### MVP serio recomendado

GandiCloud VPS **V-R4** o equivalente:

- 2 vCPU
- 4 GB RAM
- 25 GB iniciales, ampliables
- 1 IPv4 + 1 IPv6
- Ubuntu LTS o Debian estable

Motivo: deja margen para pub SSB, Caddy, panel API, frontend Node/Angular y mantenimiento. El plan de 1 GB sirve para pruebas, pero va justo para un servicio que queremos cuidar.

### Alternativa económica

Plan de 2 GB RAM si aparece disponible en el checkout. Adecuado para solo pub + landing simple. Si luego añadimos Angular SSR y monitorización, subir a V-R4.

## DNS con `escrivivir.co`

Se puede usar el dominio comprado en WordPress.com sin moverlo entero al VPS:

- Mantener `escrivivir.co` como está para WordPress/Bluesky.
- Crear subdominio `pub.escrivivir.co` con registro `A` apuntando a la IPv4 del VPS.
- Crear registro `AAAA` si se usa IPv6.
- No tocar registros Bluesky (`_atproto`, TXT/DID o los que ya uses) salvo que sepamos exactamente qué cambiar.
- Opcional futuro: `panel.pub.escrivivir.co`, solo si se protege con VPN/SSO; por defecto no se recomienda publicar panel admin.

## Épica 1 - Infraestructura VPS

- [ ] Contratar VPS Gandi recomendado.
- [ ] Crear clave SSH local dedicada para el VPS.
- [ ] Crear usuario administrativo no-root si la imagen no lo trae.
- [ ] Instalar Docker siguiendo repos oficiales.
- [ ] Activar firewall permitiendo `22`, `80`, `443`, `8008`.
- [ ] Configurar snapshots automáticos/manuales en Gandi.
- [ ] Configurar DNS `pub.escrivivir.co`.
- [ ] Validar que `pub.escrivivir.co:8008` llega desde fuera.

Criterio de aceptación:

- `ssh` operativo con clave.
- Docker y Docker Compose plugin operativos.
- Puertos públicos correctos.
- DNS resuelve al VPS.

## Épica 2 - Runtime del pub Oasis/SSB

- [x] Separar el modo pub del cliente usando `command: ["server"]`.
- [x] Evitar descarga/configuración del modelo IA en modo pub.
- [x] Añadir override de configuración para no quedar pisados por `server-config.json`.
- [x] Cargar plugin `ssb-invite` para poder generar invites desde el pub.
- [ ] Primer arranque en VPS con volumen persistente propio.
- [ ] Obtener ID del pub con `whoami`.
- [ ] Publicar perfil `about` del pub.
- [ ] Publicar anuncio `pub` con host y puerto.
- [ ] Generar invite inicial.
- [ ] Probar conexión desde cliente Oasis externo.

Criterio de aceptación:

- Contenedor `oasis-pub-scriptorium` estable.
- `manifest.json` contiene métodos de invite.
- Se genera un invite válido.
- Otro peer puede aceptar invite y replicar.

## Épica 3 - Panel de control y monitorización

Arquitectura inicial:

- `pub-panel-api`: API Node.js interna/local.
- Acceso por `127.0.0.1:8787` en el VPS.
- Acceso remoto vía túnel SSH o VS Code port forwarding.
- Autenticación por Bearer token.
- Docker socket montado solo para inspección/restart controlado; revisar hardening antes de producción pública.

Funciones MVP:

- [x] Endpoint público mínimo `/public/status` para landing.
- [x] Endpoint privado `/api/pub/status`.
- [x] Endpoint privado `/api/pub/logs`.
- [x] Endpoint privado `/api/pub/restart`.
- [ ] Endpoint privado para generar invites desde UI.
- [ ] Métricas de disco/volumen SSB.
- [ ] Indicador de peers/conexiones si el manifest lo permite.
- [ ] Registro/auditoría de acciones admin.
- [ ] Alertas básicas por caída del contenedor.

Criterio de aceptación:

- El panel muestra estado, health y últimos logs.
- El panel no queda expuesto públicamente sin túnel/token.
- Reinicio del pub desde panel funciona.

## Épica 4 - Frontend Node.js / Angular 21

La aplicación Angular 21 aportada por el proyecto será el frontend del panel/landing.

- [ ] Añadir la app Angular al workspace o como submódulo/carpeta externa.
- [ ] Definir si será Angular estático o Angular SSR Node.
- [ ] Si es estática: compilar a `OASIS_PUB/site/` o servir dist con Caddy.
- [ ] Si es SSR: usar servicio `pub-frontend` con profile `frontend`.
- [ ] Consumir `/public/status` para landing pública.
- [ ] Consumir `/api/*` con token solo en modo admin/túnel.
- [ ] Añadir variables de entorno de API.
- [ ] Añadir build reproducible.

Criterio de aceptación:

- `docker compose` levanta frontend + API + pub.
- La web pública no filtra tokens.
- La administración funciona por túnel/VS Code.

## Épica 5 - Seguridad y hardening

- [ ] Rotar `PUB_PANEL_TOKEN` antes de producción.
- [ ] Mantener panel API enlazado a `127.0.0.1`.
- [ ] Revisar exposición del Docker socket.
- [ ] Habilitar actualizaciones de seguridad del sistema.
- [ ] Desactivar login SSH por contraseña si aplica.
- [ ] Revisar backups del volumen SSB antes de updates.
- [ ] Documentar procedimiento de recuperación.

Criterio de aceptación:

- No hay panel admin público.
- No hay secretos versionados.
- Existe backup restaurable del volumen SSB.

## Épica 6 - Flujo VS Code remoto

Ruta recomendada:

- Extensión oficial **Remote - SSH** de Microsoft.
- Abrir el VPS como workspace remoto.
- Clonar este repo en `/opt/oasis-scriptorium` o `/srv/oasis-scriptorium`.
- Usar terminal integrada de VS Code sobre SSH.
- Usar port forwarding de VS Code para `127.0.0.1:8787`.
- Opcional: extensión oficial **Dev Containers** si más adelante queremos editar dentro de contenedores.
- Opcional: Docker extension para inspección, sin sustituir los scripts de deploy.

Criterio de aceptación:

- VS Code abre el VPS por SSH.
- Se puede editar repo remoto.
- Se puede ver el panel localmente vía forwarded port.

## Épica 7 - Operación continua

- [ ] Script de backup del volumen SSB.
- [ ] Script de actualización controlada.
- [ ] Snapshot antes de cambios mayores.
- [ ] Monitor externo de HTTP `https://pub.escrivivir.co`.
- [ ] Monitor externo de TCP `pub.escrivivir.co:8008`.
- [ ] Runbook de incidentes.

Criterio de aceptación:

- Podemos actualizar, revertir y recuperar identidad del pub.
- Hay visibilidad básica de caídas.
