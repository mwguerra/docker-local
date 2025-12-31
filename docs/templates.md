# Templates and Hooks

Customize new project creation with templates, hooks, and custom files.

## Overview

When you run `docker-local make:laravel <project>`, the system:

1. Executes `hooks/pre-install.sh` (if exists)
2. Creates Laravel project via Composer
3. Generates `.env` with unique identifiers
4. Executes `install.sh` (if exists)
5. Executes `hooks/post-install.sh` (if exists)
6. Generates `APP_KEY`

## Directory Structure

```
templates/
├── install.sh              # Main customization script
├── hooks/
│   ├── pre-install.sh      # Before Laravel creation
│   └── post-install.sh     # After .env, before APP_KEY
└── files/                  # Custom files to copy
    ├── .editorconfig       # Example custom file
    ├── phpstan.neon        # Example custom file
    └── ...
```

---

## Main Installation Script

### templates/install.sh

This script runs after Laravel is created and `.env` is configured.

**Available Variables:**
- `$1` / `$PROJECT_NAME` - Project name
- `$2` / `$PROJECT_PATH` - Full path to project

### Example: Development Packages

```bash
#!/bin/bash
PROJECT_NAME=$1
PROJECT_PATH=$2

echo "Installing development packages..."

docker exec -w "/var/www/$PROJECT_NAME" php composer require --dev \
    laravel/telescope \
    barryvdh/laravel-debugbar \
    laravel/pint \
    pestphp/pest --with-all-dependencies
```

### Example: Authentication Setup

```bash
#!/bin/bash
PROJECT_NAME=$1
PROJECT_PATH=$2

echo "Setting up authentication..."

# Install Sanctum
docker exec -w "/var/www/$PROJECT_NAME" php composer require laravel/sanctum
docker exec -w "/var/www/$PROJECT_NAME" php php artisan vendor:publish \
    --provider="Laravel\Sanctum\SanctumServiceProvider"
```

### Example: Admin Panel

```bash
#!/bin/bash
PROJECT_NAME=$1
PROJECT_PATH=$2

echo "Installing Filament admin panel..."

docker exec -w "/var/www/$PROJECT_NAME" php composer require filament/filament:"^3.0"
docker exec -w "/var/www/$PROJECT_NAME" php php artisan filament:install --panels
```

### Example: Spatie Packages

```bash
#!/bin/bash
PROJECT_NAME=$1
PROJECT_PATH=$2

echo "Installing Spatie packages..."

docker exec -w "/var/www/$PROJECT_NAME" php composer require \
    spatie/laravel-permission \
    spatie/laravel-medialibrary \
    spatie/laravel-activitylog
```

---

## Hooks

### Pre-Install Hook

**templates/hooks/pre-install.sh**

Runs before Laravel project creation.

Use cases:
- Validate project name
- Check prerequisites
- Prepare external resources

```bash
#!/bin/bash
PROJECT_NAME=$1
PROJECT_PATH=$2

echo "Preparing to create $PROJECT_NAME..."

# Example: Create GitHub repository
# gh repo create $PROJECT_NAME --private

# Example: Validate name format
if [[ ! "$PROJECT_NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
    echo "Error: Project name must be lowercase alphanumeric with hyphens"
    exit 1
fi
```

### Post-Install Hook

**templates/hooks/post-install.sh**

Runs after `.env` is configured but before `APP_KEY` is generated.

Use cases:
- Run migrations
- Seed database
- Create storage links
- Initialize git

```bash
#!/bin/bash
PROJECT_NAME=$1
PROJECT_PATH=$2

echo "Finalizing $PROJECT_NAME setup..."

# Run migrations
docker exec -w "/var/www/$PROJECT_NAME" php php artisan migrate

# Create storage link
docker exec -w "/var/www/$PROJECT_NAME" php php artisan storage:link

# Install npm dependencies
docker exec -w "/var/www/$PROJECT_NAME" php npm install
docker exec -w "/var/www/$PROJECT_NAME" php npm run build

# Initialize git
cd "$PROJECT_PATH"
git init
git add .
git commit -m "Initial commit - Laravel project created"
```

---

## Custom Files

### templates/files/

Place any files here to be copied to new projects.

Example structure:
```
templates/files/
├── .editorconfig
├── .php-cs-fixer.php
├── phpstan.neon
├── rector.php
└── .github/
    └── workflows/
        └── ci.yml
```

### Copying Files in install.sh

```bash
#!/bin/bash
PROJECT_NAME=$1
PROJECT_PATH=$2
TEMPLATES_DIR="$(dirname "$0")"

# Copy all files from templates/files
if [ -d "$TEMPLATES_DIR/files" ]; then
    cp -r "$TEMPLATES_DIR/files/." "$PROJECT_PATH/"
    echo "Custom files copied"
fi

# Or copy specific files
if [ -f "$TEMPLATES_DIR/files/.editorconfig" ]; then
    cp "$TEMPLATES_DIR/files/.editorconfig" "$PROJECT_PATH/"
fi
```

