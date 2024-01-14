### **¿Qué es Terraform?**

Terraform es una herramienta de código abierto que permite a los desarrolladores definir y proporcionar infraestructura de centro de datos utilizando un lenguaje de configuración declarativo. Esto incluye infraestructura de bajo nivel como almacenamiento en disco, redes, así como de alto nivel como entradas DNS, cuentas de correo electrónico, entre otros.

### **Archivo main.tf**

El archivo `main.tf` es el punto de entrada principal para la configuración de Terraform en un directorio. Es en este archivo donde se definen todos los recursos que Terraform creará y administrará.

### **Utilidades de Terraform con Azure Pipelines**

La integración de Terraform con Azure Pipelines ofrece varias ventajas. Permite a los equipos de desarrollo automatizar y simplificar el proceso de despliegue de la infraestructura, lo que puede aumentar la eficiencia y reducir los errores humanos. Además, dado que Terraform utiliza un lenguaje de configuración declarativo, los equipos pueden fácilmente rastrear y versionar las configuraciones de la infraestructura, lo que facilita la colaboración y la gestión del cambio.

### **Funcionamiento del Pipeline**

El pipeline inicia con la inicialización y validación de Terraform. Luego, se crea un plan de Terraform y se aplica. Todo esto se realiza en una máquina virtual con la imagen 'ubuntu-latest'. Después de aplicar los cambios de Terraform, el pipeline procede a realizar el análisis de SonarQube. Esto permitirá a SonarQube analizar el código y detectar posibles vulnerabilidades en la infraestructura desplegada y aprovisionada por Terraform.


Las fases de análisis de SonarQube, así como la creación del pipeline en Azure Pipelines y la descripción de SonarQube presentes en Azure-01, son idénticas y aplicables en este pipeline. 