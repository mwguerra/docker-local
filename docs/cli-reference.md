# CLI Reference

Complete reference for the `docker-local` command-line interface.

## Usage

```bash
docker-local <command> [options]
```

## Setup Commands

### init

Complete initial setup (first run).

```bash
docker-local init
```

Performs:
- Environment validation
- Docker image building
- SSL certificate generation
- Container startup
- Health checks

### doctor

Full system health check.

```bash
docker-local doctor
```

Validates:
- Docker daemon
- Container health
- Network connectivity
- SSL certificates
- DNS resolution

### setup:hosts

Add Docker hostnames to `/etc/hosts` for local PHP usage.

```bash
sudo "$(which docker-local)" setup:hosts
```

Adds entries for: `mysql`, `postgres`, `redis`, `minio`, `mailpit`

### setup:dns

Configure dnsmasq for `*.test` domain resolution.

```bash
sudo "$(which docker-local)" setup:dns
```

Enables wildcard DNS for all `.test` domains.

### config

Display current configuration.

```bash
docker-local config
```

---

## Environment Commands

### up

Start Docker environment.

```bash
docker-local up
```

### down

Stop Docker environment.

```bash
docker-local down
```

### restart

Restart Docker environment.

```bash
docker-local restart
```

### status

Show status of all services.

```bash
docker-local status
```

### logs

View Docker container logs.

```bash
# All containers
docker-local logs

# Specific service
docker-local logs mysql
docker-local logs php
docker-local logs nginx
```

### ports

Display all mapped ports.

```bash
docker-local ports
```

### update

Update Docker images and CLI.

```bash
docker-local update
```

### clean

Clean caches, logs, and Docker resources.

```bash
# Basic cleanup
docker-local clean

# Full cleanup (including volumes)
docker-local clean --all
```

---

## Project Commands

### list

List all Laravel projects.

```bash
docker-local list
```

### make:laravel

Create a new Laravel project with automatic configuration.

```bash
docker-local make:laravel <project-name>
```

Automatically:
- Creates Laravel project in `~/projects/<name>`
- Generates `.env` with unique identifiers
- Sets up proper cache prefixes
- Configures database connections

### clone

Clone and setup an existing project.

```bash
docker-local clone <git-url>
```

### open

Open project or service in browser.

```bash
# Current project
docker-local open

# Specific project
docker-local open my-project

# Services
docker-local open --mail      # Mailpit
docker-local open --minio     # MinIO Console
docker-local open --traefik   # Traefik Dashboard
```

### ide

Open project in IDE.

```bash
# VS Code (default)
docker-local ide

# PhpStorm
docker-local ide phpstorm
```

### env:check

Verify project `.env` configuration.

```bash
# Current project
docker-local env:check

# All projects (audit for conflicts)
docker-local env:check --all
```

Checks:
- Service connectivity
- Cache prefix uniqueness
- WebSocket ID conflicts
- Required variables

### make:env

Generate new `.env` file with unique identifiers.

```bash
docker-local make:env
```

### update:env

Update existing `.env` with new settings.

```bash
docker-local update:env
```

---

## Development Commands

### tinker

Open Laravel Tinker REPL.

```bash
docker-local tinker
```

### test

Run tests (Pest or PHPUnit).

```bash
# All tests
docker-local test

# With coverage
docker-local test --coverage

# Parallel execution
docker-local test --parallel

# Filter tests
docker-local test Unit
docker-local test Feature/UserTest
```

### require

Install Composer packages with smart suggestions.

```bash
# Known packages (auto-completes)
docker-local require sanctum       # laravel/sanctum
docker-local require telescope     # laravel/telescope --dev
docker-local require debugbar      # barryvdh/laravel-debugbar
docker-local require pest          # pestphp/pest
docker-local require filament      # filament/filament

# Any package
docker-local require vendor/package
```

### logs:laravel

Tail Laravel application logs.

```bash
docker-local logs:laravel
```

