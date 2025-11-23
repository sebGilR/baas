# GEMINI.md - Instructional Context for the BaaS Project

This document provides a comprehensive overview of the BaaS (Blog as a Service) project, its structure, and conventions. It is intended to be used as a context for AI-powered development assistance.

## Project Overview

BaaS is a "Blog as a Service" API built with **Ruby on Rails 8**. It is designed to be a backend for an AI-powered blogging platform.

The project follows a **modular monolithic architecture** with hexagonal principles, separating concerns into distinct domains:

*   **Core:** Authentication, accounts, and user management.
*   **Publishing:** Blogs, posts, drafts, and tags.
*   **AI Assistant:** LLM integrations and embeddings.
*   **Analytics:** Metrics, views, and reports.

### Key Technologies

*   **Backend:** Ruby on Rails 8 (API-only mode)
*   **Database:** PostgreSQL with `pgvector` for vector similarity search.
*   **Authentication:** JWT with refresh token rotation.
*   **Authorization:** Pundit policies for resource-level access control.
*   **Multi-Tenancy:** Row-level multi-tenancy using the `acts_as_tenant` gem.
*   **API Specification:** JSON:API v1.1.
*   **Containerization:** Docker and Docker Compose for development and production.

## Building and Running

The recommended way to work with this project is using Docker.

### Docker (Recommended)

The `bin/dev-docker` script is a wrapper around `docker compose` and provides a set of commands for managing the development environment.

*   **Start the application:**
    ```bash
    bin/dev-docker up
    ```
    The application will be available at `http://localhost:3000`.

*   **Stop the application:**
    ```bash
    bin/dev-docker down
    ```

*   **Run tests:**
    ```bash
    bin/dev-docker test
    ```

*   **Run migrations:**
    ```bash
    bin/dev-docker migrate
    ```

*   **Open a Rails console:**
    ```bash
    bin/dev-docker console
    ```

### Local Development

While Docker is recommended, you can also run the application locally.

*   **Install dependencies:**
    ```bash
    bundle install
    ```

*   **Setup the database:**
    ```bash
    bin/rails db:create db:migrate db:seed
    ```

*   **Start the server:**
    ```bash
    bin/dev
    # or
    bin/rails server
    ```

## Development Conventions

### Code Style

The project uses **RuboCop** to enforce a consistent code style. The configuration is in `.rubocop.yml`. Key conventions include:

*   **Line Length:** Maximum 120 characters.
*   **String Literals:** Double quotes (`"`) are preferred.
*   **Frozen String Literals:** The `frozen_string_literal: true` comment is enforced on all Ruby files.

Before committing, you can run RuboCop to check for and fix style issues:

```bash
bin/rubocop -A
```

### Testing

The project uses **RSpec** for testing. The test suite is structured to mirror the application's modular architecture.

*   **Run all tests:**
    ```bash
    bin/rspec
    ```

*   **Run a specific file:**
    ```bash
    bin/rspec spec/models/core/user_spec.rb
    ```

Factory Bot is used for creating test data, and Shoulda Matchers are used for concise and readable tests.

### API

The API follows the **JSON:API v1.1 specification**. The `jsonapi-serializer` gem is used to generate JSON:API compliant responses.

The API routes are defined in `config/routes.rb` and are versioned under `api/v1`.
