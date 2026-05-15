---
title: Testing
focus: quality
last_mapped: 2026-05-08
---

# Testing

## Framework

**Rails Minitest** (default Rails 8 test suite). Note: `CLAUDE.md` references RSpec, but the actual test suite uses Minitest — no `spec/` directory exists.

- Test runner: `bin/rails test`
- System tests: `bin/rails test:system` (Capybara + Selenium, configured in `test/application_system_test_case.rb`)
- Parallelization: enabled via `parallelize(workers: :number_of_processors)` in `test/test_helper.rb`

## Test Structure

```
test/
├── test_helper.rb              # Base config — loads fixtures :all, parallelizes
├── controllers/
│   ├── leagues_controller_test.rb      # Stub (no tests)
│   └── tournaments_controller_test.rb  # Stub (no tests)
├── models/
│   ├── league_test.rb          # Stub (no tests)
│   ├── league_user_test.rb     # Stub (no tests)
│   ├── pair_test.rb            # Stub (no tests)
│   ├── tournament_test.rb      # Stub (no tests)
│   └── user_test.rb            # Stub (no tests)
├── fixtures/
│   ├── users.yml
│   ├── leagues.yml
│   ├── league_users.yml
│   ├── tournaments.yml
│   └── pairs.yml
├── system/                     # Empty (no system tests written)
└── integration/                # Empty
```

## Coverage State

**All test files are scaffolded stubs — zero actual tests written.**

Every model and controller test file contains only the commented-out default example:
```ruby
# test "the truth" do
#   assert true
# end
```

## Fixtures

Fixtures exist for all domain tables (`users`, `leagues`, `league_users`, `tournaments`, `pairs`). They are loaded globally via `fixtures :all` in `test_helper.rb`. No factory library (FactoryBot) is installed.

## What Needs Testing (Gaps)

| Area | Priority | Notes |
|------|----------|-------|
| `LeaguesController` | High | Authorization logic (owner checks), create/update flows |
| `TournamentsController` | High | League-scoped creation, authorization |
| `User#full_name` | Medium | Edge cases: nil first/last name |
| `Pair#score` | Medium | Combined LeagueUser score aggregation |
| `LeagueUser` delegation | Low | `full_name` delegate |
| Authentication flow | High | Devise login/logout/registration |

## Test Configuration

- `test/test_helper.rb`: `ENV["RAILS_ENV"] ||= "test"`, loads fixtures, parallel workers
- `test/application_system_test_case.rb`: Capybara system test base class
- Database: PostgreSQL (same adapter as production, separate test DB)

## Running Tests

```bash
bundle exec rails test           # All unit + integration tests
bundle exec rails test:system    # System tests
bundle exec rails test test/models/user_test.rb  # Single file
```