---

## Artisan Shortcuts

Shortcuts for common `artisan make:*` commands.

### new:model

Create a model.

```bash
docker-local new:model Post
docker-local new:model Post -mcr    # with migration, controller, resource
docker-local new:model Post -a      # all (migration, factory, seeder, controller, form request, policy)
```

### new:controller

Create a controller.

```bash
docker-local new:controller UserController
docker-local new:controller UserController --api
docker-local new:controller UserController --resource
```

### new:migration

Create a migration.

```bash
docker-local new:migration create_posts_table
docker-local new:migration add_status_to_posts_table
```

### new:seeder

Create a seeder.

```bash
docker-local new:seeder UserSeeder
```

### new:factory

Create a factory.

```bash
docker-local new:factory PostFactory
```

### new:request

Create a form request.

```bash
docker-local new:request StorePostRequest
```

### new:resource

Create an API resource.

```bash
docker-local new:resource PostResource
docker-local new:resource PostResource --collection
```

### new:middleware

Create a middleware.

```bash
docker-local new:middleware CheckAge
```

### new:event

Create an event.

```bash
docker-local new:event OrderShipped
```

### new:job

Create a job.

```bash
docker-local new:job ProcessPodcast
```

### new:mail

Create a mailable.

```bash
docker-local new:mail OrderConfirmation
```

### new:command

Create an Artisan command.

```bash
docker-local new:command SendEmails
```

---

## Database Commands

### db:mysql

Open MySQL CLI.

```bash
docker-local db:mysql

# Connect to specific database
docker-local db:mysql my_database
```

### db:postgres

Open PostgreSQL CLI.

```bash
docker-local db:postgres
```

### db:redis

Open Redis CLI.

```bash
docker-local db:redis
```

### db:create

Create a new database.

```bash
docker-local db:create my_database
```

### db:dump

Export database to SQL file.

```bash
# Default database
docker-local db:dump

# Specific database
docker-local db:dump my_database
```

### db:restore

Import SQL file.

```bash
docker-local db:restore backup.sql
```

### db:fresh

Run `migrate:fresh --seed`.

```bash
docker-local db:fresh
```

---

## Queue Commands

### queue:work

Start a queue worker.

```bash
docker-local queue:work
```

### queue:restart

Restart all queue workers.

```bash
docker-local queue:restart
```

### queue:failed

List failed jobs.

```bash
docker-local queue:failed
```

### queue:retry

Retry failed jobs.

```bash
# Retry specific job
docker-local queue:retry 5

# Retry all failed jobs
docker-local queue:retry all
```

### queue:clear

Clear all queued jobs.

```bash
docker-local queue:clear
```

---

## Xdebug Commands

### xdebug on

Enable Xdebug.

```bash
docker-local xdebug on
```

### xdebug off

Disable Xdebug (better performance).

```bash
docker-local xdebug off
```

### xdebug status

Show Xdebug status.

```bash
docker-local xdebug status
```

---

## Other Commands

### shell

Open shell in PHP container.

```bash
docker-local shell
```

### completion

Generate shell completion scripts.

```bash
# Bash (add to ~/.bashrc)
eval "$(docker-local completion bash)"

# Zsh (add to ~/.zshrc)
eval "$(docker-local completion zsh)"
```

### self-update

Update docker-local CLI.

```bash
docker-local self-update
```

### help

Show help information.

```bash
docker-local help
```

---

## Environment Variables

The CLI respects these environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `DOCKER_ENV_DIR` | `~/docker-environment` | Docker environment location |
| `PROJECTS_DIR` | `~/projects` | Projects directory |

## Examples

```bash
# Complete workflow
docker-local init                    # First time setup
docker-local make:laravel blog       # Create project
cd ~/projects/blog
docker-local new:model Post -mcr     # Create model with extras
docker-local db:fresh                # Run migrations
docker-local test --coverage         # Run tests
docker-local open                    # Open in browser
```
