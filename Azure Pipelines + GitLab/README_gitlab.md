# Práctica de CI/CD y Cienca Abierta con GitLab

## Preparación del entorno

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