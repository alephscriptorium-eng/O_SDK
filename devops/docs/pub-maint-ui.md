El protocolo recomendado
------------------------

### 1\. Levantar la UI temporal del pub

bash devops/scripts/pub-maint-ui.sh up --stop-pub

Eso:

-   para `oasis-pub-scriptorium`
-   arranca `oasis-pub-maint-ui`
-   monta el mismo estado del pub:
    -   `/srv/oasis/oasis-pub/ssb-data`
    -   config del pub
    -   logs
-   lanza la imagen en `MODE=client`

### 2\. Abrir el túnel SSH

bash devops/scripts/pub-maint-ui.sh tunnel

Te imprime un comando tipo:

ssh -i devops/.ssh/<clave-de-la-instancia> -L 3000:127.0.0.1:3000 <usuario>@<host>

(Los valores salen de devops/hosts/<instancia>/host.env.)

### 3\. Abrir la interfaz local

Luego entras en:

-   `http://localhost:3000/profile/edit`
-   `http://localhost:3000/legacy`

Ahí ya estás navegando como el pub.

### 4\. Cuando termines, bajar UI y relanzar pub

bash devops/scripts/pub-maint-ui.sh down --restart-pub