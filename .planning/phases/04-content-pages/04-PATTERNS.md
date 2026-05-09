# Phase 4: Content Pages - Pattern Map

**Mapped:** 2026-05-09
**Files analyzed:** 13 (12 to modify, 1 already complete)
**Analogs found:** 13 / 13

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `app/views/dashboard/index.html.slim` | template | request-response | `app/views/leagues/index.html.slim` (card grid pattern) + `app/views/leagues/show.html.slim` (card-body structure) | role-match |
| `app/views/devise/sessions/new.html.slim` | template | request-response | `app/views/devise/passwords/new.html.slim` (identical structure) | exact |
| `app/views/devise/registrations/new.html.slim` | template | request-response | `app/views/devise/sessions/new.html.slim` (same card-centered scaffold) | exact |
| `app/views/devise/passwords/new.html.slim` | template | request-response | `app/views/devise/sessions/new.html.slim` | exact |
| `app/views/devise/passwords/edit.html.slim` | template | request-response | `app/views/devise/sessions/new.html.slim` | exact |
| `app/views/devise/registrations/edit.html.slim` | template | request-response | `app/views/devise/registrations/new.html.slim` (same scaffold, wider col-md-6) | exact |
| `app/views/devise/confirmations/new.html.slim` | template | request-response | `app/views/devise/passwords/new.html.slim` | exact |
| `app/views/devise/unlocks/new.html.slim` | template | request-response | `app/views/devise/passwords/new.html.slim` | exact |
| `app/views/leagues/index.html.slim` | template | request-response | `app/views/leagues/show.html.slim` (same container, card grid) | exact |
| `app/views/leagues/new.html.slim` | template | request-response | `app/views/tournaments/new.html.slim` (form template with container) | role-match |
| `app/views/leagues/edit.html.slim` | template | request-response | `app/views/tournaments/new.html.slim` (form template with container) | role-match |
| `app/views/tournaments/index.html.slim` | template | request-response | `app/views/leagues/show.html.slim` (table structure, `.container.py-4`) | role-match |
| `app/views/users/index.html.slim` | template | request-response | `app/views/leagues/show.html.slim` (table with avatar partial, same thead pattern) | exact |

---

## Pattern Assignments

### `app/views/dashboard/index.html.slim` (template, request-response)

**Analog:** `app/views/leagues/index.html.slim` (card grid) + `app/views/leagues/show.html.slim` (card structure)

**Change required:** Drop `.shadow-sm` from 3 `.card` elements; add stat-card row above `.row.g-4`; empty states already use `p.text-muted.mb-0`

**Current structure** (`app/views/dashboard/index.html.slim` lines 1-49 — full file):
```slim
.container.py-4
  h1.mb-4 Добро пожаловать, #{current_user.full_name}!

  .row.g-4
    .col-md-6
      .card.shadow-sm.h-100         ← drop .shadow-sm
        .card-header.fw-semibold Мои лиги
        .card-body
          - if @my_leagues.any?
            ul.list-group.list-group-flush
              - @my_leagues.each do |league|
                li.list-group-item.d-flex.justify-content-between.align-items-center
                  = link_to league.name, league_path(league)
                  span.badge.bg-secondary= league.tournaments.count
          - else
            p.text-muted.mb-0 Вы ещё не создали ни одной лиги.
        .card-footer
          = link_to "Все лиги", leagues_path, class: "btn btn-sm btn-outline-primary me-2"
          = link_to "Создать лигу", new_league_path, class: "btn btn-sm btn-primary"

    .col-md-6
      .card.shadow-sm.h-100         ← drop .shadow-sm
        .card-header.fw-semibold Мои турниры
        ...
        .card-footer
          = link_to "Все турниры", tournaments_path, class: "btn btn-sm btn-outline-primary"

  .mt-5
    h5.mb-3 Последние лиги
    - if @recent_leagues.any?
      .row.row-cols-1.row-cols-md-3.g-3
        - @recent_leagues.each do |league|
          .col
            .card.shadow-sm.h-100   ← drop .shadow-sm
              .card-body
                h6.card-title= link_to league.name, league_path(league), class: "text-decoration-none stretched-link"
                p.card-text.text-muted.small= league.description
              .card-footer.text-muted.small
                | #{league.owner.full_name} · #{league.created_at.strftime("%d.%m.%Y")}
    - else
      p.text-muted Лиг пока нет.
```

