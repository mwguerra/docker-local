# Laravel Docker Development Environment - Documentation

Complete documentation for the Laravel Docker Development Environment.

## Overview

This is a **production-ready local development stack** for Laravel that:
- Replaces Laravel Valet (especially for Linux)
- Provides complete Docker containerization
- Supports HTTPS/SSL with system-trusted certificates
- Enables multiple simultaneous projects with custom domains
- Includes wildcard subdomain support

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
# 1. Clone the repository
git clone <repo-url> ~/docker-environment && cd ~/docker-environment

# 2. Install CLI globally
./scripts/install-cli.sh

# 3. Run complete setup
docker-local init

# 4. Create your first project
docker-local make:laravel my-project

# 5. Access it
# https://my-project.test
```

## Directory Structure

```
~/docker-environment/           # Docker environment
├── bin/docker-local            # CLI (50+ commands)
├── docker-compose.yml          # Service definitions
├── php/                        # PHP configuration
├── nginx/                      # Nginx configuration
├── mysql/                      # MySQL configuration
├── postgres/                   # PostgreSQL configuration
├── redis/                      # Redis configuration
├── traefik/                    # Traefik configuration
├── scripts/                    # Helper scripts
├── templates/                  # Project templates
└── docs/                       # Documentation

~/projects/                     # Your Laravel projects
├── blog/                       → https://blog.test
├── api/                        → https://api.test
└── shop/                       → https://shop.test
```

## System Requirements

- Docker 24.0+ and Docker Compose 2.20+
- Linux (Ubuntu/Debian/Fedora/Arch), macOS 12+, or Windows (WSL2)
- 8GB RAM minimum, 16GB recommended
- 20GB free disk space

## Support

For issues and feature requests, please refer to the project repository.
