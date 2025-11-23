# Docker Setup Verification

This document helps you verify that the Docker/OrbStack environment is correctly configured.

## Prerequisites Check

### 1. Install OrbStack (Recommended) or Docker Desktop

**OrbStack (Mac/Linux):**
```bash
# Download from: https://orbstack.dev/download
# Or install via Homebrew:
brew install orbstack
```

**Docker Desktop (Alternative):**
```bash
# Download from: https://www.docker.com/products/docker-desktop/
```

### 2. Verify Docker is Running

```bash
# Check Docker daemon
docker --version
docker ps

# Should output Docker version and running containers
```

### 3. Check Docker Compose

```bash
# Verify docker compose is available
docker compose version

# Should output: Docker Compose version v2.x.x or higher
```

## Initial Setup

### 1. Clone Repository (if not already done)

```bash
git clone git@github.com:sebGilR/baas.git
cd baas
```

### 2. Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit .env if needed (optional for development)
# Default values work for local Docker development
```

### 3. Build Docker Images

```bash
# Build all services
docker compose build

# This may take 5-10 minutes on first build
# Subsequent builds will be faster due to layer caching
```

## Start the Application

### Using Helper Script (Recommended)

```bash
# Start all services
bin/dev-docker up

# Expected output:
# ==> Starting services...
# ✓ Services started! Application available at http://localhost:3000
```

### Using Docker Compose Directly

```bash
# Start in background
docker compose up -d

# View logs
docker compose logs -f web

# Stop services
docker compose down
```

## Verify Services

### 1. Check Service Health

```bash
# View running services
docker compose ps

# All services should show "healthy" or "running" status
# Expected services:
# - baas-db-1      (PostgreSQL)
# - baas-redis-1   (Redis)
# - baas-web-1     (Rails API)
```

### 2. Test Database Connection

```bash
# Connect to PostgreSQL
docker compose exec db psql -U postgres -d baas_development

# Inside psql, verify extensions:
\dx

# You should see:
# - uuid-ossp
# - pgcrypto
# - vector

# Test UUIDv7 function:
SELECT gen_uuidv7();

# Should output a UUID like: 018c5e9b-7c3a-7000-8000-123456789abc

# Exit psql:
\q
```

### 3. Test Redis Connection

```bash
# Connect to Redis
docker compose exec redis redis-cli

# Test Redis:
127.0.0.1:6379> PING
# Should output: PONG

127.0.0.1:6379> SET test "Hello"
# Should output: OK

127.0.0.1:6379> GET test
# Should output: "Hello"

# Exit:
127.0.0.1:6379> exit
```

### 4. Test Rails Application

```bash
# Check Rails console
docker compose exec web bin/rails console

# Inside console, test database connection:
ActiveRecord::Base.connection.execute("SELECT version()")
# Should output PostgreSQL version

# Exit console:
exit
```

### 5. Test HTTP Endpoint

```bash
# Test health endpoint (when implemented)
curl http://localhost:3000/health

# Or open in browser:
open http://localhost:3000
```

## Run Database Migrations

```bash
# Create database and run migrations
bin/dev-docker migrate

# Or using docker compose:
docker compose exec web bin/rails db:migrate
```

## Run Tests

```bash
# Run RSpec test suite
bin/dev-docker test

# Or using docker compose:
docker compose exec web bin/rspec
```

## Common Issues and Solutions

### Issue: Port Already in Use

**Error:** `bind: address already in use`

**Solution:**
```bash
# Find process using port 3000
lsof -ti:3000

# Kill the process
lsof -ti:3000 | xargs kill -9

# Or change port in compose.yml
```

### Issue: Database Connection Failed

**Error:** `could not connect to server: Connection refused`

**Solution:**
```bash
# Check database health
docker compose ps db

# Restart database
docker compose restart db

# Check database logs
docker compose logs db
```

### Issue: Permission Denied

**Error:** `Permission denied @ rb_sysopen`

**Solution:**
```bash
# Fix ownership (if needed)
docker compose exec -u root web chown -R rails:rails /rails

# Or locally:
sudo chown -R $(whoami) .
```

### Issue: Out of Disk Space

**Error:** `no space left on device`

**Solution:**
```bash
# Clean up Docker resources
docker system prune -a --volumes

# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune
```

### Issue: Build Fails

**Error:** Various build errors

**Solution:**
```bash
# Clean build (no cache)
docker compose build --no-cache

# Reset everything
docker compose down -v
docker system prune -a
docker compose up --build
```

## OrbStack Specific Features

If using OrbStack, you can access services via:

- **Web app:** `http://baas-web-1.orb.local:3000`
- **Database:** `baas-db-1.orb.local:5432`
- **Redis:** `baas-redis-1.orb.local:6379`

## Performance Tips

### OrbStack (Mac)
- Uses less CPU and memory than Docker Desktop
- Faster file I/O with VirtioFS
- Instant VM startup
- Native Apple Silicon support

### Docker Desktop
- Configure resource limits in Docker Desktop preferences
- Allocate at least 4GB RAM, 2 CPU cores
- Enable VirtioFS for better file sharing performance

## Development Workflow

Once everything is verified:

```bash
# Daily workflow
bin/dev-docker up       # Start services
bin/dev-docker logs -f  # Watch logs
bin/dev-docker console  # Rails console
bin/dev-docker test     # Run tests
bin/dev-docker down     # Stop services

# When pulling updates
git pull
docker compose build    # Rebuild if Gemfile changed
bin/dev-docker migrate  # Run new migrations
```

## Next Steps

1. ✅ Verify all services are running
2. ✅ Test database and Redis connections
3. ✅ Run migrations
4. ✅ Run test suite
5. 🚀 Start building features!

See [DOCKER.md](DOCKER.md) for detailed Docker documentation.

## Success Checklist

- [ ] Docker/OrbStack installed and running
- [ ] All services start successfully
- [ ] PostgreSQL connection works
- [ ] PostgreSQL extensions installed (uuid-ossp, pgcrypto, vector)
- [ ] UUIDv7 function works
- [ ] Redis connection works
- [ ] Rails console accessible
- [ ] Can run migrations
- [ ] Can run tests
- [ ] Application accessible at http://localhost:3000

---

**If all items are checked, your Docker environment is ready for development! 🎉**