**Stat-card row pattern to INSERT** (from RESEARCH.md — between `h1` and `.row.g-4`):
```slim
.row.g-3.mb-4
  .col-sm-6.col-lg-3
    .card
      .card-body.d-flex.align-items-center.gap-3
        i.bi.bi-people.fs-2.text-primary
        div
          .text-muted.small Мои лиги
          .fs-4.fw-semibold= @my_leagues.count
  .col-sm-6.col-lg-3
    .card
      .card-body.d-flex.align-items-center.gap-3
        i.bi.bi-trophy.fs-2.text-primary
        div
          .text-muted.small Мои турниры
          .fs-4.fw-semibold= @my_tournaments.count
```

**Card grid analog** — `app/views/leagues/index.html.slim` lines 7-18 (card grid with `.h-100`, no shadow):
```slim
.row.row-cols-1.row-cols-md-2.row-cols-lg-3.g-4
  - @leagues.each do |league|
    .col
      .card.h-100
        .card-body
          h5.card-title= link_to league.name, league_path(league), class: "text-decoration-none stretched-link"
          p.card-text.text-muted= league.description
        .card-footer.text-muted.small
          | Создано #{league.created_at.strftime("%d.%m.%Y")}
```

**Available controller variables** (DO NOT add others without controller change):
- `@my_leagues` — user's owned leagues
- `@my_tournaments` — user's tournaments via owned leagues
- `@recent_leagues` — 5 most recent leagues (all users)

---

### `app/views/devise/sessions/new.html.slim` (template, request-response)

**Analog:** self (drop `.shadow-sm` — identical pattern to other auth pages)

**Change required:** Line 4 — `.card.shadow-sm` → `.card`; also add `.py-4` to container

**Current file** (lines 1-27 — full file):
```slim
.container
  .row.justify-content-center.mt-5
    .col-md-5
      .card.shadow-sm     ← change to: .card
        .card-body.p-4
          h2.card-title.mb-4 Войти

          = form_for(resource, as: resource_name, url: session_path(resource_name)) do |f|
            .mb-3
              = f.label :email, class: "form-label"
              = f.email_field :email, autofocus: true, autocomplete: "email", class: "form-control"

            .mb-3
              = f.label :password, class: "form-label"
              = f.password_field :password, autocomplete: "current-password", class: "form-control"

            - if devise_mapping.rememberable?
              .mb-3.form-check
                = f.check_box :remember_me, class: "form-check-input"
                = f.label :remember_me, class: "form-check-label"

            = f.submit "Войти", class: "btn btn-primary w-100"

          hr.my-3
          .text-center.small
            = render "devise/shared/links"
```

**Auth card pattern (after change):**
```slim
.container.py-4
  .row.justify-content-center
    .col-md-5
      .card
        .card-body.p-4
          h2.card-title.mb-4 Войти
          / ... form body unchanged
```

Note: `.mt-5` on `.row` is replaced by `.py-4` on `.container` (consistent with project container convention from Phase 2). The `.row` no longer needs `.mt-5` as vertical spacing is handled by the container.

---

### `app/views/devise/registrations/new.html.slim` (template, request-response)

**Analog:** `app/views/devise/sessions/new.html.slim` (identical scaffold, wider form fields)

**Change required:** Line 1 `.container` → `.container.py-4`; line 2 `.row.justify-content-center.mt-5` → `.row.justify-content-center`; line 4 `.card.shadow-sm` → `.card`

**Current file** (lines 1-38 — full file):
```slim
.container
  .row.justify-content-center.mt-5
    .col-md-5
      .card.shadow-sm     ← change to: .card
        .card-body.p-4
          h2.card-title.mb-4 Регистрация

          = form_for(resource, as: resource_name, url: registration_path(resource_name)) do |f|
            = render "devise/shared/error_messages", resource: resource

            .row.mb-3
              .col
                = f.label :first_name, "Имя", class: "form-label"
                = f.text_field :first_name, autofocus: true, autocomplete: "given-name", class: "form-control"
              .col
                = f.label :last_name, "Фамилия", class: "form-label"
                = f.text_field :last_name, autocomplete: "family-name", class: "form-control"
            / ... remaining fields unchanged
```

