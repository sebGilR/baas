# baas — deploy_plan.md

This file is the practical deployment plan for the `baas` Rails API backend.

## Target architecture

- **Rails API** on **Fly.io** (always-on, no sleeping)
- **Sidekiq worker** on **Fly.io** (separate process group)
- **Postgres** on **DigitalOcean Managed Postgres (NYC)** via `DATABASE_URL`
- **Redis** on **Upstash** via `REDIS_URL` (Sidekiq + optional cache)
- **Frontend** on **Vercel** (Next.js) with ISR + on-demand revalidation

## Prerequisites

- Fly app created for the backend (e.g. `baas-api`)
- DigitalOcean Postgres created (NYC) and reachable from Fly
- Upstash Redis created (close to Fly region if possible)
- Vercel project deployed (see `engineeringwithsebs/deploy_plan.md`)

## Fly process model

- **web**: Rails server
- **worker**: Sidekiq (`bundle exec sidekiq -C config/sidekiq.yml`)

## Fly configuration checklist

1. **Create app**
   - `fly apps create baas-api`
2. **Set secrets**
   - `RAILS_MASTER_KEY`
   - `DATABASE_URL`
   - `REDIS_URL`
   - `RAILS_LOG_LEVEL=info`
   - `CORS_ORIGINS=https://engineeringwithsebs.com,https://www.engineeringwithsebs.com`
   - `VERCEL_REVALIDATE_URL=https://engineeringwithsebs.com/api/revalidate`
   - `VERCEL_REVALIDATE_TOKEN=...` (must match Vercel)
3. **Always-on (no sleeping)**
   - Configure Fly with `min_machines_running = 1` and `auto_stop_machines = "off"`
4. **Health check**
   - Use `GET /up` (Rails health) or `GET /api/v1/health` (API health)
5. **Migrations on deploy**
   - Run `bin/rails db:prepare` during release
6. **Resource sizing (starting point)**
   - `web`: 512MB
   - `worker`: 256MB
7. **Runtime tuning**
   - `WEB_CONCURRENCY=1`
   - `RAILS_MAX_THREADS=5`

## Verification checklist (post-deploy)

- `GET /up` returns 200
- `GET /api/v1/health` returns 200
- Can log in and publish a post from the dashboard
- After publish/unpublish, Next public pages update within ~seconds (revalidation succeeds)

