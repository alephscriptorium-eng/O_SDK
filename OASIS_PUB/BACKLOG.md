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
- El layout del host queda fijado: código en `/opt/oasis-scriptorium` y estado persistente en `/srv/oasis`.
- La red por defecto será la red Oasis existente usando `caps.shs = zTmidAb7t+tKi7W93FIHbOvlbd936x6G/vm8e8Td//A=`. Si se decide red propia, se cambia en `config/ssb/config` antes del primer arranque.
- El objetivo de validación no es levantar un pub SSB genérico: el pub debe poder ser aceptado desde el cliente Oasis en `/invites` y quedar como red federada usable para Oasis.

## Fuera de alcance del feature

- Reemplazar la instalación local de cliente Oasis.
- Servir la app completa de navegación Oasis como frontend principal.
- Ejecutar modelo IA GGUF en el VPS.
- Exponer RPC de ECOin al público.
- Montar una plataforma multiusuario de administración del servidor.

## Recomendación de VPS

### Decisión confirmada

Se contrata **GandiCloud VPS V-R4 (intermedio)** porque el pub formará parte del paquete Scriptorium, no es un experimento aislado. Características objetivo:

- 2 vCPU
- 4 GB RAM
- 25 GB iniciales, ampliables
- 1 IPv4 + 1 IPv6
- Debian 13
- Volumen adicional dedicado a datos (`/srv/oasis`) para separar disco de sistema y disco de datos

Motivo: deja margen para pub SSB, Caddy, panel API, frontend Node/Angular, segunda landing Scriptorium y mantenimiento, sin migrar de talla a corto plazo.

### Carpeta operativa

Todo el material de despliegue (claves SSH, scripts de bootstrap, runbooks) vive en `GANDI_DEVOPS_FOLDER/`, fuera de `OASIS_PUB/` y con `.gitignore` deny-by-default. La clave SSH `gandi_pub_ed25519` se genera con `GANDI_DEVOPS_FOLDER/scripts/init-ssh-key.sh`.

### Alternativa económica (descartada por ahora)

Plan más pequeño (1-2 GB RAM): adecuado solo para pub + landing simple. Se descarta porque ya está previsto añadir Angular SSR y la landing Scriptorium.

## DNS con `escrivivir.co`

Se puede usar el dominio comprado en WordPress.com sin moverlo entero al VPS:

- Mantener `escrivivir.co` como está para WordPress/Bluesky.
- Crear subdominio `pub.escrivivir.co` con registro `A` apuntando a la IPv4 del VPS.
- Crear registro `AAAA` si se usa IPv6.
- No tocar registros Bluesky (`_atproto`, TXT/DID o los que ya uses) salvo que sepamos exactamente qué cambiar.
- Opcional futuro: `panel.pub.escrivivir.co`, solo si se protege con VPN/SSO; por defecto no se recomienda publicar panel admin.

## Épica 1 - Infraestructura VPS

- [x] Contratar VPS Gandi V-R4 (intermedio).
- [x] Crear clave SSH local dedicada para el VPS (`GANDI_DEVOPS_FOLDER/.ssh/gandi_pub_ed25519`).
- [x] Subir la clave pública al panel Gandi y asociarla al VPS al crearlo.
- [x] Validar usuario administrativo no-root preexistente en la imagen (`debian` sobre Debian 13).
- [x] Instalar Docker siguiendo repos oficiales de Debian 13.
- [x] Activar firewall permitiendo `22`, `80`, `443`, `8008`.
- [ ] Configurar snapshots automáticos/manuales en Gandi.
- [x] Adjuntar volumen adicional para datos persistentes (`scriptorium-oasis-pub-volumen`, objetivo `/srv/oasis`).
- [x] Crear filesystem, montar `scriptorium-oasis-pub-volumen` en `/srv/oasis` y persistirlo en `/etc/fstab`.
- [x] Preparar perfil de despliegue del VPS con rutas absolutas bajo `/srv/oasis/oasis-pub` para que los bind mounts del pub no escriban en `/opt`.
- [x] Configurar DNS `pub.escrivivir.co`.
- [ ] (Opcional) Configurar DNS `scriptorium.escrivivir.co` para la segunda landing.
- [x] Validar que `pub.escrivivir.co:8008` llega desde fuera.

