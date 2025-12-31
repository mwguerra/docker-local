# Getting Started

Complete guide to installing and setting up the Laravel Docker Development Environment.

## Prerequisites

### Required Software

| Software | Minimum Version | Check Command |
|----------|----------------|---------------|
| Docker | 24.0+ | `docker --version` |
| Docker Compose | 2.20+ | `docker compose version` |
| PHP | 8.2+ | `php --version` |
| Composer | 2.6+ | `composer --version` |

### System Requirements

- **OS:** Linux (Ubuntu 22.04+, Debian 12+, Fedora 38+, Arch), macOS 12+, or Windows (WSL2)
- **RAM:** 8GB minimum, 16GB recommended
- **Disk:** 20GB free space

## Installation

### Step 1: Install via Composer

Install the package globally using Composer:

```bash
composer global require mwguerra/docker-local
```

### Step 2: Add Composer to PATH

Ensure Composer's global bin directory is in your PATH. Add to your `~/.bashrc` or `~/.zshrc`:

```bash
export PATH="$HOME/.composer/vendor/bin:$PATH"
```

Reload your shell:
```bash
source ~/.bashrc  # or source ~/.zshrc
```

### Step 3: Run Initial Setup

```bash
docker-local init
```

This command performs:
- Configuration directory creation (`~/.config/docker-local/`)
- Default config and .env file generation
- Docker image building
- SSL certificate generation (via mkcert)
- Container startup
- Health checks

### Step 4: Configure DNS (Optional but Recommended)

For `.test` domain resolution:

```bash
# Option A: DNS server (recommended for wildcards)
sudo docker-local setup:dns

# Option B: Manual /etc/hosts entries
sudo docker-local setup:hosts
```

## Directory Structure

After installation, files are organized as follows:

```
~/.composer/vendor/mwguerra/docker-local/    # Package (managed by Composer)
├── bin/docker-local                         # CLI entry point
├── src/                                     # PHP classes
├── lib/config.sh                            # Bash configuration helper
├── resources/docker/                        # Default Docker files
├── scripts/                                 # Helper scripts
├── stubs/                                   # Configuration templates
└── templates/                               # Project templates

~/.config/docker-local/                      # User configuration (XDG compliant)
├── config.json                              # Custom settings
├── .env                                     # Environment variables
├── certs/                                   # SSL certificates
└── docker-compose.override.yml              # Optional: user overrides

~/projects/                                  # Your Laravel projects
└── ...
```

## Creating Your First Project

```bash
# Create a new Laravel project
docker-local make:laravel blog

# Navigate to project
cd ~/projects/blog

# Open in browser
docker-local open
# Opens: https://blog.test
```

## Using Local PHP

If you prefer using local PHP with Docker services:

### Install PHP (Ubuntu/Debian)

```bash
sudo apt install php8.4 php8.4-{mysql,redis,mbstring,xml,curl,zip,gd,intl}
```

### Configure Hostnames

```bash
sudo docker-local setup:hosts
```

This adds to `/etc/hosts`:
```
127.0.0.1 mysql postgres redis minio mailpit
```

### Use Standard PHP Commands

```bash
cd ~/projects/blog
php artisan migrate
php artisan serve
composer require laravel/sanctum
```

## Environment Configuration

### Configuration File

Your settings are stored in `~/.config/docker-local/config.json`:

```json
{
  "version": "2.0.0",
  "projects_path": "~/projects",
  "docker_files_path": "~/.config/docker-local",
  "editor": "code",
  "default_php_version": "8.4",
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
    "web_port": 8025,
    "smtp_port": 1025
  },
  "xdebug": {
    "enabled": true,
    "mode": "develop,debug"
  }
}
```

### Environment Variables

Environment variables are stored in `~/.config/docker-local/.env`. View current configuration:

```bash
docker-local config
```

## Verifying Installation

### Check System Health

```bash
docker-local doctor
```

This validates:
- Docker daemon status
- Container health
- Network connectivity
- SSL certificates
- DNS resolution

### View Service Status

```bash
docker-local status
```

### Test Connections

```bash
# MySQL
docker-local db:mysql

# PostgreSQL
docker-local db:postgres

# Redis
docker-local db:redis
```

## Service URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| Your Projects | `https://<project>.test` | - |
| Traefik Dashboard | `https://traefik.localhost` | - |
| Mailpit | `https://mail.localhost` | - |
| MinIO Console | `https://minio.localhost` | minio / minio123 |
| MinIO API | `https://s3.localhost` | minio / minio123 |

## Ports

| Service | Port | Purpose |
|---------|------|---------|
| Traefik HTTP | 80 | HTTP (redirects to HTTPS) |
| Traefik HTTPS | 443 | HTTPS |
| Traefik Dashboard | 8080 | Management UI |
| MySQL | 3306 | Database |
| PostgreSQL | 5432 | Database |
| Redis | 6379 | Cache/Queue |
| MinIO API | 9000 | S3 API |
| MinIO Console | 9001 | Web UI |
| Mailpit SMTP | 1025 | Email |
| Mailpit Web | 8025 | Email UI |

## Next Steps

- [CLI Reference](cli-reference.md) - Learn all available commands
- [Services](services.md) - Configure database, cache, storage
- [Templates](templates.md) - Customize new project creation
- [Troubleshooting](troubleshooting.md) - Solve common issues
