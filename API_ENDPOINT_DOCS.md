# Documentación de la API de Enkimail

Este documento describe cómo interactuar con los endpoints de la API de Enkimail para enviar correos electrónicos, gestionar plantillas, contactos, listas de contactos y campañas, e implementar el seguimiento de eventos.

---

---

## Autenticación

Todas las solicitudes a los endpoints protegidos de esta API deben incluir un token de autorización en el encabezado `Authorization`.

**Encabezado de la solicitud:**
`Authorization: Bearer <API_KEY>`

### Endpoints de Autenticación

#### `POST /api/v1/authentication/login`
*   **Descripción:** Inicia sesión y devuelve el token de API.
*   **Respuesta Exitosa:**
    ```json
    {
      "api_key": "...",
      "email": "user@example.com",
      "role": "standard" // o "pro"
    }
    ```

#### `POST /api/v1/authentication/register`
*   **Descripción:** Registra un nuevo usuario.
*   **Respuesta Exitosa:**
    ```json
    {
      "api_key": "...",
      "email": "user@example.com",
      "role": "standard"
    }
    ```

---

## Endpoints

### 7. Transactional Emails (`/api/v1/transactional_emails`)

High performance endpoint for sending transactional emails.

#### `POST /api/v1/transactional_emails` - Send Transactional Email

*   **Description:** Enqueues a transactional email for sending.
*   **Method:** `POST`
*   **Authentication:** Yes (Bearer Token)
*   **Request Body (application/json):**
    | Parameter | Type | Required | Description |
    | :--- | :--- | :--- | :--- |
    | `to` | `String` | Yes | Recipient email address. |
    | `subject` | `String` | Yes | Email subject. |
    | `body` | `String` | Yes (or `html_body`) | Plain text body. |
    | `html_body` | `String` | Yes (or `body`) | HTML body. |
    | `from` | `String` | No | Sender email address (defaults to system default). |