Criterio de aceptación:

- `ssh` operativo con clave dedicada del repo.
- Docker y Docker Compose plugin operativos.
- Puertos públicos correctos.
- Los bind mounts persistentes del pub apuntan a rutas absolutas bajo `/srv/oasis`.
- DNS resuelve al VPS.

### Evidencia capturada (2026-05-01)

- Evidencia operativa consolidada en `GANDI_DEVOPS_FOLDER/SERVER.md`.
- Primera conexión SSH satisfactoria al VPS con la clave dedicada del repo.
- IP pública actual del VPS: `92.243.24.163`.
- IPv6 pública actual del VPS: `2001:4b98:dc0:43:f816:3eff:feb7:a5b5`.
- Fingerprint SSH ED25519 presentado por el host: `SHA256:9I0q2Nu89boQqsM5vieyHR3Zpmk3Lxb+69pmsd1p+eg`.
- Hostname devuelto por el sistema: `escrivivirco-scriptorium-pub-oasis`.
- Datacenter confirmado por Gandi: `FR-SD6` (`Paris, SD6`).
- Flavor/configuración realmente provisionada: `V-R4: 2 CPUs · 4 GB RAM`.
- Clave SSH registrada en Gandi: `oasis-pub-scriptorium@gandi-vps`.
- Usuario inicial operativo provisto por la imagen: `debian`.
- Sistema operativo activo confirmado: `Debian GNU/Linux 13`.
- Kernel reportado en el login: `6.12.38+deb13-amd64`.
- Volumen `boot` actual: `vps-boot`, ID `55f0e620-cc53-479d-88f5-68269886b3b8`, `25 GB`, estado `IN USE`, origen `Debian 13 TrixieBoot`.
- Volumen de datos ya adjuntado: `scriptorium-oasis-pub-volumen`, ID `5e4ef192-48a3-4b1b-afeb-2c00985859a3`, `40 GB`, estado `IN USE`, previsto para datos persistentes del pub.
- Filesystem de datos creado en `/dev/xvdb` como `ext4` con label truncado `scriptorium-oasi` y UUID `87fb15ef-4806-4928-813e-a2646d2e8082`.
- El volumen de datos ya está montado de forma persistente en `/srv/oasis` mediante `/etc/fstab`.
- Layout base aplicado en el host: código en `/opt/oasis-scriptorium` y estado del pub bajo `/srv/oasis/oasis-pub`.
- Perfil de despliegue real preparado como `OASIS_PUB/.env.prod`, derivado de `.env.vps.example`, con bind mounts absolutos a `/srv/oasis/oasis-pub/*`.
- Docker Engine `26.1.5+dfsg1` y Docker Compose `2.26.1-4` quedaron operativos y persistentes tras reboot.
- UFW quedó activo permitiendo `22`, `80`, `443`, `8008` en IPv4 e IPv6.
- Verificador post-reboot ejecutado con resultado `26 pass, 1 warning, 0 fail`; warning pendiente: `PermitRootLogin without-password`.
- Primer despliegue del stack en VPS completado: `oasis-pub-scriptorium` quedó `healthy`, `pub-panel-api` escucha en `127.0.0.1:8787` y `pub-web` sirve redirección HTTP->HTTPS.
- Reachability por IP ya validada desde fuera: `92.243.24.163:8008` acepta conexión y `http://92.243.24.163/public/status` responde desde Caddy con `308` hacia HTTPS.
- DNS autoritativo y resolutores públicos (`1.1.1.1`, `8.8.8.8`) ya resuelven `pub.escrivivir.co` a `92.243.24.163`.
- Reachability por hostname ya validada desde fuera: `pub.escrivivir.co:8008` acepta conexión externa.
- HTTPS público ya operativo: `https://pub.escrivivir.co/public/status` responde JSON con el estado `running/healthy` del pub.
- El atasco temporal de ACME/TLS quedó asentado tras la actualización DNS de `pub.escrivivir.co`.
- Identidad viva del pub obtenida con `whoami`: `@/snvahvaTP5obvdiYva9OX9NNnTSlUQbEUBSuDRzrZA=.ed25519`.
- Perfil `about` publicado como `PUB OASIS SCRIPTORIUM` / `Nodo pub de Scriptorium para la red Oasis.` (mensaje secuencia `2`).
- Anuncio `pub` publicado para `pub.escrivivir.co:8008` (mensaje secuencia `3`).
- `invite.create 1` ya genera invites válidos para el pub desplegado; no se versiona el código del invite por seguridad operativa.
- Prueba funcional desde cliente Oasis local realizada en `http://localhost:3000/invites`: `pub.escrivivir.co` aparece en `Federated Networks`.
- `gossip.json` del cliente local ya contiene la entrada del pub con `host = pub.escrivivir.co`, `port = 8008`, `source = pub`, `client = true` y `failure = 0`.
- Reintentar `POST /settings/invite/accept` con un invite fresco y `Referer` válido sigue devolviendo `500 {"message":"Invite not accepted by the pub"}` cuando el pub ya figura federado; queda como borde de UX/idempotencia, no como bloqueo de conectividad base.
- Persisten logs ruidosos de SHS/EBT (`invalid challenge`, `stream ended with:0 but wanted:64`, `peer ... does not support RPC ebt.replicate`), pero ya no impiden que el cliente Oasis reconozca y mantenga el pub como red federada.

