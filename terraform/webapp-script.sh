#! /bin/bash


#####################
# GLOBAL VARIABLES  #
#####################

### Constant Variables ###

# Element 1 in the commandline arguments should specify the desired action
readonly ACTION="${1}"

# Terraform Binary URL
readonly TERRAFORM_BINARY_DOWNLOAD_URL="https://dani-temp.s3-us-west-2.amazonaws.com/terraform_0.14.4"

# User which is allowed to run the script
readonly ALLOWED_USER="michael"

# Directory where the script's base directory is
readonly SCRIPT_BASE_DIR="/home/${ALLOWED_USER}/web-application"

# Log directory for the script
readonly SCRIPT_LOG_DIR="${SCRIPT_BASE_DIR}/logs"

# GitHub repository from which to download the project
readonly GITHUB_REPO="git@github.com:just-another-dude/web-application.git"

# Directory from which to execute Terraform code
readonly TERRAFORM_DIR="${SCRIPT_BASE_DIR}/terraform"

# Log file for this script
SCRIPT_LOG_FILE="${SCRIPT_LOG_DIR}/app-monitor-$(date +%Y-%m-%d-%H-%M-%S).log"

### Regular Variables ###

tomcat_container_image="tomcat:latest"
haproxy_container_image="haproxy:latest"


########################################################
# Create the required script directories               #
# Globals:                                             #
#   SCRIPT_LOG_DIR                                     #
# Arguments:                                           #
#   None                                               #
# Returns:                                             #
#   0 if directories were created or already existed,  #
#   1 if directory creation failed                     #
########################################################
function create_directories() {
  if (mkdir -p "${SCRIPT_LOG_DIR}"); then
    echo "Directory: ${SCRIPT_LOG_DIR} has been successfully created (or already existed)"
    echo "Logs for this script will be found here: ${SCRIPT_LOG_FILE}"
    return 0
  else
    echo "Failed to create directory: ${SCRIPT_LOG_DIR}"
    return 1
  fi
}

# Running the function here and not in the 'main' function,
# due to logging configuration which requires the directory to already exist.
if (! create_directories); then
  echo "Function 'create_directories' has failed!"
  exit 1
else
  echo "Function 'create_directories' has succeeded!"
fi


##########################################################################################
# Configure Logging.                                                                     #
# All stdout and stderr are redirected into the log file.                                #
# For explanation visit:                                                                 #
# https://serverfault.com/questions/103501/how-can-i-fully-log-all-bash-scripts-actions  #
##########################################################################################
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>"${SCRIPT_LOG_FILE}" 2>&1


#####################################################################
# Check the if the username running the script is allowed to do so  #
# Globals:                                                          #
#   None                                                            #
# Arguments:                                                        #
#   None                                                            #
# Returns:                                                          #
#   0 if user is allowed, 1 if not.                                 #
#####################################################################
function check_linux_user() {
  if [[ "${USER}" == "${ALLOWED_USER}" ]]; then
    return 0
  else
    return 1
  fi
}


###################################################################
# Check whether the script is running from the correct directory  #
# Globals:                                                        #
#   None                                                          #
# Arguments:                                                      #
#   None                                                          #
# Returns:                                                        #
#   0 if directory is correct, 1 if not.                          #
###################################################################
function check_working_directory() {
  working_directory=$(pwd)
  if [[ "${working_directory}" != "${TERRAFORM_DIR}" ]]; then
    return 1
  else
    return 0
  fi
}


############################################################
# Download and Install Terraform if it isn't already       #
# Globals:                                                 #
#   TERRAFORM_BINARY_DOWNLOAD_URL                          #
# Arguments:                                               #
#   None                                                   #
# Returns:                                                 #
#   0 if Terraform is downloaded & installed successfuly,  #
#   1 if Terraform is downloaded but installation failed,  #
#   2 if Terraform already exists on the system,           #
#   3 if Terraform download has failed                     #
############################################################
function install_terraform() {
  if (terraform -help); then
    echo "Terraform already exists!"
    return 2
  fi
  if (wget "${TERRAFORM_BINARY_DOWNLOAD_URL}" -O ./terraform); then
    # Make Terraform a regular system binary
    sudo chmod +x terraform
    sudo chown root:root terraform
    sudo mv terraform /usr/bin

    if (terraform -help); then
      echo "Terraform installed successfully!"
      return 0
    else
      echo "Terraform installation failed!"
      return 1
    fi
  else
    echo "Terraform download from ${TERRAFORM_BINARY_DOWNLOAD_URL} has failed!"
    return 3
  fi
}


#################################################
# Initialize the terraform environment          #
# Globals:                                      #
#   TERRAFORM_DIR                               #
# Arguments:                                    #
#   None                                        #
# Returns:                                      #
#   0 if the environment has been initialized,  #
#   1 if cloning the repo failed.               #
#################################################
function initialize_terraform_environment() {
  if (sudo terraform init); then
    echo "Terraform initialization - successful"
    return 0
  else
    echo "Terraform initialization - failed"
    return 1
  fi
}


