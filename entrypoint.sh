#!/bin/bash
set -e

# Eliminar un posible server.pid antiguo de Rails
rm -f /app/tmp/pids/server.pid

# Run migrations or setup database
echo "Checking and running migrations..."
bundle exec rails db:prepare

# Ejecutar el comando principal (el CMD del Dockerfile o del compose)
exec "$@"