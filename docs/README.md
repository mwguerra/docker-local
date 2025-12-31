# docker-local Documentation

Complete documentation for **docker-local** (`mwguerra/docker-local`), a global Composer package that provides a complete Docker development environment for Laravel.

## Overview

**docker-local** is a **production-ready local development stack** for Laravel that:
- Installs globally via Composer — no per-project Docker files needed
- Replaces Laravel Valet (especially for Linux)
- Provides complete Docker containerization with 50+ CLI commands
- Supports HTTPS/SSL with system-trusted certificates
- Enables multiple simultaneous projects with custom domains
- Includes wildcard subdomain support and automatic project isolation

**Package:** `mwguerra/docker-local`
**Version:** 2.0.0
**License:** MIT

## Quick Links

| Document | Description |
|----------|-------------|
| [Getting Started](getting-started.md) | Installation and initial setup |
| [CLI Reference](cli-reference.md) | Complete command documentation |
| [Services](services.md) | Docker services configuration |
| [Architecture](architecture.md) | System design and request flow |
| [Templates](templates.md) | Project templates and hooks |
| [Troubleshooting](troubleshooting.md) | Common issues and solutions |

## Technology Stack

| Component | Version | Purpose |
|-----------|---------|---------|
| PHP | 8.4 | Application runtime with Xdebug, OPcache, JIT |
| MySQL | 9.1 | Primary relational database |
| PostgreSQL | 17 | Alternative relational database |
| Redis | 8 | Cache, sessions, queues, broadcasting |
| Traefik | 3.6 | Reverse proxy with automatic SSL/HTTPS |
| Nginx | Alpine | Web server with multi-project routing |
| MinIO | Latest | S3-compatible object storage |
| Mailpit | Latest | Email testing and visualization |

## Features

- **50+ CLI Commands** - Comprehensive management interface
- **PHP 8.4** with all Laravel extensions and Xdebug
- **MySQL 9.1** and **PostgreSQL 17** running simultaneously
- **Redis 8** for cache, sessions, and queues
- **Automatic SSL** with mkcert certificates
- **Wildcard Subdomains** (e.g., `api.myproject.test`)
- **Project Isolation** - Automatic conflict detection
- **PHP Local Support** - Works with both Docker and local PHP

## Quick Start

```bash
# 1. Install globally via Composer
composer global require mwguerra/docker-local

# 2. Add to PATH (add to ~/.bashrc or ~/.zshrc for persistence)
export PATH="$HOME/.composer/vendor/bin:$PATH"

# 3. Run complete setup
docker-local init

# 4. Create your first project
docker-local make:laravel my-project

# 5. Access it
# https://my-project.test
```

See [Getting Started](getting-started.md) for detailed installation instructions for all platforms.

## Directory Structure

docker-local uses three locations on your system:

```
~/.composer/vendor/mwguerra/docker-local/  # Package (Composer managed)
├── bin/docker-local                       # CLI entry point
├── src/                                   # PHP classes
├── docker-compose.yml                     # Service definitions
├── php/, nginx/, mysql/, ...              # Docker configurations
├── scripts/                               # Helper scripts
└── docs/                                  # Documentation

~/.config/docker-local/                    # Your configuration (persistent)
├── config.json                            # Custom settings
├── .env                                   # Environment variables
├── certs/                                 # SSL certificates
└── docker-compose.override.yml            # Optional custom services

~/projects/                                # Your Laravel projects
├── blog/                                  → https://blog.test
├── api/                                   → https://api.test
└── shop/                                  → https://shop.test
```

## System Requirements

- Docker 24.0+ and Docker Compose 2.20+
- Linux (Ubuntu/Debian/Fedora/Arch), macOS 12+, or Windows (WSL2)
- 8GB RAM minimum, 16GB recommended
- 20GB free disk space

## Support

For issues and feature requests, please refer to the project repository.
