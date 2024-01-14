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