# Enkimail API - Your Humble Brevo Clone Backend

Welcome to the Enkimail API, a robust backend solution designed to power your email marketing needs, akin to a humble version of Brevo. This API provides functionalities for managing email templates, contacts, contact lists, campaigns, and basic email tracking (opens and clicks).

## Table of Contents

1.  [Features](#features)
2.  [Getting Started](#getting-started)
    *   [Prerequisites](#prerequisites)
    *   [Setup](#setup)
    *   [Running the Application](#running-the-application)
3.  [API Documentation](#api-documentation)
4.  [Database Management](#database-management)
5.  [Running Tests](#running-tests)
6.  [Next Steps & Future Enhancements](#next-steps--future-enhancements)
7.  [Contributing](#contributing)
8.  [License](#license)

## Features

The Enkimail API currently supports:

*   **Email Template Management**:
    *   CRUD operations for email templates (`name`, `subject`, `body`, `plain_text_body`).
    *   Dynamic content rendering in templates using ERB.
*   **Contact Management**:
    *   CRUD operations for contacts (`email`, `first_name`, `last_name`, `status`, `custom_attributes`).
*   **Contact List Management**:
    *   CRUD operations for contact lists (`name`, `description`).
    *   Add/remove contacts from specific lists.
*   **Campaign Management**:
    *   CRUD operations for email campaigns (`name`, `subject`, `status`, `email_template_id`, `contact_list_id`).
    *   Triggering campaign sends to associated contact lists.
*   **Email Sending**:
    *   Individual email sends using templates and dynamic data.
    *   Mass email sends via campaigns, processed asynchronously using Sidekiq.
*   **Basic Email Tracking**:
    *   Open tracking (using an invisible pixel).
    *   Click tracking (rewriting links and redirecting).
*   **Authentication & Authorization**:
    *   Basic token-based API authentication (hardcoded token for development).
    *   Pundit-based authorization for all key resources.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

*   Docker and Docker Compose installed on your system.
    *   [Install Docker Engine](https://docs.docker.com/engine/install/)
    *   [Install Docker Compose](https://docs.docker.com/compose/install/)

### Setup

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/enkimail-api.git
    cd enkimail-api
    ```

2.  **Build the Docker images:**
    ```bash
    docker compose build
    ```

3.  **Set up the database:**
    This will create the PostgreSQL database and run all pending migrations.
    ```bash
    docker compose run --rm web rails db:create db:migrate
    ```

### Running the Application

To start all services (Rails API, Sidekiq, PostgreSQL, Redis, Mailpit):

```bash
docker compose up -d
```

Once running:
*   The Rails API will be accessible at `http://localhost:3000`.
*   Mailpit (for viewing sent emails) will be accessible at `http://localhost:8025`.
*   Sidekiq Web UI (for monitoring background jobs) might be configured at `http://localhost:3000/sidekiq` if enabled in `config/routes.rb` (currently not configured, but a common practice).

## API Documentation

For **detailed information on how to use all Enkimail API endpoints**, including authentication, request/response formats, parameters, and `curl` examples, please refer to the dedicated documentation file:

[**API Endpoint Documentation (API_ENDPOINT_DOCS.md)**](API_ENDPOINT_DOCS.md)

This document is your primary resource for interacting with the Enkimail API.

## Database Management

To run database migrations:
```bash
docker compose run --rm web rails db:migrate
```

To rollback the last migration:
```bash
docker compose run --rm web rails db:rollback
```

To access the Rails console:
```bash
docker compose run --rm web rails console
```

## Running Tests

To run the application's test suite:
```bash
docker compose run --rm web rails test
```

## Next Steps & Future Enhancements

The Enkimail API provides a strong foundation. Here are some key areas for future development to make it a more complete Brevo-like platform:

*   **Robust Authentication & User Management**: Implement actual user accounts, API key generation, and management.
*   **Multi-tenancy**: Securely isolate data for multiple users/organizations.
*   **Advanced Contact Segmentation**: Dynamic segments based on contact attributes and email engagement.
*   **Contact Import/Export**: Bulk import/export contacts via CSV.
*   **Campaign Scheduling**: Schedule campaigns for future delivery.
*   **Email Tracking Enhancements**: Handle bounces, spam complaints, and provide analytics (dashboards).
*   **Transactional Email API**: A dedicated, highly performant endpoint for transactional emails.
*   **Webhooks**: Notify external systems of email events.
*   **Admin UI**: A user-friendly web interface for managing all aspects of the platform.

## Contributing

Contributions are welcome! Please feel free to open issues or pull requests.

## License

This project is open-source under the [MIT License](LICENSE.md) (assuming you'll add one).
