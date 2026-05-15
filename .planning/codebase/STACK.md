# Technology Stack

**Analysis Date:** 2026-05-08

## Languages

**Primary:**
- Ruby 3.3.6 - Application code (`app/`, `config/`, `lib/`)
- HTML/Slim 5.2.1 - View templates (`app/views/**/*.html.slim`)

**Secondary:**
- JavaScript (ESM) - Frontend interactivity (`app/javascript/`)
- SCSS - Stylesheets via Bootstrap (`app/assets/stylesheets/`)
- SQL - PostgreSQL queries via ActiveRecord

## Runtime

**Environment:**
- Ruby 3.3.6 (pinned in `.ruby-version`)
- Node.js 21.7.3 (pinned in `.node-version`, used for CSS build only)

**Package Manager:**
- Bundler 2.5.23 (Ruby gems)
- Yarn 1.22.22 (Node packages for CSS pipeline only)
- Lockfiles: `Gemfile.lock` present, `yarn.lock` present

## Frameworks

**Core:**
- Ruby on Rails 8.0.5 - Full-stack web framework (`config/application.rb`)

**Authentication:**
- Devise 5.0.3 - User authentication (`app/models/user.rb`, `app/views/devise/`)

**Frontend:**
- Hotwire Turbo 2.0.23 - SPA-like navigation without full page reloads
- Stimulus 1.3.4 - Modest JavaScript framework (`app/javascript/controllers/`)
- Bootstrap 5.3.3 - CSS framework (`package.json`, `app/assets/stylesheets/application.bootstrap.scss`)
- Bootstrap Icons 1.11.3 - Icon library

**Testing:**
- Minitest - Built-in Rails test framework (`test/`)
- Capybara 3.40.0 - System/integration test helpers
- Selenium WebDriver 4.43.0 - Browser automation for system tests

**Build/Dev:**
- Propshaft 1.3.2 - Asset pipeline (replaces Sprockets)
- cssbundling-rails 1.4.3 - CSS build orchestration
- importmap-rails 2.2.3 - JavaScript import maps (no bundler needed)
- Sass 1.77.0 - SCSS compiler (Node dev dependency)
- Autoprefixer 10.4.19 + PostCSS 8.4.38 - CSS post-processing
- Bootsnap 1.24.3 - Boot time caching

## Key Dependencies

**Critical:**
- `pg` 1.6.3 - PostgreSQL adapter for ActiveRecord (`Gemfile`)
- `devise` 5.0.3 - Authentication; used by `User` model and all controllers via `before_action :authenticate_user!`
- `slim-rails` 4.0.0 - Slim template engine; all views use `.html.slim` extension
- `jbuilder` 2.14.1 - JSON view builder (available but not yet heavily used)

**Infrastructure:**
- `solid_queue` 1.4.0 - Database-backed background job queue (PostgreSQL-based)
- `solid_cache` 1.0.10 - Database-backed Rails cache store
- `solid_cable` 3.0.12 - Database-backed Action Cable adapter (dev); Redis in production
- `thruster` 0.1.20 - HTTP/2 asset caching proxy, wraps Puma in production
- `kamal` 2.11.0 - Docker deployment tool (`bin/kamal`)

**Development:**
- `annotaterb` 4.22.0 - Auto-annotates models with schema info (`app/models/*.rb` headers)
- `brakeman` 8.0.4 - Static security analysis
- `rubocop-rails-omakase` 1.1.0 - Rails-style linter
- `web-console` 4.3.0 - In-browser console for development errors

## Configuration

**Environment:**
- `config/database.yml` - PostgreSQL connections; production password via `ENV["PADEL_PULT_DATABASE_PASSWORD"]`
- `config/credentials.yml.enc` - Encrypted credentials (decrypted with `config/master.key`)
- `RAILS_MAX_THREADS` - Puma thread count (default: 3) and DB pool size
- `PORT` - Puma port (default: 3000)
- `SOLID_QUEUE_IN_PUMA` - Run Solid Queue supervisor inside Puma process
- `RAILS_LOG_LEVEL` - Production log level (default: info)
- `REDIS_URL` - Required in production for Action Cable (default: `redis://localhost:6379/1`)

**Build:**
- `config/importmap.rb` - JavaScript import map pins
- `package.json` - CSS build scripts (`yarn build:css`)
- `.rubocop.yml` - Inherits `rubocop-rails-omakase` ruleset with no overrides

## Platform Requirements

**Development:**
- Ruby 3.3.6, Node.js 21.7.3, PostgreSQL, Yarn 1.22.22
- Dev server: `bin/dev` runs `bin/rails server` + `yarn watch:css` via `Procfile.dev`

**Production:**
- Docker container (`Dockerfile`) based on `ruby:3.3.6-slim`
- System packages: `libjemalloc2`, `libvips`, `postgresql-client`
- Server: Thruster (HTTP/2 proxy) → Puma → Rails
- jemalloc enabled at runtime via `bin/docker-entrypoint`
- Deployment: Kamal v2 (`bin/kamal`)
- Production databases: 4 separate PostgreSQL databases (primary, cache, queue, cable)

---

*Stack analysis: 2026-05-08*
