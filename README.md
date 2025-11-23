# BaaS - Blog as a Service API

**Backend API for an AI-powered blogging platform using Rails 8 + Hexagonal Architecture + Multi-Tenancy**

[![Rails](https://img.shields.io/badge/Rails-8.0.4-red.svg)](https://rubyonrails.org/)
[![Ruby](https://img.shields.io/badge/Ruby-3.3.7-red.svg)](https://www.ruby-lang.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17-blue.svg)](https://www.postgresql.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 🚀 Quick Start

### Option 1: Docker/OrbStack (Recommended)

```bash
# Clone and setup
git clone git@github.com:sebGilR/baas.git
cd baas
cp .env.example .env

# Start with helper script
bin/dev-docker up

# Or use docker compose directly
docker compose up -d
```

**Application will be available at:** http://localhost:3000

See [DOCKER.md](DOCKER.md) for detailed Docker documentation.

### Option 2: Local Development

```bash
# Install dependencies
bundle install

# Setup database
bin/rails db:create db:migrate db:seed

# Start server
bin/rails server
```

## 📋 Requirements

- **Ruby**: 3.3.7
- **Rails**: 8.0.4
- **PostgreSQL**: 14+ (with uuid-ossp, pgcrypto, and pgvector extensions)
- **Redis**: 7+ (for caching and background jobs - optional for now)
- **Docker/OrbStack**: Latest (for containerized development)

## 🏗️ Architecture

This project implements a **modular monolithic architecture** with hexagonal principles:

```
app/
├── models/          # Domain models (namespaced)
│   ├── core/        # Authentication, accounts, users
│   ├── publishing/  # Blogs, posts, drafts, tags
│   ├── ai_assistant/# LLM integrations, embeddings
│   └── analytics/   # Metrics, views, reports
├── services/        # Business logic (command pattern)
├── policies/        # Authorization (Pundit)
├── serializers/     # JSON:API v1.1 serializers
└── controllers/     # API endpoints (thin layer)
```

### Key Design Decisions

✅ **Framework**: Rails 8 API-only mode  
✅ **Database**: PostgreSQL with pgvector extension  
✅ **Authentication**: JWT tokens with refresh token rotation  
✅ **Authorization**: Pundit policies  
✅ **Multi-Tenancy**: Row-level with `acts_as_tenant`  
✅ **IDs**: UUIDv7 for public APIs, bigint PKs internally  
✅ **API Format**: JSON:API v1.1 specification  

See [ARCHITECTURE.md](../project_docs/baas/ARCHITECTURE.md) for detailed documentation.

## 🗄️ Database Schema

### Core Models
- **Account** - Tenant boundary for multi-tenancy
- **User** - Authentication and user management
- **AccountMembership** - User-to-account relationships with roles

### Publishing Models
- **Blog** - Blog configuration and settings
- **Post** - Published blog posts
- **Draft** - Work-in-progress content
- **Tag** - Content categorization

See [DATABASE_SCHEMA_HYBRID.md](../project_docs/baas/DATABASE_SCHEMA_HYBRID.md) for complete schema.

## 🔐 Authentication & Authorization

- **JWT access tokens** (15-minute expiry)
- **Refresh tokens** (30-day expiry with rotation)
- **Device-based token storage**
- **Pundit policies** for resource-level authorization
- **Tenant scoping** enforced at the database level

See [AUTH_FLOW.md](../project_docs/baas/AUTH_FLOW.md) for authentication details.

## 🛠️ Development

### Docker Commands (Recommended)

```bash
# Start services
bin/dev-docker up

# View logs
bin/dev-docker logs -f

# Rails console
bin/dev-docker console

# Run tests
bin/dev-docker test

# Run migrations
bin/dev-docker migrate

# Database console
bin/dev-docker psql

# Stop services
bin/dev-docker down
```

### Local Commands

```bash
# Rails console
bin/rails console

# Run tests
bin/rspec

# Run migrations
bin/rails db:migrate

# Linting
bin/rubocop

# Security audit
bundle exec bundle-audit check
```

## 🧪 Testing

```bash
# Run all tests
bin/rspec

# Run specific test file
bin/rspec spec/models/core/user_spec.rb

# Run with coverage
COVERAGE=true bin/rspec
```

Test structure follows the application's modular architecture:
```
spec/
├── models/
│   ├── core/
│   ├── publishing/
│   └── ai_assistant/
├── services/
├── requests/
└── policies/
```

## 📚 API Documentation

API endpoints follow JSON:API v1.1 specification:

```
POST   /api/v1/auth/register       # Register new user
POST   /api/v1/auth/login          # Login and get tokens
POST   /api/v1/auth/refresh        # Refresh access token
DELETE /api/v1/auth/logout         # Logout and revoke tokens

GET    /api/v1/blogs               # List blogs
POST   /api/v1/blogs               # Create blog
GET    /api/v1/blogs/:id           # Get blog
PATCH  /api/v1/blogs/:id           # Update blog
DELETE /api/v1/blogs/:id           # Delete blog

GET    /api/v1/posts               # List posts
POST   /api/v1/posts               # Create post
GET    /api/v1/posts/:id           # Get post
PATCH  /api/v1/posts/:id           # Update post
DELETE /api/v1/posts/:id           # Delete post
```

OpenAPI 3.1 specification (coming soon): `/api/docs`

## 🔧 Configuration

Environment variables (see `.env.example`):

```bash
# Database
DATABASE_URL=postgres://postgres:postgres@db:5432/baas_development

# Redis
REDIS_URL=redis://redis:6379/0

# Rails
RAILS_ENV=development
SECRET_KEY_BASE=your_secret_key

# JWT
JWT_SECRET_KEY=your_jwt_secret
JWT_EXPIRATION_HOURS=24

# CORS
CORS_ORIGINS=http://localhost:3001,http://localhost:3000
```

## 🚢 Deployment

### Docker Production Build

```bash
# Build production image
docker build -t baas:production .

# Run with environment variables
docker run -e RAILS_ENV=production -e DATABASE_URL=... -p 3000:3000 baas:production
```

### Kamal (Coming Soon)

Kamal configuration for zero-downtime deployments.

## 📖 Documentation

- [DOCKER.md](DOCKER.md) - Docker/OrbStack development guide
- [SETUP.md](SETUP.md) - Initial setup instructions
- [SETUP_COMPLETE.md](SETUP_COMPLETE.md) - Setup verification checklist
- [ARCHITECTURE.md](../project_docs/baas/ARCHITECTURE.md) - Architecture deep dive
- [DATABASE_SCHEMA_HYBRID.md](../project_docs/baas/DATABASE_SCHEMA_HYBRID.md) - Database design
- [AUTH_FLOW.md](../project_docs/baas/AUTH_FLOW.md) - Authentication flows
- [MULTI_TENANCY.md](../project_docs/baas/MULTI_TENANCY.md) - Multi-tenancy implementation

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

This project follows:
- **RuboCop** for code style
- **RSpec** for testing
- **Hexagonal Architecture** principles
- **JSON:API v1.1** specification

Run linters before committing:
```bash
bin/rubocop -A  # Auto-fix style issues
bin/rspec       # Run tests
```

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Rails team for Rails 8
- PostgreSQL team for pgvector
- The Ruby community

## 📞 Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/sebGilR/baas/issues)
- **Documentation**: See `project_docs/baas/` for detailed guides

---

**Built with ❤️ using Rails 8, PostgreSQL, and Hexagonal Architecture**
