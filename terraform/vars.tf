variable "tomcat_image_version" {
    type = string
    description = "The version of the Docker container tomcat image"
    default = "latest"
}

variable "haproxy_image_version" {
    type = string
    description = "The version of the Docker cotnainer HAProxy image"
    default = "latest"
}

variable "home_directory" {
    type = string
    description = "The home directory on the linux machine from which the Terraform is run"
    default = "/home/michael/web-application"
}
