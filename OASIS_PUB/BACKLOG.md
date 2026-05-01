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
- [ ] Instalar Docker siguiendo repos oficiales.
- [ ] Activar firewall permitiendo `22`, `80`, `443`, `8008`.
- [ ] Configurar snapshots automáticos/manuales en Gandi.
- [ ] Adjuntar volumen adicional para datos persistentes (`/srv/oasis`).
- [ ] Configurar DNS `pub.escrivivir.co`.
- [ ] (Opcional) Configurar DNS `scriptorium.escrivivir.co` para la segunda landing.
- [ ] Validar que `pub.escrivivir.co:8008` llega desde fuera.

Criterio de aceptación:

- `ssh` operativo con clave dedicada del repo.
- Docker y Docker Compose plugin operativos.
- Puertos públicos correctos.
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
- Almacenamiento actual: único volumen `boot` de `25 GB` en uso; el volumen adicional para datos del pub sigue pendiente.

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
- Clonar este repo en `/opt/oasis-scriptorium` o `/srv/oasis-scriptorium`.
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
