# 📋 **baas — Development Plan & Pre-Deployment Checklist**

*Roadmap, milestones, and pre-deployment checklist for the baas backend API.*

---

## 🎯 **Project Goals**

Build a production-ready, AI-powered blogging platform backend that demonstrates:
- Rails 8 API-only architecture
- Multi-tenant SaaS patterns
- Hexagonal architecture with Rails Engines
- JWT authentication with refresh tokens
- AI integration (LLMs, embeddings, semantic search)
- JSON:API specification compliance
- Comprehensive API documentation

---

## 🗺️ **Development Roadmap**

### **Phase 1: Foundation (Weeks 1-2)**

**Goal:** Core infrastructure and authentication

- [ ] **Project Setup**
  - [ ] Initialize Rails 8 API-only app
  - [ ] Configure PostgreSQL with UUID
  - [ ] Set up RSpec with FactoryBot
  - [ ] Configure RuboCop and Brakeman
  - [ ] Set up GitHub repository with CI

- [ ] **Core Engine — Authentication**
  - [ ] User model with BCrypt
  - [ ] JWT token generation/validation
  - [ ] Refresh token model and rotation
  - [ ] Registration endpoint
  - [ ] Login endpoint
  - [ ] Refresh endpoint
  - [ ] Logout endpoint
  - [ ] Authentication middleware
  - [ ] Tests for auth flow

- [ ] **Core Engine — Multi-Tenancy**
  - [ ] Account model (tenant)
  - [ ] AccountMembership model (roles)
  - [ ] acts_as_tenant configuration
  - [ ] Tenant context middleware
  - [ ] Account switching endpoint
  - [ ] Tests for tenant isolation

- [ ] **Authorization with Pundit**
  - [ ] Install and configure Pundit
  - [ ] ApplicationPolicy base class
  - [ ] AuthorizationContext
  - [ ] Tests for authorization

---

### **Phase 2: Publishing Engine (Weeks 3-4)**

**Goal:** Core blogging functionality

- [ ] **Blog Management**
  - [ ] Blog model
  - [ ] Blog CRUD endpoints
  - [ ] BlogPolicy
  - [ ] Blog serializers
  - [ ] Tests

- [ ] **Post Management**
  - [ ] Post model with status enum
  - [ ] Post CRUD endpoints
  - [ ] Post publishing logic
  - [ ] Post scheduling
  - [ ] PostPolicy
  - [ ] Post serializers
  - [ ] Tests

- [ ] **Draft System**
  - [ ] Draft model
  - [ ] Draft CRUD endpoints
  - [ ] Autosave functionality
  - [ ] Convert draft to post
  - [ ] Tests

- [ ] **Content Organization**
  - [ ] Tag model
  - [ ] Category model
  - [ ] Taggings (polymorphic)
  - [ ] Tag/Category endpoints
  - [ ] Tests

- [ ] **Content Versioning**
  - [ ] Revision model
  - [ ] Save revision on publish
  - [ ] Restore from revision
  - [ ] Tests

---

### **Phase 3: API Documentation (Week 5)**

**Goal:** Auto-generated, beautiful API docs

- [ ] **OpenAPI 3.1 Setup**
  - [ ] Install rswag or similar gem
  - [ ] Configure OpenAPI spec generation
  - [ ] Document existing endpoints
  - [ ] Add request/response examples

- [ ] **Swagger UI**
  - [ ] Mount Swagger UI
  - [ ] Configure authentication
  - [ ] Test interactive docs

- [ ] **Redoc**
  - [ ] Mount Redoc
  - [ ] Configure styling
  - [ ] Test documentation UX

- [ ] **JSON:API Compliance**
  - [ ] Install jsonapi-serializer
  - [ ] Convert all serializers to JSON:API format
  - [ ] Add pagination, filtering, sorting
  - [ ] Add relationship includes
  - [ ] Tests

---

### **Phase 4: Background Jobs & Email (Week 6)**

**Goal:** Async processing and notifications

- [ ] **Sidekiq Setup**
  - [ ] Install Sidekiq and Redis
  - [ ] Configure queues (critical, default, ai, analytics, mailers)
  - [ ] Set up Sidekiq web UI
  - [ ] Configure monitoring

