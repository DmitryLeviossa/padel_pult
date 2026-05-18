---
title: Architecture
focus: arch
last_mapped: 2026-05-08
---

# Architecture

## Pattern

Standard **MVC Rails monolith** with Devise for authentication.

- **Pattern:** Model-View-Controller (Rails conventions)
- **Authentication layer:** Devise (`before_action :authenticate_user!` globally in ApplicationController)
- **Authorization:** Manual owner checks in controllers (no Pundit/CanCanCan)
- **Asset pipeline:** Propshaft + Tailwind CSS + Bootstrap via Importmaps
- **Frontend:** Slim templates + Stimulus JS (default Rails 8 setup)

## Layers

```
Browser
  └── Rails Router (config/routes.rb)
        └── Controllers (app/controllers/)
              ├── ApplicationController — auth + Devise param config
              ├── DashboardController  — home page, aggregates user data
              ├── LeaguesController    — CRUD leagues, owner authorization
              ├── TournamentsController — CRUD tournaments (scoped to league)
              └── UsersController      — index only
        └── Models (app/models/)
              ├── User                — Devise auth, full_name helper, photo attachment
              ├── League              — owned by User, has tournaments + members, logo attachment
              ├── LeagueUser          — join table User↔League, tracks score
              ├── Tournament          — belongs to League, has pairs, type/status columns
              └── Pair                — two LeagueUsers in a tournament, computes combined score
        └── Views (app/views/)
              ├── layouts/application — Slim layout with Bootstrap nav
              ├── dashboard/          — index showing user's leagues/tournaments
              ├── leagues/            — index, show, new, edit
              ├── tournaments/        — index, show, new
              └── devise/             — all auth views in Slim
```

## Data Flow

1. Request hits router → controller action
2. Controller queries models (ActiveRecord), sets instance variables
3. View renders with instance variables
4. No service objects or serializers currently — all logic in models/controllers

## Domain Model

```
User ──< LeagueUser >── League
                           │
                        Tournament
                           │
                   Pair (player1: LeagueUser, player2: LeagueUser)
```

- A `User` can be a member of multiple `League`s via `LeagueUser` join (which tracks their score)
- A `League` has one `owner` (User) and many tournament entries
- A `Tournament` belongs to a `League` and contains `Pair`s
- A `Pair` links two `LeagueUser` records within a `Tournament`
- `Tournament.type` uses `self.inheritance_column = nil` to avoid STI

## Entry Points

- **HTTP:** `config/routes.rb` — Devise routes + RESTful resources
- **Root route:** `dashboard#index` (requires authentication)
- **Health check:** `GET /up`
- **PWA:** `app/views/pwa/` — manifest.json + service worker

## Key Abstractions

| Abstraction | Location | Purpose |
|-------------|----------|---------|
| `ApplicationController` | `app/controllers/application_controller.rb` | Global auth + Devise params |
| `ApplicationRecord` | `app/models/application_record.rb` | Base model class |
| `LeagueUser` | `app/models/league_user.rb` | Join model; delegates `full_name` to User |
| `Pair#score` | `app/models/pair.rb` | Aggregates player1 + player2 scores |

## Active Storage

Both `User` (photo) and `League` (logo) use Active Storage attachments. Configured but storage backend not confirmed (likely local disk in dev).
