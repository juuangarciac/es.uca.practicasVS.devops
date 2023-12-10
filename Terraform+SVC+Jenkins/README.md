# Descripción de las Herramientas utilizadas para el desarrollo de la práctica

## Terraform
__Terraform__ es una herramienta de código abierto para automatizar la configuración de infraestructura. Permite definir y administrar recursos en la nube usando código, facilitando la creación, modificación y eliminación eficiente de recursos.

Con Terraform, se puede describir la infraestructura deseada de manera declarativa, lo que simplifica su gestión y asegura una implementación consistente en diferentes proveedores de servicios en la nube

## SVC
Los __sistemas de control de versiones__ (SCM, "Source Control Management") como Git son herramientas que rastrean y administran cambios en el código de manera eficiente. Permiten a los equipos colaborar, controlar versiones y gestionar el historial de modificaciones del código fuente.

Usando un SCM como Git, los desarrolladores pueden trabajar simultáneamente en proyectos, crear ramas para nuevas funciones o correcciones, fusionar cambios y revertir a versiones anteriores. Estos sistemas proporcionan un entorno controlado que facilita el seguimiento y la colaboración en el desarrollo de software.

## Jenkins
__Jenkins__ es un servidor de automatización de código abierto y autocontenido que se puede utilizar para automatizar diversas tareas relacionadas con la construcción, prueba y entrega o implementación de software.

Jenkins se puede instalar a través de paquetes nativos del sistema, Docker o incluso ejecutarse de forma independiente en cualquier máquina con un entorno de ejecución de Java (JRE) instalado.

[Jenkins Workflow](./img/img01.png)

# Despliegue de una aplicación Python mediante un pipeline en Jenkins

# Linux

1. Abrimos una terminal

2. Creamos una __bridge network__ (En términos de Docker, una red puente utiliza un puente de software que permite que los contenedores conectados a la misma red puente se comuniquen, al tiempo que proporciona aislamiento de los contenedores que no están conectados a esa red puente. El controlador del puente Docker instala automáticamente reglas en la máquina host para que los contenedores en diferentes redes puente no puedan comunicarse directamente entre sí.) en Docker, usando el siguiente comando:
<pre>docker network create jenkins</pre>

3. Para ejecutar comandos de Docker dentro de los nodos de Jenkins, descargue y ejecute la imagen de Docker docker:dind usando el siguiente comando de ejecución de Docker:
    <pre>
        docker run \
        --name jenkins-docker \
        --rm \
        --detach \
        --privileged \
        --network jenkins \
        --network-alias docker \
        --env DOCKER_TLS_CERTDIR=/certs \
        --volume jenkins-docker-certs:/certs/client \
        --volume jenkins-data:/var/jenkins_home \
        --publish 2376:2376 \
        --publish 3000:3000 --publish 5000:5000 \
        docker:dind \
        --storage-driver overlay2 
    </pre>

    Este comando establece un entorno Docker dentro de Jenkins, facilitando la ejecución de comandos Docker para realizar diversas tareas, como construcción y despliegue de aplicaciones.

