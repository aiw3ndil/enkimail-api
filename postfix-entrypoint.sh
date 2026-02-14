#!/bin/sh
set -e

# Forzar la configuración de DNS para evitar problemas de lookup en Coolify
# Escribimos un nuevo /etc/resolv.conf al iniciar el contenedor.
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf

# Entregar la ejecución al comando original del contenedor (CMD).
# Esto asegura que el script de inicio por defecto de la imagen de Postfix se ejecute después de nuestra configuración de DNS.
exec "$@"
