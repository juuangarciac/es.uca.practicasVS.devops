# Azure + Gitlab - Entregable

# Práctica 1 de azure
<details open>

## **Descripción del Pipeline**

Este pipeline de Azure consta de dos partes principales: la construcción y despliegue de una imagen Docker, y el análisis de código con SonarQube.

### **Docker Build y Despliegue**

El pipeline inicia con la construcción de una imagen Docker utilizando un Dockerfile que se encuentra en la raíz del repositorio. La imagen se etiqueta como `latest`. 

### **Registro de Contenedores de Azure Pipelines**

Un registro de contenedores es un lugar donde se almacenan y distribuyen imágenes de contenedores. Los contenedores en Azure Pipelines son instancias aisladas y portátiles que encapsulan un entorno de software completo, incluyendo la aplicación y todas sus dependencias. Esto permite que la aplicación se ejecute de manera consistente en cualquier plataforma o entorno de nube, facilitando así el desarrollo, las pruebas y la implementación. En este pipeline, la imagen Docker se empuja a un registro de contenedores denominado `trabajovscontenedor`. Para configurar un registro de contenedores en Azure Pipelines, se deberá crear un servicio de Azure Container Registry y luego conectarlo al pipeline.

### **Service Connections de Azure**

Las Service Connections en Azure DevOps son enlaces entre el proyecto de Azure DevOps y otro servicio, como Azure Container Registry. Se requerirá una `Service Connection` para empujar la imagen Docker al registro de contenedores. Para crear una Service Connection, se debe ir a la configuración del proyecto en Azure DevOps, seleccionar `Service Connections` y luego `New Service Connection`. Se deben seguir los pasos para crear una nueva conexión al servicio de Azure Container Registry.

Posteriormente, la imagen se empuja a un registro de contenedores denominado `trabajovscontenedor`. Finalmente, se utiliza `docker-compose` para levantar los servicios definidos en el archivo `docker-compose.yml` que se encuentra en la raíz del repositorio.

### **Análisis de SonarQube**

La segunda parte del pipeline es el análisis de SonarQube. SonarQube es una plataforma de código abierto utilizada para medir y analizar la calidad del código fuente en proyectos de desarrollo de software. Proporciona informes sobre bugs, olores de código, y problemas de seguridad, además de ofrecer sugerencias para mejorar la calidad del código, lo que facilita el mantenimiento y la escalabilidad a largo plazo del software. Se prepara SonarQube para el análisis, se construye una imagen Docker y se guarda como un archivo .tar.gz. Luego, se realiza el análisis de SonarQube y se publican los resultados. El tiempo de espera de sondeo para la publicación es de 300 segundos.

## **Creación del Pipeline en Azure Pipelines**

Para crear este pipeline en Azure Pipelines, se deben seguir estos pasos:

1. Ir al proyecto en Azure DevOps.
2. Hacer clic en 'Pipelines' en el menú de la izquierda.
3. Hacer clic en 'Crear Pipeline'.
4. Seleccionar donde está alojado el código.
5. Configurar el repositorio y la rama.
6. En 'Configurar el pipeline', seleccionar 'YAML'.
7. Pegar el código del pipeline en el editor de YAML.
8. Hacer clic en 'Ejecutar' para guardar y ejecutar el pipeline.
   
## **Configuración e Instalación de SonarQube en Azure Pipelines**

Para configurar e instalar SonarQube en Azure Pipelines, se deben seguir los siguientes pasos:

1. **Instalar SonarQube en un servidor**: Primero, se necesita tener una instancia de SonarQube ejecutándose en un servidor accesible.

2. **Crear un proyecto en SonarQube**: Iniciar sesión en la instancia de SonarQube y crear un nuevo proyecto. Hay que anotar la clave del proyecto, ya que se necesitará en `cliProjectKey`.

3. **Configurar el servicio de SonarQube en Azure DevOps**: En la configuración del proyecto en Azure DevOps, seleccionar 'Service Connections' y luego 'New Service Connection'. Elegir 'SonarQube' y seguir los pasos para crear una nueva conexión al servicio de SonarQube.

