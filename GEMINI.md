# Contexto de EnkiMail

Este proyecto es una plataforma de email marketing "humilde" estilo Brevo.

## Stack Tecnológico
- **Backend:** Ruby on Rails 7.1 (API + Dashboard).
- **Base de Datos:** PostgreSQL 15.
- **Colas:** Sidekiq + Redis 7.
- **MTA (Desarrollo):** Mailpit (Puerto 8025/1025).
- **MTA (Producción):** Postfix propio en contenedor Docker.

## Reglas del Proyecto
1. Toda lógica de envío debe ser asíncrona usando `ActiveJob` con Sidekiq.
2. Las peticiones externas de clientes deben entrar por el namespace `/api/v1/`.
3. No usar servicios externos (AWS SES/SendGrid) a menos que se indique; la prioridad es el Postfix propio.
4. No hacer git commit o git push sin preguntar primero.
5. Todos los comentarios del codigo deberan estar en inglés.
6. Los mesajes de commit estarán en inglés. Usando conventional commit.
7. Documenta siempre que sea posible.