- [ ] **Email System**
  - [ ] Configure SendGrid
  - [ ] ActionMailer setup
  - [ ] Welcome email
  - [ ] Password reset email
  - [ ] Team invitation email
  - [ ] Email templates (HTML)
  - [ ] Tests

- [ ] **Scheduled Jobs**
  - [ ] Sidekiq-Cron setup
  - [ ] Scheduled post publishing job
  - [ ] Cleanup expired tokens job
  - [ ] Tests

---

### **Phase 5: AI Assistant Engine (Weeks 7-8)**

**Goal:** AI-powered writing features

- [ ] **LLM Integration**
  - [ ] OpenAI API adapter
  - [ ] Anthropic API adapter (optional)
  - [ ] Adapter factory pattern
  - [ ] Error handling and retries
  - [ ] VCR cassettes for tests

- [ ] **AI Services**
  - [ ] Rewrite content service
  - [ ] Improve clarity service
  - [ ] Summarize service
  - [ ] Generate SEO metadata service
  - [ ] Inline suggestions service
  - [ ] Tests

- [ ] **AI Endpoints**
  - [ ] POST /api/v1/ai/rewrite
  - [ ] POST /api/v1/ai/improve
  - [ ] POST /api/v1/ai/summarize
  - [ ] POST /api/v1/ai/seo
  - [ ] POST /api/v1/ai/suggest
  - [ ] Rate limiting for AI endpoints
  - [ ] Tests

- [ ] **Cost Tracking**
  - [ ] AIRequest model
  - [ ] Track tokens and costs
  - [ ] Usage analytics per account
  - [ ] Tests

---

### **Phase 6: Semantic Search (Weeks 9-10)**

**Goal:** Vector embeddings and semantic search

- [ ] **pgvector Setup**
  - [ ] Enable pgvector extension
  - [ ] Embedding model
  - [ ] Vector indexes
  - [ ] Tests

- [ ] **Embedding Generation**
  - [ ] OpenAI embeddings adapter
  - [ ] GenerateEmbeddingService
  - [ ] GenerateEmbeddingJob (async)
  - [ ] Trigger on post create/update
  - [ ] Content hashing to avoid re-embedding
  - [ ] Tests

- [ ] **Semantic Search**
  - [ ] SemanticSearchService
  - [ ] GET /api/v1/search/semantic
  - [ ] Related posts recommendation
  - [ ] Tests

- [ ] **Full-Text Search**
  - [ ] PostgreSQL full-text search
  - [ ] GET /api/v1/search
  - [ ] Hybrid search (full-text + semantic)
  - [ ] Tests

---

### **Phase 7: Analytics Engine (Week 11)**

**Goal:** Track and report engagement

- [ ] **Page View Tracking**
  - [ ] PageView model
  - [ ] POST /api/v1/analytics/pageviews
  - [ ] Anonymized visitor tracking
  - [ ] Batch insert optimization
  - [ ] Tests

- [ ] **Analytics Queries**
  - [ ] Popular posts query
  - [ ] Timeline analytics query
  - [ ] Traffic sources query
  - [ ] Engagement metrics calculation
  - [ ] Tests

- [ ] **Analytics Endpoints**
  - [ ] GET /api/v1/analytics/stats
  - [ ] GET /api/v1/analytics/popular
  - [ ] GET /api/v1/analytics/timeline
  - [ ] Tests

- [ ] **Materialized Views (Optional)**
  - [ ] Daily engagement metrics
  - [ ] Refresh strategy
  - [ ] Tests

---

### **Phase 8: AI Image Generation (Week 12)**

**Goal:** Auto-generate cover images

- [ ] **Image Generation Service**
  - [ ] Replicate API adapter
  - [ ] Generate image from post title/summary
  - [ ] GenerateCoverImageJob (async)
  - [ ] Tests

- [ ] **Image Endpoints**
  - [ ] POST /api/v1/ai/cover_image
  - [ ] Tests

- [ ] **File Storage Integration** (Deferred for now)
  - [ ] ActiveStorage setup
  - [ ] S3/R2 configuration
  - [ ] Presigned URL uploads
  - [ ] Tests

---

## ✅ **Pre-Deployment Checklist**

