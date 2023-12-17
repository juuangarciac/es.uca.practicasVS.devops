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

# Preparación del entorno de Terraform

## Linux

Descarga de terraform en Linux:
<pre>
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
</pre>

## Entorno

1. Primero, creamos un directorio de trabajo para Terraform, denominado *terraform*.

2. Dentro del directorio de trabajo, inicializa un proyecto Terraform con el siguiente comando: **`terraform init`** 

3. Se creará un archivo de configuración **`main.tf`** de Terraform.


# Despliegue de una aplicación Python mediante un pipeline en Jenkins

## Imagen personalizada de jenkins-blueocean

Personalizamos la imagen oficial de Jenkins Docker, ejecutando los pasos siguientes:
1. Crear un _Dockerfile_ . Este Dockerfile establece un entorno Jenkins con soporte Docker y plugins adicionales para funcionalidades específicas.

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

2. Creamos una nueva imagen de docker a partir de este Dockerfile.

        <pre>
            docker build --pull --rm -f "practicasVS/Terraform+SVC+Jenkins/Dockerfile" -t myjenkins-blueocean:2.426.1-1 "practicasVS/Terraform+SVC+Jenkins"
        </pre>

## Infraestructura Terraform para Jenkins

1. Este código configura Terraform para que utilice el proveedor de Docker de la fuente "*kreuzwerker/docker*" en la **`versión 3.0.1`**, lo que permite a Terraform interactuar con recursos de Docker como parte de la infraestructura definida como código.
    <pre>
    terraform {
        required_providers {
            docker = {
            source  = "kreuzwerker/docker"
            version = "~> 3.0.1"
            }
        }
    }
    </pre>


2. El bloque de configuración provider se utiliza para configurar el proveedor de Docker en este caso.
    <pre>
    provider "docker" {
    # Configura el proveedor de Docker
    }
    </pre>


3. Este bloque de configuración Terraform crea una red de Docker llamada "*jenkins_default_network*" utilizando el driver "*bridge*". La red se define como un recurso de tipo "*docker_network*", permitiendo la configuración y gestión de redes Docker mediante Terraform.
    <pre>
    # Crear red de Docker
    resource "docker_network" "jenkins_network" {
    name   = "jenkins_default_network"
    driver = "bridge"
    }
    </pre>


4. Este código define dos recursos de tipo "*docker_volume*". El primer recurso crea un volumen llamado **`"jenkins-data"`**, y el segundo crea otro volumen llamado **`"jenkins-docker-certs"`**. Estos volúmenes son utilizados para persistir datos y certificados relacionados con un entorno Jenkins ejecutado en contenedores Docker, proporcionando almacenamiento independiente del ciclo de vida de los contenedores y facilitando la persistencia de datos y configuraciones importantes.
    <pre>
    # Crear volumen para jenkins-data
    resource "docker_volume" "jenkins_data" {
    name = "jenkins-data"
    }
    # Crear volumen para jenkins-docker-certs
    resource "docker_volume" "jenkins_docker_certs" {
    name = "jenkins-docker-certs"
    }
    </pre>


5. Este bloque de configuración crea un contenedor Docker para ejecutar un servicio Jenkins con soporte para la ejecución de contenedores Docker adicionales. Aquí hay una explicación resumida:

    - **docker_container**: Este recurso define un contenedor Docker llamado "*jenkins_docker*".

        - **name**: Asigna un nombre al contenedor como "jenkins-docker".

        - **image**: Especifica la imagen Docker utilizada para crear el contenedor, en este caso, "docker:dind" que proporciona soporte para la ejecución de contenedores Docker dentro de otro contenedor.

        - **privileged**: Configura el contenedor para tener privilegios elevados, lo cual es necesario para ejecutar contenedores Docker dentro de este contenedor.

        - **network_mode**: Asigna el contenedor a la red Docker previamente creada llamada "jenkins_default_network".

        - **volumes**: Define dos volúmenes montados en el contenedor.

            - El primer volumen, vinculado al nombre del volumen "*jenkins_docker_certs*", se monta en el directorio "*/certs/client*" del contenedor.

            - El segundo volumen, vinculado al nombre del volumen "*jenkins_data*", se monta en el directorio "*/var/jenkins_home*" del contenedor. Este volumen se utiliza para persistir los datos de Jenkins.

        - **command**: Especifica una serie de argumentos para el comando de inicio del contenedor. En este caso, se pasa el argumento **`"--storage-driver overlay2"`** para configurar el controlador de almacenamiento Docker como "*overlay2*".
        
        <pre>
        # Crear contenedor para jenkins-docker
        resource "docker_container" "jenkins_docker" {
        name         = "jenkins-docker"
        image        = "docker:dind"
        privileged   = true
        network_mode = docker_network.jenkins_network.name

        volumes {
            volume_name      = docker_volume.jenkins_docker_certs.name
            container_path = "/certs/client"
        }

        volumes {
            volume_name      = docker_volume.jenkins_data.name
            container_path = "/var/jenkins_home"
        }

        command = ["--storage-driver", "overlay2"]
        }
        </pre>


