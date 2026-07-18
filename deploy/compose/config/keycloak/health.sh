#!/usr/bin/env bash
# Healthcheck Keycloak sans curl : GET /health/ready sur le port management 9000. FT-2.
set -euo pipefail
exec 3<>/dev/tcp/127.0.0.1/9000
printf 'GET /health/ready HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n' >&3
head -n1 <&3 | grep -q ' 200 '