4. **Agregar tareas de SonarQube al pipeline**: En el archivo de pipeline, agregar las tareas de `SonarQubePrepare`, `SonarQubeAnalyze` y `SonarQubePublish`.

5. **Ejecutar el pipeline**: Guardar y ejecutar el pipeline. Si todo está configurado correctamente, debería ver los resultados del análisis de SonarQube en la interfaz de SonarQube después de que se complete la ejecución del pipeline.

## Explicación del código

## Explicación del archivo `azure-pipelines-01.yml`

El archivo `azure-pipelines-01.yml` es una configuración de pipeline de CI/CD (Integración Continua / Entrega Continua) que define una serie de `stages` (etapas) y `jobs` (trabajos) que se ejecutan en cada etapa. Cada trabajo puede tener múltiples `steps` (pasos) que se ejecutan en orden. Aquí está la explicación detallada:

## Stages

### Stage: Docker_Build_and_Compose



Este es el primer `stage` del pipeline. Contiene un `job` llamado `Build_and_Compose` que se ejecuta en una máquina virtual con la imagen 'ubuntu-latest'. Este trabajo tiene varios pasos:

1. **Starting Docker Build and Compose**: Este paso imprime un mensaje en la consola para indicar que el proceso de construcción y composición de Docker ha comenzado.

```yaml
- stage: Docker_Build_and_Compose
  jobs:
  - job: Build_and_Compose
    pool:
      vmImage: 'ubuntu-latest'
    steps:
      - script: echo 'Starting Docker Build and Compose'
        displayName: 'Starting Docker Build and Compose'

```

2. **Build Docker Image**: Este paso utiliza la tarea Docker@2 para construir una imagen de Docker a partir de un Dockerfile que se encuentra en cualquier subdirectorio del repositorio. La imagen se etiqueta como 'latest'.

```yaml
- task: Docker@2
        displayName: 'Build Docker Image'
        inputs:
          command: 'build'
          Dockerfile: '**/Dockerfile'
          tags: 'latest'

```

3. **Push Docker Image to Registry**: Este paso también utiliza la tarea Docker@2 para empujar la imagen de Docker construida en el paso anterior a un registro de contenedores llamado 'trabajovscontenedor'.

```yaml
- task: Docker@2
        displayName: 'Push Docker Image to Registry'
        inputs:
          command: 'push'
          tags: 'latest'
          containerRegistry: 'trabajovscontenedor'

```

4. **Docker Compose Up**: Este paso utiliza la tarea Docker@2 para ejecutar `docker-compose up` con un archivo `docker-compose.yml` que se encuentra en cualquier subdirectorio del repositorio (en este caso en la raiz). Esto inicia todos los servicios definidos en el archivo `docker-compose.yml` en modo detached (desacoplado) y elimina los contenedores existentes al tirar.

```yaml
- task: Docker@2
        displayName: 'Docker Compose Up'
        inputs:
          command: 'composeUp'
          dockerComposeFile: '**/docker-compose.yml'
          removeContainersOnPull: true
          detachedService: true

```

### Stage: SonarQube_Analysis

Este es el segundo `stage` del pipeline. Contiene un `job` llamado `Analyze` que se ejecuta en una máquina virtual con la imagen 'ubuntu-latest'. Este trabajo tiene varios pasos:

1. **SonarQubePrepare**: Este paso prepara el análisis de SonarQube. Se configura para usar el modo 'CLI' y la configuración 'manual'. El proyecto se identifica con la clave 'ProyectoVS-SonarQube-Key' y se analiza el directorio actual ('.').

```yaml
- task: SonarQubePrepare@4
        inputs:
          SonarQube: 'SonarQube' 
          scannerMode: 'CLI'
          configMode: 'manual'
          cliProjectKey: 'ProyectoVS-SonarQube-Key' 
          cliSources: '.'

```

2. **docker build -t my-image .**: Este paso construye una imagen de Docker con la etiqueta 'my-image' a partir de un Dockerfile en el directorio actual.


3. **docker save my-image | gzip > my-image.tar.gz**: Este paso guarda la imagen de Docker construida en el paso anterior en un archivo tar y luego comprime ese archivo con gzip.

