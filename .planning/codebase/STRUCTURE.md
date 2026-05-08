---
title: Directory Structure
focus: arch
last_mapped: 2026-05-08
---

# Directory Structure

## Top-Level Layout

```
padel_pult/
├── app/                    # Application code
├── bin/                    # Executables (rails, bundle, rubocop, etc.)
├── config/                 # App configuration
├── db/                     # Schema + migrations
├── test/                   # Rails Minitest suite
├── .planning/              # GSD planning artifacts
├── .github/                # GitHub Actions CI
├── Gemfile / Gemfile.lock  # Ruby dependencies
├── Dockerfile              # Container build
├── .rubocop.yml            # Linter config
└── .ruby-version           # Ruby version pin (3.3.x)
```

## app/ Breakdown

```
app/
├── assets/
│   ├── builds/             # Compiled CSS output (application.css)
│   ├── images/             # Static images
│   └── stylesheets/
│       └── application.bootstrap.scss  # Bootstrap + custom styles
├── controllers/
│   ├── application_controller.rb       # Base: auth + Devise params
│   ├── dashboard_controller.rb         # Root page
│   ├── leagues_controller.rb           # Leagues CRUD
│   ├── tournaments_controller.rb       # Tournaments CRUD
│   └── users_controller.rb             # Users index
├── helpers/
│   ├── application_helper.rb
│   ├── leagues_helper.rb
│   └── tournaments_helper.rb
├── javascript/
│   ├── application.js                  # Importmap entrypoint
│   └── controllers/
│       ├── application.js              # Stimulus setup
│       ├── hello_controller.js         # Default stub
│       └── index.js                    # Auto-loader
├── jobs/
│   └── application_job.rb              # Base job class (stub)
├── mailers/
│   └── application_mailer.rb           # Base mailer class (stub)
├── models/
│   ├── application_record.rb           # Base AR class
│   ├── league.rb
│   ├── league_user.rb                  # Join model
│   ├── pair.rb
│   ├── tournament.rb
│   └── user.rb                         # Devise user
└── views/
    ├── layouts/
    │   ├── application.html.slim       # Main layout
    │   ├── mailer.html.slim
    │   └── mailer.text.slim
    ├── dashboard/
    │   └── index.html.slim
    ├── devise/                         # All Devise views (Slim)
    ├── leagues/
    │   ├── index.html.slim
    │   ├── show.html.slim
    │   ├── new.html.slim
    │   └── edit.html.slim
    ├── tournaments/
    │   ├── index.html.slim
    │   ├── show.html.slim
    │   └── new.html.slim
    ├── users/
    │   └── index.html.slim
    └── pwa/
        ├── manifest.json.erb
        └── service-worker.js
```

## config/ Key Files

```
config/
├── routes.rb               # All routes — Devise + resources
├── database.yml            # PostgreSQL config
├── application.rb          # App-level config
├── environments/           # dev/test/prod configs
├── initializers/           # Boot-time setup
└── locales/                # i18n files
```

## db/ Key Files

```
db/
├── schema.rb               # Authoritative schema (Rails 8.0, PostgreSQL)
└── migrate/                # Migration history
```

## test/ Layout

```
test/
├── test_helper.rb          # Minitest config + fixtures :all
├── controllers/            # Controller integration tests (stubs only)
├── models/                 # Model unit tests (stubs only)
├── fixtures/               # YAML fixtures for all tables
│   ├── users.yml
│   ├── leagues.yml
│   ├── league_users.yml
│   ├── tournaments.yml
│   └── pairs.yml
├── system/                 # System tests (empty)
└── integration/            # Integration tests (empty)
```

## Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Models | PascalCase singular | `LeagueUser` |
| Controllers | PascalCase plural + Controller | `LeaguesController` |
| Views | snake_case, folder per controller | `leagues/show.html.slim` |
| Migrations | timestamp prefix | `20260508171340_...` |
| DB tables | snake_case plural | `league_users` |
| DB columns | snake_case | `owner_id`, `start_date` |
| Routes | RESTful resources | `resources :leagues` |

## Key File Locations

| Purpose | Path |
|---------|------|
| Routes | `config/routes.rb` |
| DB schema | `db/schema.rb` |
| App layout | `app/views/layouts/application.html.slim` |
| Auth base | `app/controllers/application_controller.rb` |
| Base model | `app/models/application_record.rb` |
| Bootstrap entry | `app/assets/stylesheets/application.bootstrap.scss` |
| JS entry | `app/javascript/application.js` |