4. Personalizamos la imagen oficial de Jenkins Docker, ejecutando los pasos siguientes:
    - Crear un _Dockerfile_ . Este Dockerfile establece un entorno Jenkins con soporte Docker y plugins adicionales para funcionalidades específicas.

     <pre>
        FROM jenkins/jenkins:2.426.1-jdk17
        USER root
        RUN apt-get update && apt-get install -y lsb-release
        RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
        https://download.docker.com/linux/debian/gpg
        RUN echo "deb [arch=$(dpkg --print-architecture) \
        signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
        https://download.docker.com/linux/debian \
        $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
        RUN apt-get update && apt-get install -y docker-ce-cli
        USER jenkins
        RUN jenkins-plugin-cli --plugins "blueocean:1.27.9 docker-workflow:572.v9
    </pre>

    -   Creamos una nueva imagen de docker a partir de este Dockerfile.

        <pre>
            docker build --pull --rm -f "practicasVS/Terraform+SVC+Jenkins/Dockerfile" -t myjenkins-blueocean:2.426.1-1 "practicasVS/Terraform+SVC+Jenkins"
        </pre>

        - **`docker build`**: Inicia el proceso de construcción de una imagen Docker.

        - **`--pull`**: Solicita a Docker que siempre intente actualizar la imagen base (`--pull always`). Esto garantiza que se utilice la última versión de la imagen base si está disponible.

        - **`--rm`**: Elimina el contenedor temporal intermedio después de que la imagen se ha construido con éxito, lo que ayuda a reducir la acumulación de contenedores no utilizados.

        - **`-f "practicasVS/Terraform+SVC+Jenkins/Dockerfile"`**: Especifica la ruta al Dockerfile que se utilizará para la construcción de la imagen. En este caso, el Dockerfile se encuentra en la ruta "practicasVS/Terraform+SVC+Jenkins/Dockerfile".

        - **`-t myjenkins-blueocean:2.426.1-1`**: Etiqueta la imagen resultante con el nombre `myjenkins-blueocean` y la versión `2.426.1-1`. Esta etiqueta facilita la identificación y referencia de la imagen.

        - **`"practicasVS/Terraform+SVC+Jenkins"`**: Especifica el contexto de construcción. Todos los archivos y directorios dentro de esta ruta se enviarán al daemon de Docker para su procesamiento durante la construcción.

    - Corremos nuestra propia imagen **`myjenkins-blueocean:2.426.1-1`** como contenedor de Docker usando el siguiente comando:
        ### Start Jenkins
        <pre>
            docker run \
                --name jenkins-blueocean \
                --detach \
                --network jenkins \
                --env DOCKER_HOST=tcp://docker:2376 \
                --env DOCKER_CERT_PATH=/certs/client \
                --env DOCKER_TLS_VERIFY=1 \
                --publish 8080:8080 \
                --publish 50000:50000 \
                --volume jenkins-data:/var/jenkins_home \
                --volume jenkins-docker-certs:/certs/client:ro \
                --volume "$HOME":/home \
                --restart=on-failure \
                --env JAVA_OPTS="-Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true" \
            myjenkins-blueocean:2.426.1-1 
        </pre>

Enlace a [Interfaz Web de Jenkins](http://localhost:8080).

Enlace a [Comunicación entre Servidor Jenkins y Agentes Remotos](http://localhost:5000).

# Setup wizard

## Desbloqueando Jenkins

1. Desplegamos la interfaz de Jenkins usando el comando:
<pre>docker logs jenkins-blueocean</pre>

2. Copiar la contraseña auto-generada.
    [Imagen ejemplo](./img/img02.png)

3. En la interfaz web de Jenkins, pegamos la contraseña en el campo **Administrator password** y clickamos en **Continue**

## Personalizar Jenkins con plugins

Después de desbloquear Jenkins, nos aparecerá la página **Customize Jenkins**.

En esta página clickamos en **Install suggested plugins**. 

## Crear el primero usuario adminsitrador

Rellenamos el formulario para crear el primer usuario administrador, una vez finalizado clickar **Save and Finish**. Después de configurar también la URL (dejaremos la default), nos deberá salir una página como la [siguiente](./img/img03.png)

## Stopping and restarting Jenkins
Como recordatorio, podemos parar nuestro contenedor de Docker ejecutando el siguiente comando:
<pre>docker stop jenkins-blueocean jenkins-docker</pre>

Para volver a lanzarlo, ejecutamos de nuevo el comando [run...](###start-jenkins)

# Fork and clone the sample repository

1. Fork [simple-python-pyinstaller-app](https://github.com/jenkins-docs/simple-python-pyinstaller-app) y clonarlo localmente a nuestra máquina. 
<pre>
    sudo mkdir /home/<user-name>/GitHub
    cd /home/<user-name>/GitHub
    git clone https://github.com/juuangarciac/simple-python-pyinstaller-app
</pre>

[Enlace al repositorio](https://github.com/juuangarciac/simple-python-pyinstaller-app)

# Create your Pipeline Project in Jenkins