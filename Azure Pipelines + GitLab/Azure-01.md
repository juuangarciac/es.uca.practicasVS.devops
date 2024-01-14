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

# Explicación del archivo `pipeline.yaml`

El archivo `pipeline.yaml` es una configuración de pipeline de CI/CD (Integración Continua / Entrega Continua) que define una serie de `stages` (etapas) y `jobs` (trabajos) que se ejecutan en cada etapa. Cada trabajo puede tener múltiples `steps` (pasos) que se ejecutan en orden. Aquí está la explicación detallada:

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