---

### `app/views/devise/passwords/new.html.slim` (template, request-response)

**Analog:** `app/views/devise/sessions/new.html.slim` (identical scaffold, single email field)

**Change required:** Line 1 `.container` → `.container.py-4`; line 2 remove `.mt-5`; line 4 `.card.shadow-sm` → `.card`

**Current file** (lines 1-20 — full file):
```slim
.container
  .row.justify-content-center.mt-5
    .col-md-5
      .card.shadow-sm     ← change to: .card
        .card-body.p-4
          h2.card-title.mb-4 Забыли пароль?
          / ... form body unchanged
```

---

### `app/views/devise/passwords/edit.html.slim` (template, request-response)

**Analog:** `app/views/devise/passwords/new.html.slim` (same scaffold, different form fields)

**Change required:** Line 1 `.container` → `.container.py-4`; line 2 remove `.mt-5`; line 4 `.card.shadow-sm` → `.card`

**Current file** (lines 1-27 — full file):
```slim
.container
  .row.justify-content-center.mt-5
    .col-md-5
      .card.shadow-sm     ← change to: .card
        .card-body.p-4
          h2.card-title.mb-4 Изменить пароль
          / ... form body unchanged
```

---

### `app/views/devise/registrations/edit.html.slim` (template, request-response)

**Analog:** `app/views/devise/registrations/new.html.slim` (same scaffold, two `.card` blocks, col-md-6 instead of col-md-5)

**Change required:** Line 1 `.container` → `.container.py-4`; line 2 remove `.mt-5`; line 4 `.card.shadow-sm` → `.card`; line 49 `.card.shadow-sm.mt-3` → `.card.mt-3`

**Current file** (lines 1-54 — full file):
```slim
.container
  .row.justify-content-center.mt-5
    .col-md-6
      .card.shadow-sm     ← change to: .card
        .card-body.p-4
          h2.card-title.mb-4 Редактировать аккаунт

          = form_for(resource, as: resource_name, url: registration_path(resource_name), html: { method: :put, multipart: true }) do |f|
            = render "devise/shared/error_messages", resource: resource

            .mb-3.text-center
              = render "shared/avatar", user: resource, size: 100   ← already correct (Phase 3)
              = f.label :photo, "Фото профиля", class: "form-label d-block"
              = f.file_field :photo, accept: "image/*", class: "form-control"
            / ... remaining fields unchanged

      .card.shadow-sm.mt-3     ← change to: .card.mt-3
        .card-body.p-4
          h5.card-title.text-danger Удалить аккаунт
          p.text-muted Вы уверены, что хотите удалить аккаунт?
          = button_to "Удалить мой аккаунт", registration_path(resource_name), data: { confirm: "Вы уверены?", turbo_confirm: "Вы уверены?" }, method: :delete, class: "btn btn-danger btn-sm"
```

Note: `.card.shadow-sm.mt-3` is NOT inside the `.row.justify-content-center` block — it is a sibling after the closing col/row, sitting at the `.container` level. The row should also be removed for this second card or it should be wrapped correctly.

---

### `app/views/devise/confirmations/new.html.slim` (template, request-response)

**Analog:** `app/views/devise/passwords/new.html.slim` (identical scaffold)

**Change required:** Line 1 `.container` → `.container.py-4`; line 2 remove `.mt-5`; line 4 `.card.shadow-sm` → `.card`

**Current file** (lines 1-20 — full file):
```slim
.container
  .row.justify-content-center.mt-5
    .col-md-5
      .card.shadow-sm     ← change to: .card
        .card-body.p-4
          h2.card-title.mb-4 Повторная отправка инструкций подтверждения
          / ... form body unchanged
```

---

### `app/views/devise/unlocks/new.html.slim` (template, request-response)

**Analog:** `app/views/devise/passwords/new.html.slim` (identical scaffold)

**Change required:** Line 1 `.container` → `.container.py-4`; line 2 remove `.mt-5`; line 4 `.card.shadow-sm` → `.card`

**Current file** (lines 1-20 — full file):
```slim
.container
  .row.justify-content-center.mt-5
    .col-md-5
      .card.shadow-sm     ← change to: .card
        .card-body.p-4
          h2.card-title.mb-4 Повторная отправка инструкций разблокировки
          / ... form body unchanged
```