## Épica 2 - Runtime del pub Oasis/SSB

- [x] Separar el modo pub del cliente usando `command: ["server"]`.
- [x] Evitar descarga/configuración del modelo IA en modo pub.
- [x] Añadir override de configuración para no quedar pisados por `server-config.json`.
- [x] Cargar plugin `ssb-invite` para poder generar invites desde el pub.
- [x] Primer arranque en VPS con volumen persistente propio.
- [x] Obtener ID del pub con `whoami`.
- [x] Publicar perfil `about` del pub.
- [x] Publicar anuncio `pub` con host y puerto.
- [x] Generar invite inicial.
- [x] Probar conexión desde cliente Oasis externo.

Criterio de aceptación:

- Contenedor `oasis-pub-scriptorium` estable.
- `manifest.json` contiene métodos de invite.
- Se genera un invite válido.
- Otro peer puede aceptar invite y replicar.

### Plan de remate - aceptar invite desde cliente Oasis

Estado actual:

- `https://pub.escrivivir.co` funciona.
- `pub.escrivivir.co:8008` acepta conexión externa.
- El pub tiene identidad, perfil `about`, anuncio `pub` e invites generados desde `invite.create`.
- El cliente Oasis local ya muestra `pub.escrivivir.co` en `Federated Networks` y su `gossip.json` lo registra con `failure = 0`.
- Al intentar aceptar el invite desde el cliente Oasis local en `http://localhost:3000/invites`, el contenedor `oasis-server-dev` registra errores SHS como:
  - `client sent invalid challenge (phase 1)`
  - `possibly they tried to speak a different protocol or had wrong application cap`
  - `peer @/snvahvaTP5obvdiYva9OX9NNnTSlUQbEUBSuDRzrZA=.ed25519 does not support RPC ebt.replicate`
- Reintentar `POST /settings/invite/accept` con `Referer` correcto devuelve `500 {"message":"Invite not accepted by the pub"}`; eso apunta más a un borde de reintento/UX que a un fallo de federación inicial.

