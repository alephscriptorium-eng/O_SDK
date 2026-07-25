1.  #### Tú dijiste:

2.  #### ChatGPT Plus

    Sí. Si te refieres a **RAD** (el framework/CLI que se instala con un comando tipo `curl ... | sh`), el truco está en que el `curl` **no "encuentra" nada por sí mismo**. Lo que hace es descargar un script desde un servidor y ejecutarlo.

    Por ejemplo, un instalador típico tiene este aspecto:

    ```
    curl -fsSL https://ejemplo.com/install.sh | sh

    ```

    o

    ```
    curl -fsSL https://ejemplo.com/install.sh | bash

    ```

    El proceso es:

    1.  `curl` hace una petición HTTP a `https://ejemplo.com/install.sh`.
    2.  El servidor devuelve el contenido del script.
    3.  El `| sh` (o `| bash`) envía ese contenido al intérprete de comandos para ejecutarlo.

    Dentro de ese script suele haber lógica como:

    ```
    OS=$(uname -s)
    ARCH=$(uname -m)

    if [ "$OS" = "Linux" ]; then
        URL="https://servidor/rad-linux-amd64.tar.gz"
    elif [ "$OS" = "Darwin" ]; then
        URL="https://servidor/rad-macos-arm64.tar.gz"
    fi

    curl -L "$URL" -o /tmp/rad.tar.gz
    tar -xzf /tmp/rad.tar.gz
    mv rad /usr/local/bin/

    ```

    ### ¿Y el `localhost`?

    Si durante la instalación aparece algo como:

    ```
    http://localhost:8080

    ```

    eso normalmente **no se usa para instalar**. Significa que el programa ya está instalado y ha arrancado un servidor web en tu propio ordenador.

    Por ejemplo:

    ```
    rad serve

    ```

    puede mostrar:

    ```
    Server listening on http://localhost:3000

    ```

    `localhost` siempre apunta a tu propia máquina (`127.0.0.1`), así que el navegador se conecta al proceso que acaba de iniciar el programa.

    ### ¿Cómo sabe el script dónde está RAD?

    Depende del proyecto:

    -   El script conoce una URL fija donde descargar el binario.
    -   O consulta una API (por ejemplo, la última versión en GitHub Releases).
    -   O instala mediante un gestor de paquetes (`apt`, `brew`, `cargo`, etc.).

    No "busca" el programa en tu ordenador; el script ya lleva escrita la lógica para descargarlo e instalarlo.

    Si me dices **qué RAD** es (o pegas el comando `curl` que aparece en la web), puedo explicarte exactamente cómo funciona ese instalador línea por línea.

3.  #### Tú dijiste:

4.  #### ChatGPT Plus

    La respuesta corta es: **no, no de forma nativa**.

    Según la documentación oficial, **Radicle solo soporta Linux, macOS y otros sistemas tipo Unix**. **Windows no está soportado actualmente**, por lo que ejecutar el instalador desde Git Bash no hará que funcione como si fuera Linux.

    De hecho, en la FAQ indican explícitamente que tienen intención de añadir soporte para Windows si hay suficiente demanda.

    ### ¿Y Git Bash?

    Git Bash puede ejecutar el comando:

    ```
    curl -sSLf https://radicle.xyz/install | sh

    ```

    pero el problema no es `curl` ni `sh`. El script descarga binarios **para Linux/macOS/BSD**, no para Windows. En la página de descargas tampoco aparecen binarios para Windows; únicamente hay objetivos para Linux y macOS.

    ### Si estás en Windows, tienes dos opciones

    -   **WSL2 (recomendado)**: instala Ubuntu u otra distribución Linux y ejecuta Radicle dentro de WSL. Es la opción más cercana a una instalación nativa de Linux.
    -   **Máquina virtual** con Linux.

    ### Mi recomendación

    Si ya usas Windows y Git Bash, **no perdería tiempo intentando instalar Radicle ahí**. Instala **WSL2 + Ubuntu** y sigue exactamente las instrucciones oficiales dentro de la terminal de Ubuntu. Tendrás prácticamente la misma experiencia que un usuario de Linux y el CLI `rad` funcionará como está previsto.

    Si tu objetivo es **solo experimentar con Radicle**, puedo guiarte para dejarlo funcionando en WSL en unos 10 minutos.

5.  #### Tú dijiste:

