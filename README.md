# ACME Salary Management

A web application that replaces ACME's Excel-based salary tracking. HR managers use it to manage salaries for about 10,000 employees across many countries, run payroll with country-specific income tax, issue payslips, and see how the organisation pays people.

Built with Ruby on Rails 8, Hotwire and PostgreSQL.

## Contents

- [Features](#features)
- [Tech stack](#tech-stack)
- [Getting started](#getting-started)
- [Testing and code quality](#testing-and-code-quality)
- [Further documentation](#further-documentation)

## Features

- **Employee management:** search, filter, sort and paginate 10,000 employees, each with nationality, residence and payroll country kept separate.
- **Salary management:** effective-dated salary records built from components; a revision closes the old record instead of overwriting it.
- **Audit trail:** records who created, changed or deleted each employee and salary, shown in the salary history.
- **Tax calculation:** progressive income tax from each payroll country's brackets; a country without brackets is never taxed at a guessed 0%.
- **Payroll runs:** processed in the background, paying each period's share of annual net pay and tax, with skipped employees and reasons recorded.
- **Payslips:** issued automatically per employee when a run completes, and downloadable as a PDF.
- **Dashboard:** headcount, compensation, payroll cost over time and department averages, for one salary currency at a time.
- **JSON API:** JWT-secured endpoints for auth, employees, salary history and salary records.

## Tech stack

| Area | Technology |
| --- | --- |
| Language / framework | Ruby 3.2.0, Rails 8.0.5.1 |
| Database | PostgreSQL (app database plus a separate Solid Queue database) |
| Frontend | Hotwire (Turbo, Stimulus), importmap (no Node build), Tailwind CSS v4 via `tailwindcss-rails` |
| Background jobs | Solid Queue |
| Authentication | Devise password hashing plus JWT (signed httponly cookie for pages, `Authorization: Bearer` for the API) |
| Pagination | Pagy 9 |
| Tests | RSpec, FactoryBot, Faker |

## Getting started

### 1. System packages

```bash
sudo apt-get update
sudo apt-get install -y curl gnupg2 git build-essential libpq-dev postgresql postgresql-contrib   # build tools + PostgreSQL
sudo systemctl enable --now postgresql   # start PostgreSQL
```

### 2. Ruby 3.2.0 (RVM)

```bash
gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB   # RVM signing keys
\curl -sSL https://get.rvm.io | bash -s stable   # install RVM
source ~/.rvm/scripts/rvm                         # load RVM
rvm install 3.2.0                                 # install Ruby
rvm use 3.2.0 --default                           # make it the default
```

### 3. PostgreSQL user

```bash
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';"   # matches the credentials below
```

### 4. Code and gems

```bash
git clone <repository-url> salary_management && cd salary_management
gem install bundler
bundle install
```

### 5. Credentials

```bash
bin/rails secret                        # copy the output: your secret_key_base
rm config/credentials.yml.enc           # only if you don't have config/master.key
EDITOR=nano bin/rails credentials:edit
```

Paste, replacing the placeholder with the output of `bin/rails secret`:

```yaml
secret_key_base: <output of bin/rails secret>

database:
  development:
    username: postgres
    password: postgres

  test:
    username: postgres
    password: postgres

  production:
    username: postgres
    password: postgres

# production email (SMTP)
app_host: salary.example.com
smtp:
  address: smtp.example.com
  port: 587
  domain: example.com
  user_name: your_smtp_user
  password: your_smtp_password
```

### 6. Databases

```bash
bin/rails db:prepare   # creates app, Solid Queue and test databases
```

### 7. Seed data (Global Tax API)

```bash
bin/rails db:seed   # departments, job titles, components, HR user, tax data from globaltaxcalculator.net, 50 employees
```

Refresh tax data from the Global Tax API at any time:

```bash
bin/rails runner "r = TaxDataImporter.new.call; puts \"Imported: #{r.imported.size}, failed: #{r.failed.size}\""
```

### 8. Run

```bash
bin/rails tailwindcss:build   # build CSS once
bin/rails server              # terminal 1: app + background jobs
bin/rails tailwindcss:watch   # terminal 2: rebuild CSS on change
```

Open <http://localhost:3000>. Login: `hr@acme.test` / `SecurePass123!`

## Testing and code quality

```bash
bundle exec rspec          # model, service and client specs
bin/rubocop                # style
bin/brakeman               # security static analysis
```

Jobs use the `:test` adapter in the test environment, so they're recorded rather than run.

> `bin/ci` currently runs `bin/rails test` (Minitest) instead of RSpec, so it won't run this project's specs. Use `bundle exec rspec` until that step is updated.

## Further documentation

- [Database design](Design%20document.md)
- [ER diagram](salary-management-E-R-diagram.png)
