# Ruby Development Guidelines

> Objective: Define standards for idiomatic, secure, and maintainable Ruby code, covering style conventions, language features, metaprogramming, testing, security, and tooling.

## 1. Style & Conventions

- Follow the **Ruby Style Guide** (rubocop-hq/ruby-style-guide). Enforce with **RuboCop** in CI. Commit `.rubocop.yml` to the repository with explicit configuration — avoid inheriting uncurated community configs blindly:

  ```yaml
  # .rubocop.yml
  AllCops:
    NewCops: enable
    TargetRubyVersion: 3.3
    Exclude:
      - "db/schema.rb"
      - "vendor/**/*"

  Metrics/MethodLength:
    Max: 15

  Metrics/BlockLength:
    Exclude: ["spec/**/*", "config/routes.rb"]
  ```

- Add `# frozen_string_literal: true` as the first line of **all** Ruby files. This prevents inadvertent string mutation and improves performance by allowing Ruby to intern string literals.
- **Naming conventions** (mandatory):
  - `snake_case`: methods, variables, symbols, files, directories
  - `PascalCase`: classes, modules
  - `SCREAMING_SNAKE_CASE`: constants
  - `?` suffix: predicate methods (return boolean), e.g., `user.active?`
  - `!` suffix: dangerous methods (mutate receiver, raise exceptions), e.g., `user.save!`
- Use **2-space indentation** (not tabs). Use **trailing commas** in multi-line method calls, hashes, and arrays for cleaner diffs.
- Prefer **single quotes** for strings that do not require interpolation. Use double quotes only when interpolation or escape sequences (e.g., `\n`) are required.
- Use **StandardRB** (zero-configuration opinionated RuboCop config) for projects that want consistent style without debate.

## 2. Language Features & Idioms

- Use `Enumerable` methods over imperative `for` loops for all collection operations:

  ```ruby
  # ✅ Idiomatic
  active_users = users.select(&:active?)
  emails = users.map(&:email)
  total = orders.sum(&:amount)
  admins = users.group_by(&:role).fetch("admin", [])

  # ❌ Imperative
  active_users = []
  users.each { |u| active_users << u if u.active? }
  ```

- **Rescue specific exception classes** — never `rescue Exception`:

  ```ruby
  # ✅ Specific rescue
  begin
    user.save!
  rescue ActiveRecord::RecordInvalid => e
    handle_validation_error(e)
  rescue ActiveRecord::RecordNotFound
    render_not_found
  end

  # ❌ Catches system signals (SIGTERM, Interrupt) — prevents graceful shutdown
  rescue Exception => e
  ```

- Use `&&`/`||` for boolean expressions in conditions. Use `and`/`or` only for explicit control flow sequencing (very rare):

  ```ruby
  # ✅ Boolean operators
  return if user.nil? || !user.active?

  # ✅ Control flow (only when intentional — document why)
  raise "Not found" unless record and record.valid?
  ```

- Use **Ruby structs** or **value objects** for structured data instead of plain hashes with string/symbol keys:

  ```ruby
  # Struct (lightweight)
  Point = Struct.new(:x, :y) do
    def distance_to(other) = Math.sqrt((x - other.x)**2 + (y - other.y)**2)
  end

  # Data (immutable, Ruby 3.2+)
  Address = Data.define(:street, :city, :country)
  addr = Address.new(street: "Main St", city: "Portland", country: "US")
  ```

- Use **Pattern Matching** (`case/in`) for complex structure matching (Ruby 3+):

  ```ruby
  case response
  in { status: 200, body: { user: { id: Integer => id, name: String => name } } }
    puts "User #{id}: #{name}"
  in { status: 404 }
    puts "Not found"
  in { status: 500.. }
    puts "Server error"
  end
  ```

- Mix in standard modules to add well-understood capabilities: `Comparable` (adds `<`, `>`, `between?`, `clamp` via `<=>` definition), `Enumerable` (all collection methods via `each` definition).
- Use **keyword arguments** for methods with multiple parameters to improve call-site readability:

  ```ruby
  def create_user(name:, email:, role: :user, verified: false)
    User.new(name: name, email: email, role: role, verified: verified)
  end
  create_user(name: "Alice", email: "alice@example.com")
  ```

## 3. Architecture & Design Patterns

- Use **Plain Old Ruby Objects (POROs)** for domain logic — classes that do not inherit from any framework class. This makes them lightweight, portable, and trivially testable in isolation.
- Follow **single responsibility**: one class, one reason to change. If a class has methods that span different concerns, extract to separate classes.
- Use **Service Objects** for operations that span multiple domain objects, external services, or require transactional steps:

  ```ruby
  class RegisterUserService
    def initialize(params)
      @params = params
    end

    def call
      user = User.create!(@params)
      SendWelcomeEmailJob.perform_later(user.id)
      CreateDefaultProjectService.new(user).call
      user
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors)
    end
  end
  # Usage: result = RegisterUserService.new(params).call
  ```

