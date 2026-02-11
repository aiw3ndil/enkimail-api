#!/bin/bash
set -e

# Eliminar un posible server.pid antiguo de Rails
rm -f /app/tmp/pids/server.pid

# Ejecutar el comando principal (el CMD del Dockerfile o del compose)
exec "$@"