Regla de enfoque: **no tocar arquitectura** hasta aislar esto. El problema a cerrar está en compatibilidad runtime del cliente Oasis / invite / red SSB usada por Oasis, no en Caddy, DNS, Docker base del VPS ni en la landing pública.

Hipótesis a verificar, en este orden:

1. **Cliente local desactualizado o imagen stale**: el contenedor `oasis-server-dev` puede no estar ejecutando el `src/server` actual que carga `ssb-invite-client`, `ssb-ebt` y `caps.shs` Oasis.
2. **`caps.shs` runtime distinto al esperado**: aunque `src/configs/server-config.json` declare `zTmidAb7t+tKi7W93FIHbOvlbd936x6G/vm8e8Td//A=`, hay que comprobar lo que ve realmente `require('/app/src/server/ssb_config').caps.shs` dentro del contenedor local.
3. **Formato de invite incompatible con el flujo Oasis**: el cliente pasa por `meta.acceptInvite()` y `toLegacyInvite()` en `src/models/main_models.js`; hay que validar que acepta tanto `host:port:@key.ed25519~secret` como formatos multiserver `net:host:port~shs:key~invite:secret` si aparecen.
4. **Ruido por protocolo equivocado contra `8008` local**: los errores desde `net:::ffff:172.18.0.1:*~shs:` pueden venir de probes HTTP/TCP contra el puerto SSB local; distinguir ruido de fallo real mirando `gossip.json`, retorno HTTP de `/settings/invite/accept` y logs del pub remoto.
5. **Diferencia con Oasis upstream de epsylon**: comparar el flujo actual de `/invites`, `acceptInvite`, `toLegacyInvite`, `ssb_config` y carga de plugins contra el repo Oasis de epsylon que usa el cliente Docker, porque probablemente ya existe ahí el comportamiento correcto.

Pasos concretos:

- [ ] Hacer backup antes de tocar estado local: `volumes-dev/ssb-data` y, como mínimo, `.ssb/secret`, `gossip.json`, `gossip_unfollowed.json` y `manifest.json`.
- [ ] Comprobar dentro de `oasis-server-dev` el runtime real:
  - `caps.shs`
  - `config.path`
  - `manifest.json` con `invite.accept`, `conn.*`, `gossip.*` y `ebt.*`
  - versión/carga de `ssb-invite-client`, `ssb-invite`, `ssb-ebt` y `ssb-replication-scheduler`.
- [ ] Comprobar dentro de `oasis-pub-scriptorium` el runtime equivalente del pub:
  - mismo `caps.shs`
  - `manifest.json` con `invite.create` y métodos de conexión esperados
  - `connections.incoming.net[].external = pub.escrivivir.co`.
- [ ] Generar un invite nuevo de un solo uso en el VPS y probar aceptación desde el cliente local con dos caminos:
  - UI `http://localhost:3000/invites`
  - llamada directa al handler `POST /settings/invite/accept` para capturar código HTTP y error real sin depender del navegador.
- [ ] Si el fallo es de formato, ajustar `toLegacyInvite()` y añadir casos explícitos para el formato real generado por `ssb-invite` del pub.
- [ ] Si el fallo es de imagen stale, reconstruir/recrear solo `oasis-server-dev` con la codebase actual sin borrar el volumen SSB local salvo backup explícito.
- [ ] Si el fallo es de `caps.shs`, alinear cliente local y pub a la red Oasis existente antes de generar nuevos invites; no mezclar invites generados con caps antiguos.
- [ ] Si el fallo es de plugin/API, portar el patrón upstream de epsylon al cliente Docker de esta repo y documentar la divergencia.
- [ ] Confirmar éxito observando `gossip.json`/vista `/invites`: `pub.escrivivir.co` debe aparecer como red federada activa, no como unreachable.
- [ ] Confirmar replicación mínima: el cliente local debe poder resolver el feed del pub `@/snvahvaTP5obvdiYva9OX9NNnTSlUQbEUBSuDRzrZA=.ed25519` y recibir mensajes posteriores al `about`/`pub`.

