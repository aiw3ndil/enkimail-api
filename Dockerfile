# 1. Usamos una versión estable de Ruby (ejemplo 3.2)
FROM ruby:3.3.7

# 2. Instalamos dependencias del sistema
# - build-essential y libpq-dev son para compilar gemas como 'pg' (PostgreSQL)
# - curl y git son utilidades básicas
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# 3. Configuramos el directorio de trabajo
WORKDIR /app

# 4. Instalamos las gemas (Bundler)
# Copiamos primero estos archivos para aprovechar el sistema de capas de Docker
COPY Gemfile Gemfile.lock ./
RUN bundle install

# 5. Copiamos el resto del código de la aplicación
COPY . .

# 6. Exponemos el puerto de Rails
EXPOSE 3000

# 7. Script de entrada para limpiar archivos temporales del servidor
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# El comando por defecto (será sobrescrito en el docker-compose para Sidekiq)
CMD ["rails", "server", "-b", "0.0.0.0"]