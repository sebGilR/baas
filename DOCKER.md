# Docker Development with OrbStack

This guide explains how to set up and run the BaaS (Blog as a Service) application using Docker and OrbStack.

## Prerequisites

- [OrbStack](https://orbstack.dev/) installed (recommended for Mac/Linux)
- Or [Docker Desktop](https://www.docker.com/products/docker-desktop/) (alternative)
- Git

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone git@github.com:sebGilR/baas.git
   cd baas
   ```

2. **Set up environment variables:**
   ```bash
   cp .env.example .env
   # Edit .env if needed for local development
   ```

3. **Build and start services:**
   ```bash
   docker compose up --build
   ```

   The application will be available at: http://localhost:3000

## Services

The Docker setup includes:

- **web**: Rails 8 API application (port 3000)
- **db**: PostgreSQL 17 with pgvector extension (port 5432)
- **redis**: Redis 7 for caching and background jobs (port 6379)

## Development Workflow

### Starting the application

```bash
# Start all services in the background
docker compose up -d

# View logs
docker compose logs -f web

# Stop all services
docker compose down
```

### Running Rails commands

```bash
# Open Rails console
docker compose exec web bin/rails console

# Run migrations
docker compose exec web bin/rails db:migrate

# Run tests
docker compose exec web bin/rspec

# Generate a migration
docker compose exec web bin/rails g migration CreatePosts

# Run RuboCop
docker compose exec web bundle exec rubocop
```

### Database operations

```bash
# Create and setup database
docker compose exec web bin/rails db:create db:schema:load

# Reset database
docker compose exec web bin/rails db:reset

# Access PostgreSQL directly
docker compose exec db psql -U postgres -d baas_development

# Run a SQL file
docker compose exec db psql -U postgres -d baas_development -f /path/to/file.sql
```

### Installing new gems

```bash
# Add gem to Gemfile, then:
docker compose exec web bundle install

# Rebuild the image if needed
docker compose up --build
```

### Debugging

```bash
# Attach to running web container for byebug/pry
docker attach baas-web-1

# View container logs
docker compose logs -f web

# Inspect container
docker compose exec web bash
```

## File Persistence

Volumes are used to persist data:

- `postgres_data`: Database files
- `redis_data`: Redis data
- `bundle_cache`: Bundled gems
- `rails_cache`: Rails cache
- `rails_storage`: Uploaded files

## Troubleshooting

### Port already in use

If you get a "port already allocated" error:

```bash
# Stop other services using the port
lsof -ti:3000 | xargs kill -9

# Or change the port in compose.yml
```

### Database connection issues

```bash
# Check if database is healthy
docker compose ps

# Restart database service
docker compose restart db

# Check database logs
docker compose logs db
```

### Permission issues

```bash
# Fix file permissions
docker compose exec web chown -R rails:rails .

# Or run as root temporarily
docker compose exec -u root web bash
```

### Clean slate

```bash
# Remove all containers, volumes, and images
docker compose down -v
docker system prune -a

# Rebuild from scratch
docker compose up --build
```

## OrbStack Specific Features

OrbStack provides better performance and resource usage on macOS:

1. **Domain access**: Services are accessible at `http://baas-web-1.orb.local`
2. **Linux integration**: Better file system performance
3. **Resource efficiency**: Lower CPU and memory usage
4. **Fast startup**: Instant VM startup

## Production Considerations

This Docker setup is optimized for development. For production:

1. Change `RAILS_ENV` to `production` in Dockerfile
2. Use proper secrets management (not .env files)
3. Configure SSL/TLS termination
4. Set up proper logging and monitoring
5. Use a managed database service
6. Configure CDN for static assets
7. Set up load balancing

## Architecture Notes

The application follows Hexagonal Architecture with:

- **Core**: Authentication, accounts, users
- **Publishing**: Blogs, posts, drafts
- **AiAssistant**: LLM integrations (future)
- **Analytics**: Metrics and reporting (future)

See the main [README.md](../README.md) for detailed architecture documentation.

## Useful Commands

```bash
# Shell into web container
docker compose exec web bash

# Run bundle audit
docker compose exec web bundle exec bundle-audit check

# Run RuboCop with autocorrect
docker compose exec web bundle exec rubocop -A

# Create a new service object
docker compose exec web bin/rails g service Publishing::Posts::CreatePost

# Monitor resource usage
docker stats

# Clean up unused Docker resources
docker system prune -a --volumes
```

## Next Steps

1. **Set up authentication**: Implement JWT token generation and validation
2. **Create models**: Add Account, User, Blog, Post models with UUIDv7
3. **Add policies**: Implement Pundit authorization policies
4. **Configure multi-tenancy**: Set up acts_as_tenant for row-level tenancy
5. **Write tests**: Add RSpec model, request, and service specs
6. **API documentation**: Generate OpenAPI 3.1 specs

---

For more information, see:
- [Rails Guides - Docker](https://guides.rubyonrails.org/getting_started_with_devcontainer.html)
- [OrbStack Documentation](https://docs.orbstack.dev/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
