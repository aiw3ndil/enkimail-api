#!/bin/bash
set -e

# Eliminar un posible server.pid antiguo de Rails
rm -f /app/tmp/pids/server.pid

# Run migrations or setup database
echo "Checking and running migrations..."
bundle exec rails db:prepare

# Exportar llaves DKIM verificadas al volumen compartido
echo "Exporting DKIM keys..."
bundle exec rake enkimail:export_dkim_keys RAILS_ENV=production DISABLE_DATABASE_ENVIRONMENT_CHECK=1 || echo "DKIM export skipped or failed."

# Ejecutar el comando principal (el CMD del Dockerfile o del compose)
exec "$@"