6.  #### ChatGPT Plus

    Perfecto. La forma más sencilla y estable es **Windows 11 + WSL2 + Ubuntu + Radicle**. En unos minutos deberías tenerlo funcionando.

    Paso 1. Instalar WSL2
    ---------------------

    Abre **PowerShell como Administrador** y ejecuta:

    ```
    wsl --install

    ```

    Esto instala WSL2 y Ubuntu automáticamente. Cuando termine, **reinicia el PC** si te lo pide.

    * * * * *

    Paso 2. Crear tu usuario Linux
    ------------------------------

    Al abrir **Ubuntu** por primera vez, te pedirá:

    ```
    Enter new UNIX username:

    ```

    Por ejemplo:

    ```
    juan

    ```

    Después:

    ```
    New password:
    Retype new password:

    ```

    Ese usuario **es independiente del usuario de Windows**.

    * * * * *

    Paso 3. Actualizar Ubuntu
    -------------------------

    En la terminal de Ubuntu:

    ```
    sudo apt update
    sudo apt upgrade -y

    ```

    * * * * *

    Paso 4. Instalar Radicle
    ------------------------

    Ejecuta exactamente los comandos de la documentación oficial:

    ```
    curl -LO https://radicle.dev/apt/radicle-archive-keyring.deb
    chmod a+r radicle-archive-keyring.deb
    sudo apt install ./radicle-archive-keyring.deb

    ```

    Añade el repositorio:

    ```
    echo "deb [signed-by=/usr/share/radicle/radicle-archive-keyring.asc] https://radicle.dev/apt release main" | sudo tee -a /etc/apt/sources.list

    ```

    Actualiza e instala:

    ```
    sudo apt update
    sudo apt install radicle

    ```

    * * * * *

    Paso 5. Comprobar
    -----------------

    ```
    rad --version

    ```

    Si ves algo como:

    ```
    rad 1.x.x

    ```

    ya está instalado.

    * * * * *

    Paso 6. Configurar Git
    ----------------------

    ```
    git config --global user.name "Tu Nombre"
    git config --global user.email "tu@email.com"

    ```

    * * * * *

    Paso 7. Crear tu identidad de Radicle
    -------------------------------------

    Normalmente:

    ```
    rad auth

    ```

    o el asistente equivalente según la versión instalada, que te generará tus claves criptográficas.

    * * * * *

    ### Una pregunta

    ¿Ya tienes WSL instalado?

    Compruébalo desde PowerShell con:

    ```
    wsl -l -v

    ```

    Pega aquí la salida. Según lo que aparezca (por ejemplo `Ubuntu-24.04`, `Debian` o si aún no hay ninguna distribución), te digo exactamente el siguiente paso.

7.  #### Tú dijiste:

8.  #### ChatGPT Plus

    Sí, sin problema. WSL monta automáticamente las unidades de Windows bajo `/mnt`.

    Si tus repositorios están en:

    ```
    C:\s

    ```

    en WSL los verás como:

    ```
    /mnt/c/s

    ```

    Por ejemplo:

    ```
    cd /mnt/c/s/mi-repo
    git status
    rad init

    ```

    ¿Es recomendable?
    -----------------

    Depende del uso.

    ### ✔ Para empezar y usar Radicle

    Perfectamente válido. Mucha gente trabaja así y mantiene una única copia del repositorio.

    ### ✔ Si editas desde VS Code en Windows

    También funciona muy bien. Puedes abrir el repositorio desde Windows y ejecutar `git` o `rad` desde WSL.

    ### ❌ Si haces compilaciones pesadas (Rust, Node, Docker...)

    Entonces es mejor mover el proyecto al sistema de archivos de Linux (`~/projects`), porque el acceso a `/mnt/c` es más lento.

    * * * * *

    Mi recomendación para tu caso
    -----------------------------

    Si ya tienes todos tus repos en `C:\s`, **no los movería**.

    Puedes hacer algo como:

    ```
    cd /mnt/c/s
    ls

    ```

    y trabajar desde ahí.

    Si usas VS Code, incluso puedes abrir el repositorio con:

    ```
    code .

    ```

    desde WSL (instalando la extensión **WSL** de VS Code), y tendrás el editor de Windows usando las herramientas de Linux.

    * * * * *

    ### Una advertencia importante

    Procura no usar **Git para Windows** y **Git de WSL** sobre el mismo repositorio al mismo tiempo (por ejemplo, dos procesos escribiendo en `.git` simultáneamente). No suele dar problemas si trabajas de forma normal, pero es mejor que para un repositorio uses siempre las operaciones de Git/Radicle desde WSL.

    Por curiosidad, ¿qué flujo quieres montar con Radicle?

    -   ¿Solo usar `rad` como sustituto de GitHub para tus repositorios?
    -   ¿O quieres tener un nodo de Radicle siempre activo para sincronizar proyectos con otras personas?