### **🔐 Security**

- [ ] All secrets in Rails credentials (not ENV vars in code)
- [ ] JWT secret key strong (256-bit)
- [ ] BCrypt cost factor set to 12
- [ ] CORS configured for production domains only
- [ ] Rate limiting enabled (Rack::Attack)
- [ ] SQL injection prevention verified
- [ ] XSS prevention verified
- [ ] CSRF not needed (API-only, stateless)
- [ ] Security headers configured
- [ ] Brakeman security scan passes
- [ ] Bundler audit passes
- [ ] SSL/TLS enforced in production
- [ ] Sensitive data encrypted at rest

### **🗄️ Database**

- [ ] Database migrations tested
- [ ] Database indexes reviewed and optimized
- [ ] Foreign key constraints in place
- [ ] UUIDs used for primary keys
- [ ] Tenant isolation tested thoroughly
- [ ] pgvector extension enabled
- [ ] Connection pool configured
- [ ] Backup strategy in place
- [ ] Database credentials secured

### **🔑 Authentication & Authorization**

- [ ] JWT expiration times appropriate
- [ ] Refresh token rotation working
- [ ] Token revocation working
- [ ] Pundit policies complete
- [ ] Authorization tests passing
- [ ] Multi-tenant isolation verified
- [ ] Account switching tested
- [ ] Password reset flow tested

### **📡 API**

- [ ] All endpoints documented in OpenAPI spec
- [ ] JSON:API format consistent
- [ ] Error responses standardized
- [ ] HTTP status codes correct
- [ ] Pagination working
- [ ] Filtering working
- [ ] Sorting working
- [ ] Including relationships working
- [ ] Sparse fieldsets working
- [ ] API versioning in place
- [ ] Swagger UI accessible
- [ ] Redoc accessible
- [ ] Rate limiting tested

### **🤖 AI Features**

- [ ] LLM API keys secured
- [ ] Error handling for API failures
- [ ] Retry logic implemented
- [ ] Rate limiting for AI endpoints
- [ ] Cost tracking working
- [ ] Usage quotas enforced
- [ ] VCR cassettes recorded
- [ ] AI tests passing

### **🔍 Search**

- [ ] pgvector indexes created
- [ ] Embedding generation working
- [ ] Semantic search tested
- [ ] Full-text search tested
- [ ] Search performance acceptable

### **📊 Analytics**

- [ ] Page view tracking working
- [ ] Analytics queries performant
- [ ] Materialized views (if used) refreshing
- [ ] Analytics tests passing

### **⚙️ Background Jobs**

- [ ] Sidekiq configured
- [ ] Redis connected
- [ ] All jobs tested
- [ ] Job retry logic appropriate
- [ ] Dead job queue monitored
- [ ] Sidekiq web UI secured
- [ ] Scheduled jobs (cron) configured

### **✉️ Email**

- [ ] SendGrid configured
- [ ] Email templates tested
- [ ] Unsubscribe links working
- [ ] Email deliverability tested
- [ ] SPF, DKIM, DMARC configured

### **🧪 Testing**

- [ ] All tests passing
- [ ] Test coverage > 80%
- [ ] Request specs for all endpoints
- [ ] Model specs with Shoulda Matchers
- [ ] Policy specs for authorization
- [ ] Service specs for business logic
- [ ] Job specs for background jobs
- [ ] Contract tests between engines
- [ ] Integration tests for critical flows
- [ ] VCR cassettes for external APIs

### **📝 Code Quality**

- [ ] RuboCop passes (no offenses)
- [ ] Code reviewed
- [ ] No obvious code smells
- [ ] DRY principles followed
- [ ] SOLID principles followed
- [ ] Rails best practices followed
- [ ] Comments for complex logic

### **🚀 Deployment**

- [ ] Deployment platform chosen (Render/Fly/GCP)
- [ ] Environment variables configured
- [ ] Database provisioned
- [ ] Redis provisioned
- [ ] Health check endpoint (/health)
- [ ] Dockerfile tested (if containerized)
- [ ] CI/CD pipeline configured
- [ ] Monitoring configured
- [ ] Error tracking configured (Sentry/Rollbar)
- [ ] Logging configured (structured JSON)
- [ ] Performance monitoring configured
- [ ] Uptime monitoring configured