---

### `app/views/leagues/index.html.slim` (template, request-response)

**Analog:** `app/views/leagues/show.html.slim` (same container convention, card grid layout)

**Change required:** Line 10 `.card.h-100.shadow-sm` → `.card.h-100`

**Current file** (lines 1-21 — full file):
```slim
.container.py-4
  .d-flex.justify-content-between.align-items-center.mb-4
    h1.mb-0 Лиги
    = link_to "Новая лига", new_league_path, class: "btn btn-primary"

  - if @leagues.any?
    .row.row-cols-1.row-cols-md-2.row-cols-lg-3.g-4
      - @leagues.each do |league|
        .col
          .card.h-100.shadow-sm    ← change to: .card.h-100
            - if league.logo.attached?
              = image_tag league.logo, class: "card-img-top", style: "height: 140px; object-fit: cover;"
            .card-body
              h5.card-title= link_to league.name, league_path(league), class: "text-decoration-none stretched-link"
              - if league.description.present?
                p.card-text.text-muted= league.description
            .card-footer.text-muted.small
              | Создано #{league.created_at.strftime("%d.%m.%Y")}
  - else
    p.text-muted Лиг пока нет.
```

---

### `app/views/leagues/new.html.slim` (template, request-response)

**Analog:** `app/views/tournaments/new.html.slim` (form with container, `.d-flex` header, `form_with`)

**Change required:** Wrap entire file in `.container.py-4` block; add `.d-flex` header matching project convention

**Current file** (lines 1-20 — full file):
```slim
h1 Новая лига                          ← NO container — bleeds to edge

= form_with model: @league, class: "mt-4" do |f|
  .mb-3
    = f.label :name, class: "form-label"
    = f.text_field :name, class: "form-control", required: true
    - if @league.errors[:name].any?
      .text-danger.small= @league.errors[:name].first

  .mb-3
    = f.label :description, class: "form-label"
    = f.text_area :description, class: "form-control", rows: 4

  .mb-3
    = f.label :logo, "Логотип", class: "form-label"
    = f.file_field :logo, class: "form-control", accept: "image/*"

  = f.submit "Создать лигу", class: "btn btn-primary"
  = link_to "Отмена", leagues_path, class: "btn btn-secondary ms-2"
```

**Container wrapper pattern** from `app/views/tournaments/new.html.slim` lines 1-5:
```slim
.container.py-4
  .d-flex.justify-content-between.align-items-center.mb-4
    h1.mb-0 Новый турнир
    = link_to "← #{@league.name}", league_path(@league), class: "btn btn-outline-secondary btn-sm"

  = form_with model: [@league, @tournament], class: "row g-3" do |f|
```

**After change:**
```slim
.container.py-4
  h1.mb-4 Новая лига

  = form_with model: @league, class: "mt-4" do |f|
    / ... existing form fields unchanged
```

---

### `app/views/leagues/edit.html.slim` (template, request-response)

**Analog:** `app/views/leagues/new.html.slim` (identical structure — same container problem)

**Change required:** Wrap entire file in `.container.py-4` block

**Current file** (lines 1-23 — full file):
```slim
h1 Редактировать лигу                  ← NO container — bleeds to edge

= form_with model: @league, class: "mt-4" do |f|
  .mb-3
    = f.label :name, class: "form-label"
    = f.text_field :name, class: "form-control", required: true
    - if @league.errors[:name].any?
      .text-danger.small= @league.errors[:name].first

  .mb-3
    = f.label :description, class: "form-label"
    = f.text_area :description, class: "form-control", rows: 4

  .mb-3
    = f.label :logo, "Логотип", class: "form-label"
    - if @league.logo.attached?
      .mb-2
        = image_tag @league.logo, class: "rounded", style: "width: 80px; height: 80px; object-fit: cover;"
    = f.file_field :logo, class: "form-control", accept: "image/*"

  = f.submit "Сохранить", class: "btn btn-primary"
  = link_to "Отмена", @league, class: "btn btn-secondary ms-2"
```

**After change:**
```slim
.container.py-4
  h1.mb-4 Редактировать лигу

  = form_with model: @league, class: "mt-4" do |f|
    / ... existing form fields unchanged
```

---

### `app/views/tournaments/index.html.slim` (template, request-response)