9.  #### Tú dijiste:

10. #### ChatGPT Plus

    Esa es una de las cuestiones más importantes de Radicle, y la respuesta es: **depende de si has hecho copia de tus claves**.

    Hay que distinguir entre dos cosas:

    1.  **El repositorio** (el código).
    2.  **Tu identidad criptográfica** (las claves privadas con las que firmas).

    ### Caso 1: Se rompe el disco y pierdes WSL, pero otros tienen el repositorio

    El repositorio **no desaparece**. Si otros nodos lo están replicando, podrán seguir clonándolo y sincronizándolo.

    Lo que pierdes es **la capacidad de actuar como tu identidad** si también has perdido tu clave privada.

    ### Caso 2: Pierdes tu clave privada

    Entonces no puedes:

    -   Firmar cambios como esa identidad.
    -   Publicar actualizaciones con esa identidad.
    -   Gestionar el proyecto como el mismo usuario.

    Tendrías que crear una identidad nueva y, si procede, los colaboradores podrían reconocerla como la continuación del proyecto.

    ### La solución: hacer copia de seguridad de las claves

    En WSL tendrás un directorio similar a:

    ```
    ~/.radicle

    ```

    (o el que corresponda a la versión que instales).

    Ahí se guardan las claves y la configuración. Si haces una copia de ese directorio y la guardas en un lugar seguro (por ejemplo, un disco externo o un gestor de copias cifradas), podrás reinstalar WSL y recuperar exactamente tu identidad.

    Un ejemplo sencillo:

    ```
    cp -a ~/.radicle /mnt/c/Users/TuUsuario/Backups/radicle

    ```

    O incluso mejor, cifrar esa copia antes de almacenarla.

    ### Es parecido a...

    Piensa en GitHub:

    -   Si olvidas tu contraseña, GitHub puede ayudarte a recuperarla.
    -   En Radicle no hay una autoridad central que pueda devolverte la clave privada.

    Tu identidad depende de que conserves esa clave.

    ### Mi recomendación

    Si vas a usar Radicle de forma habitual:

    -   Haz copia de `~/.radicle` después de crear tu identidad.
    -   Guarda esa copia en al menos dos sitios (por ejemplo, un disco externo y una copia cifrada en la nube).
    -   Si quieres máxima seguridad, exporta también la semilla o clave de recuperación si la versión de Radicle que instales ofrece esa opción.

    Así, aunque reinstales Windows o WSL, podrás restaurar la carpeta y seguir usando exactamente la misma identidad criptográfica.

11. #### Tú dijiste:

