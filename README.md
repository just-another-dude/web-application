# General
* Author: Michael Gurin
* Date: 20/01/2021
* This project incorporates Terraform & Docker to run a web application consisting of a load balancer (HAProxy), three web servers (Tomcat) and a bash script to control the application. The script is named "webapp-script.sh".


# Project Requests
1. Run X web-servers that serves a single static page with a message: Hello from web-server (1..X)
2. Run a load-balancer in front of the web-servers that performs round robin load balancing
3. On both web-servers and load-balancer, add a health endpoint returning the name of the component (web-server-(1..X) / load-balancer).
4. Create support for setting different versions for the web-server and load-balancer
5. Write a shell script for install(using git pull from github)/start/stop/status of the cluster
6. Write a README file


# Requirements
* AMI Linux 2 (may be compatible with other OS types, although not tested).
* User with superuser permissions (sudo).
* Terraform v0.14.4 (downloaded as part of the script).
* Docker installed with required user permissions (add user to docker group) - the allowed user is configured as 'michael' by default.
* SSH access to the GitHub repo.
* Port 42069 needs to be available on the host.


# Installation & Usage  
1. Clone this project into the allowed user's home directory (variable 'ALLOWED_USER' is configured as 'michael' in the script). The script supports SSH by default, but this can be changed as well by editing the 'GITHUB_REPO' variable.

2. To install Terraform and initialize the environment, run: "./webapp-script.sh install". The script must always be run from the terraform directory as defined in the 'TERRAFORM_DIR' variable in the script.

3. To start the web application, you may simply run: "./webapp-script.sh start".  
The script also supports docker image versioning, so if you want a different tag than "latest", you may run the following:  
"./webapp-script.sh start tomcat:<custom-tag> haproxy:<custom-tag>".  
Specifiying only one tag is also supported, for example: "./webapp-script.sh start haproxy:2.2".
  
4. To stop the application, run: "./webapp-script.sh stop".


# Functionality
After starting the application, you may check the running containers by running: "sudo docker ps".  
You can check if the application is functioning properly by running this from the host: "curl http://localhost:42069".
The HAProxy will do round-robin load balancing to each of the tomcats.

To reach the health check endpoint for the tomcats, run this from the host: "curl http://localhost:42069/healthcheck/".
To reach the HAProxy health check endpoint, run this from the host: "curl http://localhost:42069/lb_health.html".

I implemented a docker bridge network for easier communication between the containers.

"git pull" is run as part of starting the application, so no need to do that when changing something.


# Files
* haproxy.cfg --> HAProxy configuration that is bound to the docker container from the host.
* haproxy-health-display.sh --> A script which creates the HTML file for the HAProxy to serve and then runs the HAProxy.
* tomcat-display-page.sh --> A script which creates the HTML pages for the tomcats to serve and then runs 'catalina.sh' (tomcat startup script).


# Potential TODOS:
* Additional exception handling
* Terraform Binary URL can be changed to anything you want. The point is to have a binary with a specific version in a location you control such as S3 so that version incompatibility does not occur.
* More options and ease of use for the user.


# Challenges
1. How to display the hostname in the HTML page. Javascript was attempted before realizing that is executed by the client and does not show the actual container's hostname.
2. After realizing it needed to be done as part of bash, there were some challenges when attempting to integrate with the terraform as the default container image command that runs the app got overridden.


# References / Documentation / Sources:
* https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs - Terraform docker provider
* https://hub.docker.com/_/tomcat - Tomcat docker contaer image
* https://hub.docker.com/_/haproxy - HAProxy docker contaer image
* https://discourse.haproxy.org/t/how-do-i-serve-a-single-static-file-from-haproxy/32 - Serve HTTP file in HAProxy
* https://www.shellcheck.net/ - Shell script checker
