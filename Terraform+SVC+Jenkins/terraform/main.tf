terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {
  # Configura el proveedor de Docker
}

# Crear red de Docker
resource "docker_network" "jenkins_network" {
  name   = "jenkins"
  driver = "bridge"
}

# Crear volumen para jenkins-data
resource "docker_volume" "jenkins_data" {
  name = "jenkins-data"
}

# Crear volumen para jenkins-docker-certs
resource "docker_volume" "jenkins_docker_certs" {
  name = "jenkins-docker-certs"
}

# Crear contenedor para jenkins-docker
resource "docker_container" "jenkins_docker" {
  name         = "jenkins-docker"
  image        = "docker:dind"
  privileged   = true
  network_mode = docker_network.jenkins_network.name

  volumes {
    volume {
      name      = docker_volume.jenkins_docker_certs.name
      container = "/certs/client"
    }
  }

  volumes {
    volume {
      name      = docker_volume.jenkins_data.name
      container = "/var/jenkins_home"
    }
  }

  command = ["--storage-driver", "overlay2"]
}

# Crear imagen personalizada de Jenkins
# Use an external tool like Docker to build the image

# Crear contenedor para jenkins-blueocean
resource "docker_container" "jenkins_blueocean" {
  name         = "jenkins-blueocean"
  image        = "myjenkins-blueocean"  # Assuming the image is already built
  network_mode = docker_network.jenkins_network.name

  volumes {
    volume {
      name = docker_volume.jenkins_data.name
    }
  }

  volumes {
    volume {
      name = docker_volume.jenkins_docker_certs.name
    }
  }

  volumes {
    volume {
      host_path  = "$HOME"
      container = "/home"
    }
  }

  restart = "on-failure"

  env = [
    "DOCKER_HOST=tcp://docker:2376",
    "DOCKER_CERT_PATH=/certs/client",
    "DOCKER_TLS_VERIFY=1",
    "JAVA_OPTS=-Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true",
  ]
}