12. #### ChatGPT Plus

    Muy buena pregunta. La idea se parece a lo que describes, pero **no hace un broadcast a toda Internet** diciendo "¿quién tiene este repo?". Sería muy ineficiente.

    El funcionamiento es más parecido a una **DHT (Distributed Hash Table)**, como BitTorrent o IPFS.

    ### 1\. Publicas un repositorio

    Cuando publicas un repositorio, tu nodo anuncia algo como:

    > "Yo tengo el repositorio con ID `rad:z3gqc...`"

    Esa información se propaga por la red de Radicle mediante una DHT.

    * * * * *

    ### 2\. Tú quieres clonarlo

    Cuando ejecutas algo como:

    ```
    rad clone rad:z3gqc...

    ```

    tu nodo pregunta a la DHT:

    > "¿Qué nodos conocen el repositorio `rad:z3gqc...`?"

    La DHT responde con una lista de peers, por ejemplo:

    ```
    Peer A
    Peer B
    Peer C

    ```

    No son todos los nodos de la red, solo los que han anunciado que tienen ese repositorio.

    * * * * *

    ### 3\. Descarga

    Tu nodo intenta conectar con esos peers.

    ```
    Tú
     │
     ├── Peer A  (offline)
     ├── Peer B  (responde)
     └── Peer C  (también responde)

    ```

    En cuanto encuentra uno que tiene el repositorio y está disponible, descarga los objetos Git mediante el protocolo de Radicle.

    * * * * *

    ### 4\. Tú también pasas a ser un peer

    Una vez descargado:

    ```
    A
    │
    ├──B
    │
    └──Tú

    ```

    Tu nodo también puede anunciar:

    > "Ahora yo también tengo este repositorio."

    Y otros usuarios podrán obtenerlo de ti.

    * * * * *

    ¿Y si solo mi amigo lo tiene?
    -----------------------------

    Imagina que tu amigo apaga el ordenador justo después de publicar.

    ```
    Amigo (offline)
          │
          X

    ```

    La DHT puede seguir recordando durante un tiempo que él tenía el repo, pero cuando intentas descargarlo no habrá nadie que responda.

    En ese momento el repositorio **no está disponible**, hasta que alguien que lo tenga vuelva a conectarse.

    Por eso es recomendable que un proyecto importante tenga varios nodos replicándolo.

    * * * * *

    Esto es una diferencia importante respecto a GitHub
    ---------------------------------------------------

    En GitHub:

    ```
    Todos
       │
    GitHub

    ```

    Hay un servidor central que siempre sirve el repositorio.

    En Radicle:

    ```
    A ─── B
    │   ╱
    │  ╱
    C ─ D

    ```

    No hay un servidor central. La disponibilidad depende de que al menos un nodo con una copia esté conectado.

    * * * * *

    Es un modelo muy parecido al de BitTorrent, con una diferencia clave: **el contenido es un repositorio Git firmado criptográficamente**. Aunque lo descargues de un tercero, puedes verificar que los commits y las referencias firmadas corresponden a las identidades que esperas, sin necesidad de confiar en el nodo que te los ha enviado.

13. #### Tú dijiste:

14. #### ChatGPT Plus

    Sí, y de hecho **es una de las mejores formas de usar Radicle**.

    Hay dos maneras de hacerlo:

    ### Opción 1. El VPS tiene su propia identidad (recomendado)

    El VPS ejecuta un nodo de Radicle 24/7.

    ```
    Portátil ─────┐
                  │
    PC Windows ───┼──── VPS (siempre online)
                  │
    Otro PC ──────┘

    ```

    Publicas desde tu portátil y el VPS replica automáticamente tus repositorios.

    Ventajas:

    -   Tus repos siempre están disponibles.
    -   Si apagas el portátil, el VPS sigue sirviendo el repositorio.
    -   Tus amigos siempre tienen un nodo al que conectarse.

    En este caso, el VPS tiene **sus propias claves**, independientes de las tuyas.

    * * * * *

    ### Opción 2. Copias tu identidad al VPS

    Puedes copiar `~/.radicle` al VPS.

    Entonces:

    ```
    Portátil
         │
         └── misma identidad ─── VPS

    ```

    Es exactamente la misma identidad en dos máquinas.

    Esto también funciona, pero implica que tu clave privada vive en el VPS. Si ese servidor se compromete, podrían robar esa identidad.

    Para un VPS propio y bien securizado puede ser aceptable, pero hay que ser consciente del riesgo.

    * * * * *

    Lo que yo haría
    ---------------

    Si fuera mi infraestructura:

    ```
    Windows + WSL
          │
          │ desarrollo
          │
          ▼
     VPS 2 €/mes
          │
          │ siempre online
          ▼
    Red Radicle

    ```

    El VPS mantiene una copia y la VPS sería un nodo de réplica.

    Mi portátil publica.

    El VPS mantiene una copia y la anuncia continuamente.

    Si mañana se me rompe el portátil:

    -   recupero mis claves desde la copia de seguridad;
    -   reinstalo WSL;
    -   vuelvo a conectar;
    -   el VPS sigue teniendo todos los repos.

    No he perdido el código.

    * * * * *

    Incluso puedes sustituir GitHub en muchos casos
    -----------------------------------------------

    Para proyectos personales, podrías tener:

    -   **Forgejo** o Gitea en el VPS para la interfaz web.
    -   **Radicle** para la replicación P2P.

    Así tendrías:

    -   interfaz web para navegar el código;
    -   sincronización distribuida sin depender de GitHub;
    -   un nodo siempre conectado para que otros puedan obtener tus repositorios incluso cuando tu ordenador esté apagado.

    Es una combinación bastante potente si ya dispones de un VPS.
