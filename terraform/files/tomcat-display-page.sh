#!/bin/bash

WEBAPP_DIR="/usr/local/tomcat/webapps"
ROOT_DIR="${WEBAPP_DIR}/ROOT/"
HEALTHCHECK_DIR="${WEBAPP_DIR}/healthcheck/"

mkdir -p "${ROOT_DIR}" && mkdir -p "${HEALTHCHECK_DIR}"

cat <<EOF > "${ROOT_DIR}"/index.html
<!DOCTYPE html>
<html>
    <head>
    </head>
    <body>
        <p>Hello from ${HOSTNAME}</p>
    </body>
</html>
EOF

cat <<EOF > "${HEALTHCHECK_DIR}"/index.html
<!DOCTYPE html>
<html>
    <head>
    </head>
    <body>
        <p>${HOSTNAME}</p>
    </body>
</html>
EOF

# Run tomcat
/usr/local/tomcat/bin/catalina.sh run
