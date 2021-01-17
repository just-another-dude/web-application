#!/bin/bash

HAPROXY_CONFIG_FILE="/usr/local/etc/haproxy/haproxy.cfg"
HAPROXY_DIR="/etc/haproxy/errors/"
HAPROXY_HEALTH_FILE="${HAPROXY_DIR}200health.http"

mkdir -p "${HAPROXY_DIR}"

# Health page
cat <<EOF > "${HAPROXY_HEALTH_FILE}"
HTTP/1.0 200 Found
Cache-Control: no-cache
Connection: close
Content-Type: text/html

<html>
    <head>
    </head>
    <body>
        <p>${HOSTNAME}</p>
    </body>
</html>
EOF

haproxy -f "${HAPROXY_CONFIG_FILE}"
