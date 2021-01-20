References / Documentation / Sources:
https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs
https://hub.docker.com/_/tomcat
https://hub.docker.com/_/haproxy
https://discourse.haproxy.org/t/how-do-i-serve-a-single-static-file-from-haproxy/32


README:
Tested on AMI Linux 2, to add support for other OS types, some functions need changing.
Commandline arg $1 - install, delete, start, stop
Tomcat IPs:
172.17.0.2-4

Versioning is possible for the Tomcat & HAProxy container image. Use the variables specified in vars.tf.

Files in use --> index.html, haproxy.cfg, 

A private docker bridge network is used for efficient networking and an easier configuration

HAProxy is also bound to the host machine on port 42069 (was done simply for testing).

You first need to download and run the webapp-script.sh script with the 'install' argument to get everything installed.
Then you can start/stop the cluster. Git pull is incorporated when starting the cluster, so no need to do it manually.
To start/stop the application, you must run the webapp-script.sh script from within the TERRAFORM_DIR.

Commands:
curl http://localhost:42069  --> Access to tomcats (round-robin)
curl http://localhost:42069/healthcheck/ --> Access to tomcat healthcheck
curl http://localhost:42069/lb_health.html --> HAProxy healthcheck


TODOS:
Additional exception handling
Terraform Binary URL can be changed to anything you want. The point is to have a binary with a specific version in a location you control such as S3 so that version incompatibility does not occur.

Requirements:
AMI Linux 2
User with superuser permissions (sudo)
Terraform v0.14.4
Docker installed with required user permissions (add user to docker group)
SSH access to the GitHub repo
