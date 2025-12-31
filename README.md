# docker-local

Complete Docker development environment for Laravel with a powerful CLI.

[![PHP Version](https://img.shields.io/badge/PHP-8.2%2B-blue.svg)](https://www.php.net/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Features

- **PHP 8.4** with Xdebug 3.4, FFmpeg, and all Laravel extensions
- **MySQL 9.1** and **PostgreSQL 17 with pgvector** (AI embeddings)
- **Redis 8** for cache, sessions, and queues
- **MinIO** S3-compatible object storage
- **Traefik 3.6** reverse proxy with automatic SSL
- **Mailpit** for email testing
- **RTMP Server** (optional) for live streaming with HLS
- **Whisper AI** (optional) for audio transcription
- **Node.js 20** (optional) standalone container for asset builds
- **50+ CLI commands** for rapid development
- **Multi-project support** with automatic isolation
- **Cross-platform** - Linux, macOS, and Windows (WSL2)

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
  - [Linux](#linux)
  - [macOS](#macos)
  - [Windows (WSL2)](#windows-wsl2)
- [Quick Start](#quick-start)
- [CLI Commands](#cli-commands)
- [Configuration](#configuration)
  - [Directory Structure](#directory-structure)
  - [Understanding Environment Files](#understanding-environment-files)
- [Services](#services)
- [Optional Services](#optional-services)
- [Multi-Project Support](#multi-project-support)
- [Migrating from Project-Specific Docker](#migrating-from-project-specific-docker)
- [IDE Integration](#ide-integration)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Requirements

### All Platforms

| Software | Minimum Version | Check Command |
|----------|-----------------|---------------|
| Docker | 24.0+ | `docker --version` |
| Docker Compose | 2.20+ | `docker compose version` |
| PHP | 8.2+ | `php --version` |
| Composer | 2.6+ | `composer --version` |

### System Requirements

- **RAM:** 8GB minimum, 16GB recommended
- **Disk:** 20GB free space
- **CPU:** 64-bit processor with virtualization support

## Installation

### Linux

Tested on Ubuntu 22.04+, Debian 12+, Fedora 38+, and Arch Linux.

```bash
# 1. Install Docker (if not already installed)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker

# 2. Install PHP and Composer (Ubuntu/Debian)
sudo apt update
sudo apt install php8.3 php8.3-{cli,curl,mbstring,xml,zip} unzip
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# 3. Install docker-local
composer global require mwguerra/docker-local

# 4. Add Composer bin to PATH (add to ~/.bashrc or ~/.zshrc)
export PATH="$HOME/.composer/vendor/bin:$PATH"

# 5. Reload shell and run setup
source ~/.bashrc  # or source ~/.zshrc
docker-local init

# 6. (Optional) Configure DNS for *.test domains
sudo docker-local setup:dns
```

### macOS

Tested on macOS 12 (Monterey) and later.

```bash
# 1. Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install Docker Desktop
brew install --cask docker
# Launch Docker Desktop from Applications

# 3. Install PHP and Composer
brew install php composer

# 4. Install docker-local
composer global require mwguerra/docker-local

# 5. Add Composer bin to PATH (add to ~/.zshrc)
export PATH="$HOME/.composer/vendor/bin:$PATH"

# 6. Reload shell and run setup
source ~/.zshrc
docker-local init

# 7. (Optional) Configure DNS for *.test domains
sudo docker-local setup:dns
```

### Windows (WSL2)

**Important:** docker-local requires WSL2 on Windows. Native Windows is not supported.

#### Step 1: Install WSL2

```powershell
# Run in PowerShell as Administrator
wsl --install -d Ubuntu
```

Restart your computer when prompted.

#### Step 2: Install Docker Desktop

1. Download [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)
2. During installation, ensure "Use WSL 2 based engine" is checked
3. After installation, go to Settings > Resources > WSL Integration
4. Enable integration with your Ubuntu distribution

#### Step 3: Install docker-local (in WSL2 Ubuntu)

```bash
# Open Ubuntu from Start Menu, then run:

# Install PHP and Composer
sudo apt update
sudo apt install php8.3 php8.3-{cli,curl,mbstring,xml,zip} unzip
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# Install docker-local
composer global require mwguerra/docker-local

# Add to PATH (add to ~/.bashrc)
echo 'export PATH="$HOME/.composer/vendor/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Run setup
docker-local init

# (Optional) Configure DNS
sudo docker-local setup:dns
```

#### Accessing Projects from Windows

Your WSL2 projects are accessible in Windows Explorer at:
```
\\wsl$\Ubuntu\home\<username>\projects
```

Or in VS Code:
```bash
# From WSL2 terminal
code ~/projects/my-project
```

## Quick Start

```bash
# Create a new Laravel project
docker-local make:laravel my-app

# Navigate to project
cd ~/projects/my-app

# Open in browser (https://my-app.test)
docker-local open

# Run artisan commands
docker-local tinker
docker-local new:model Post -mcr

# View logs
docker-local logs
docker-local logs:laravel

# Stop environment
docker-local down
```

## CLI Commands

### Setup & Diagnostics

```bash
docker-local init              # Complete initial setup
docker-local doctor            # Full system health check
docker-local config            # View current configuration
docker-local setup:hosts       # Add Docker hostnames to /etc/hosts (sudo)
docker-local setup:dns         # Configure dnsmasq for *.test (sudo)
docker-local update            # Update Docker images
```

### Environment Management

```bash
docker-local up                # Start all containers
docker-local down              # Stop all containers
docker-local restart           # Restart all containers
docker-local status            # Show service status
docker-local logs [service]    # View logs (all or specific service)
docker-local clean             # Clean caches and unused Docker resources
```

### Project Commands

```bash
docker-local list              # List all Laravel projects
docker-local make:laravel NAME # Create new Laravel project
docker-local clone REPO        # Clone and setup existing project
docker-local open [name]       # Open project in browser
docker-local open --mail       # Open Mailpit
docker-local open --minio      # Open MinIO Console
docker-local open --traefik    # Open Traefik Dashboard
docker-local ide [editor]      # Open in IDE (code, phpstorm)
```

### Development Commands

```bash
docker-local tinker            # Laravel Tinker REPL
docker-local test [options]    # Run tests (supports --coverage, --parallel)
docker-local require PACKAGE   # Install Composer package with suggestions
docker-local logs:laravel      # Tail Laravel logs
docker-local shell             # Open PHP container shell
```

### Artisan Shortcuts

```bash
docker-local new:model NAME [-mcr]       # make:model (with migration, controller, resource)
docker-local new:controller NAME [--api] # make:controller
docker-local new:migration NAME          # make:migration
docker-local new:seeder NAME             # make:seeder
docker-local new:factory NAME            # make:factory
docker-local new:request NAME            # make:request
docker-local new:resource NAME           # make:resource
docker-local new:middleware NAME         # make:middleware
docker-local new:event NAME              # make:event
docker-local new:job NAME                # make:job
docker-local new:mail NAME               # make:mail
docker-local new:command NAME            # make:command
```

### Database Commands

```bash
docker-local db:mysql          # Open MySQL CLI
docker-local db:postgres       # Open PostgreSQL CLI
docker-local db:redis          # Open Redis CLI
docker-local db:create NAME    # Create new database
docker-local db:dump [name]    # Export database to SQL
docker-local db:restore FILE   # Import SQL file
docker-local db:fresh          # migrate:fresh --seed
```

### Queue Commands

```bash
docker-local queue:work        # Start queue worker
docker-local queue:restart     # Restart queue workers
docker-local queue:failed      # List failed jobs
docker-local queue:retry ID    # Retry failed job (or 'all')
docker-local queue:clear       # Clear all queued jobs
```

### Xdebug Commands

```bash
docker-local xdebug on         # Enable Xdebug
docker-local xdebug off        # Disable Xdebug (better performance)
docker-local xdebug status     # Show Xdebug status
```

### Startup Commands

Configure docker-local to start automatically when your computer boots:

```bash
docker-local startup enable    # Start on OS boot
docker-local startup disable   # Disable startup on boot
docker-local startup status    # Show startup status
```

**Platform-specific behavior:**

| Platform | Method | Location |
|----------|--------|----------|
| Linux | systemd service | `~/.config/systemd/user/docker-local.service` |
| macOS | LaunchAgent | `~/Library/LaunchAgents/com.mwguerra.docker-local.plist` |
| WSL2 | bashrc script | Entry in `~/.bashrc` |

### Environment Verification

```bash
docker-local env:check         # Verify current project .env
docker-local env:check --all   # Audit ALL projects for conflicts
docker-local make:env          # Generate new .env with unique IDs
docker-local update:env        # Update existing .env
```

## Configuration

Configuration is stored in `~/.config/docker-local/config.json`:

```json
{
  "version": "2.0.0",
  "projects_path": "~/projects",
  "editor": "code",
  "mysql": {
    "version": "9.1",
    "port": 3306,
    "root_password": "secret",
    "database": "laravel",
    "user": "laravel",
    "password": "secret"
  },
  "postgres": {
    "version": "17",
    "port": 5432,
    "database": "laravel",
    "user": "laravel",
    "password": "secret"
  },
  "redis": {
    "version": "8",
    "port": 6379
  },
  "minio": {
    "api_port": 9000,
    "console_port": 9001,
    "root_user": "minio",
    "root_password": "minio123"
  },
  "mailpit": {
    "smtp_port": 1025,
    "web_port": 8025
  },
  "xdebug": {
    "enabled": true,
    "mode": "develop,debug"
  }
}
```

### Directory Structure

```
~/.composer/vendor/mwguerra/docker-local/   # Package (Composer managed)
├── bin/docker-local                        # CLI entry point
├── src/                                    # PHP classes
├── lib/                                    # Bash helpers
├── resources/docker/                       # Default Docker files
├── scripts/                                # Helper scripts
├── stubs/                                  # Configuration templates
└── tests/                                  # Pest tests

~/.config/docker-local/                     # User configuration
├── config.json                             # Custom settings
├── .env                                    # Environment variables
├── certs/                                  # SSL certificates
└── docker-compose.override.yml             # Optional: user overrides

~/projects/                                 # Your Laravel projects
├── blog/                                   → https://blog.test
├── api/                                    → https://api.test
└── shop/                                   → https://shop.test
```

### Understanding Environment Files

docker-local uses **two separate `.env` files** for different purposes:

| File | Scope | Used By | Location |
|------|-------|---------|----------|
| `.env.example` | Docker infrastructure | `docker-compose.yml` | `~/.config/docker-local/.env` |
| `laravel.env.example` | Laravel application | Laravel framework | `~/projects/<project>/.env` |

#### `.env.example` (Docker/Infrastructure)

Controls **how Docker containers are built and connected**:

```bash
PROJECTS_PATH=~/projects       # Where your projects live
MYSQL_PORT=3306               # Port exposed to your host machine
MYSQL_ROOT_PASSWORD=secret    # Container MySQL password
XDEBUG_ENABLED=true           # PHP container configuration
```

This file is copied to `~/.config/docker-local/.env` and read by `docker-compose.yml` via `${VARIABLE}` syntax.

#### `laravel.env.example` (Application)

Controls **how Laravel connects to services from inside the container**:

```bash
DB_HOST=mysql                 # Docker service name (NOT localhost!)
DB_PORT=3306                  # Internal container port
REDIS_HOST=redis              # Docker service name
MAIL_HOST=mailpit             # Docker service name
```

This file is copied to each project's `.env` (`~/projects/my-app/.env`) and read by Laravel via `env()` and `config()`.

#### Why Both Files Exist

**Key insight:** The same service has different addresses depending on where you're accessing it from:

| Accessing From | MySQL Address | Why |
|----------------|---------------|-----|
| Your host (TablePlus, DBeaver) | `localhost:3306` | Uses exposed port |
| Inside PHP container (Laravel) | `mysql:3306` | Uses Docker DNS |

The Docker `.env` configures what ports are **exposed to your machine**, while the Laravel `.env` configures how to reach services **via Docker's internal network**.

#### Related Files

```
docker-local/
├── .env.example              # Docker infrastructure template
├── laravel.env.example       # Laravel application template (manual use)
└── stubs/
    ├── .env.stub             # Docker template (for CLI automation)
    └── laravel.env.stub      # Laravel template with {{PLACEHOLDERS}}
```

The `stubs/` versions contain placeholders like `{{PROJECT_NAME}}` for automated project creation via `docker-local make:laravel`.

## Services

### URLs

| Service | URL |
|---------|-----|
| Your Projects | `https://<project>.test` |
| Traefik Dashboard | `https://traefik.localhost` |
| Mailpit | `https://mail.localhost` |
| MinIO Console | `https://minio.localhost` |

### Ports

| Service | Port | Purpose |
|---------|------|---------|
| Traefik HTTP | 80 | HTTP (redirects to HTTPS) |
| Traefik HTTPS | 443 | HTTPS |
| MySQL | 3306 | Database |
| PostgreSQL | 5432 | Database |
| Redis | 6379 | Cache/Queue |
| MinIO API | 9000 | S3 API |
| MinIO Console | 9001 | Web UI |
| Mailpit SMTP | 1025 | Email |
| Mailpit Web | 8025 | Email UI |

### Default Credentials

| Service | Username | Password |
|---------|----------|----------|
| MySQL (root) | root | secret |
| MySQL (user) | laravel | secret |
| PostgreSQL | laravel | secret |
| MinIO | minio | minio123 |

## All Included Services

All services are now enabled by default. Simply run:

```bash
docker-compose up -d
```

### RTMP Server (Live Streaming)

The RTMP server provides live streaming with HLS delivery:

**RTMP Configuration:**

| Endpoint | URL |
|----------|-----|
| RTMP Ingest | `rtmp://localhost:1935/live/<stream_key>` |
| HLS Playback | `http://localhost:8088/hls/<stream_key>.m3u8` |
| HLS (via Traefik) | `https://stream.localhost/hls/<stream_key>.m3u8` |
| Stats | `http://localhost:8088/stat` |

**Customizing RTMP:**

To add project-specific webhooks (e.g., on_publish callbacks), create a custom config:

```yaml
# docker-compose.override.yml
services:
  rtmp:
    volumes:
      - ./docker/rtmp/nginx-rtmp.conf:/etc/nginx/nginx.conf:ro
      - ./storage/app/hls:/var/www/hls
      - ./storage/app/recordings:/var/www/recordings
```

### Node.js Container

A dedicated Node.js 20 container for long-running build processes:

```bash
# Run npm commands
docker-compose exec node npm install
docker-compose exec node npm run dev
```

### PostgreSQL with pgvector

PostgreSQL 17 now includes the pgvector extension for AI embeddings:

```sql
-- Enabled automatically, just use it
CREATE TABLE items (
  id SERIAL PRIMARY KEY,
  embedding vector(1536)
);

-- Similarity search
SELECT * FROM items ORDER BY embedding <-> '[...]' LIMIT 10;
```

### AI/Whisper Transcription

PHP-AI container with OpenAI Whisper for audio transcription:

```bash
# Run transcription
docker-compose exec php-ai whisper audio.mp3 --model base --language en

# Or from your Laravel app
docker-compose exec php-ai php artisan transcribe:audio path/to/audio.mp3
```

**Whisper Models:**

| Model | Size | Memory | Speed | Accuracy |
|-------|------|--------|-------|----------|
| tiny | 39M | ~1GB | Fastest | Lower |
| base | 74M | ~1GB | Fast | Good |
| small | 244M | ~2GB | Medium | Better |
| medium | 769M | ~5GB | Slow | High |
| large | 1550M | ~10GB | Slowest | Best |

Configure the model in `.env`:
```bash
WHISPER_MODEL=base
WHISPER_LANGUAGE=en
```

### Laravel Workers (Horizon, Reverb, Scheduler)

For Laravel-specific services, use the override stub as a template:

```bash
# Copy the stub
cp ~/.composer/vendor/mwguerra/docker-local/stubs/docker-compose.override.yml.stub \
   ~/.config/docker-local/docker-compose.override.yml

# Uncomment the services you need and customize
```

Available templates:
- **Horizon** - Queue worker with Laravel Horizon
- **Reverb** - WebSocket server for real-time features
- **Scheduler** - Cron-like task scheduler
- **Elasticsearch/Meilisearch** - Full-text search
- **Soketi** - Open-source Pusher alternative

## Multi-Project Support

docker-local supports multiple Laravel projects sharing the same Docker services. Each project gets automatic isolation through unique identifiers.

### Automatic Isolation

When you create a project with `docker-local make:laravel`, unique values are generated:

| Variable | Purpose | Example |
|----------|---------|---------|
| `CACHE_PREFIX` | Isolates cache between projects | `blog_cache_` |
| `REVERB_APP_ID` | Unique WebSocket app ID | `847291` |
| `REVERB_APP_KEY` | WebSocket authentication | `abc123...` |

### Conflict Detection

```bash
# Check current project
docker-local env:check

# Audit ALL projects for conflicts
docker-local env:check --all
```

Example conflict output:

```
┌─ Cross-Project Conflicts ─────────────────────────────────────────┐
  ⚠ CACHE_PREFIX conflict with 'other-project'
    Both projects use: laravel_cache_

  Why: Cache data will be shared/corrupted between projects
  Fix: Change CACHE_PREFIX in one of the projects' .env files
```

## Migrating from Project-Specific Docker

If your project has its own Docker configuration, you can migrate to docker-local for a shared, centralized environment.

### What docker-local Provides

| Service | Included | Notes |
|---------|----------|-------|
| PHP 8.4 FPM | Yes | With FFmpeg, ImageMagick, 50+ extensions |
| PostgreSQL 17 | Yes | With pgvector for AI embeddings |
| MySQL 9.1 | Yes | Innovation release |
| Redis 8 | Yes | With persistence |
| MinIO | Yes | S3-compatible storage |
| Mailpit | Yes | Email testing |
| Nginx | Yes | Dynamic multi-project routing |
| Traefik | Yes | Reverse proxy with SSL |
| RTMP Server | Yes | Live streaming with HLS |
| Whisper AI | Yes | php-ai container with transcription |
| Node.js 20 | Yes | Frontend build tooling |

### What Stays Project-Specific

These should remain in your project's `docker-compose.override.yml`:

| Service | Reason |
|---------|--------|
| Laravel Horizon | Uses app container, just different command |
| Laravel Reverb | WebSocket server specific to your app |
| Scheduler | Cron jobs specific to your app |
| E2E Testing (Playwright) | Test infrastructure is project-specific |
| Custom AI Models | Specialized ML models beyond Whisper |

### Migration Steps

1. **Copy your project's custom services to an override file:**

```bash
# Create override in project root
touch ~/projects/your-app/docker-compose.override.yml
```

2. **Add Laravel-specific services:**

```yaml
# docker-compose.override.yml
services:
  horizon:
    image: php  # Uses docker-local's PHP image
    container_name: your-app-horizon
    working_dir: /var/www/your-app
    volumes:
      - ${PROJECTS_PATH:-../projects}:/var/www:cached
    networks:
      - laravel-dev
    command: php artisan horizon
    depends_on:
      - redis
      - postgres

  reverb:
    image: php
    container_name: your-app-reverb
    working_dir: /var/www/your-app
    volumes:
      - ${PROJECTS_PATH:-../projects}:/var/www:cached
    ports:
      - "8080:8080"
    networks:
      - laravel-dev
    command: php artisan reverb:start --host=0.0.0.0 --port=8080

  scheduler:
    image: php
    container_name: your-app-scheduler
    working_dir: /var/www/your-app
    volumes:
      - ${PROJECTS_PATH:-../projects}:/var/www:cached
    networks:
      - laravel-dev
    command: sh -c "while true; do php artisan schedule:run; sleep 60; done"

networks:
  laravel-dev:
    external: true
```

3. **Update your .env for docker-local:**

```bash
# Database (uses docker-local's PostgreSQL)
DB_CONNECTION=pgsql
DB_HOST=postgres
DB_PORT=5432
DB_DATABASE=your_app
DB_USERNAME=laravel
DB_PASSWORD=secret

# Redis
REDIS_HOST=redis
REDIS_PORT=6379

# MinIO
FILESYSTEM_DISK=s3
AWS_ENDPOINT=http://minio:9000
AWS_ACCESS_KEY_ID=minio
AWS_SECRET_ACCESS_KEY=minio123
AWS_BUCKET=your-app
AWS_USE_PATH_STYLE_ENDPOINT=true

# Mail
MAIL_MAILER=smtp
MAIL_HOST=mailpit
MAIL_PORT=1025
```

4. **For RTMP/streaming features:**

```bash
# RTMP is included by default, just start docker-local
cd ~/projects/docker-environment
docker-compose up -d

# Create custom RTMP config with your callbacks (optional)
mkdir -p ~/projects/your-app/docker/rtmp
# Edit nginx-rtmp.conf with on_publish webhooks
```

5. **Remove old Docker files from your project:**

```bash
cd ~/projects/your-app
rm -rf docker/
rm docker-compose.yml
rm docker-compose.test.yml
# Keep docker-compose.override.yml for project-specific services
```

6. **Start using docker-local:**

```bash
docker-local up
docker-local open your-app
```

### Example: pcast Migration

For a complex streaming application like pcast:

**Before (project-specific):**
```
pcast/
├── docker/
│   ├── app/Dockerfile          # Custom PHP with Whisper
│   ├── nginx/                  # nginx configs
│   ├── playwright/             # E2E testing
│   ├── rtmp-tester/            # Test tools
│   └── webrtc-tester/          # Test tools
├── docker-compose.yml          # 12 services
├── docker-compose.test.yml     # Testing
└── docker-compose.testing.yml  # E2E testing
```

**After (docker-local):**
```
pcast/
├── docker/
│   └── rtmp/nginx-rtmp.conf    # Only: Custom RTMP callbacks
├── docker-compose.override.yml # Horizon, Reverb, Scheduler
└── .env                        # Updated for docker-local
```

**Start docker-local (all features included):**
```bash
cd ~/projects/docker-environment
docker-compose up -d
```

**Benefits:**
- Shared services across all projects
- Centralized updates and maintenance
- Consistent development environment
- Smaller project footprint

## IDE Integration

### VS Code

1. Install PHP Debug extension
2. Create `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [{
    "name": "Listen for Xdebug",
    "type": "php",
    "request": "launch",
    "port": 9003,
    "pathMappings": {
      "/var/www/my-project": "${workspaceFolder}"
    }
  }]
}
```

3. Start debugging: F5

### PhpStorm

1. Settings → PHP → Debug → Port: `9003`
2. Settings → PHP → Servers:
   - Name: `docker`
   - Host: `localhost`, Port: `443`
   - Path mappings: `/var/www/project` → `~/projects/project`
3. Click "Start Listening for PHP Debug Connections"

## Troubleshooting

### General Diagnostics

```bash
docker-local doctor            # Full health check
docker-local status            # Service status
docker-local logs              # View all logs
docker-local logs mysql        # View specific service logs
```

### Common Issues

#### "Docker daemon is not running"

```bash
# Linux
sudo systemctl start docker

# macOS
open -a Docker

# Windows (WSL2)
# Start Docker Desktop from Windows
```

#### "Port already in use"

```bash
# Find what's using the port
lsof -i :3306  # or :5432, :6379, etc.

# Or change the port in config
# Edit ~/.config/docker-local/config.json
```

#### "Permission denied" errors

```bash
# Linux: Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Or fix project permissions
sudo chown -R $USER:$USER ~/projects
```

#### SSL Certificate Issues

```bash
# Regenerate certificates
docker-local init --certs

# Or manually with mkcert
mkcert -install
mkcert "*.test" "*.localhost"
```

### Cleaning Up

```bash
# Clean caches and logs
docker-local clean

# Full cleanup (removes volumes)
docker-local clean --all

# Reset everything
docker-local down
docker system prune -af
docker volume prune -f
docker-local init
```

## Using Local PHP

If you prefer using your local PHP installation with Docker services:

```bash
# 1. Configure hostnames
sudo docker-local setup:hosts

# 2. Now use standard PHP commands
cd ~/projects/my-app
php artisan migrate
php artisan serve
composer require laravel/sanctum
```

The `setup:hosts` command adds to `/etc/hosts`:
```
127.0.0.1 mysql postgres redis minio mailpit
```

## Shell Completion

### Bash

```bash
# Add to ~/.bashrc
eval "$(docker-local completion bash)"
```

### Zsh

```bash
# Add to ~/.zshrc
eval "$(docker-local completion zsh)"
```

## Updating

```bash
# Update docker-local CLI
composer global update mwguerra/docker-local

# Update Docker images
docker-local update

# Or combined
docker-local self-update
```

## Extending

### Adding Custom Services

Create `~/.config/docker-local/docker-compose.override.yml`:

```yaml
services:
  elasticsearch:
    image: elasticsearch:8.11.0
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - ES_JAVA_OPTS=-Xms512m -Xmx512m
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
    networks:
      - laravel-dev
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9200/_cluster/health"]
      interval: 30s
      timeout: 10s
      retries: 5

volumes:
  elasticsearch_data:
```

Then restart:

```bash
docker-local restart
```

### Custom PHP Configuration

Create `~/.config/docker-local/php/custom.ini`:

```ini
memory_limit = 512M
upload_max_filesize = 100M
post_max_size = 100M
```

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

```bash
# Clone the repository
git clone https://github.com/mwguerra/docker-local.git
cd docker-local

# Install dependencies
composer install

# Run tests
./vendor/bin/pest

# Run tests with coverage
./vendor/bin/pest --coverage
```

## License

MIT License. See [LICENSE](LICENSE) for details.

---

Made with :heart: for Laravel developers.