### **📖 Documentation**

- [ ] README.md complete
- [ ] ARCHITECTURE.md complete
- [ ] API_DESIGN.md complete
- [ ] AUTH_FLOW.md complete
- [ ] MULTI_TENANCY.md complete
- [ ] DATABASE_SCHEMA.md complete
- [ ] DEVELOPMENT.md complete (setup instructions)
- [ ] CONTRIBUTING.md (if open source)
- [ ] LICENSE file present
- [ ] CHANGELOG.md initialized

### **🎨 Frontend Integration**

- [ ] CORS configured for frontend domain
- [ ] OpenAPI spec accessible to frontend
- [ ] TypeScript types generated (or instructions provided)
- [ ] Authentication flow documented for frontend
- [ ] Example API requests documented
- [ ] Websocket/SSE support (if needed)

---

## 📅 **Timeline Summary**

| Phase | Duration | Focus |
|-------|----------|-------|
| Phase 1 | Weeks 1-2 | Foundation & Auth |
| Phase 2 | Weeks 3-4 | Publishing Engine |
| Phase 3 | Week 5 | API Documentation |
| Phase 4 | Week 6 | Background Jobs & Email |
| Phase 5 | Weeks 7-8 | AI Assistant |
| Phase 6 | Weeks 9-10 | Semantic Search |
| Phase 7 | Week 11 | Analytics |
| Phase 8 | Week 12 | AI Images |
| **Total** | **12 weeks** | **To MVP** |

---

## 🎯 **Definition of Done (Per Phase)**

A phase is complete when:
- [ ] All features implemented
- [ ] All tests passing
- [ ] Code reviewed
- [ ] Documentation updated
- [ ] OpenAPI spec updated
- [ ] No known bugs
- [ ] Performance acceptable
- [ ] Security reviewed

---

## 🚦 **Go/No-Go Criteria for Production**

✅ **GO if:**
- All pre-deployment checklist items complete
- Test coverage > 80%
- Security scan passes
- Performance benchmarks met
- Documentation complete
- CI/CD pipeline green
- Staging environment tested

🛑 **NO-GO if:**
- Security vulnerabilities exist
- Critical bugs present
- Tests failing
- Performance issues
- Documentation incomplete

---

## 📊 **Success Metrics**

**Technical:**
- API response time < 200ms (p95)
- Background job processing time < 5s (p95)
- Test coverage > 80%
- Zero security vulnerabilities
- Uptime > 99.9%

**Product:**
- API can handle 100 req/sec
- AI features respond < 10s
- Semantic search < 1s
- Database queries optimized (< 100ms)

---

## 🔄 **Post-Launch Iterations**

**Phase 9: Enhancements**
- Webhook system for integrations
- GraphQL API (optional)
- Advanced analytics
- Team collaboration features
- Content import/export
- Custom domains per blog
- Theme customization API

**Phase 10: Scaling**
- Database read replicas
- Redis cluster
- CDN integration
- Caching strategy optimization
- Background job optimization
- Kubernetes deployment (if needed)

---

## 📚 **Related Documentation**

* `OVERVIEW.md` — Project overview
* `ARCHITECTURE.md` — System architecture
* `API_DESIGN.md` — API design and endpoints
* `AUTH_FLOW.md` — Authentication flows
* `MULTI_TENANCY.md` — Multi-tenant implementation
* `DATABASE_SCHEMA.md` — Database schema
* `DEVELOPMENT.md` — Local setup (to be created)

---

## 🎓 **Learning Goals**

This project aims to teach:
- [ ] Rails 8 API-only architecture
- [ ] Multi-tenant SaaS patterns
- [ ] JWT authentication best practices
- [ ] Hexagonal architecture in Rails
- [ ] Rails Engines for modularity
- [ ] JSON:API specification
- [ ] OpenAPI documentation
- [ ] AI/LLM integration
- [ ] Vector embeddings and semantic search
- [ ] Background job processing
- [ ] Testing strategies for APIs
- [ ] Deployment and DevOps practices

---

**Next Steps:** Begin Phase 1 by setting up the Rails project and implementing authentication.