############################################################
# Install everything required for the application to run   #
# Globals:                                                 #
#   None                                                   #
# Arguments:                                               #
#   None                                                   #
# Returns:                                                 #
#   0 if all the installation is successful,               #
#   1 if one of the components of the installation failed  #
############################################################
function install_application() {
  install_terraform
  case "${?}" in
    1)
      echo "Function 'install_terraform' has failed"
      # Possible exception handling
      return 1
      ;;
    2)
      echo "Terraform exists - possible version incompatibility"
      # Further checks warranted
      ;;
  esac
  
  initialize_terraform_environment
  case "${?}" in
    0)
      echo "Function 'initialize_terraform_environment' has succeeded!"
      ;;
    1)
      echo "Function 'initialize_terraform_environment' has failed!"
      return 1
      ;;
    2)
      # Potentially different exception handling
      echo "Function 'initialize_terraform_environment' has failed!"
      return 1
      ;;
  esac

  return 0
}


######################################################
# Update local git repo and run the web application  #
# Globals:                                           #
#   TERRAFORM_DIR                                    #
# Arguments:                                         #
#   None                                             #
# Returns:                                           #
#   0 if application started successfully,           #
#   1 if the application failed to start,            #
#   2 if the application is not ready to run         #
#   3 if the local git repository update failed      #
######################################################
function run_application() {
  if (git pull "${GITHUB_REPO}"); then
    echo "Local repository updated!"
    if (sudo terraform plan \
        -var="tomcat_image_version=${tomcat_container_image}" \
        -var="haproxy_image_version=${haproxy_container_image}"); then
      
      echo "Application ready to run!"
      echo "Tomcat container image: ${tomcat_container_image}"
      echo "HAProxy container image: ${haproxy_container_image}"
      if (sudo terraform apply -auto-approve \
          -var="tomcat_image_version=${tomcat_container_image}" \
          -var="haproxy_image_version=${haproxy_container_image}"); then
        
        echo "Application started successfully!"
        return 0
      else
        echo "Application failed to start!"
        return 1
      fi
    else
      echo "Application is not ready to run!"
      return 2
    fi
  else
    echo "Local repository could not be updated!"
    return 3
  fi
}


###########################################################################
# Stop the web application destroying the infrastructure using Terraform  #
# Globals:                                                                #
#   TERRAFORM_DIR                                                         #
# Arguments:                                                              #
#   None                                                                  #
# Returns:                                                                #
#   0 if the application stopped successfully,                            #
#   1 if the application failed to stop.                                  #
###########################################################################
function stop_application() {
  if (sudo terraform destroy -auto-approve "${TERRAFORM_DIR}"); then
    echo "Application stopped successfully!"
    return 0
  else
    echo "Application failed to stop!"
    return 1
  fi
}


function usage() {
  echo "-----------------------------------------------------------------------"
  echo -e "Usage: $(dirname "${0}")/$(basename "${0}") [ARGUMENT] [OPTIONS]"
  echo -e "\nArguments"
  echo -e "\n    install     - first-time installation and environment setup"
  echo -e "\n    start       - run the web application"
  echo -e "\n    stop        - stop the web application"
  echo -e "\nOptions"
  echo -e "\n    tomcat container image (e.g. tomcat:latest)"
  echo -e "\n    HAProxy container image (e.g. haproxy:latest)"
  echo "-----------------------------------------------------------------------"
}


function main() {
  echo "Starting 'main' function on: ${HOSTNAME}"
  if (! check_linux_user); then
    echo "Script must be run as: ${ALLOWED_USER}"
    return 1
  fi

  if (! check_working_directory); then
    echo "Script must be run from: ${TERRAFORM_DIR}"
    return 1
  fi

  if [[ "${ACTION}" == "install" ]]; then
    if (install_application); then
      echo "Function 'install_application' finished successfully!"
    else
      echo "Function 'install_application' failed!"
      return 1
    fi
  
  elif [[ "${ACTION}" == "start" ]]; then
    if [[ -n "${2}" ]]; then  # If commandline argument #2 exists. 
      # Check versioning option - commandline argument 2
      if [[ "${2}" == *"tomcat"* ]]; then
        tomcat_container_image="${2}"
      elif [[ "${2}" == *"haproxy"* ]]; then
        haproxy_container_image="${2}"
      else
        echo "Unknown option: ${2}"
        usage
        return 1
      fi
      
      # Check versioning option - commandline argument 3
      if [[ -n "${3}" ]]; then
        if [[ "${3}" == *"tomcat"* ]]; then
          tomcat_container_image="${3}"
        elif [[ "${3}" == *"haproxy"* ]]; then
          haproxy_container_image="${3}"
        else
          echo "Unknown option: ${3}"
          usage
          return 1
        fi
      fi
    fi

    if (run_application); then
      echo "Function 'run_application' finished successfully!"
    else
      echo "Function 'run_application' failed!"
      usage
      return 1
    fi

  elif [[ "${ACTION}" == "stop" ]]; then
    if (stop_application); then
      echo "Function 'stop_application' finished successfully!"
    else
      echo "Function 'stop_application' failed!"
      usage
      return 1
    fi

  else # Unrecognized action
    usage
    return 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "${@}"
fi