- Avoid **ActiveRecord callbacks** (`before_save`, `after_create`) for side effects (emails, jobs, external APIs). Callbacks are implicit, make behavior hard to trace, and cause hidden coupling during tests.
- Use **background jobs** (Sidekiq, GoodJob, Solid Queue) for work that exceeds 100ms or involves external services. Jobs MUST be idempotent — assume they may be executed more than once.

## 4. Testing

- Use **RSpec** with BDD-style `describe`, `context`, and `it` with descriptive strings:

  ```ruby
  RSpec.describe UserRegistrationService do
    describe "#call" do
      context "with valid params" do
        let(:params) { { email: "alice@example.com", name: "Alice" } }

        it "creates a user" do
          expect { described_class.new(params).call }
            .to change(User, :count).by(1)
        end

        it "enqueues a welcome email" do
          described_class.new(params).call
          expect(SendWelcomeEmailJob).to have_been_enqueued
        end
      end

      context "with invalid email" do
        it "returns a failure result" do
          result = described_class.new(email: "not-an-email", name: "X").call
          expect(result).to be_failure
          expect(result.errors[:email]).to be_present
        end
      end
    end
  end
  ```

- Use **FactoryBot** for test data:
  - `build_stubbed` (fastest — no DB, all IDs stubbed) for pure unit tests
  - `build` (in-memory, no DB) for tests that do not need IDs
  - `create` (writes to DB) only when persistence is required for the test
- Use **WebMock** or **VCR** to stub external HTTP calls. Never make real network calls in CI tests.
- Use `simplecov` for coverage reporting. Target ≥ 85% coverage on critical paths. Run `parallel_tests` to parallelize RSpec across CPU cores in CI for fast feedback on large suites.
- Run `bundle exec rspec --format progress --require spec_helper` in CI.

## 5. Security & Tooling

### Security

- Run **`bundle-audit`** in CI as a hard gate:

  ```bash
  bundle exec bundle-audit update && bundle exec bundle-audit check --ignore GHSA-xxxx
  ```

- Use **`brakeman`** for static analysis of Rails/Sinatra security:

  ```bash
  bundle exec brakeman --exit-on-warn --only-files app
  ```

  Fix all `High` confidence findings before merging. Document consciously ignored warnings in `.brakeman.ignore`.

- Sanitize all user output. In Rails, ERB auto-escapes — never use `raw`, `html_safe`, or `sanitize(:safe_list)` with untrusted user content.
- Use **encrypted credentials** (Rails 7+: `config/credentials.yml.enc` with `RAILS_MASTER_KEY`) for production secrets management:

  ```bash
  rails credentials:edit --environment production
  ```

  Reference via `Rails.application.credentials.dig(:aws, :access_key_id)`.

### Ruby Version & Dependency Management

- Pin the **Ruby version** in `.ruby-version` (rbenv/rvm/unirtm) and `Gemfile`:

  ```ruby
  # Gemfile — pin to exact Ruby version
  ruby "3.3.4"  # ✅ exact, not "~> 3.3" (range)
  ```

- **Strict Version Pinning (MANDATORY)**: All gems in `Gemfile` MUST use **exact version numbers**. Never use range operators (`~>`, `>=`, `!=`). Commit `Gemfile.lock` to version control — this is the lockfile for reproducible installs.

  ```ruby
  # ❌ WRONG — version ranges are non-deterministic
  gem "rails", "~> 7.1"
  gem "sidekiq", ">= 7.0"

  # ✅ CORRECT — exact, auditable, reproducible
  gem "rails", "7.1.3"
  gem "sidekiq", "7.2.4"
  ```

  Use `bundle install` (reads `Gemfile.lock`) rather than `bundle update` in CI to guarantee deterministic installs.
- Audit gems before adding them: check maintenance status, download count, license, and security history. Prefer gems with active maintenance and a clear security disclosure policy.

### Tooling

- Configure **RuboCop** with these extensions:
  - `rubocop-performance` — performance-focused cops
  - `rubocop-rspec` — RSpec-specific cops
  - `rubocop-factory_bot` — FactoryBot-specific cops
  - `rubocop-rails` — Rails-specific cops (if using Rails)
- Run `bundle exec rubocop --parallel` in CI. Fail on any offense above `Minor` severity.
- Use **`solargraph`** for IDE LSP support (code completion, inline docs, type inference). Commit `solargraph.yml` to the repository for consistent language server behavior across the team.