```yaml
    - script: docker build -t my-image .
    - script: docker save my-image | gzip > my-image.tar.gz
```

4. **SonarQubeAnalyze**: Este paso realiza el análisis de SonarQube.

5. **SonarQubePublish**: Este paso publica los resultados del análisis de SonarQube. Se configura para esperar hasta 300 segundos para que el servidor de SonarQube procese los resultados del análisis.

```yaml
    - task: SonarQubeAnalyze@4
      - task: SonarQubePublish@4
        inputs:
          pollingTimeoutSec: '300'
```



## **Requisitos**

Este pipeline requiere que se tenga un Dockerfile y un archivo docker-compose.yml en el repositorio. También se necesita tener un registro de contenedores configurado en Azure Pipelines y un proyecto en SonarQube.

</details>

# Práctica 2 de azure
<details open>

### **Funcionamiento del Pipeline**

El pipeline automatiza el proceso de aprovisionamiento de la infraestructura definida en el archivo `main.tf` (El archivo `main.tf` es el punto de entrada principal para la configuración de Terraform en un directorio. Es en este archivo donde se definen todos los recursos que Terraform creará y administrará). Inicia con la inicialización y validación de Terraform. Luego, se crea un plan de Terraform y se aplica. Todo esto se realiza en una máquina virtual con la imagen `'ubuntu-latest'`. 

Después de aplicar los cambios de Terraform, el pipeline procede a realizar el análisis de `SonarQube`. Esto permitirá a SonarQube analizar el código y detectar posibles vulnerabilidades en la infraestructura desplegada y aprovisionada por Terraform.

**Nota:** *Las fases de análisis de SonarQube, así como la creación del pipeline en Azure Pipelines y la descripción de SonarQube presentes en Azure-01, son idénticas y aplicables en este pipeline.* 

## Etapa Terraform
Esta etapa define un trabajo llamado `Apply` que se ejecutará en un agente con la imagen más reciente de Ubuntu.

### Configuracion 

```yaml
stages:
- stage: Terraform
  jobs:
  - job: Apply
    pool:
      vmImage: 'ubuntu-latest'
    steps:
      - task: UseDotNet@2
        inputs:
          packageType: 'sdk'
          version: '3.1.x'
          installationPath: $(Agent.ToolsDirectory)/dotnet

      - script: |
          terraform init
          terraform validate
        displayName: 'Terraform Init and Validate'

      - script: 'terraform plan -out=tfplan'
        displayName: 'Terraform Plan'

      - script: 'terraform apply -auto-approve tfplan'
        displayName: 'Terraform Apply'
```
- **Trabajo: Apply**
  - **Pool**:
    - **vmImage**: 'ubuntu-latest' (Utiliza la última versión disponible de Ubuntu)

  - **Pasos**:
    1. **Tarea: UseDotNet@2**
       - Instala el SDK de .NET Core versión 3.1.x en la ruta especificada por `$(Agent.ToolsDirectory)/dotnet`.
       - **Entradas**:
         - **packageType**: 'sdk' (Especifica que se instalará el SDK)
         - **version**: '3.1.x' (La versión del SDK a instalar)
         - **installationPath**: $(Agent.ToolsDirectory)/dotnet (La ruta de instalación del SDK)

    2. **Script**: Inicializa y valida la configuración de Terraform.
       - **displayName**: 'Terraform Init and Validate' (Nombre descriptivo para la tarea)

    3. **Script**: Genera un plan de ejecución de Terraform y lo guarda en un archivo llamado 'tfplan'.
       - **displayName**: 'Terraform Plan' (Nombre descriptivo para la tarea)

    4. **Script**: Aplica los cambios especificados en el plan de Terraform de forma automática y sin necesidad de aprobación manual.
       - **displayName**: 'Terraform Apply' (Nombre descriptivo para la tarea)

1. **Preparar SonarQube** (`SonarQubePrepare@4`):
   - Conecta con la instancia de SonarQube especificada.
   - Configura el análisis en modo CLI (línea de comandos).
   - Establece la configuración de forma manual.
   - Define la clave del proyecto y la ubicación del código fuente a analizar.

