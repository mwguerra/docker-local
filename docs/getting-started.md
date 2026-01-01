# Getting Started

Complete guide to installing and setting up **docker-local** (`mwguerra/docker-local`), a global Composer package that provides a complete Docker development environment for Laravel.

## What is docker-local?

**docker-local** is a CLI tool you install once globally on your machine. It manages a shared Docker environment for all your Laravel projects — no need to configure Docker files in each project.

**Key benefits:**
- Install once, use for all projects
- 50+ commands for common Laravel tasks
- Automatic project isolation (databases, cache, sessions)
- Works on Linux, macOS, and Windows (WSL2)

---

## Quick Install (TL;DR)

If you already have Docker, PHP 8.2+, and Composer installed:

```bash
composer global require mwguerra/docker-local
export PATH="$HOME/.composer/vendor/bin:$PATH"
docker-local init
docker-local make:laravel my-first-app
```

Your app is now running at `https://my-first-app.test`!

---

## Prerequisites

### Required Software

Before installing docker-local, you need these tools on your system:

| Software | Minimum Version | Check Command | Purpose |
|----------|----------------|---------------|---------|
| Docker | 24.0+ | `docker --version` | Runs the containers |
| Docker Compose | 2.20+ | `docker compose version` | Orchestrates services |
| PHP | 8.2+ | `php --version` | Runs the CLI tool |
| Composer | 2.6+ | `composer --version` | Installs the package |

**Don't have these installed?** See platform-specific guides below:
- [Linux Installation](#installing-prerequisites-on-linux)
- [macOS Installation](#installing-prerequisites-on-macos)
- [Windows/WSL2 Installation](#installing-prerequisites-on-windows-wsl2)

### System Requirements

- **OS:** Linux (Ubuntu 22.04+, Debian 12+, Fedora 38+, Arch), macOS 12+, or Windows 10/11 (WSL2 required)
- **RAM:** 8GB minimum, 16GB recommended
- **Disk:** 20GB free space
- **CPU:** 64-bit processor with virtualization support (VT-x/AMD-V)

---

## Installation

### Step 1: Install docker-local via Composer

Install the package globally using Composer's `global require` command:

```bash
composer global require mwguerra/docker-local
```

This downloads the package to `~/.composer/vendor/mwguerra/docker-local/`.

### Step 2: Add Composer's Global Bin to PATH

Composer installs executable scripts to a global bin directory. You need to add this to your PATH so you can run `docker-local` from anywhere.

**Find your Composer bin path:**
```bash
composer global config bin-dir --absolute
# Usually: /home/<user>/.composer/vendor/bin (Linux)
# Or: /Users/<user>/.composer/vendor/bin (macOS)
```

**Add to your shell configuration:**

For **Bash** (most Linux systems), add to `~/.bashrc`:
```bash
echo 'export PATH="$HOME/.composer/vendor/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

For **Zsh** (macOS default), add to `~/.zshrc`:
```bash
echo 'export PATH="$HOME/.composer/vendor/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**Verify it works:**
```bash
docker-local --version
# Should output: docker-local 2.x.x
```

### Step 3: Initialize the Environment

Run the setup wizard:

```bash
docker-local init
```

This command performs:
- Creates configuration directory (`~/.config/docker-local/`)
- Generates default config and .env files
- Builds Docker images (PHP, databases, etc.)
- Generates SSL certificates for HTTPS (via mkcert)
- Starts all containers
- Runs health checks

**First run takes 5-10 minutes** as Docker downloads base images.

### Step 4: Configure DNS (Optional but Recommended)

For automatic `.test` domain resolution (so `https://my-app.test` works):

```bash
# Option A: Automatic DNS (recommended)
# Sets up dnsmasq to resolve all *.test domains
sudo "$(which docker-local)" setup:dns

# Option B: Manual /etc/hosts entries
# Adds specific hostnames to /etc/hosts
sudo "$(which docker-local)" setup:hosts
```

---

## Installing Prerequisites

### Installing Prerequisites on Linux

**Ubuntu/Debian:**

```bash
# Update package list
sudo apt update

# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker

# Install PHP and extensions
sudo apt install php8.3 php8.3-{cli,curl,mbstring,xml,zip} unzip

# Install Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# Verify installations
docker --version
php --version
composer --version
```

**Fedora:**

```bash
sudo dnf install docker docker-compose php php-cli php-curl php-mbstring php-xml php-zip composer
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

**Arch Linux:**

```bash
sudo pacman -S docker docker-compose php composer
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

### Installing Prerequisites on macOS

```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Docker Desktop
brew install --cask docker
# Open Docker Desktop from Applications to complete setup

# Install PHP and Composer
brew install php composer

# Verify installations
docker --version
php --version
composer --version
```

### Installing Prerequisites on Windows (WSL2)

**docker-local requires WSL2** — it does not run on native Windows.

**Step 1: Install WSL2 (PowerShell as Administrator):**
```powershell
wsl --install -d Ubuntu
```
Restart your computer when prompted.

**Step 2: Install Docker Desktop for Windows:**
1. Download from [docker.com](https://www.docker.com/products/docker-desktop/)
2. During installation, check "Use WSL 2 based engine"
3. After installation: Settings → Resources → WSL Integration → Enable Ubuntu

**Step 3: Install PHP and Composer in WSL2 (Ubuntu terminal):**
```bash
sudo apt update
sudo apt install php8.3 php8.3-{cli,curl,mbstring,xml,zip} unzip
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
```

Now continue with the main [Installation](#installation) steps above.

---

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
sudo "$(which docker-local)" setup:hosts
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
