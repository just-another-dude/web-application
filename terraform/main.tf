locals {
  # Tomcat vars
  tomcat_display_page_script = "${var.home_directory}/terraform/files/tomcat-display-page.sh"

  # HAProxy vars
  haproxy_config_file = "${var.home_directory}/terraform/files/haproxy.cfg"
  haproxy_health_display_script = "${var.home_directory}/terraform/files/haproxy-health-display.sh"
}

terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "2.10.0"
    }
  }
}

# Configure the Docker provider
provider "docker" {}

# Create a new docker network
resource "docker_network" "private_docker_network" {
  name = "private_docker_network"
}

resource "docker_image" "tomcat_image" {
  name = "tomcat:${var.tomcat_image_version}"
  keep_locally = true
}

# Create a container
resource "docker_container" "tomcat" {
  count = 3
  image = docker_image.tomcat_image.latest
  name  = "tomcat-${count.index}"
  hostname = "tomcat-${count.index}"
  command = ["bash", "/usr/local/tomcat/tomcat-display-page.sh"]

  mounts {
    target = "/usr/local/tomcat/tomcat-display-page.sh"
    source = local.tomcat_display_page_script
    type = "bind"
  }

  networks_advanced {
    name = "private_docker_network"
  }
}

resource "docker_image" "haproxy_image" {
  name = "haproxy:${var.haproxy_image_version}"
  keep_locally = true
}

# Create a container
resource "docker_container" "haproxy" {
  image = docker_image.haproxy_image.latest
  name  = "haproxy"
  hostname = "haproxy"
  command = ["bash", "/usr/local/etc/haproxy/haproxy-health-display.sh"]
  
  mounts {
    target = "/usr/local/etc/haproxy/haproxy.cfg"
    source = local.haproxy_config_file
    type = "bind"
  }

  mounts {
    target = "/usr/local/etc/haproxy/haproxy-health-display.sh"
    source = local.haproxy_health_display_script
    type = "bind"
  }

  networks_advanced {
    name = "private_docker_network"
  }

  ports {
    internal = 80
    external = 42069
  }
}