*   **Success Response (202 Accepted):**
    ```json
    {
      "message": "Email queued for sending",
      "status": "queued"
    }
    ```
    ```
*   **Error Response (422 Unprocessable Entity):**
    ```json
    {
      "error": "Missing required parameters: to, subject, and body (or html_body)"
    }
    ```
*   **Error Response (429 Too Many Requests):**
    ```json
    {
      "error": "Daily email limit reached (300 emails/day). Upgrade to Pro for unlimited emails."
    }
    ```

---

## Endpoints

### 1. Gestión de Plantillas de Correo (`/email_templates`)

Permite crear, leer, actualizar y eliminar plantillas de correo electrónico.

#### `POST /email_templates` - Crear Plantilla

*   **Descripción:** Crea una nueva plantilla de correo electrónico.
*   **Método:** `POST`
*   **Autenticación:** Sí
*   **Cuerpo de la Solicitud (application/json):**
    | Parámetro           | Tipo     | Requerido | Descripción                                                                |
    | :------------------ | :------- | :-------- | :------------------------------------------------------------------------- |
    | `email_template`    | `Object` | Sí        | Objeto que contiene los datos de la plantilla.                             |
    | `email_template.name` | `String` | Sí        | Nombre único de la plantilla (ej. `welcome_email`).                       |
    | `email_template.subject` | `String` | Sí        | Asunto del correo. Puede contener variables ERB (ej. `Hola <%= user_name %>`). |
    | `email_template.body` | `String` | Sí        | Cuerpo HTML del correo. Puede contener variables ERB.                      |
    | `email_template.plain_text_body` | `String` | No        | Cuerpo de texto plano del correo. Puede contener variables ERB.            |
*   **Ejemplo de Solicitud:**
    ```json
    {
      "email_template": {
        "name": "welcome_email",
        "subject": "Bienvenido, <%= user_name %> a <%= company_name %>!",
        "body": "<h1>Hola <%= user_name %>,</h1><p>Gracias por unirte a <%= company_name %>.</p>",
        "plain_text_body": "Hola <%= user_name %>,\nGracias por unirte a <%= company_name %>."
      }
    }
    ```
*   **Respuesta Exitosa (201 Created):**
    ```json
    {
      "id": 1,
      "name": "welcome_email",
      "subject": "Bienvenido, <%= user_name %> a <%= company_name %>!",
      "body": "<h1>Hola <%= user_name %>,</h1><p>Gracias por unirte a <%= company_name %>.</p>",
      "plain_text_body": "Hola <%= user_name %>,\nGracias por unirte a <%= company_name %>.",
      "created_at": "...",
      "updated_at": "..."
    }
    ```
*   **Ejemplo `curl`:**
    ```bash
    curl -X POST \
      http://localhost:3000/email_templates \
      -H 'Authorization: Bearer my_secret_api_token' \
      -H 'Content-Type: application/json' \
      -d '{
        "email_template": {
          "name": "welcome_email",
          "subject": "Bienvenido, <%= user_name %> a <%= company_name %>!",
          "body": "<h1>Hola <%= user_name %>,</h1><p>Gracias por unirte a <%= company_name %>.</p>",
          "plain_text_body": "Hola <%= user_name %>,\nGracias por unirte a <%= company_name %>."
        }
      }'
    ```

#### `GET /email_templates` - Listar Plantillas

*   **Descripción:** Recupera una lista de todas las plantillas de correo electrónico.
*   **Método:** `GET`
*   **Autenticación:** Sí
*   **Respuesta Exitosa (200 OK):** Array de objetos `email_template`.
*   **Ejemplo `curl`:**
    ```bash
    curl -X GET \
      http://localhost:3000/email_templates \
      -H 'Authorization: Bearer my_secret_api_token'
    ```

#### `GET /email_templates/:id` - Mostrar Plantilla

*   **Descripción:** Recupera una plantilla de correo electrónico específica por su ID.
*   **Método:** `GET`
*   **Autenticación:** Sí
*   **Parámetros de Ruta:** `id` (entero, ID de la plantilla).
*   **Respuesta Exitosa (200 OK):** Objeto `email_template`.
*   **Ejemplo `curl`:**
    ```bash
    curl -X GET \
      http://localhost:3000/email_templates/1 \
      -H 'Authorization: Bearer my_secret_api_token'
    ```

#### `PATCH/PUT /email_templates/:id` - Actualizar Plantilla

*   **Descripción:** Actualiza una plantilla de correo electrónico existente por su ID.
*   **Método:** `PATCH` o `PUT`
*   **Autenticación:** Sí
*   **Parámetros de Ruta:** `id` (entero, ID de la plantilla).
*   **Cuerpo de la Solicitud (application/json):** Igual que `POST /email_templates`, pero con los campos a actualizar.
*   **Respuesta Exitosa (200 OK):** Objeto `email_template` actualizado.
*   **Ejemplo `curl`:**
    ```bash
    curl -X PATCH \
      http://localhost:3000/email_templates/1 \
      -H 'Authorization: Bearer my_secret_api_token' \
      -H 'Content-Type: application/json' \
      -d '{
        "email_template": {
          "subject": "Asunto Actualizado: <%= user_name %>"
        }
      }'
    ```

#### `DELETE /email_templates/:id` - Eliminar Plantilla

*   **Descripción:** Elimina una plantilla de correo electrónico existente por su ID.
*   **Método:** `DELETE`
*   **Autenticación:** Sí
*   **Parámetros de Ruta:** `id` (entero, ID de la plantilla).
*   **Respuesta Exitosa (204 No Content):** Sin contenido en el cuerpo de la respuesta.
*   **Ejemplo `curl`:**
    ```bash
    curl -X DELETE \
      http://localhost:3000/email_templates/1 \
      -H 'Authorization: Bearer my_secret_api_token'
    ```

### 2. Gestión de Contactos (`/contacts`)

Permite crear, leer, actualizar y eliminar contactos individuales.

#### `POST /contacts` - Crear Contacto

*   **Descripción:** Crea un nuevo contacto.
*   **Método:** `POST`
*   **Autenticación:** Sí
*   **Cuerpo de la Solicitud (application/json):**
    | Parámetro           | Tipo     | Requerido | Descripción                                                                |
    | :------------------ | :------- | :-------- | :------------------------------------------------------------------------- |
    | `contact`           | `Object` | Sí        | Objeto que contiene los datos del contacto.                                |
    | `contact.email`     | `String` | Sí        | Dirección de correo electrónico del contacto (debe ser única).             |
    | `contact.first_name`| `String` | No        | Nombre del contacto.                                                       |
    | `contact.last_name` | `String` | No        | Apellido del contacto.                                                     |
    | `contact.status`    | `Integer`/`String` | No | Estado del contacto (0: `subscribed`, 1: `unsubscribed`, 2: `bounced`, 3: `complained`). Por defecto `subscribed` (0). |
    | `contact.custom_attributes` | `Object` | No | Objeto JSON con atributos personalizados del contacto.                  |
*   **Ejemplo de Solicitud:**
    ```json
    {
      "contact": {
        "email": "juan.perez@example.com",
        "first_name": "Juan",
        "last_name": "Perez",
        "status": "subscribed",
        "custom_attributes": {
          "city": "Madrid",
          "age": 30
        }
      }
    }
    ```
*   **Respuesta Exitosa (201 Created):**
    ```json
    {
      "id": 1,
      "email": "juan.perez@example.com",
      "first_name": "Juan",
      "last_name": "Perez",
      "status": "subscribed",
      "custom_attributes": {
        "city": "Madrid",
        "age": 30
      },
      "created_at": "...",
      "updated_at": "..."
    }
    ```
*   **Ejemplo `curl`:**
    ```bash
    curl -X POST \
      http://localhost:3000/contacts \
      -H 'Authorization: Bearer my_secret_api_token' \
      -H 'Content-Type: application/json' \
      -d '{
        "contact": {
          "email": "nuevo.contacto@example.com",
          "first_name": "Nuevo",
          "last_name": "Contacto",
          "status": "subscribed"
        }
      }'
    ```

#### `GET /contacts` - Listar Contactos

*   **Descripción:** Recupera una lista de todos los contactos.
*   **Método:** `GET`
*   **Autenticación:** Sí
*   **Respuesta Exitosa (200 OK):** Array de objetos `contact`.
*   **Ejemplo `curl`:**
    ```bash
    curl -X GET \
      http://localhost:3000/contacts \
      -H 'Authorization: Bearer my_secret_api_token'
    ```

#### `GET /contacts/:id` - Mostrar Contacto

*   **Descripción:** Recupera un contacto específico por su ID.
*   **Método:** `GET`
*   **Autenticación:** Sí
*   **Parámetros de Ruta:** `id` (entero, ID del contacto).
*   **Respuesta Exitosa (200 OK):** Objeto `contact`.
*   **Ejemplo `curl`:**
    ```bash
    curl -X GET \
      http://localhost:3000/contacts/1 \
      -H 'Authorization: Bearer my_secret_api_token'
    ```

#### `PATCH/PUT /contacts/:id` - Actualizar Contacto

*   **Descripción:** Actualiza un contacto existente por su ID.
*   **Método:** `PATCH` o `PUT`
*   **Autenticación:** Sí
*   **Parámetros de Ruta:** `id` (entero, ID del contacto).
*   **Cuerpo de la Solicitud (application/json):** Igual que `POST /contacts`, pero con los campos a actualizar.
*   **Respuesta Exitosa (200 OK):** Objeto `contact` actualizado.
*   **Ejemplo `curl`:**
    ```bash
    curl -X PATCH \
      http://localhost:3000/contacts/1 \
      -H 'Authorization: Bearer my_secret_api_token' \
      -H 'Content-Type: application/json' \
      -d '{
        "contact": {
          "status": "unsubscribed"
        }
      }'
    ```

#### `DELETE /contacts/:id` - Eliminar Contacto

*   **Descripción:** Elimina un contacto existente por su ID.
*   **Método:** `DELETE`
*   **Autenticación:** Sí
*   **Parámetros de Ruta:** `id` (entero, ID del contacto).
*   **Respuesta Exitosa (204 No Content):** Sin contenido en el cuerpo de la respuesta.
*   **Ejemplo `curl`:**
    ```bash
    curl -X DELETE \
      http://localhost:3000/contacts/1 \
      -H 'Authorization: Bearer my_secret_api_token'
    ```

### 2.1 Importación y Exportación de Contactos

#### `POST /contacts/import` - Importar Contactos (CSV)

*   **Descripción:** Importa contactos masivamente desde un archivo CSV. El proceso se realiza en segundo plano.
*   **Método:** `POST`
*   **Autenticación:** Sí
*   **Tipo de Contenido:** `multipart/form-data`
*   **Parámetros:**
    | Parámetro | Tipo | Requerido | Descripción |
    | :--- | :--- | :--- | :--- |
    | `file` | `File` | Sí | Archivo CSV con los contactos. |
*   **Formato del CSV:**
    El archivo CSV debe tener los siguientes encabezados (en la primera fila):
    - `email` (Requerido)
    - `first_name` (Opcional)
    - `last_name` (Opcional)
    - `status` (Opcional: `subscribed`, `unsubscribed`)

    **Ejemplo de CSV:**
    ```csv
    email,first_name,last_name,status
    juan@example.com,Juan,Perez,subscribed
    maria@example.com,Maria,Gomez,subscribed
    ```
*   **Respuesta Exitosa (202 Accepted):**
    ```json
    {
      "message": "Contact import has been queued."
    }
    ```
*   **Ejemplo `curl`:**
    ```bash
    curl -X POST \
      http://localhost:3000/contacts/import \
      -H 'Authorization: Bearer my_secret_api_token' \
      -F 'file=@/ruta/al/archivo/contactos.csv'
    ```

#### `GET /contacts/export` - Exportar Contactos

*   **Descripción:** Inicia un trabajo en segundo plano para exportar todos los contactos. El usuario recibirá un enlace para descargar el archivo (próximamente).
*   **Método:** `GET`
*   **Autenticación:** Sí
*   **Respuesta Exitosa (202 Accepted):**
    ```json
    {
      "message": "Contact export has been queued. You will receive an email with the download link shortly."
    }
    ```

### 3. Gestión de Listas de Contactos (`/contact_lists`)

Permite crear, leer, actualizar y eliminar listas de contactos, así como gestionar la membresía de contactos en dichas listas.

#### `POST /contact_lists` - Crear Lista de Contactos

*   **Descripción:** Crea una nueva lista de contactos.
*   **Método:** `POST`
*   **Autenticación:** Sí
*   **Cuerpo de la Solicitud (application/json):**
    | Parámetro           | Tipo     | Requerido | Descripción                                                                |
    | :------------------ | :------- | :-------- | :------------------------------------------------------------------------- |
    | `contact_list`      | `Object` | Sí        | Objeto que contiene los datos de la lista de contactos.                    |
    | `contact_list.name` | `String` | Sí        | Nombre único de la lista (ej. `clientes_premium`).                         |
    | `contact_list.description` | `String` | No        | Descripción de la lista de contactos.                                      |
*   **Ejemplo de Solicitud:**
    ```json
    {
      "contact_list": {
        "name": "Clientes Premium",
        "description": "Lista de clientes con alto valor."
      }
    }
    ```
*   **Respuesta Exitosa (201 Created):**
    ```json
    {
      "id": 1,
      "name": "Clientes Premium",
      "description": "Lista de clientes con alto valor.",
      "created_at": "...",
      "updated_at": "..."
    }
    ```
*   **Ejemplo `curl`:**
    ```bash
    curl -X POST \
      http://localhost:3000/contact_lists \
      -H 'Authorization: Bearer my_secret_api_token' \
      -H 'Content-Type: application/json' \
      -d '{
        "contact_list": {
          "name": "Newsletter Suscriptores",
          "description": "Todos los suscriptores del newsletter."
        }
      }'
    ```

#### `GET /contact_lists` - Listar Listas de Contactos

*   **Descripción:** Recupera una lista de todas las listas de contactos.
*   **Método:** `GET`
*   **Autenticación:** Sí
*   **Respuesta Exitosa (200 OK):** Array de objetos `contact_list`.
*   **Ejemplo `curl`:**
    ```bash
    curl -X GET \
      http://localhost:3000/contact_lists \
      -H 'Authorization: Bearer my_secret_api_token'
    ```

#### `GET /contact_lists/:id` - Mostrar Lista de Contactos

*   **Descripción:** Recupera una lista de contactos específica por su ID, incluyendo sus contactos asociados.
*   **Método:** `GET`
*   **Autenticación:** Sí
*   **Parámetros de Ruta:** `id` (entero, ID de la lista).
*   **Respuesta Exitosa (200 OK):** Objeto `contact_list` con array de `contacts`.
*   **Ejemplo `curl`:**
    ```bash
    curl -X GET \
      http://localhost:3000/contact_lists/1 \
      -H 'Authorization: Bearer my_secret_api_token'
    ```

#### `PATCH/PUT /contact_lists/:id` - Actualizar Lista de Contactos

*   **Descripción:** Actualiza una lista de contactos existente por su ID.
*   **Método:** `PATCH` o `PUT`
*   **Autenticación:** Sí
*   **Parámetros de Ruta:** `id` (entero, ID de la lista).
*   **Cuerpo de la Solicitud (application/json):** Igual que `POST /contact_lists`, pero con los campos a actualizar.
*   **Respuesta Exitosa (200 OK):** Objeto `contact_list` actualizado.
*   **Ejemplo `curl`:**
    ```bash
    curl -X PATCH \
      http://localhost:3000/contact_lists/1 \
      -H 'Authorization: Bearer my_secret_api_token' \
      -H 'Content-Type: application/json' \
      -d '{
        "contact_list": {
          "description": "Todos los suscriptores activos del newsletter."
        }
      }'
    ```

#### `DELETE /contact_lists/:id` - Eliminar Lista de Contactos

*   **Descripción:** Elimina una lista de contactos existente por su ID.
*   **Método:** `DELETE`
*   **Autenticación:** Sí
*   **Parámetros de Ruta:** `id` (entero, ID de la lista).
*   **Respuesta Exitosa (204 No Content):** Sin contenido en el cuerpo de la respuesta.
*   **Ejemplo `curl`:**
    ```bash
    curl -X DELETE \
      http://localhost:3000/contact_lists/1 \
      -H 'Authorization: Bearer my_secret_api_token'
    ```

#### `POST /contact_lists/:id/add_contact` - Añadir Contacto a Lista

*   **Descripción:** Añade un contacto existente a una lista de contactos específica.
*   **Método:** `POST`
*   **Autenticación:** Sí
*   **Parámetros de Ruta:** `id` (entero, ID de la lista de contactos).
*   **Cuerpo de la Solicitud (application/json):**
    | Parámetro       | Tipo     | Requerido | Descripción                                                                |
    | :-------------- | :------- | :-------- | :------------------------------------------------------------------------- |
    | `contact_id`    | `Integer`| Sí        | El ID del contacto a añadir a la lista.                                    |
*   **Respuesta Exitosa (200 OK):** Array de contactos en la lista (incluyendo el añadido).
*   **Ejemplo `curl`:**
    ```bash
    curl -X POST \
      http://localhost:3000/contact_lists/1/add_contact \
      -H 'Authorization: Bearer my_secret_api_token' \
      -H 'Content-Type: application/json' \
      -d '{
        "contact_id": 1
      }'
    ```

#### `DELETE /contact_lists/:id/remove_contact` - Eliminar Contacto de Lista

*   **Descripción:** Elimina un contacto de una lista de contactos específica.
*   **Método:** `DELETE`
*   **Autenticación:** Sí
*   **Parámetros de Ruta:** `id` (entero, ID de la lista de contactos).
*   **Cuerpo de la Solicitud (application/json):**
    | Parámetro       | Tipo     | Requerido | Descripción                                                                |
    | :-------------- | :------- | :-------- | :------------------------------------------------------------------------- |
    | `contact_id`    | `Integer`| Sí        | El ID del contacto a eliminar de la lista.                                 |
*   **Respuesta Exitosa (200 OK):** Array de contactos restantes en la lista.
*   **Ejemplo `curl`:**
    ```bash
    curl -X DELETE \
      http://localhost:3000/contact_lists/1/remove_contact \
      -H 'Authorization: Bearer my_secret_api_token' \
      -H 'Content-Type: application/json' \
      -d '{
        "contact_id": 1
      }'
    ```

### 4. Gestión de Campañas (`/campaigns`)

Permite crear, leer, actualizar y eliminar campañas de email.

#### `POST /campaigns` - Crear Campaña

*   **Descripción:** Crea una nueva campaña de correo electrónico.
*   **Método:** `POST`
*   **Autenticación:** Sí
*   **Cuerpo de la Solicitud (application/json):**
    | Parámetro           | Tipo     | Requerido | Descripción                                                                |
    | :------------------ | :------- | :-------- | :------------------------------------------------------------------------- |
    | `campaign`          | `Object` | Sí        | Objeto que contiene los datos de la campaña.                              |
    | `campaign.name`     | `String` | Sí        | Nombre de la campaña.                                                     |
    | `campaign.subject`  | `String` | Sí        | Asunto del correo de la campaña.                                          |
    | `campaign.status`   | `Integer`/`String` | No | Estado de la campaña (0: `draft`, 1: `scheduled`, 2: `sending`, 3: `sent`, 4: `failed`). Por defecto `draft` (0). |
    | `campaign.scheduled_at` | `DateTime` | No | Fecha y hora de programación para el envío de la campaña. Si se proporciona, la campaña se programará. |
    | `campaign.email_template_id` | `Integer`| Sí | ID de la plantilla de correo a usar.                                       |
    | `campaign.contact_list_id` | `Integer`| Sí | ID de la lista de contactos a la que se enviará la campaña.                |
*   **Ejemplo de Solicitud:**
    ```json
    {
      "campaign": {
        "name": "Campaña de Lanzamiento",
        "subject": "¡Gran Lanzamiento de Nuestro Nuevo Producto!",
        "email_template_id": 1,
        "contact_list_id": 1
      }
    }
    ```
*   **Respuesta Exitosa (201 Created):**
    ```json
    {
      "id": 1,
      "name": "Campaña de Lanzamiento",
      "subject": "¡Gran Lanzamiento de Nuestro Nuevo Producto!",
      "status": "draft",
      "email_template_id": 1,
      "contact_list_id": 1,
      "created_at": "...",
      "updated_at": "...",
      "email_template": {...},
      "contact_list": {...}
    }
    ```
*   **Ejemplo `curl`:**
    ```bash
    curl -X POST \
      http://localhost:3000/campaigns \
      -H 'Authorization: Bearer my_secret_api_token' \
      -H 'Content-Type: application/json' \
      -d '{
        "campaign": {
          "name": "Campaña de Verano",
          "subject": "¡Ofertas de Verano!",
          "email_template_id": 1,
          "contact_list_id": 1
        }
      }'
    ```

#### `GET /campaigns` - Listar Campañas

*   **Descripción:** Recupera una lista de todas las campañas.
*   **Método:** `GET`
*   **Autenticación:** Sí
*   **Respuesta Exitosa (200 OK):** Array de objetos `campaign`, incluyendo `email_template` y `contact_list`.
*   **Ejemplo `curl`:**
    ```bash
    curl -X GET \
      http://localhost:3000/campaigns \
      -H 'Authorization: Bearer my_secret_api_token'
    ```

#### `GET /campaigns/:id` - Mostrar Campaña

*   **Descripción:** Recupera una campaña específica por su ID, incluyendo su plantilla de correo y lista de contactos asociadas.
*   **Método:** `GET`
*   **Autenticación:** Sí
*   **Parámetros de Ruta:** `id` (entero, ID de la campaña).
*   **Respuesta Exitosa (200 OK):** Objeto `campaign`, incluyendo `email_template` y `contact_list`.
*   **Ejemplo `curl`:**
    ```bash
    curl -X GET \
      http://localhost:3000/campaigns/1 \
      -H 'Authorization: Bearer my_secret_api_token'
    ```

#### `PATCH/PUT /campaigns/:id` - Actualizar Campaña

*   **Descripción:** Actualiza una campaña existente por su ID.
*   **Método:** `PATCH` o `PUT`
*   **Autenticación:** Sí
*   **Parámetros de Ruta:** `id` (entero, ID de la campaña).
*   **Cuerpo de la Solicitud (application/json):** Igual que `POST /campaigns`, pero con los campos a actualizar.
*   **Respuesta Exitosa (200 OK):** Objeto `campaign` actualizado.
*   **Ejemplo `curl`:**
    ```bash
    curl -X PATCH \
      http://localhost:3000/campaigns/1 \
      -H 'Authorization: Bearer my_secret_api_token' \
      -H 'Content-Type: application/json' \
      -d '{
        "campaign": {
          "status": "draft"
        }
      }'
    ```

#### `DELETE /campaigns/:id` - Eliminar Campaña

*   **Descripción:** Elimina una campaña existente por su ID.
*   **Método:** `DELETE`
*   **Autenticación:** Sí
*   **Parámetros de Ruta:** `id` (entero, ID de la campaña).
*   **Respuesta Exitosa (204 No Content):** Sin contenido en el cuerpo de la respuesta.
*   **Ejemplo `curl`:**
    ```bash
    curl -X DELETE \
      http://localhost:3000/campaigns/1 \
      -H 'Authorization: Bearer my_secret_api_token'
    ```

#### `POST /campaigns/:id/send` - Enviar o Programar Campaña

*   **Descripción:** Encola una campaña para ser enviada o la programa para una fecha futura. La campaña debe estar en estado `draft`.
*   **Método:** `POST`
*   **Autenticación:** Sí
*   **Parámetros de Ruta:** `id` (entero, ID de la campaña).
*   **Cuerpo de la Solicitud (application/json):**
    | Parámetro           | Tipo     | Requerido | Descripción                                                                |
    | :------------------ | :------- | :-------- | :------------------------------------------------------------------------- |
    | `scheduled_at`      | `DateTime` | No        | Fecha y hora de programación para el envío. Si se omite o es una fecha pasada, la campaña se envía inmediatamente. |
*   **Respuesta Exitosa (202 Accepted) - Campaña Programada:**
    ```json
    {
      "status": "success",
      "message": "Campaign scheduled for delivery",
      "campaign": {
        "id": 1,
        "name": "Campaña Programada",
        "subject": "¡Próximas Ofertas!",
        "status": "scheduled",
        "scheduled_at": "2026-03-01T10:00:00.000Z",
        "email_template_id": 1,
        "contact_list_id": 1,
        "created_at": "...",
        "updated_at": "...",
        "email_template": {...},
        "contact_list": {...}
      }
    }
    ```
*   **Respuesta Exitosa (202 Accepted) - Campaña Encolada para Envío Inmediato:**
    ```json
    {
      "status": "success",
      "message": "Campaign queued for immediate sending",
      "campaign": {
        "id": 1,
        "name": "Campaña de Lanzamiento",
        "subject": "¡Gran Lanzamiento de Nuestro Nuevo Producto!",
        "status": "sending",
        "scheduled_at": null,
        "email_template_id": 1,
        "contact_list_id": 1,
        "created_at": "...",
        "updated_at": "...",
        "email_template": {...},
        "contact_list": {...}
      }
    }
    ```
*   **Respuesta de Error (422 Unprocessable Entity):** Si la campaña no está en estado `draft`.
    ```json
    {
      "status": "error",
      "message": "Campaign must be in draft status to be sent or scheduled"
    }
    ```
*   **Ejemplo `curl` - Programar Campaña:**
    ```bash
    curl -X POST \
      http://localhost:3000/campaigns/1/send \
      -H 'Authorization: Bearer my_secret_api_token' \
      -H 'Content-Type: application/json' \
      -d '{
        "scheduled_at": "2026-03-01T10:00:00.000Z"
      }'
    ```
*   **Ejemplo `curl` - Enviar Campaña Inmediatamente:**
    ```bash
    curl -X POST \
      http://localhost:3000/campaigns/1/send \
      -H 'Authorization: Bearer my_secret_api_token'
    ```

### 5. Seguimiento de Correos (`/track`)

Endpoints para el seguimiento de aperturas y clics en correos electrónicos. Estos endpoints no son para ser llamados directamente por el usuario final, sino que son utilizados internamente por los correos enviados para registrar eventos.

#### `GET /track/opens/:email_event_id` - Seguimiento de Apertura

*   **Descripción:** Registra un evento de apertura de correo electrónico. Este endpoint se incrusta como un píxel transparente en el cuerpo HTML de los correos.
*   **Método:** `GET`
*   **Autenticación:** No (maneja el `email_event_id` para identificar el evento).
*   **Parámetros de Ruta:** `email_event_id` (entero, ID del evento de correo a registrar).
*   **Respuesta:** Devuelve un GIF transparente 1x1.
*   **Ejemplo `curl` (solo para fines ilustrativos; llamado automáticamente por clientes de correo):**
    ```bash
    curl -X GET http://localhost:3000/track/opens/123
    ```

#### `GET /track/clicks/:email_event_id` - Seguimiento de Clic

*   **Descripción:** Registra un evento de clic en un enlace de correo electrónico y redirige al usuario a la URL original. Este endpoint se utiliza para reescribir los enlaces dentro de los correos.
*   **Método:** `GET`
*   **Autenticación:** No (maneja el `email_event_id` para identificar el evento).
*   **Parámetros de Ruta:** `email_event_id` (entero, ID del evento de correo a registrar).
*   **Respuesta:** Redirección 302 a la URL original.
*   **Ejemplo `curl` (solo para fines ilustrativos; llamado automáticamente por clientes de correo):**
    ```bash
    curl -X GET http://localhost:3000/track/clicks/456
    ```

### 6. Envío de Correo Electrónico Individual (`/emails`)

Permite enviar correos electrónicos individuales utilizando una plantilla definida.

#### `POST /emails` - Enviar Correo con Plantilla (Individual)

*   **Descripción:** Encola un trabajo de envío de correo electrónico utilizando una plantilla especificada y datos dinámicos. Para un envío individual, se requiere que el `to` corresponda a un contacto existente y se debe proporcionar un `template_name` existente.
*   **Método:** `POST`
*   **Autenticación:** Sí
*   **Cuerpo de la Solicitud (application/json):**
    | Parámetro       | Tipo     | Requerido | Descripción                                                                |
    | :-------------- | :------- | :-------- | :------------------------------------------------------------------------- |
    | `to`            | `String` | Sí        | La dirección de correo electrónico del destinatario (debe existir como `Contact`). |
    | `template_name` | `String` | Sí        | El nombre de la plantilla de correo a utilizar (debe existir como `EmailTemplate`). |
    | `data`          | `Object` | No        | Un objeto JSON con pares clave-valor para interpolar en la plantilla.       |
*   **Ejemplo de Solicitud:**
    ```json
    {
      "to": "destinatario@example.com",
      "template_name": "welcome_email",
      "data": {
        "user_name": "Alice",
        "company_name": "Example Corp"
      }
    }
    ```
*   **Respuesta Exitosa (202 Accepted):**
    ```json
    {
      "status": "success",
      "message": "Email queued for sending using template",
      "to": "destinatario@example.com",
      "template_name": "welcome_email",
      "data": {
        "user_name": "Alice",
        "company_name": "Example Corp"
      }
    }
    ```
*   **Ejemplo `curl`:**
    ```bash
    curl -X POST \
      http://localhost:3000/emails \
      -H 'Authorization: Bearer my_secret_api_token' \
      -H 'Content-Type: application/json' \
      -d '{
        "to": "nuevo_usuario@example.com",
        "template_name": "welcome_email",
        "data": {
          "user_name": "Juan Perez",
          "company_name": "Enkimail Solutions"
        }
      }'
    ```

---

## Respuestas de Error Comunes

*   **400 Bad Request - Parámetros Faltantes/Inválidos:**
    ```json
    {
      "status": "error",
      "message": "param is missing or the value is empty: to"
    }
    ```
*   **401 Unauthorized - No Autenticado:**
    ```json
    {
      "error": "Not Authorized"
    }
    ```
*   **403 Forbidden - No Autorizado:**
    ```json
    {
      "error": "You are not authorized to perform this action."
    }
    ```
*   **404 Not Found - Recurso No Encontrado:**
    ```json
    {
      "error": "EmailTemplate not found"
    }
    ```
*   **422 Unprocessable Entity - Error de Validación:**
    ```json
    {
      "name": ["has already been taken"]
    }
    ```
*   **500 Internal Server Error - Error del Servidor:**
    ```json
    {
      "status": "error",
      "message": "Mensaje de error interno del servidor"
    }
    ```

---

## Webhooks

Manage webhook endpoints to receive real-time notifications for email events.

### 1. List Webhook Endpoints

**Endpoint:** `GET /api/v1/webhook_endpoints`

**Headers:**
- `Authorization`: `Bearer <API_KEY>`

**Response:**
```json
[
  {
    "id": 1,
    "url": "https://example.com/webhooks",
    "events": ["sent", "open", "click"],
    "active": true,
    "created_at": "2023-10-27T10:00:00.000Z",
    "updated_at": "2023-10-27T10:00:00.000Z"
  }
]
```

### 2. Create Webhook Endpoint

**Endpoint:** `POST /api/v1/webhook_endpoints`

**Headers:**
- `Authorization`: `Bearer <API_KEY>`
- `Content-Type`: `application/json`

**Body:**
```json
{
  "webhook_endpoint": {
    "url": "https://example.com/webhooks",
    "events": ["sent", "open", "click", "bounce", "spam_report"]
  }
}
```

**Response:**
```json
{
  "id": 1,
  "url": "https://example.com/webhooks",
  "events": ["sent", "open", "click", "bounce", "spam_report"],
  "active": true,
  "secret": "a1b2c3d4e5f6...",
  "created_at": "...",
  "updated_at": "..."
}
```
*Note: Store the `secret` securely. It is used to sign webhook payloads.*

### 3. Update Webhook Endpoint

**Endpoint:** `PUT /api/v1/webhook_endpoints/:id`

**Body:**
```json
{
  "webhook_endpoint": {
    "active": false,
    "events": ["bounce", "spam_report"]
  }
}
```

### 4. Delete Webhook Endpoint

**Endpoint:** `DELETE /api/v1/webhook_endpoints/:id`

---

### Webhook Payloads

Webhooks are sent as POST requests with a JSON body.

**Headers:**
- `X-EnkiMail-Signature`: `t=1698400000,v1=hwOi...` (HMAC-SHA256 signature)
- `Content-Type`: `application/json`

**Body Example (Sent Event):**
```json
{
  "event": "sent",
  "timestamp": 1698400000,
  "email": "user@example.com",
  "campaign_id": null,
  "template_id": null,
  "url": null,
  "ip": null,
  "user_agent": null,
  "details": null
}
```

**Verifying Signatures:**
1. Extract `t` (timestamp) and `v1` (signature) from `X-EnkiMail-Signature`.
2. Construct the signed string: `timestamp.payload_body`.
3. Calculate HMAC-SHA256 using your endpoint's `secret`.
4. Compare with `v1`.

---

### 8. Gestión de Dominios (`/domains`)

Permite añadir dominios personalizados y verificar su propiedad mediante registros DNS (SPF, DKIM).

#### `GET /api/v1/domains` - Listar Dominios
*   **Descripción:** Devuelve la lista de dominios del usuario.
*   **Método:** `GET`
*   **Respuesta Exitosa:**
    ```json
    [
      {
        "id": 1,
        "name": "example.com",
        "status": "unverified",
        "dkim_selector": "enki",
        "dkim_public_key": "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQ...",
        "dkim_record_name": "enki._domainkey",
        "dkim_record_value": "v=DKIM1; k=rsa; p=MIGfMA0...",
        "spf_record_value": "v=spf1 include:mail.enkimail.com ~all",
        "verification_error": null
      }
    ]
    ```

#### `POST /api/v1/domains` - Añadir Dominio
*   **Descripción:** Añade un nuevo dominio para enviar correos. Genera automáticamente las llaves DKIM.
*   **Método:** `POST`
*   **Body:** `{ "domain": { "name": "example.com" } }`
*   **Respuesta Exitosa (201 Created):** Objeto `domain` creado con las instrucciones DNS.

#### `POST /api/v1/domains/:id/verify` - Verificar Dominio
*   **Descripción:** Realiza una consulta DNS inmediata para verificar los registros SPF y DKIM.
*   **Método:** `POST`
*   **Respuesta Exitosa:**
    ```json
    {
      "message": "Verification queued",
      "domain": { ... }
    }
    ```
    *Nota: Si la verificación falla, el campo `verification_error` del objeto dominio contendrá los detalles.*

#### `DELETE /api/v1/domains/:id` - Eliminar Dominio
*   **Descripción:** Elimina un dominio.
*   **Método:** `DELETE`
*   **Respuesta Exitosa (204 No Content)**

---

### 9. Gestión de Remitentes (`/senders`)

Gestiona las direcciones de correo "From" autorizadas.

#### `GET /api/v1/senders` - Listar Remitentes
*   **Descripción:** Lista los remitentes creados.
*   **Método:** `GET`
*   **Respuesta Exitosa:**
    ```json
    [
      {
        "id": 1,
        "email": "hola@miempresa.com",
        "name": "Soporte",
        "domain_id": 1
      }
    ]
    ```

#### `POST /api/v1/senders` - Crear Remitente
*   **Descripción:** Crea un nuevo remitente. El dominio del email debe coincidir con un Dominio verificado existente.
*   **Método:** `POST`
*   **Body:** `{ "sender": { "email": "ventas@miempresa.com", "name": "Ventas" } }`
*   **Respuesta Exitosa (201 Created):** Objeto `sender`.
*   **Error Común (422):** Si el dominio no está verificado o si se excede el límite del plan.

#### `DELETE /api/v1/senders/:id` - Eliminar Remitente
*   **Descripción:** Elimina un remitente.
*   **Método:** `DELETE`
*   **Respuesta Exitosa (204 No Content)**