2. **Analizar con SonarQube** (`SonarQubeAnalyze@4`):
   - Ejecuta el análisis de código estático utilizando SonarQube.

3. **Publicar Resultados de SonarQube** (`SonarQubePublish@4`):
   - Publica los resultados del análisis en SonarQube.
   - Establece un tiempo de espera para la publicación de `300` segundos.

## Etapa SonarQube
La configuración `SonarQube_Analysis` se implementa de la misma manera que en el pipeline descrito en el apartado `Practica Azure 01`.

```yaml
- stage: SonarQube_Analysis
  jobs:
  - job: Analyze
    pool:
      vmImage: 'ubuntu-latest'
    steps:
      - task: SonarQubePrepare@4
        inputs:
          SonarQube: 'SonarQube' 
          scannerMode: 'CLI'
          configMode: 'manual'
          cliProjectKey: 'ProyectoVS02-SonarQube-Key' 
          cliSources: '.'

      - task: SonarQubeAnalyze@4
      - task: SonarQubePublish@4
        inputs:
          pollingTimeoutSec: '300'
```
</details>

# Práctica de CI/CD y Cienca Abierta con GitLab
<details open>

## Preparación del entorno

### Uso de GitHub Tokens

Los tokens de acceso personal de GitHub, conocidos como Personal `Access Tokens (PAT)`, son una alternativa segura a las contraseñas para la autenticación en GitHub cuando se utiliza la API de GitHub o la línea de comandos. Estos tokens permiten acceder a los recursos de GitHub en tu nombre sin utilizar tu contraseña, lo que es especialmente útil en scripts y en la int

Para generar un token de acceso personal (PAT) en GitHub, sigue estos pasos:

1. Inicia sesión en GitHub con tu cuenta.
2. Ve a tu perfil en la esquina superior derecha y selecciona Settings (Configuración).
3. En la barra lateral izquierda, selecciona Developer settings (Configuración del desarrollador).
4. Luego, en la misma barra lateral, elige Personal access tokens (Tokens de acceso personal).
5. Haz clic en Generate new token (Generar nuevo token).
6. Te pedirán que ingreses tu contraseña de GitHub para verificar tu identidad.
7. En la página de nuevo token, proporciona un nombre para tu token para identificarlo más tarde.
8. Establece una fecha de expiración para tu token. Puedes elegir entre diferentes duraciones o no establecer ninguna para que no expire.
9. Selecciona los permisos o scopes que deseas que tenga el token. Estos determinarán qué acciones puede realizar el token en tu nombre.
10. Una vez que hayas configurado los permisos, haz clic en Generate token (Generar token) al final de la página.
11. Recibirás un nuevo PAT que podrás usar en lugar de tu contraseña. Asegúrate de copiar y guardar tu PAT en un lugar seguro, ya que no podrás verlo nuevamente después de salir de la página.

### Declaración de la Imagen 

Debido a que se va a  trabajar con una aplicación desarrollada en `python`. El pipeline configurado se ejecuta sobre un contenedor, con la imagen de `python:3.9`.

En el fichero de configuración del pipeline, este requisito se implementa mediante: 
```yaml
image: python:3.9
```

### Definición de los stages

A continuación, se definirán los `stages` o etapas que ejecutará nuestro pipeline. En concreto, nuestro pipeline, ejecutará la fase de `build` y `documentation`. 
```yaml
stages:
  - build
  - documentation
```

### Variables globales
Como paso previo a la definición de los scripts, se declararán `variables` que podrán ser utilizadas a lo largo de la ejecución de los mismos.

```yaml
variables:
  SCRIPT_PATH: "python_script.py"
  DATA_PATH: "SensorData.csv"
  #FIGSHARE_API_TOKEN:"715945f9a15bbc11841a01c999a3c4e07f39e2369072f9bfaee13ad78aa4166baabb60de29379cfe95ccc7380e72c78078efd65491d7c11d0922e6f867d3e539"
```