**Analog:** `app/views/leagues/show.html.slim` lines 33-53 (table with status badge, `.container.py-4`)

**Change required:** Line 1 `.container.mt-4` → `.container.py-4`; line 5 `.table.table-striped.table-hover` → `.table.table-hover`

**Current file** (lines 1-30 — full file):
```slim
.container.mt-4                         ← change to: .container.py-4
  h1.mb-4 Турниры

  - if @tournaments.any?
    table.table.table-striped.table-hover   ← change to: table.table.table-hover
      thead
        tr
          th Название
          th Место
          th Дата начала
          th Дата окончания
          th Тип
          th Статус
          th Макс. участников
      tbody
        - @tournaments.each do |tournament|
          tr
            td= tournament.name
            td= tournament.location.presence || "—"
            td= tournament.start_date
            td= tournament.end_date
            td= tournament.type.capitalize
            td
              - badge_class = { "draft" => "secondary", "active" => "success", "completed" => "primary", "cancelled" => "danger" }.fetch(tournament.status, "secondary")
              span.badge class="bg-#{badge_class}"
                = tournament.status.capitalize
            td.text-center= tournament.max_participants
  - else
    p.text-muted Турниров пока нет.
```

**Status badge analog** from `app/views/tournaments/show.html.slim` lines 28-31:
```slim
- badge_class = { "draft" => "secondary", "active" => "success", "completed" => "primary", "cancelled" => "danger" }.fetch(@tournament.status, "secondary")
span.badge class="bg-#{badge_class}"
  = @tournament.status.capitalize
```

---

### `app/views/users/index.html.slim` (template, request-response)

**Analog:** `app/views/leagues/show.html.slim` lines 55-73 (dark table with avatar partial, `thead` plain after Phase 3)

**Change required:** Line 6 `.table.table-striped.table-hover.align-middle` → `.table.table-hover.align-middle`; add email column

**Current file** (lines 1-23 — full file):
```slim
.container.py-4
  h1.mb-4 Пользователи

  - if @users.any?
    .table-responsive
      table.table.table-striped.table-hover.align-middle    ← change to: table.table.table-hover.align-middle
        thead
          tr
            th #
            th Фото
            th Имя
            th Дата регистрации
        tbody
          - @users.each_with_index do |user, i|
            tr
              td= i + 1
              td
                = render "shared/avatar", user: user
              td= user.full_name
              td= user.created_at.strftime("%d.%m.%Y")
  - else
    p.text-muted Пользователей пока нет.
```

**Email column addition:** Add `th Email` after `th Имя` in `thead`, and `td= user.email` after `td= user.full_name` in `tbody`. No controller change needed — `user.email` is always available.

**Table with avatar analog** from `app/views/leagues/show.html.slim` lines 59-73:
```slim
table.table.table-hover
  thead
    tr
      th Фото
      th Имя
      th Очки
  tbody
    - @league.league_users.order(score: :desc).each do |league_user|
      tr
        td
          = render "shared/avatar", user: league_user.user
        td= league_user.full_name
        td= league_user.score
```

---

## Shared Patterns

### Shadow removal (apply to ALL card elements across all 13 files)
**Source:** `app/assets/stylesheets/_theme.scss` (Phase 3 — `--bs-box-shadow-sm: none` suppresses all shadows)
**Rule:** Remove `.shadow-sm` from every `.card` selector in every template. It is harmless but misleading.
**Grep to verify completion:** `grep -r "shadow-sm" app/views/` must return 0 results after all plans execute.

Files affected:
- `dashboard/index.html.slim` lines 6, 22, 42 — `.card.shadow-sm.h-100` and `.card.shadow-sm`
- `sessions/new.html.slim` line 4
- `registrations/new.html.slim` line 4
- `registrations/edit.html.slim` lines 4 and 49
- `passwords/new.html.slim` line 4
- `passwords/edit.html.slim` line 4
- `confirmations/new.html.slim` line 4
- `unlocks/new.html.slim` line 4
- `leagues/index.html.slim` line 10

### Container convention (apply to all templates missing it)
**Source:** `app/views/leagues/show.html.slim` line 1, `app/views/tournaments/new.html.slim` line 1
```slim
.container.py-4
  h1.mb-4 Page Title
  / ... content
```
**Apply to:** `leagues/new.html.slim` (no wrapper at all), `leagues/edit.html.slim` (no wrapper at all)
**Adjust on:** `devise/sessions/new.html.slim` and all auth pages — change `.container` to `.container.py-4` and drop `.mt-5` from inner `.row`

