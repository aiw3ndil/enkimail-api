#!/bin/bash
set -e

# Eliminar un posible server.pid antiguo de Rails
rm -f /app/tmp/pids/server.pid

# Esperar a que la base de datos esté lista
echo "Waiting for database..."
until bundle exec rails db:version > /dev/null 2>&1; do
  echo "Database not ready, retrying in 2s..."
  sleep 2
done

# Run migrations or setup database
echo "Checking and running migrations..."
bundle exec rails db:prepare

# Exportar llaves DKIM verificadas al volumen compartido
echo "Exporting DKIM keys..."
# Limpiamos el archivo de configuración en la ruta real del volumen
DKIM_PATH="${OPENDKIM_DATA_PATH:-config/opendkim}"
rm -rf "$DKIM_PATH/opendkim.conf"
bundle exec rake enkimail:export_dkim_keys RAILS_ENV=${RAILS_ENV:-production} DISABLE_DATABASE_ENVIRONMENT_CHECK=1 || echo "DKIM export skipped or failed."
echo "Contenido de $DKIM_PATH tras exportación:"
ls -lR "$DKIM_PATH"

# Asegurar permisos del volumen compartido para que Postfix pueda leerlo
if [ -d "$DKIM_PATH" ]; then
  chmod -R 0755 "$DKIM_PATH"
fi

# Ejecutar el comando principal (el CMD del Dockerfile o del compose)
exec "$@"