# External Integrations

**Analysis Date:** 2026-05-08

## APIs & External Services

No third-party external API integrations detected. The application is self-contained.

## Data Storage

**Databases:**
- PostgreSQL (primary) - All application data
  - Connection (dev): OS default user, database `padel_pult_development`
  - Connection (production): `ENV["PADEL_PULT_DATABASE_PASSWORD"]`, username `padel_pult`, database `padel_pult_production`
  - Connection (production cache): database `padel_pult_production_cache`, migrations at `db/cache_migrate`
  - Connection (production queue): database `padel_pult_production_queue`, migrations at `db/queue_migrate`
  - Connection (production cable): database `padel_pult_production_cable`, migrations at `db/cable_migrate`
  - Client: ActiveRecord with `pg` gem 1.6.3
  - Pool size: controlled by `ENV["RAILS_MAX_THREADS"]` (default 5)

**File Storage:**
- Active Storage configured (`db/schema.rb` contains `active_storage_*` tables)
- Current storage: local disk (`config/storage.yml` - `local` and `test` services)
- Production storage: local disk (`config/environments/production.rb` - `config.active_storage.service = :local`)
- S3, GCS, Azure options are commented out in `config/storage.yml` — not active
- `User` model uses `has_one_attached :photo` (`app/models/user.rb`)

**Caching:**
- Development/Test: in-process Rails cache (not Solid Cache in those environments)
- Production: Solid Cache backed by `padel_pult_production_cache` PostgreSQL database

## Authentication & Identity

**Auth Provider:**
- Devise 5.0.3 — self-hosted, no OAuth providers configured
  - Modules active: `:database_authenticatable`, `:registerable`, `:recoverable`, `:rememberable`, `:validatable`
  - Modules inactive (commented out): `:confirmable`, `:lockable`, `:timeoutable`, `:trackable`, `:omniauthable`
  - Implementation: `app/models/user.rb`, routes via `devise_for :users` in `config/routes.rb`
  - Views: `app/views/devise/` (sessions, registrations, passwords, confirmations, unlocks)
  - Password hashing: bcrypt 3.1.22 (Devise dependency)

## Monitoring & Observability

**Error Tracking:**
- Not detected — no Sentry, Rollbar, Honeybadger, or similar gem present

**Logs:**
- Development: default Rails logger to file (`log/development.log`)
- Production: `ActiveSupport::TaggedLogging` to STDOUT, tagged with `request_id`, level controlled by `ENV["RAILS_LOG_LEVEL"]` (default `info`)
- Health check endpoint: `GET /up` (silenced from production logs)

## CI/CD & Deployment

**Hosting:**
- Docker container deployment via Kamal v2 (`bin/kamal`, `Dockerfile`)
- Production server: Thruster → Puma on port 80
- SSL terminated at application level (`config.assume_ssl = true`, `config.force_ssl = true`)

**CI Pipeline:**
- GitHub Actions (`.github/workflows/ci.yml`) on PRs and pushes to `main`
- Jobs:
  - `scan_ruby` — Brakeman security scan (`bin/brakeman --no-pager`)
  - `scan_js` — importmap JavaScript dependency audit (`bin/importmap audit`)
  - `lint` — RuboCop style check (`bin/rubocop -f github`)
  - `test` — Full test suite with PostgreSQL service container (`bin/rails db:test:prepare test test:system`)
- Dependabot configured for daily Bundler and GitHub Actions dependency updates (`.github/dependabot.yml`)
- Failed system test screenshots uploaded as CI artifacts

## Background Jobs

**Job Queue:**
- Solid Queue 1.4.0 backed by `padel_pult_production_queue` PostgreSQL database
- In development: can run in-process via Puma plugin (`SOLID_QUEUE_IN_PUMA=1`)
- Base job class: `app/jobs/application_job.rb`
- No custom job classes exist yet

## Real-Time / WebSockets

**Action Cable:**
- Development: `async` adapter (in-process, `config/cable.yml`)
- Test: `test` adapter
- Production: Redis adapter — `ENV["REDIS_URL"]` (default `redis://localhost:6379/1`)
- Note: Redis is the only runtime dependency not backed by PostgreSQL in production. The CI workflow has Redis commented out, suggesting it is not used in tests.

## Email

**Mailer:**
- Action Mailer configured with Devise mailer views at `app/views/devise/mailer/`
- Production host: `example.com` (placeholder — not yet configured for real domain)
- SMTP settings: commented out in `config/environments/production.rb`; credentials would come from `Rails.application.credentials.dig(:smtp, ...)`
- No real mail delivery is configured for production yet

## Environment Configuration

**Required environment variables (production):**
- `PADEL_PULT_DATABASE_PASSWORD` — Primary PostgreSQL password
- `RAILS_MASTER_KEY` — Decrypts `config/credentials.yml.enc`
- `REDIS_URL` — Action Cable Redis connection (default fallback available but not reliable in production)

**Optional environment variables:**
- `RAILS_MAX_THREADS` — Puma threads and DB pool size (default: 3 in Puma, 5 in DB)
- `PORT` — Puma listen port (default: 3000; Thruster exposes 80)
- `SOLID_QUEUE_IN_PUMA` — Embed job worker in web process
- `RAILS_LOG_LEVEL` — Production log verbosity (default: info)

**Secrets location:**
- Encrypted: `config/credentials.yml.enc` (opened with `bin/rails credentials:edit`)
- Key file: `config/master.key` (gitignored, must be provided at deploy time)

## Webhooks & Callbacks

**Incoming:**
- None detected

**Outgoing:**
- None detected

---

*Integration audit: 2026-05-08*
