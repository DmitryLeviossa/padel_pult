# Ruby on Rails Project

This is a Ruby on Rails application following Rails conventions.

## Project Structure

- `app/models/` - ActiveRecord models
- `app/controllers/` - Request handlers
- `app/views/` - ERB/Slim templates
- `app/services/` - Service objects
- `app/jobs/` - Background jobs
- `db/migrate/` - Database migrations
- `spec/` - Tests

## Conventions

- Follow Rails conventions (CoC)
- Use RESTful routing
- Fat models, skinny controllers
- Extract complex logic to service objects
- Use concerns for shared model behavior

## Database

- Always use migrations for schema changes
- Never edit schema.rb directly
- Use strong_migrations for safe deployments
- Index foreign keys and frequently queried columns

## Testing

- Write request specs for API endpoints
- Write model specs for validations and scopes
- Use FactoryBot for test data
- Use RSpec as configured

## GIT

- Write clear and not super detailed description to PR
- Before creation of PR check that new functional is covered with rspecs
- Commit messages should start with feat/fix and short description of changes, example 'feat: created schedules functionality'

## Commands

- `bin/rails s` - Start development server
- `bin/rails c` - Open Rails console
- `bundle exec rspec` - Run tests
- `bin/rails db:migrate` - Run migrations
- `bin/rubocop` - Run linter