Criterio de cierre de este remate:

- `/settings/invite/accept` devuelve éxito o redirección limpia sin stacktrace.
- `/invites` muestra `pub.escrivivir.co:8008` como federado/activo.
- No queda un bucle de `invalid challenge` asociado al intento de aceptar el invite; si aparecen probes aislados contra `8008`, quedan clasificados como ruido no bloqueante.
- El pub remoto registra conexión/replicación del cliente.
- Se documenta en `GANDI_DEVOPS_FOLDER/SERVER.md` la evidencia final sin guardar invites vivos en el repo.

## Épica 3 - Panel de control y monitorización

Arquitectura inicial:

- `pub-panel-api`: API Node.js interna/local.
- Acceso por `127.0.0.1:8787` en el VPS.
- Acceso remoto vía túnel SSH o VS Code port forwarding.
- Autenticación por Bearer token (estado actual; pendiente reforzar).
- Docker socket montado solo para inspección/restart controlado; revisar hardening antes de producción pública.

Funciones MVP:

- [x] Endpoint público mínimo `/public/status` para landing.
- [x] Endpoint privado `/api/pub/status`.
- [x] Endpoint privado `/api/pub/logs`.
- [x] Endpoint privado `/api/pub/restart`.
- [x] UI admin local servida por `pub-web` en `/admin/` con look & feel poster-template.
- [ ] Endpoint privado para generar invites desde UI.
- [ ] Métricas de disco/volumen SSB.
- [ ] Indicador de peers/conexiones si el manifest lo permite.
- [ ] Registro/auditoría de acciones admin.
- [ ] Alertas básicas por caída del contenedor.

### Auth "de verdad" del panel (pendiente de decidir)

Opciones consideradas, de menos a más estricto:

1. **Bearer token + bind a 127.0.0.1 + túnel SSH** (estado actual).
   - Pros: simple, sin más infraestructura, encaja con el flujo VS Code Remote SSH.
   - Contras: si alguien expone el puerto por error, el token es la única defensa.
2. **Bearer token + mTLS de Caddy en una ruta `/admin-api/` privada**.
   - Caddy exige certificado de cliente firmado por una CA privada propia.
   - Pros: imposible llegar al panel sin certificado válido aunque se exponga.
   - Contras: hay que generar y rotar certificados de cliente.
3. **OIDC (GitHub OAuth o similar) delante del panel via `caddy-security` / `oauth2-proxy`**.
   - Pros: sin tokens largos en el navegador, rotación delegada al IdP.
   - Contras: dependencia externa, más piezas que mantener.

Decisión por defecto para MVP: **opción 1** mientras vivamos en local + túnel; al pasar a VPS pasar a **opción 2** antes de cualquier exposición real.

Criterio de aceptación:

- El panel muestra estado, health y últimos logs.
- El panel no queda expuesto públicamente sin túnel/token.
- Reinicio del pub desde panel funciona.
- En VPS: el panel API nunca acepta conexiones sin certificado de cliente válido.

## Épica 4 - Frontend Node.js / Angular 21 (easy-switch)

Objetivo: que `pub-web` pueda servir **landing estática actual** o **frontend Angular** sin tocar Caddy ni cambiar puertos. Solo cambiando una variable de entorno o un profile de compose.

Arquitectura propuesta:

- `pub-web` (Caddy) sigue siendo el único punto de entrada público.
- El contenido servido en `/` se decide por:
  - `OASIS_PUB_FRONT_MODE=static` → bind mount de `OASIS_PUB/site/` (lo de hoy).
  - `OASIS_PUB_FRONT_MODE=angular` → bind mount del `dist/` compilado de la app Angular, o reverse proxy a `pub-frontend` si se usa SSR.
- Las rutas `/public/*` y `/admin/` siguen funcionando igual independientemente del modo.