6. Este bloque de configuración Terraform se utiliza para crear un contenedor Docker que ejecuta Jenkins con el tema "*Blue Ocean*". Aquí hay una explicación resumida:

    - **docker_container**: Este recurso define un contenedor Docker llamado "*jenkins_blueocean*".

        - **name**: Asigna un nombre al contenedor como "*jenkins-blueocean*".

        - **image**: Especifica la imagen Docker utilizada para crear el contenedor, en este caso, "*myjenkins-blueocean:2.426.1-1*". Se asume que esta imagen ya ha sido construida previamente.

        - **network_mode**: Asigna el contenedor a la red Docker previamente creada llamada "*jenkins_default_network*".

        - **volumes**: Define tres volúmenes montados en el contenedor.

            - El primer volumen, vinculado al nombre del volumen "*jenkins_data*", se monta en el directorio "*/var/jenkins_home*" del contenedor. Este volumen se utiliza para persistir los datos de Jenkins.

            - El segundo volumen, vinculado al nombre del volumen "*jenkins_docker_certs*", se monta en el directorio "*/certs/client*" del contenedor.

            - El tercer volumen se vincula al directorio "*/home*" del host y se monta en el directorio "*/home*" del contenedor.

        - **ports**: Define la configuración de puertos, mapeando el puerto 8080 del contenedor al puerto 8080 del host.

        - **restart**: Configura la política de reinicio del contenedor en caso de fallo, en este caso, se reinicia "*on-failure*".

        - **env**: Define variables de entorno para el contenedor, incluyendo configuraciones relacionadas con Docker, certificados, y opciones específicas de Jenkins como permitir la comprobación local de repositorios Git.

    <pre>
    # Crear imagen personalizada de Jenkins
    # Use an external tool like Docker to build the image
    # Crear un contenedor para jenkins-blueocean

    resource "docker_container" "jenkins_blueocean" {
    name         = "jenkins-blueocean"
    image        = "myjenkins-blueocean:2.426.1-1"  # Assuming the image is already built
    network_mode = docker_network.jenkins_network.name

    volumes {
        volume_name = docker_volume.jenkins_data.name
        container_path = "/var/jenkins_home"
    }

    volumes {
        volume_name = docker_volume.jenkins_docker_certs.name
        container_path = "/certs/client"
    }

    volumes {
        host_path  = "/home"
        container_path = "/home"
    }

    ports {
        internal = 8080
        external = 8080
    }

    restart = "on-failure"

    env = [
        "DOCKER_HOST=tcp://docker:2376",
        "DOCKER_CERT_PATH=/certs/client",
        "DOCKER_TLS_VERIFY=1",
        "JAVA_OPTS=-Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true",
    ]
    }
    </pre>

## Despliegue

1. Inicializar el directorio de trabajo de Terraform: **`terraform init`**

2. Planificar la infraestructura (verificar cambios antes de aplicarlos): **`terraform plan`**

3. Aplicar los cambios para crear la infraestructrura: **`terraform apply`**


Enlace a [Interfaz Web de Jenkins](http://localhost:8080).

Enlace a [Comunicación entre Servidor Jenkins y Agentes Remotos](http://localhost:5000).

## Setup wizard

### Desbloqueando Jenkins

1. Desplegamos la interfaz de Jenkins usando el comando:
<pre>docker logs jenkins-blueocean</pre>

2. Copiar la contraseña auto-generada.
    [Imagen ejemplo](./img/img02.png)

3. En la interfaz web de Jenkins, pegamos la contraseña en el campo **Administrator password** y clickamos en **Continue**

### Personalizar Jenkins con plugins

Después de desbloquear Jenkins, nos aparecerá la página **Customize Jenkins**.

En esta página clickamos en **Install suggested plugins**. 

### Crear el primer usuario adminsitrador

Rellenamos el formulario para crear el primer usuario administrador, una vez finalizado clickar **Save and Finish**. Después de configurar también la URL (dejaremos la default), nos deberá salir una página como la [siguiente](./img/img03.png)

### Stopping and restarting Jenkins
Como recordatorio, podemos parar nuestro contenedor de Docker ejecutando el siguiente comando:
<pre>docker stop jenkins-blueocean jenkins-docker</pre>

Para volver a lanzarlo, ejecutamos de nuevo el comando [run...](###start-jenkins)

## Fork and clone the sample repository

1. Fork [simple-python-pyinstaller-app](https://github.com/jenkins-docs/simple-python-pyinstaller-app) y clonarlo localmente a nuestra máquina. 
<pre>
    sudo mkdir /home/<user-name>/GitHub
    cd /home/<user-name>/GitHub
    git clone https://github.com/juuangarciac/simple-python-pyinstaller-app
</pre>

[Enlace al repositorio](https://github.com/juuangarciac/simple-python-pyinstaller-app)

## Create your Pipeline Project in Jenkins

Creamos un nuevo trabajo de Jenkins. En la sección de Pipeline, en el campo __Definition__, elegimos la opción **`Pipeline script from SCM`**. En __SCM__ elegimos **`Git`**. En el repositorio indicamos la ubicación donde tenemos clonado el repositorio local.

[Imagen de la configuración en Jenkins](./img/img04.png)

## Create your initial Pipeline as a Jenkinsfile

El **`Pipeline`** será creado como un __Jenkinsfile__, el cúal habrá que hacerle un commit a nuestro repositorio local. 

Esto es la base de _"Pipeline-as-Code"_ (Pipeline como código), que trata el flujo de entrega continua como parte de la aplicación para ser versionada y revisada como cualquier otro código.

Primero, se creará un Pipeline inicial denominado **`Build`** que ejecuta la primera parte de el proceso de producción entero para nuestra aplicación. Este "Build" descarga una imagen de Python en Docker y ejecuta el contenedor, que compila una aplicación simple de Python.

Posteriormente, accedemos de nuevo a la interfaz web de Jenkins, clickamos en **Blueocean**. ejecutamos **Run** y abrimos el enlace, donde se observará que Jenkins está corriendo nuestro Pipeline project.