### Auth page scaffold (apply to all 7 devise pages)
**Source:** `app/views/devise/sessions/new.html.slim` lines 1-5 (current, before change)
**After change — canonical pattern:**
```slim
.container.py-4
  .row.justify-content-center
    .col-md-5
      .card
        .card-body.p-4
          h2.card-title.mb-4 Page Title
          / ... form
          hr.my-3
          .text-center.small
            = render "devise/shared/links"
```
Note: `registrations/edit.html.slim` uses `.col-md-6` (wider) due to the two-column name row — keep that difference.

### Empty state pattern (already consistent — verify only)
**Source:** `app/views/dashboard/index.html.slim` lines 16 and 32, `app/views/leagues/index.html.slim` line 20
```slim
p.text-muted.mb-0 Вы ещё не создали ни одной лиги.
```
All empty states already use `.text-muted` — no change needed. Verify `p.text-muted` (not `.text-secondary` or inline style) is used consistently.

### Table striped removal (apply to table-only pages)
**Source:** Phase 3 PATTERNS.md — `_tables.scss` uses `var(--color-bg-surface)` for `thead` background; `.table-striped` alternating rows use `--bs-table-striped-bg` which does not match surface token
**Rule:** Remove `.table-striped` from dark tables. Keep `.table-hover`.
**Apply to:** `tournaments/index.html.slim` line 5, `users/index.html.slim` line 6

### Bootstrap Icons inline usage
**Source:** RESEARCH.md Pattern 3 — Bootstrap Icons imported via `@import 'bootstrap-icons/font/bootstrap-icons'` in `application.bootstrap.scss`
```slim
i.bi.bi-people.fs-2.text-primary
i.bi.bi-trophy.fs-2.text-primary
```
**Apply to:** Dashboard stat-card row only. Do not add icons elsewhere unless explicitly required.

### Avatar partial calling convention
**Source:** `app/views/users/index.html.slim` line 18, `app/views/leagues/show.html.slim` line 69
```slim
= render "shared/avatar", user: user
= render "shared/avatar", user: league_user.user
= render "shared/avatar", user: resource, size: 100
```
**Rule:** Always pass `.user` when calling from an association context (league_user, pair.player1, pair.player2). Never pass the association object itself. Size defaults to 40; use `size: 100` for profile/edit pages.

### Status badge pattern (already consistent — verify only)
**Source:** `app/views/tournaments/index.html.slim` lines 24-26, `app/views/tournaments/show.html.slim` lines 28-31
```slim
- badge_class = { "draft" => "secondary", "active" => "success", "completed" => "primary", "cancelled" => "danger" }.fetch(tournament.status, "secondary")
span.badge class="bg-#{badge_class}"
  = tournament.status.capitalize
```
This pattern is already present and correct. Bootstrap `.badge.bg-*` classes respond to `data-bs-theme="dark"` automatically. No change needed.

---

## No Analog Found

All 13 files have analogs from the existing codebase. No files require fallback to RESEARCH.md patterns only.

---

## Files Verified as Requiring No Changes (Phase 4 scope)

| File | Reason |
|------|--------|
| `app/views/devise/shared/_error_messages.html.slim` | Uses `.alert.alert-danger` — Bootstrap dark handles automatically |
| `app/views/devise/shared/_links.html.slim` | Plain `p` + `link_to` — inherits body text color, no overrides needed |
| `app/views/leagues/show.html.slim` | Already complete — `.container.py-4`, plain `thead`, avatar partial used |
| `app/views/tournaments/show.html.slim` | Already complete — `.container.py-4`, plain `thead`, avatar partial used |
| `app/views/tournaments/new.html.slim` | Already complete — `.container.py-4`, `.row.g-3` grid form, no shadow |

---

## Metadata

**Analog search scope:** `app/views/dashboard/`, `app/views/devise/`, `app/views/leagues/`, `app/views/tournaments/`, `app/views/users/`, `app/views/shared/`
**Files scanned:** 20 (all content templates from Phase 4 inventory)
**Pattern extraction date:** 2026-05-09