Tareas:

- [ ] Añadir variable `OASIS_PUB_FRONT_MODE` con valores `static` o `angular`.
- [ ] Documentar cómo intercambiar modo en local y en VPS.
- [ ] Añadir la app Angular al workspace o como submódulo/carpeta externa.
- [ ] Definir si será Angular estático o Angular SSR Node.
- [ ] Si es estática: compilar a `OASIS_PUB/site-angular/` y montar en Caddy.
- [ ] Si es SSR: usar servicio `pub-frontend` con profile `frontend`.
- [ ] Consumir `/public/status` para landing pública.
- [ ] Consumir `/api/*` con token solo en modo admin/túnel.
- [ ] Añadir variables de entorno de API.
- [ ] Añadir build reproducible.

Criterio de aceptación:

- `docker compose` levanta frontend + API + pub.
- Cambiar `OASIS_PUB_FRONT_MODE` y reiniciar `pub-web` basta para alternar landing estática/Angular.
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
- Clonar este repo en `/opt/oasis-scriptorium`.
- Usar terminal integrada de VS Code sobre SSH.
- Usar port forwarding de VS Code para `127.0.0.1:8787`.
- Opcional: extensión oficial **Dev Containers** si más adelante queremos editar dentro de contenedores.
- Opcional: Docker extension para inspección, sin sustituir los scripts de deploy.

Criterio de aceptación:

- VS Code abre el VPS por SSH.
- Se puede editar repo remoto.
- Se puede ver el panel localmente vía forwarded port.

## Épica 8 - Landing Scriptorium (segunda web pública)

Objetivo: añadir una **segunda landing pública**, hermana de la del pub, dedicada a presentar **Scriptorium como paquete de herramientas para la red Oasis** (no solo este pub). Pensada para ser visitada por usuarios de Oasis interesados en Scriptorium, no para administrar nada.

Decisión a tomar antes de implementar:

- **A)** Servirla desde el mismo `pub-web` en una ruta secundaria, p. ej. `/scriptorium/`, con bind mount de `OASIS_PUB/site/scriptorium/`.
  - Pros: cero infra extra, mismo certificado HTTPS, mismo stack.
  - Contras: acopla Scriptorium al ciclo de vida del pub.
- **B)** Subdominio dedicado (`scriptorium.escrivivir.co`) servido por `pub-web` como vhost extra.
  - Pros: independencia visual y de marca, mismo Caddy, sin contenedor nuevo.
  - Contras: requiere DNS extra y un bloque adicional en `Caddyfile`.
- **C)** Contenedor nuevo `scriptorium-web` (otra imagen Caddy/nginx) con su propio compose service.
  - Pros: ciclo de vida totalmente independiente, fácil mover a otro host.
  - Contras: más piezas, más mounts, más superficie a mantener.

Recomendación inicial: empezar por **A** (ruta `/scriptorium/`) durante la fase local, y migrar a **B** (subdominio) cuando se contrate el VPS y se configure DNS, sin necesidad de pasar por **C** salvo que Scriptorium crezca a un site con backend propio.

Tareas:

- [ ] Crear esqueleto en `OASIS_PUB/site/scriptorium/index.html` con look & feel poster-template.
- [ ] Decidir contenido inicial (qué es Scriptorium, herramientas incluidas, enlaces a SDK y al pub).
- [ ] Habilitar la ruta `/scriptorium/` en `Caddyfile` (modo A).
- [ ] Documentar el switch a subdominio (modo B) cuando exista DNS público.
- [ ] Marcar explícitamente que esta landing **no requiere panel ni API**: es puro contenido.

Criterio de aceptación:

- `http://localhost:8088/scriptorium/` sirve la landing Scriptorium.
- La landing del pub y la de Scriptorium son visualmente coherentes pero independientes en contenido.
- Cambiar a subdominio en VPS es solo un bloque más de Caddy, sin tocar contenedores.

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