---

## Complete Example

### Full install.sh Template

```bash
#!/bin/bash

# ==============================================================================
# install.sh - Custom installation script for new Laravel projects
# ==============================================================================

PROJECT_NAME=$1
PROJECT_PATH=$2
TEMPLATES_DIR="$(dirname "$0")"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Running custom installation for ${PROJECT_NAME}...${NC}"

# ==============================================================================
# COMPOSER PACKAGES
# ==============================================================================

# Development packages
docker exec -w "/var/www/$PROJECT_NAME" php composer require --dev \
    laravel/telescope \
    barryvdh/laravel-debugbar \
    laravel/pint \
    pestphp/pest --with-all-dependencies

# Publish Telescope
docker exec -w "/var/www/$PROJECT_NAME" php php artisan telescope:install

# Authentication
docker exec -w "/var/www/$PROJECT_NAME" php composer require laravel/sanctum

# ==============================================================================
# ARTISAN COMMANDS
# ==============================================================================

# Run migrations
docker exec -w "/var/www/$PROJECT_NAME" php php artisan migrate

# Create storage link
docker exec -w "/var/www/$PROJECT_NAME" php php artisan storage:link

# ==============================================================================
# NPM/FRONTEND
# ==============================================================================

docker exec -w "/var/www/$PROJECT_NAME" php npm install
docker exec -w "/var/www/$PROJECT_NAME" php npm run build

# ==============================================================================
# CUSTOM DIRECTORY STRUCTURE
# ==============================================================================

mkdir -p "$PROJECT_PATH/app/Actions"
mkdir -p "$PROJECT_PATH/app/Services"
mkdir -p "$PROJECT_PATH/app/Repositories"
mkdir -p "$PROJECT_PATH/app/Traits"
mkdir -p "$PROJECT_PATH/app/Enums"
mkdir -p "$PROJECT_PATH/app/DTOs"

# ==============================================================================
# CUSTOM FILES
# ==============================================================================

if [ -d "$TEMPLATES_DIR/files" ]; then
    cp -r "$TEMPLATES_DIR/files/." "$PROJECT_PATH/"
fi

# ==============================================================================
# GIT INITIALIZATION
# ==============================================================================

cd "$PROJECT_PATH"
git init
git add .
git commit -m "Initial commit - Laravel project with custom setup"

echo -e "${GREEN}Custom installation complete!${NC}"
```

---

## Laravel .env Template

When creating a project, these variables are automatically configured:

```env
APP_NAME=project_name
APP_ENV=local
APP_DEBUG=true
APP_URL=https://project.test

# Database (MySQL)
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=secret

# Cache (unique prefix)
CACHE_STORE=redis
CACHE_PREFIX=project_cache_

# Redis
REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379

# Session
SESSION_DRIVER=redis
SESSION_LIFETIME=120

# Queue
QUEUE_CONNECTION=redis

# S3/MinIO
FILESYSTEM_DISK=s3
AWS_ACCESS_KEY_ID=minio
AWS_SECRET_ACCESS_KEY=minio123
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=laravel
AWS_ENDPOINT=http://minio:9000
AWS_USE_PATH_STYLE_ENDPOINT=true

# Mail
MAIL_MAILER=smtp
MAIL_HOST=mailpit
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null

# Broadcasting/WebSockets (unique IDs)
BROADCAST_CONNECTION=reverb
REVERB_APP_ID=847291
REVERB_APP_KEY=<random-base64>
REVERB_APP_SECRET=<random-base64>
REVERB_HOST=localhost
REVERB_PORT=8080
REVERB_SCHEME=http
```

---

## Tips

### Running Commands in Container

Always use the Docker exec pattern:

```bash
docker exec -w "/var/www/$PROJECT_NAME" php <command>
```

Examples:
```bash
# Composer
docker exec -w "/var/www/$PROJECT_NAME" php composer require package/name

# Artisan
docker exec -w "/var/www/$PROJECT_NAME" php php artisan migrate

# NPM
docker exec -w "/var/www/$PROJECT_NAME" php npm install
```

### Conditional Installation

```bash
# Only install if package not present
if ! docker exec -w "/var/www/$PROJECT_NAME" php composer show laravel/sanctum 2>/dev/null; then
    docker exec -w "/var/www/$PROJECT_NAME" php composer require laravel/sanctum
fi
```

### Environment-Based Configuration

```bash
# Check environment variable
if [ "${INSTALL_FILAMENT:-false}" = "true" ]; then
    docker exec -w "/var/www/$PROJECT_NAME" php composer require filament/filament
fi
```

### Interactive Mode

```bash
# Ask user
read -p "Install Filament? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker exec -w "/var/www/$PROJECT_NAME" php composer require filament/filament
fi
```