- `SCRIPT_PATH: "python_script.py"`. Almacena la ruta al script de python que ejecutará el pipeline.
- ` DATA_PATH: "SensorData.csv"`. Ruta hacia el fichero que almacena los datos usados por el programa python.
- `FIGSHARE_API_TOKEN:...`. Contiene el token de acceso a la API de Figshare. Este token es una clave única que permite al script autenticarse y realizar operaciones en la plataforma Figshare, como subir o descargar datos y otros recursos.

### Before script
También, se prepará el contenedor con las dependencias necesarias para poder ejecutar la aplicación.

```yaml
before_script:
  - apt-get update -qy
  - pip install pandas matplotlib
  - apt-get install -y git
  - git config --global user.email "juuangarcandon@gmail.com"
  - git config --global user.name "Juan Garcia Candon"
  - git config --global credential.helper store
  - echo "https://juuangarcandon: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@github.com" > ~/.git-credentials
```

1. Se descargan las bibliotecas de `pandas` y `matplotlib`, necesarias para cargar los datos del archivo y la generación de la gráfica. 
2. Después, se descarga `git`. Configuramos la herramienta para automatizar el trabajo realizado en el repositorio.


Una vez preparado el entorno, ejecutamos la etapa`build`.

## Etapa Build
En esta etapa, se clonará el repositorio de gitlab, con su correspondiente contenido, y se ejecutará la aplicación python.

### Configuración de la etapa

```yaml
build_job:
  stage: build
  script:
    - git clone https://gitlab.com/trabajovs/gitlab
    - cd gitlab
    - python3 $SCRIPT_PATH
```

## Etapa Upload
La sección `upload_to_figshare` del archivo de configuración del pipeline define una etapa que se encarga de subir archivos a la plataforma Figshare. 

### Configuración de la etapa

```yaml
upload_to_figshare:
  stage: upload
  script:
    - apt-get update -qy
    - apt-get install -y figshare-cli
    - figshare --token $FIGSHARE_API_TOKEN upload temperatura_humedad.png
```
- `figshare --token $FIGSHARE_API_TOKEN upload temperatura_humedad.png `: Este comando sube el archivo temperatura_humedad.png a Figshare utilizando el token de acceso a la API almacenado en la variable FIGSHARE_API_TOKEN.

## Etapa de Documentación

Esta etapa del pipeline se encarga de generar y publicar la documentación del proyecto en formato HTML.

### Configuración de la Etapa

La etapa `documentation` se define de la siguiente manera:

```yaml
generate_documentation:
  stage: documentation
  script:
    - apt-get update -qy
    - apt-get install -y pandoc
    - pip install pandoc
    - pandoc Python_Script_README.md -o documentation.html
    - cd ../
    - git clone https://github.com/usuario/repositorio.git
    - cd repositorio
    - cp /builds/proyecto/documentacion.html ./index.html
    - mkdir ./img
    - mv /builds/proyecto/imagen.png ./img/imagen.png
    - echo "<img src='img/imagen.png'>" >> index.html
    - git add .
    - git commit -m "Actualizar archivo HTML"
    - git push origin main
    - echo "URL de la documentación publicada"
  only:
    - main
```
El script inicia con la actualización de los paquetes del sistema utilizando `apt-get update`, lo que garantiza que todos los paquetes estén actualizados. Posteriormente, instala **Pandoc** con `apt-get install -y pandoc` y `pip install pandoc`, herramientas necesarias para convertir archivos markdown a HTML.

Con **Pandoc**, el script convierte un archivo README de markdown a HTML. Luego, procede a clonar un repositorio de GitHub específico y se mueve al directorio del mismo. Dentro de este repositorio, copia el archivo HTML generado y crea un directorio nuevo para imágenes, trasladando una imagen seleccionada a este lugar.

El script añade la imagen al archivo HTML mediante una etiqueta `<img>`. Finaliza el proceso agregando todos los cambios al repositorio con `git add .`, realizando un commit con `git commit -m "Actualizar archivo HTML"` y subiendo los cambios a la rama principal con `git push origin main`.

Para concluir, el script imprime la URL donde la documentación actualizada está ahora disponible públicamente, reflejando los cambios más recientes y manteniendo la documentación del proyecto al día de manera automatizada.

</details>