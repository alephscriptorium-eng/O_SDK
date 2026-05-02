El protocolo recomendado
------------------------

### 1\. Levantar la UI temporal del pub

bash GANDI_DEVOPS_FOLDER/scripts/pub-maint-ui.sh up --stop-pub

Eso:

-   para `oasis-pub-scriptorium`
-   arranca `oasis-pub-maint-ui`
-   monta el mismo estado del pub:
    -   `/srv/oasis/oasis-pub/ssb-data`
    -   config del pub
    -   logs
-   lanza la imagen en `MODE=client`

### 2\. Abrir el túnel SSH

bash GANDI_DEVOPS_FOLDER/scripts/pub-maint-ui.sh tunnel

ssh -i "/c/Users/aleph/OASIS/alephscript-network-sdk/GANDI_DEVOPS_FOLDER/.ssh/gandi_pub_ed25519" -L 3000:127.0.0.1:3000 debian@92.243.24.163

Te imprime un comando tipo:

ssh -i GANDI_DEVOPS_FOLDER/.ssh/gandi_pub_ed25519 -L 3000:127.0.0.1:3000 debian@92.243.24.163

### 3\. Abrir la interfaz local

Luego entras en:

-   `http://localhost:3000/profile/edit`
-   `http://localhost:3000/legacy`

Ahí ya estás navegando como el pub.

### 4\. Cuando termines, bajar UI y relanzar pub

bash GANDI_DEVOPS_FOLDER/scripts/pub-maint-ui.sh down --restart-pub